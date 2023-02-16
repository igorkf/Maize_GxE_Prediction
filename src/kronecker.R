library(data.table)

# generate files for each combination
args <- commandArgs(trailingOnly = TRUE)
debug <- as.logical(args[1])  # FALSE or TRUE  (for debugging set to TRUE)
dataset <- args[2]  # "train" or "val"
kinship_type <- args[3]  # "additive", "dominant", "epi_AA", "epi_DD", or "epi_AD"
kinship_path <- paste0("output/kinship_", kinship_type, ".txt")
outfile <- paste0("output/kronecker_", kinship_type, "_", dataset, ".feather")
cat("Debug mode:", debug, "\n")
cat("Using", kinship_type, "matrix\n")
cat("dataset:", dataset, "\n")


x <- fread(paste0("output/x", dataset, ".csv"), data.table = F)
x <- x[, !grepl("yield_lag", colnames(x))]  # remove all yield related features
x$Hybrid <- NULL 
x$Env <- substr(x$Env, 1, nchar(x$Env) - 5)
x <- aggregate(x, by = list(x$Env), FUN = tail, n = 1)  # keep only last row of each Env
x$Group.1 <- NULL
rownames(x) <- x$Env
x$Env <- NULL
x <- as.matrix(x)

y <- fread(paste0("output/y", dataset, ".csv"), data.table = F)
y$Env <- substr(y$Env, 1, nchar(y$Env) - 5)

if (debug == FALSE) {
  kinship <- fread(kinship_path, data.table = F)
} else{
  kinship <- fread(kinship_path, data.table = F, nrows = 100)
}
colnames(kinship) <- substr(colnames(kinship), 1, nchar(colnames(kinship)) / 2)  # fix column names
kinship <- as.matrix(kinship)
rownames(kinship) <- colnames(kinship)[1:dim(kinship)[1]]
kinship <- kinship[rownames(kinship) %in% y$Hybrid, ]

K <- kronecker(x, kinship, make.dimnames = T)
cat("K dim:", dim(K), "\n")

K <- K[rownames(K) %in% paste0(y$Env, ":", y$Hybrid), ]
cat("K dim:", dim(K), "\n")

# write to feather for fast reading
arrow::write_feather(
  data.frame(id = rownames(K), K), 
  outfile,
  chunk_size = 1000
)
cat("Writing file:", outfile, "\n\n")


