#!/bin/bash

#SBATCH --job-name=gblupcv2
#SBATCH --output=logs/job_part_gblupcv2.txt
#SBATCH --partition comp72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=32
#SBATCH --time=30:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2

## run
./run_gblup_model.sh 2 FALSE FALSE

