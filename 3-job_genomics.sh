#!/bin/bash

#SBATCH --job-name=genomics
#SBATCH --output=logs/job_genomics.txt
#SBATCH --partition=comp06
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=02:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 intel/19.0.5 R/4.2.2 vcftools/0.1.15 plink/5.2


## create a list of individuals to be used for VCF file
python3 -u src/create_individuals.py > "logs/individuals.txt"

## filter VCF and create kinships matrices (you will need `vcftools` and `plink` here):
vcftools --vcf data/Training_Data/5_Genotype_Data_All_Years.vcf --keep 'output/individuals.csv' --recode --recode-INFO-all --out output/maize_indiv
vcftools --vcf output/maize_indiv.recode.vcf --maf 0.01 --recode --recode-INFO-all --out output/maize_maf001
plink --vcf output/maize_maf001.recode.vcf --double-id --indep-pairwise 100 20 0.9 --out output/maize_pruned
plink --vcf output/maize_maf001.recode.vcf --double-id --extract output/maize_pruned.prune.in --recode vcf --out output/maize_pruned
Rscript src/kinship.R > "logs/kinships.txt"
