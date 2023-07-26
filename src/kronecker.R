library(data.table)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
  fold <- 0
  debug <- TRUE
  kinship_type <- "additive"
} else {
  cv <- args[1]  # 0, 1, or 2
  fold <- args[2]  # 0, 1, 2, 3 or 4
  debug <- as.logical(args[3])  # FALSE or TRUE (for debugging set to TRUE)
  kinship_type <- args[4]  # "additive", "dominant", "epi_AA", "epi_DD", or "epi_AD"
}
kinship_path <- paste0("output/kinship_", kinship_type, ".txt")
outfile <- paste0("output/cv", cv, "/kronecker_", kinship_type, "_fold", fold, ".feather")
cat("Debug mode:", debug, "\n")
cat("Using", kinship_type, "matrix\n")

xtrain <- fread(paste0("output/cv", cv, "/xtrain_fold", fold, ".csv"), data.table = F)
xval <- fread(paste0("output/cv", cv, "/xval_fold", fold, ".csv"), data.table = F)
x <- rbind(xtrain, xval)
x <- x[, !grepl("yield_lag", colnames(x))]  # remove all yield related features
x$Hybrid <- NULL
x <- aggregate(x, by = list(x$Env), FUN = tail, n = 1)  # keep only last row of each Env
x$Group.1 <- NULL
rownames(x) <- x$Env
x$Env <- NULL
x <- as.matrix(x)

ytrain <- fread(paste0("output/cv", cv, "/ytrain_fold", fold, ".csv"), data.table = F)
yval <- fread(paste0("output/cv", cv, "/yval_fold", fold, ".csv"), data.table = F)
y <- rbind(ytrain, yval)

if (debug == FALSE) {
  kinship <- fread(kinship_path, data.table = F)
} else {
  kinship <- fread(kinship_path, data.table = F, nrows = 100)
}
colnames(kinship) <- substr(colnames(kinship), 1, nchar(colnames(kinship)) / 2)  # fix column names
kinship <- as.matrix(kinship)
rownames(kinship) <- colnames(kinship)
kinship <- kinship[rownames(kinship) %in% y$Hybrid, colnames(kinship) %in% y$Hybrid]

K <- kronecker(x, kinship, make.dimnames = T)
rm(x); rm(kinship); gc()
cat("K dim:", dim(K), "\n")

# some Env:Hybrid combinations were not phenotyped
K <- K[rownames(K) %in% paste0(y$Env, ":", y$Hybrid), ]
rm(y)
cat("K dim:", dim(K), "\n")

# write to feather for fast reading
arrow::write_feather(
  data.frame(id = rownames(K), K), 
  outfile,
  chunk_size = 1000
)
rm(K); gc()
cat("Writing file:", outfile, "\n\n")
Sys.sleep(5)
