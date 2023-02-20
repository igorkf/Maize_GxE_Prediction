# change paths here
vcftools_path="/scrfs/apps/bioinformatics/vcftools/0.1.15/bin/vcftools"
plink_path="/share/apps/bioinformatics/plink/5.2/plink"

Rscript src/kinship.R $vcftools_path $plink_path > logs/kinships.txt

# clean heavy stuff if you want (+6GB)
# rm output/maize_maf001.recode.vcf
# rm output/maize_pruned.vcf
