# install simple PHENOTYPES
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES", build_vignettes = TRUE)

library(simplePHENOTYPES)
library(data.table)
library(AGHmatrix)

args <- commandArgs(trailingOnly = TRUE)
vcftools_path <- args[1]
plink_path <- args[2]

# using vcftools to remove snps with minor allele count 1%
system(paste0(vcftools_path, " --vcf data/Training_Data/5_Genotype_Data_All_Years.vcf --maf 0.01 --recode --recode-INFO-all --out output/maize_maf001"))

# using plink to prune SNPs with LD > 0.9 (in a window of 100 SNPs)
system(paste0(plink_path, " --vcf output/maize_maf001.recode.vcf --double-id --indep-pairwise 100 20 0.9 --out output/maize_pruned"))
system(paste0(plink_path, " --vcf output/maize_maf001.recode.vcf --double-id --extract output/maize_pruned.prune.in --recode vcf --out output/maize_pruned"))

# converting from vcf to numeric...some files can be removed afterwards (only look at the *_numeric.txt file)
create_phenotypes(
  geno_file = "output/maize_pruned.vcf",
  add_QTN_num = 1,
  add_effect = 0.2,
  big_add_QTN_effect = 0.9,
  rep = 10,
  h2 = 0.7,
  model = "A",
  home_dir = paste0(getwd(), "/output"),
  out_geno = "numeric",
)

#loading the numeric file
#SNPs are -1, 0, or 1
dt_num <- fread("output/maize_pruned_numeric.txt", data.table = F)
dt_num[1:10, 1:10]

# the package AGHmatrix requires SNPs to be 0, 1, or 2
# transposing to have individuals in rows and SNPs in columns
# adding 1 to have it as 0, 1, 2
dt <- t(dt_num[, -1:-5]) + 1

# using the AGHmatrix package to create an Additive relationship matrix
kin_A <- Gmatrix(dt)

# saving additive matrix to file
fwrite(kin_A, "output/kinship_additive.txt", sep = "\t", quote = F)
print("kinship A ok")

# using the AGHmatrix package to create a dominant relationship matrix
kin_d <- Gmatrix(dt, "Vitezica")

# saving additive matrix to file
fwrite(kin_d, "output/kinship_dominant.txt", sep = "\t", quote = F)
print("kinship D ok")

# creating epistatic relationship matrices
# Additive x Additive
kin_AA <- kin_A * kin_A
fwrite(kin_AA, "output/kinship_epi_AA.txt", sep = "\t", quote = F)
print("kinship epi AA ok")

# Dominante x Dominant
kin_DD <- kin_d * kin_d
fwrite(kin_DD, "output/kinship_epi_DD.txt", sep = "\t", quote = F)
print("kinship epi DD ok")

# Additive x Dominant
kin_AD <- kin_A * kin_d
fwrite(kin_AD, "output/kinship_epi_AD.txt", sep = "\t", quote = F)
print("kinship epi AD ok")

