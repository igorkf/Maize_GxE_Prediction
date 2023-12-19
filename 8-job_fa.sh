#!/bin/bash

#SBATCH --partition=comp72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=24:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2


## fit FA(1) models
debug=FALSE
invert=FALSE
for cv in {0..2}
do 
    echo "CV=${cv}"
    for fold in {0..4}
    do
        echo "Fold=${fold}" 
        Rscript src/fa.R $cv $fold $seed $debug $invert > "logs/fa_cv${cv}_fold${fold}_seed${seed}.txt"
    done
    echo " "
done
