library(data.table)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cv <- 0
  debug <- TRUE
  kinship_type <- "additive"
} else {
  cv <- args[1]  # 0, 1, or 2
  debug <- as.logical(args[2])  # FALSE or TRUE (for debugging set to TRUE)
  kinship_type <- args[3]  # "additive" or "dominant"
}
kinship_path <- paste0("output/kinship_", kinship_type, ".txt")
outfile <- paste0("output/cv", cv, "/kronecker_", kinship_type, ".arrow")
cat("Debug mode:", debug, "\n")
cat("Using", kinship_type, "matrix\n")

# read files
xtrain <- data.frame()
for (file in list.files('output/cv0', pattern = 'xtrain_fold*')) {
  xtrain <- rbind(xtrain, fread(paste0('output/cv', cv, '/', file), data.table = F))
}
xval <- data.frame()
for (file in list.files('output/cv0', pattern = 'xval_fold*')) {
  xval <- rbind(xval, fread(paste0('output/cv', cv, '/', file), data.table = F))
}

# bind files and aggregate
x <- rbind(xtrain, xval)
rm(xtrain); rm(xval); gc()
x <- x[, !grepl("yield_lag", colnames(x))]  # remove all yield-related features
x$Hybrid <- NULL
x <- aggregate(x[, -1], by = list(x$Env), FUN = mean)  # take mean within envs
rownames(x) <- x$Group.1
x$Group.1 <- NULL
x$Env <- NULL
x <- as.matrix(x)

# read phenotypes
ytrain <- data.frame()
for (file in list.files('output/cv0', pattern = 'ytrain_fold*')) {
  ytrain <- rbind(ytrain, fread(paste0('output/cv', cv, '/', file), data.table = F))
}
yval <- data.frame()
for (file in list.files('output/cv0', pattern = 'yval_fold*')) {
  yval <- rbind(yval, fread(paste0('output/cv', cv, '/', file), data.table = F))
}

# get unique combinations
y <- rbind(ytrain, yval)
hybrids <- unique(y$Hybrid)
env_hybrid <- unique(interaction(y$Env, y$Hybrid, sep = ':', drop = T))
rm(y); rm(ytrain); rm(yval); gc()

# load kinship
if (debug == FALSE) {
  kinship <- fread(kinship_path, data.table = F)
} else {
  kinship <- fread(kinship_path, data.table = F, nrows = 100)
}
colnames(kinship) <- substr(colnames(kinship), 1, nchar(colnames(kinship)) / 2)  # fix column names
kinship <- as.matrix(kinship)
rownames(kinship) <- colnames(kinship)[1:nrow(kinship)]
kinship <- kinship[rownames(kinship) %in% hybrids, colnames(kinship) %in% hybrids]
cat("kinship dim:", dim(kinship), "\n")

K <- kronecker(x, kinship, make.dimnames = T)
rm(x); rm(kinship); gc()
cat("K dim:", dim(K), "\n")

# some Env:Hybrid combinations were not phenotyped
K <- K[rownames(K) %in% env_hybrid, ]
cat("K dim:", dim(K), "\n")

# write to feather for fast reading
arrow::write_feather(
  data.frame(id = rownames(K), K), 
  outfile
)
rm(K); gc()
cat("Writing file:", outfile, "\n\n")
Sys.sleep(5)
