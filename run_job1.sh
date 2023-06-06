#!/bin/bash

#SBATCH --job-name=maize1
#SBATCH --output=logs/job_part1.txt
#SBATCH --partition comp72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --time=72:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2 vcftools/0.1.15 plink/5.2
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
## Create all datasets:
./run_cv_datasets.sh

## Create a list of individuals to be used:
python3 -u src/create_individuals.py

## Filter VCF and create kinships matrices (you will need `vcftools` and `plink` here):
./run_vcf_filtering.sh
./run_kinships.sh

## Run models
## Run all CVs for E and G models:   
./run_cv_e_g_models.sh

