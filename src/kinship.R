library(simplePHENOTYPES)
library(data.table)
library(AGHmatrix)

# converting from vcf to numeric...some files can be removed afterwards (only look at the *_numeric.txt file)
create_phenotypes(
  geno_file = "output/maize_pruned.vcf",
  add_QTN_num = 1,
  add_effect = 0.2,
  big_add_QTN_effect = 0.9,
  rep = 10,
  h2 = 0.7,
  model = "A",
  home_dir = getwd(),
  out_geno = "numeric",
)

# loading the numeric file
# SNPs are -1, 0, or 1
dt_num <- fread("maize_pruned_numeric.txt", data.table = F)
dt_num[1:5, 1:5]

# the package AGHmatrix requires SNPs to be 0, 1, or 2
# transposing to have individuals in rows and SNPs in columns
# adding 1 to have it as 0, 1, 2
dt <- t(dt_num[, -1:-5]) + 1

# create an Additive relationship matrix
kin_A <- Gmatrix(dt)
fwrite(kin_A, "output/kinship_additive.txt", sep = "\t", quote = F)
cat("kinship A ok\n")

# create a dominant relationship matrix
kin_d <- Gmatrix(dt, "Vitezica")
fwrite(kin_d, "output/kinship_dominant.txt", sep = "\t", quote = F)
cat("kinship D ok\n")

# creating epistatic relationship matrices
# Additive x Additive
kin_AA <- kin_A * kin_A
fwrite(kin_AA, "output/kinship_epi_AA.txt", sep = "\t", quote = F)
cat("kinship epi AA ok\n")

# Dominante x Dominant
kin_DD <- kin_d * kin_d
fwrite(kin_DD, "output/kinship_epi_DD.txt", sep = "\t", quote = F)
cat("kinship epi DD ok\n")

# Additive x Dominant
kin_AD <- kin_A * kin_d
fwrite(kin_AD, "output/kinship_epi_AD.txt", sep = "\t", quote = F)
cat("kinship epi AD ok\n")

