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


## fit E models
for cv in {0..2}
do 
    echo "CV=${cv}"
    for fold in {0..4}
    do
        echo "Fold=${fold}"
        python3 -u src/run_e_model.py --cv=${cv} --fold=${fold} --seed=${seed} > "logs/e_model_cv${cv}_fold${fold}_seed${seed}.txt"
    done
    echo " "
done
