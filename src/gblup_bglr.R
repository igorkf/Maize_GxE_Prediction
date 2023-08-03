options(warn = 1)

library(data.table)
library(BGLR)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
  fold <- 0
  seed <- 1
} else {
  cv <- args[1]  # 0, 1, or 2
  fold <- args[2]  # 0, 1, 2, 3 or 4
  seed <- args[3]  # 1, ..., 10
}
cat('Fold:', fold, '\n')

# datasets
ytrain <- fread(paste0('output/cv', cv, '/ytrain_fold', fold, '_seed', seed, '.csv'), data.table = F)
ytrain <- transform(ytrain, Env = factor(Env), Hybrid = factor(Hybrid))
cat('ytrain shape:', dim(ytrain), '\n')

yval <- fread(paste0('output/cv', cv, '/yval_fold', fold, '_seed', seed, '.csv'), data.table = F)
yval <- transform(yval, Env = factor(Env), Hybrid = factor(Hybrid))
cat('yval shape:', dim(yval), '\n')

# additive matrix
kmatrix <- fread('output/kinship_additive.txt', data.table = F)
kmatrix <- as.matrix(kmatrix)
colnames(kmatrix) <- substr(colnames(kmatrix), 1, nchar(colnames(kmatrix)) / 2)  # fix column names
rownames(kmatrix) <- colnames(kmatrix)
print(kmatrix[1:5, 1:5])
unique_inds <- unique(c(ytrain$Hybrid, yval$Hybrid))  # keep only phenotyped individuals
kmatrix <- kmatrix[unique_inds, unique_inds]
cat('Number of individuals being used:', nrow(kmatrix), '\n')


# ---------------------------------
# prep data for GBLR
if (cv == 0) {
  # for CV0-Year we dont need to bind train/val
  ytrain_wider <- reshape(ytrain, direction = 'wide', idvar = 'Hybrid', timevar = 'Env')
}

if (cv %in% c(1, 2)) {
  # unknown hybrids must be in the matrix as NA
  ytrain_wider <- reshape(rbind(ytrain, yval), direction = 'wide', idvar = 'Hybrid', timevar = 'Env')
}

# fix column names
colnames(ytrain_wider) <- sub('Yield_Mg_ha.', '', colnames(ytrain_wider))
ytrain_wider <- ytrain_wider[order(factor(ytrain_wider$Hybrid, levels = rownames(kmatrix))), ]  # keep same order as kmatrix
rownames(ytrain_wider) <- NULL

if (cv == 2) {
  # we dont need some envs here
  ytrain_wider$MIH1_2020 <- NULL
  ytrain_wider$NCH1_2020 <- NULL
  ytrain_wider$TXH2_2020 <- NULL
  ytrain_wider$SCH1_2020 <- NULL
  ytrain_wider$NYS1_2020 <- NULL
  ytrain_wider$NYS1_2021 <- NULL
  ytrain_wider$COH1_2021 <- NULL
  
  if (fold == 2) {
    ytrain_wider$GAH2_2020 <- NULL
    ytrain_wider$NEH3_2020 <- NULL
    ytrain_wider$TXH1_2020 <- NULL
  }
  
  if (fold == 3) {
    ytrain_wider$NEH3_2020 <- NULL
  }
  
  if (fold == 4) {
    ytrain_wider$NEH1_2020 <- NULL
    ytrain_wider$NEH3_2020 <- NULL
  }
}

# missings
missing_per_env <- colSums(is.na(ytrain_wider[, -1])) / nrow(ytrain_wider[, -1])
missing_per_gen <- rowSums(is.na(ytrain_wider[, -1])) / ncol(ytrain_wider[, -1])
names(missing_per_gen) <- ytrain_wider$Hybrid

# threshold for sparse envs
estimate_fa <- missing_per_env < 0.82
M <- as.matrix(unname(estimate_fa))
cat('# Environments:', nrow(M), '\n')
cat('# Environments set to TRUE:', length(M[M == T, 1]), '\n')


# -------------------------------
# fit GBLUP using FA1
ETA <- list(G = list(K = kmatrix, model = 'RKHS', Cov = list(type = 'FA', M = M)))
# ETA$G$Cov$df0 <- 10
ETA$G$Cov$S0 <- rep(10, nrow(M))
resCov <- list(type = 'DIAG', S0 = rep(1, nrow(M)))

fit_model <- function() {
  mod <- Multitrait(
    y = as.matrix(ytrain_wider[, -1]),  # Phenotypic data
    ETA = ETA,
    resCov = resCov,  # default is UN (unstructured)
    nIter = 5000,       # Number of iterations for the model
    burnIn = 500,       # Burnin iterations
    thin = 5,           # Sampling throughout iterations
    saveAt = paste0('output/cv', cv, '/BGLR/GBLUP_FA_fold', fold, '_seed', seed, '_'),
    verbose = T
  )
  return(mod)
}

run <- function() {
  mod <- T
  while (is.list(mod) == F) {
    mod <- tryCatch({fit_model()}, error = function(e) { return(TRUE) })
  }
  return(mod)
}

set.seed(2023)
start <- proc.time()[3]
mod <- run()
end <- proc.time()[3]
elapsed <- (end - start) / 60
cat('Time to fit:', elapsed, 'minutes', '\n')


# -----------------------------
# predictions
# -----------------------------

# store predictions
pred <- as.data.frame(mod$ETAHat)
pred$Hybrid <- ytrain_wider$Hybrid

# bind predictions in val
pred_longer <- reshape2::melt(pred, id.vars = c('Hybrid'), variable.name = 'Env', value.name = 'predicted.value')
pred_longer$Field_Location <- sub('_(.*)', '', pred_longer$Env)
pred_longer <- with(pred_longer, aggregate(predicted.value, list(Field_Location, Hybrid), mean))
colnames(pred_longer) <- c('Field_Location', 'Hybrid', 'predicted.value')
val_year <- sub('(.*)_', '', yval$Env[1])
pred_longer$Env <- paste0(pred_longer$Field_Location, '_', val_year)
pred_longer <- merge(yval, pred_longer, by = c('Env', 'Hybrid'), all.x = TRUE)  # left join
assertthat::are_equal(nrow(yval), nrow(pred_longer))
cat('NAs remaining:', nrow(pred_longer[is.na(pred_longer$predicted.value), ]), '\n')
pred_longer[is.na(pred_longer$predicted.value), 'predicted.value'] <- mean(pred_longer$predicted.value, na.rm = T)  # fill NA if needed
cat('cor:', cor(pred_longer$Yield_Mg_ha, pred_longer$predicted.value, use = 'complete.obs'), '\n')
# plot(pred_longer$Yield_Mg_ha, pred_longer$predicted.value)

evaluate <- function(df) {
  df$error <- df$Yield_Mg_ha - df$predicted.value
  rmses <- with(df, aggregate(error, by = list(Env), FUN = function(x) sqrt(mean(x ^ 2))))
  colnames(rmses) <- c('Env', 'RMSE')
  print(rmses)
  cat('RMSE:', mean(rmses$RMSE), '\n')
}

evaluate(pred_longer)

# -----------------------
# write predictions
cols <- c('Env', 'Hybrid', 'Yield_Mg_ha', 'predicted.value')
pred_longer <- pred_longer[, cols]
colnames(pred_longer) <- c('Env', 'Hybrid', 'ytrue', 'ypred')
head(pred_longer)
fwrite(pred_longer, paste0('output/cv', cv, '/oof_gblup_bglr_model_fold', fold, '_seed', seed, '.csv'))

# write predictions for train
# pred_train_env_hybrid <- pred_train_env_hybrid[, cols]
# colnames(pred_train_env_hybrid) <- c('Env', 'Hybrid', 'ytrue', 'ypred')
# fwrite(pred_train_env_hybrid, paste0('output/cv', cv, '/pred_train_gblup_env_hybrid_model.csv'))

# compare with asreml model predictions
# asr <- read.csv(paste0('output/cv', cv, '/oof_gblup_env_hybrid_model.csv'))
# cat('Correlation between asreml and BGLR predictions:\n', cor(asr$ypred, pred_env_hybrid$ypred), '\n')
