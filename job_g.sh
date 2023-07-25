#!/bin/bash

#SBATCH --job-name=g_models
#SBATCH --output=logs/job_g.txt
#SBATCH --partition comp06
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=02:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
./run_cv_g_models.sh
