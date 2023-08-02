#!/bin/bash

#SBATCH --job-name=blues
#SBATCH --output=logs/job_blues.txt
#SBATCH --partition=comp01
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=01:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 intel/19.0.5 R/4.2.2


## run
Rscript src/blues.R > logs/blues.txt
