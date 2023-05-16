library(data.table)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
  debug <- FALSE
  dataset <- "train"
  kinship_type <- "additive"
} else {
  cv <- args[1]  # 0, 1, or 2
  debug <- as.logical(args[2])  # FALSE or TRUE  (for debugging set to TRUE)
  dataset <- args[3]  # "train" or "val"
  kinship_type <- args[4]  # "additive", "dominant", "epi_AA", "epi_DD", or "epi_AD"
}
kinship_path <- paste0("output/kinship_", kinship_type, ".txt")
outfile <- paste0("output/cv", cv, "/kronecker_", kinship_type, "_", dataset, ".feather")
cat("Debug mode:", debug, "\n")
cat("Using", kinship_type, "matrix\n")
cat("dataset:", dataset, "\n")

x <- fread(paste0("output/cv", cv, "/x", dataset, ".csv"), data.table = F)
x <- x[, !grepl("yield_lag", colnames(x))]  # remove all yield related features
x$Hybrid <- NULL 
x$Env <- substr(x$Env, 1, nchar(x$Env) - 5)
x <- aggregate(x, by = list(x$Env), FUN = tail, n = 1)  # keep only last row of each Env
x$Group.1 <- NULL
rownames(x) <- x$Env
x$Env <- NULL
x <- as.matrix(x)

y <- fread(paste0("output/cv", cv, "/y", dataset, ".csv"), data.table = F)
y$Env <- substr(y$Env, 1, nchar(y$Env) - 5)

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

# some Env:Hybrid combinations does not exist so we can remove
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


