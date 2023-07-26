options(warn = 1)

library(data.table)
library(asreml)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
  fold <- 0
  debug <- TRUE
  invert <- FALSE
} else {
  cv <- args[1]  # 0, 1, or 2
  fold <- args[2]  # 0, 1, 2, 3, or 4
  debug <- as.logical(args[3])  # TRUE or FALSE
  invert <- as.logical(args[4]) # TRUE or FALSE
}
cat('debug:', debug, '\n')
cat('invert:', invert, '\n')

if (cv == 0) {
  asreml.options(
    workspace = '8gb',
    pworkspace = '8gb',
    maxit = 300,
    na.action = na.method(y = 'include', x = 'omit')
  )
} else {
  asreml.options(
    workspace = '12gb',
    pworkspace = '12gb',
    maxit = 300,
    na.action = na.method(y = 'include', x = 'omit')
  )
}

# datasets
ytrain <- fread(paste0('output/cv', cv, '/ytrain_fold', fold, '.csv'), data.table = F)
ytrain <- transform(ytrain, Env = factor(Env), Hybrid = factor(Hybrid))
cat('ytrain shape:', dim(ytrain), '\n')
yval <- fread(paste0('output/cv', cv, '/yval_fold', fold, '.csv'), data.table = F)
yval <- transform(yval, Env = factor(Env), Hybrid = factor(Hybrid))

# additive matrix
kmatrix <- fread('output/kinship_additive.txt', data.table = F)
kmatrix <- as.matrix(kmatrix)
colnames(kmatrix) <- substr(colnames(kmatrix), 1, nchar(colnames(kmatrix)) / 2)  # fix column names
rownames(kmatrix) <- colnames(kmatrix)
print(kmatrix[1:5, 1:5])

# keep only phenotyped individuals
ind_idxs <- which(rownames(kmatrix) %in% c(ytrain$Hybrid, yval$Hybrid) == TRUE)
kmatrix <- kmatrix[ind_idxs, ind_idxs]
if (debug == TRUE) {
  set.seed(2023)
  sampled_idx <- sample(1:nrow(kmatrix), 100)
  kmatrix <- kmatrix[sampled_idx, sampled_idx]
  ytrain <- subset(ytrain, Hybrid %in% rownames(kmatrix))
}
cat('Number of individuals being used:', nrow(kmatrix), '\n')

# invert relationship matrix
if (invert == TRUE) {
  A <- MASS::ginv(kmatrix)
  print(A[1:5, 1:5])

  # changing inverted A matrix format to be used in asreml
  A[upper.tri(A)] <- NA
  A <- na.omit(reshape2::melt(A))  # returns data.frame row, col, value
  rownames(A) <- NULL
  ginv <- data.frame(
    Row = A[, 2],
    Column = A[, 1],
    GINV = A[, 3]
  )
  attr(ginv, 'rowNames') <- rownames(kmatrix)
  attr(ginv, 'INVERSE') <- TRUE
}

# modeling
set.seed(2023)
if (invert == TRUE) {
  mod <- asreml(
    Yield_Mg_ha ~ Env,
    random = ~ fa(Env):vm(Hybrid, source = ginv),
    predict = predict.asreml(classify = 'Env:Hybrid'),
    data = ytrain
  )
} else {
  mod <- asreml(
    Yield_Mg_ha ~ Env,
    random = ~ fa(Env):vm(Hybrid, source = kmatrix, singG = 'NSD'),
    predict = predict.asreml(classify = 'Env:Hybrid'),
    data = ytrain,
  )
}
gc()
varcomp <- summary(mod)$varcomp
varcomp <- transform(varcomp, component = round(component, 8))
print(varcomp)
fa_comps <- nrow(varcomp) - 1  # -1 due sigma_R
cat('Number of components estimated for FA(1):', fa_comps, '\n')

# FA number of estimated components is E(k+1) - k(k-1)/2, where E is the number of environments and k is the FA order
E <- length(unique(ytrain$Env))
k <- 1
exp_fa_comps <- E * (k + 1) - 0.5 * k * (k - 1)
cat('Number of componentes expected from formula (E(k+1) - k(k-1)/2):', exp_fa_comps, '\n')

evaluate <- function(df) {
  df$error <- df$Yield_Mg_ha - df$predicted.value
  rmses <- with(df, aggregate(error, by = list(Env), FUN = function(x) sqrt(mean(x ^ 2))))
  colnames(rmses) <- c('Env', 'RMSE')
  print(rmses)
  cat('RMSE:', mean(rmses$RMSE), '\n')
}

pred <- mod$predictions$pvals[, 1:3]
pred_train_env_hybrid <- merge(ytrain, pred, by = c('Env', 'Hybrid'))

# average between years
val_year <- sub('(.*)_', '', yval$Env[1])
pred$Field_Location <- as.factor(sub('_(.*)', '', pred$Env))
pred <- with(pred, aggregate(predicted.value, list(Field_Location, Hybrid), mean))
colnames(pred) <- c('Field_Location', 'Hybrid', 'predicted.value')
pred$Env <- paste0(pred$Field_Location, '_', val_year)

# merge on val
pred_env_hybrid <- merge(yval, pred, by = c('Env', 'Hybrid'))
evaluate(pred_env_hybrid)

# write predictions
cols <- c('Env', 'Hybrid', 'Yield_Mg_ha', 'predicted.value')
pred_env_hybrid <- pred_env_hybrid[, cols]
colnames(pred_env_hybrid) <- c('Env', 'Hybrid', 'ytrue', 'ypred')
fwrite(pred_env_hybrid, paste0('output/cv', cv, '/oof_gblup_env_hybrid_model_fold', fold, '.csv'))

# write predictions for train
pred_train_env_hybrid <- pred_train_env_hybrid[, cols]
colnames(pred_train_env_hybrid) <- c('Env', 'Hybrid', 'ytrue', 'ypred')
fwrite(pred_train_env_hybrid, paste0('output/cv', cv, '/pred_train_gblup_env_hybrid_model_fold', fold, '.csv'))

cor(pred_env_hybrid$ytrue, pred_env_hybrid$ypred)
# plot(pred_env_hybrid$ytrue, pred_env_hybrid$ypred)

