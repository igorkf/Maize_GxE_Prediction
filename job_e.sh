#!/bin/bash

#SBATCH --job-name=e_models
#SBATCH --output=logs/job_e.txt
#SBATCH --partition comp01
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=01:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
./run_cv_e_models.sh
