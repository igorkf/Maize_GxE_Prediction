options(warn = 1)

library(data.table)
library(BGLR)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
} else {
  cv <- args[1]  # 0, 1, or 2
}

# datasets
ytrain <- fread(paste0('output/cv', cv, '/ytrain.csv'), data.table = F)
ytrain <- transform(ytrain, Env = factor(Env), Hybrid = factor(Hybrid))
ytrain$Field_Location <- factor(sub('_[^_]+$', '', ytrain$Env))
cat('ytrain shape:', dim(ytrain), '\n')

yval <- fread(paste0('output/cv', cv, '/yval.csv'), data.table = F)
yval <- transform(yval, Env = factor(Env), Hybrid = factor(Hybrid))
yval$Field_Location <- factor(sub('_[^_]+$', '', yval$Env))
cat('yval shape:', dim(yval), '\n')

# additive matrix
kmatrix <- fread('output/kinship_additive.txt', data.table = F)
kmatrix <- as.matrix(kmatrix)
colnames(kmatrix) <- substr(colnames(kmatrix), 1, nchar(colnames(kmatrix)) / 2)  # fix column names
rownames(kmatrix) <- colnames(kmatrix)
print(kmatrix[1:5, 1:5])

# keep only phenotyped individuals
unique_inds <- unique(c(ytrain$Hybrid, yval$Hybrid))
kmatrix <- kmatrix[unique_inds, unique_inds]
cat('Number of individuals being used:', nrow(kmatrix), '\n')

# pivot wide
ytrain_wider <- tidyr::pivot_wider(
  ytrain[, c('Field_Location', 'Hybrid', 'Yield_Mg_ha')],
  names_from = Field_Location, values_from = Yield_Mg_ha
)
assertthat::are_equal(dim(kmatrix)[1], dim(ytrain_wider)[1])
# cor(as.matrix(ytrain_wider[, -1]), use = 'pairwise.complete.obs')


# -----------------------

# GBLUP using FA1
M <- matrix(nrow = ncol(ytrain_wider[, -1]), ncol = 1, data = T)
CovFA <- list(type = 'FA', M = M)  # M is the number of environments (or traits if model is multi-trait)
ETA <- list(A = list(K = kmatrix, model = 'RKHS', Cov = CovFA))

fit_model <- function() {
  mod <- Multitrait(
    y = as.matrix(ytrain_wider[, -1]),  # Phenotypic data
    ETA = ETA,          # Model ETA
    resCov = list(type = 'DIAG'),  # default is UN (unstructured)
    nIter = 5000,       # Number of iterations for the model
    burnIn = 500,       # Burnin iterations
    thin = 5,           # Sampling throughout iterations
    saveAt = paste0('output/cv', cv, '/BGLR/GBLUP_FA_'),
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


# -----------------------


# page 251 from Genetic Data Analysis for Plant and Animal Breeding (maybe formula 8.23?)
build_predictions <- function(y_wider, mod) {
  yhat <- data.frame(Hybrid = y_wider$Hybrid)
  yhat <- cbind(yhat, mod$ETAHat)
  yhat <- tidyr::pivot_longer(yhat, cols = -Hybrid, names_to = 'Field_Location', values_to = 'predicted.value')
  yhat <- merge(yval, yhat, by = c('Field_Location', 'Hybrid'))
  assertthat::are_equal(nrow(yhat), nrow(yval))
  return(yhat)
}

evaluate <- function(df) {
  df$error <- df$Yield_Mg_ha - df$predicted.value
  rmses <- with(df, aggregate(error, by = list(Field_Location), FUN = function(x) sqrt(mean(x ^ 2))))
  colnames(rmses) <- c('Env', 'RMSE')
  print(rmses)
  cat('RMSE:', mean(rmses$RMSE), '\n')
}

yhat <- build_predictions(ytrain_wider, mod)
evaluate(yhat)

# write predictions
cols <- c('Env', 'Hybrid', 'Yield_Mg_ha', 'predicted.value')
pred_env_hybrid <- yhat[, cols]
colnames(pred_env_hybrid) <- c('Env', 'Hybrid', 'ytrue', 'ypred')
fwrite(pred_env_hybrid, paste0('output/cv', cv, '/oof_gblup_bglr_model.csv'))

# write predictions for train
# pred_train_env_hybrid <- pred_train_env_hybrid[, cols]
# colnames(pred_train_env_hybrid) <- c('Env', 'Hybrid', 'ytrue', 'ypred')
# fwrite(pred_train_env_hybrid, paste0('output/cv', cv, '/pred_train_gblup_env_hybrid_model.csv'))

# compare with asreml model predictions
asr <- read.csv(paste0('output/cv', cv, '/oof_gblup_env_hybrid_model.csv'))
cat('Correlation between asreml and BGLR predictions:\n', cor(asr$ypred, pred_env_hybrid$ypred))

