#!/bin/bash

#SBATCH --partition=comp01
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=01:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction


## fit G and G+E models
for cv in {0..2}
do 
    echo "CV=${cv}"
    for fold in {0..4}
    do
        echo "Fold=${fold}"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=G --A --svd --lag_features > "logs/g_model_A_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=G --A --E --svd --lag_features > "logs/g_model_A_E_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        echo '[G] A model ok'

        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=G --D --svd --lag_features > "logs/g_model_D_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=G --D --E --svd --lag_features > "logs/g_model_D_E_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        echo '[G] D model ok'
    done
    echo " "
done
