#!/bin/bash

#SBATCH --job-name=maize_gxe_prediction_part3
#SBATCH --output=logs/job_part3.txt
#SBATCH --partition comp72
#SBATCH --nodes=2
#SBATCH --tasks-per-node=32
#SBATCH --time=72:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2

## run
## Run all CVs for GBLUP models:
./run_cv_gblup_models.sh

