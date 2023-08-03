#!/bin/bash

#SBATCH --partition=himem72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=8
#SBATCH --time=72:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5 python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction


## fit GxE models
for cv in {0..2}
do 
    echo "CV=${cv}"
    for fold in {0..4}
    do
        echo "Fold=${fold}"
        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --A > "logs/gxe_model_A_cv${cv}_fold${fold}_seed${seed}.txt"
        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --A --svd > "logs/gxe_model_A_svd_cv${cv}_fold${fold}_seed${seed}.txt"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --A --svd --lag_features > "logs/gxe_model_A_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        echo '[GxE] A model ok'

        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --D > "logs/gxe_model_D_cv${cv}_fold${fold}_seed${seed}.txt"
        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --D --svd > "logs/gxe_model_D_svd_cv${cv}_fold${fold}_seed${seed}.txt"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --D --svd --lag_features > "logs/gxe_model_D_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        echo '[GxE] D model ok'

        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --epiAA --epiDD --epiAD --n_components=250 > "logs/gxe_model_epiAA_epiDD_epiAD_cv${cv}_fold${fold}_seed${seed}.txt"
        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --epiAA --epiDD --epiAD --svd --n_components=250 > "logs/gxe_model_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}_seed${seed}.txt"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --epiAA --epiDD --epiAD --svd --n_components=250 --lag_features > "logs/gxe_model_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        echo '[GxE] epi model ok'

        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --A --D --epiAA --epiDD --epiAD --n_components=250 > "logs/gxe_model_A_D_epiAA_epiDD_epiAD_cv${cv}_fold${fold}_seed${seed}.txt"
        # python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --A --D --epiAA --epiDD --epiAD --svd --n_components=250 > "logs/gxe_model_A_D_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}_seed${seed}.txt"
        python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --seed=${seed} --model=GxE --A --D --epiAA --epiDD --epiAD --svd --n_components=250 --lag_features > "logs/gxe_model_A_D_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}_seed${seed}_lag_features.txt"
        echo '[GxE] all model ok'
    done
    echo " "
done
