#!/bin/bash

#SBATCH --partition=comp06
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=06:00:00

## configs 
if command -v module &> /dev/null
then
    module purge
    module load gcc/9.3.1 mkl/19.0.5 R/4.2.2
    exit 1
fi


## fit FA(1) models
seed=$1
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
