#!/bin/bash

#SBATCH --job-name=maize2
#SBATCH --output=logs/job_part2.txt
#SBATCH --partition comp72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --time=6:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
## Run all GxE for GBLUP models:
./run_cv_gxe_models.sh

