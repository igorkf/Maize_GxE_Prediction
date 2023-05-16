#!/bin/bash

#SBATCH --job-name=maize_gxe_prediction_part2
#SBATCH --output=logs/job_part2.txt
#SBATCH --partition himem06
#SBATCH --nodes=2
#SBATCH --tasks-per-node=32
#SBATCH --time=6:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2 vcftools/0.1.15 plink/5.2
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
./run_cv_gxe_models.sh

