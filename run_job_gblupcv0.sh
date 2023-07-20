#!/bin/bash

#SBATCH --job-name=gblupcv0
#SBATCH --output=logs/job_part_gblup_bglr_cv0.txt
#SBATCH --partition comp06
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --time=01:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2

## run
./run_gblup_model.sh 0

