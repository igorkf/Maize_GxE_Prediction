vcftools --vcf data/Training_Data/5_Genotype_Data_All_Years.vcf --keep output/individuals.csv --recode --recode-INFO-all --out output/maize_indiv && 
vcftools --vcf output/maize_indiv.recode.vcf --maf 0.01 --recode --recode-INFO-all --out output/maize_maf001 &&
plink --vcf output/maize_maf001.recode.vcf --double-id --indep-pairwise 100 20 0.9 --out output/maize_pruned &&
plink --vcf output/maize_maf001.recode.vcf --double-id --extract output/maize_pruned.prune.in --recode vcf --out output/maize_pruned
