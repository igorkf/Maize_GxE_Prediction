#!/bin/bash

#SBATCH --job-name=datasets
#SBATCH --output=logs/job_datasets.txt
#SBATCH --partition=comp01
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=01:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 intel/19.0.5 R/4.2.2 vcftools/0.1.15 plink/5.2 python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction


## create all datasets
for cv in {0..2}
do
    echo "CV=${cv}"
    for fold in {0..4}
    do
        echo "Fold=${fold}"
        for seed in {1..10}
        do 
            echo "Seed=${seed}"
            python3 -u src/create_datasets.py --cv=${cv} --fold=${fold} --seed=${seed} > "logs/datasets_cv${cv}_fold${fold}_seed${seed}.txt"
        done
    done
    echo " "
done
