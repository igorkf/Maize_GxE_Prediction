#!/bin/bash

#SBATCH --job-name=kronecker
#SBATCH --output=logs/job_kroneckers.txt
#SBATCH --partition=himem06
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=02:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2


## create Kronecker products between environmental and genomic matrices
debug=FALSE
for cv in {0..2}
do 
    echo "CV=${cv}"
    for kinship in additive dominant epi_AA epi_DD epi_AD
    do 
        Rscript src/kronecker.R $cv $debug $kinship > "logs/kronecker_${kinship}_cv${cv}.txt" &&
        echo "[Kronecker] ${kinship}"
    done
done
