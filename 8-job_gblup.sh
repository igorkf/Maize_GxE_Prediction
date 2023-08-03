#!/bin/bash

#SBATCH --partition=comp06
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=06:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2


## fit GBLUP FA(1) models
for cv in {0..2}
do 
    echo "CV=${cv}"
    for fold in {0..4}
    do
        echo "Fold=${fold}" 
        Rscript src/gblup_bglr.R $cv $fold $seed > "logs/gblup_bglr_cv${cv}_fold${fold}_seed${seed}.txt"
    done
    echo " "
done
