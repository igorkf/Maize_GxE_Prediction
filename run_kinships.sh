cv=$1

Rscript src/kinship.R > "logs/kinships_cv${cv}.txt"

# clean heavy stuff if you want (+6GB)
# rm output/maize_maf001.recode.vcf
# rm output/maize_pruned.vcf

