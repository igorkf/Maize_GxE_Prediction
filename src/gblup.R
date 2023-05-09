library(data.table)
library(asreml)

args <- commandArgs(trailingOnly = TRUE)
cv <- args[1]  # 0, 1, or 2
outfile <- paste0('output/cv', cv, '/oof_gblup_model.csv')

asreml.options(
  workspace = '4000mb',
  pworkspace = '4000mb',
  maxit = 300,
  na.action = na.method(y = 'include', x = 'omit')
)

# additive matrix
kmatrix <- fread('output/kinship_additive.txt', data.table = F)
kmatrix <- as.matrix(kmatrix)
colnames(kmatrix) <- substr(colnames(kmatrix), 1, nchar(colnames(kmatrix)) / 2)  # fix column names
rownames(kmatrix) <- colnames(kmatrix)
kmatrix[1:5, 1:5]

# invert relationship matrix
# A <- MASS::ginv(kmatrix)
# A[1:5, 1:5]

# changing inverted A matrix format to be used in asreml
# A[upper.tri(A)] <- NA
# A <- na.omit(reshape2::melt(A))  # returns data.frame row, col, value
# rownames(A) <- NULL
# ginv <- data.frame(
#   Row = A[, 2],
#   Column = A[, 1], 
#   GINV = A[, 3]
# )
# attr(ginv, 'rowNames') <- rownames(kmatrix)
# attr(ginv, 'INVERSE') <- TRUE

# modeling
ytrain <- fread(paste0('output/cv', cv, '/ytrain.csv'), data.table = F)
ytrain <- transform(ytrain, Env = factor(Env), Hybrid = factor(Hybrid))
mod <- asreml(
  Yield_Mg_ha ~ Env,
  # random = ~ Hybrid,
  random = ~ vm(Hybrid, source = kmatrix, singG = 'NSD'),
  predict = predict.asreml(classify = 'Hybrid', sed = TRUE),
  data = ytrain
)

# evaluate
yval <- fread(paste0('output/cv', cv, '/yval.csv'), data.table = F)
yval <- transform(yval, Env = factor(Env), Hybrid = factor(Hybrid))
preds <- merge(yval, mod$predictions$pvals, by = 'Hybrid')
preds$error <- preds$Yield_Mg_ha - preds$predicted.value
rmses <- with(preds, aggregate(error, by = list(Env), FUN = function(x) sqrt(mean(x ^ 2))))
colnames(rmses) <- c('Env', 'RMSE')
print(rmses)
cat('RMSE:', mean(rmses$RMSE))

# write predictions
fwrite(preds, outfile)






