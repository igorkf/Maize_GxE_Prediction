options(warn = 1)

library(data.table)
library(asreml)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
  debug <- TRUE
  invert <- FALSE
} else {
  cv <- args[1]  # 0, 1, or 2
  debug <- as.logical(args[2])  # TRUE or FALSE
  invert <- as.logical(args[3]) # TRUE or FALSE
}
cat('debug:', debug, '\n')
cat('invert:', invert, '\n')

if (debug == TRUE) {
  asreml.options(
    workspace = '24gb',
    # pworkspace = '24gb',
    maxit = 300,
    na.action = na.method(y = 'include', x = 'omit')
  )
} else {
  asreml.options(
    workspace = '24gb',
    # pworkspace = '1gb',
    maxit = 300,
    na.action = na.method(y = 'include', x = 'omit')
  )
}

# datasets
ytrain <- fread(paste0('output/cv', cv, '/ytrain.csv'), data.table = F)
ytrain <- transform(ytrain, Env = factor(Env), Hybrid = factor(Hybrid))
ytrain$Field_Location <- factor(sub('_[^_]+$', '', ytrain$Env))
if (debug == TRUE) {
  ytrain <- subset(ytrain, Hybrid %in% rownames(kmatrix))
  rownames(ytrain) <- NULL
}
cat('ytrain shape:', dim(ytrain), '\n')
yval <- fread(paste0('output/cv', cv, '/yval.csv'), data.table = F)
yval <- transform(yval, Env = factor(Env), Hybrid = factor(Hybrid))
yval$Field_Location <- factor(sub('_[^_]+$', '', yval$Env))

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
if (invert == TRUE) {
  mod <- asreml(
    Yield_Mg_ha ~ Field_Location,
    random = ~ fa(Field_Location):vm(Hybrid, source = ginv),
    data = ytrain
  )
} else {
  mod <- asreml(
    Yield_Mg_ha ~ Field_Location,
    random = ~ fa(Field_Location):vm(Hybrid, source = kmatrix, singG = 'NSD'),
    # random = ~ vm(Hybrid, source = kmatrix, singG = 'NSD') + Field_Location:Hybrid,
    data = ytrain
  )
}
gc()

evaluate <- function(df) {
  df$error <- df$Yield_Mg_ha - df$predicted.value
  rmses <- with(df, aggregate(error, by = list(Field_Location), FUN = function(x) sqrt(mean(x ^ 2))))
  colnames(rmses) <- c('Env', 'RMSE')
  print(rmses)
  cat('RMSE:', mean(rmses$RMSE), '\n')
}

# predict and evaluate
cat('\nPrediction for Hybrid\n')
pred_hybrid <- predict.asreml(mod, classify = 'Hybrid')$pvals[, 1:2]
pred_hybrid <- merge(yval, pred_hybrid, by = 'Hybrid')
evaluate(pred_hybrid)
gc()

cat('\nPrediction for Env:Hybrid\n')
pred_env_hybrid <- predict.asreml(mod, classify = 'Field_Location:Hybrid')$pvals[, 1:3]
pred_env_hybrid <- merge(yval, pred_env_hybrid, by = c('Field_Location', 'Hybrid'))
evaluate(pred_env_hybrid)
gc()

# write predictions
cols <- c('Env', 'Hybrid', 'predicted.value')
fwrite(pred_hybrid[, cols], paste0('output/cv', cv, '/oof_gblup_hybrid_model.csv'))
fwrite(pred_env_hybrid[, cols], paste0('output/cv', cv, '/oof_gblup_env_hybrid_model.csv'))

