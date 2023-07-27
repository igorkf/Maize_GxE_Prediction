#!/bin/bash

#SBATCH --job-name=gxe_mod
#SBATCH --output=logs/job_gxe.txt
#SBATCH --partition himem72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=72:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
./run_cv_gxe_models.sh

