#!/bin/bash

#SBATCH --job-name=maizesup
#SBATCH --output=logs/job_part_supplementary.txt
#SBATCH --partition himem72
#SBATCH --nodes=1
#SBATCH --tasks-per-node=24
#SBATCH --time=72:00:00

## configs 
module purge
module load gcc/9.3.1 mkl/19.0.5
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate
conda activate maize_gxe_prediction

## run
for cv in 0 1 2
do
    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --A > "logs/gxe_model_A_full_cv${cv}.txt" &&
    echo '[GxE] A model ok' &&

    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --D > "logs/gxe_model_D_full_cv${cv}.txt" &&
    echo '[GxE] D model ok' &&

    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --epiAA --epiDD --epiAD > "logs/gxe_model_epiAA_epiDD_epiAD_full_cv${cv}.txt" &&
    echo '[GxE] epiAA epiDD epiAD model ok' &&

    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --A --D --epiAA --epiDD --epiAD > "logs/gxe_model_A_D_epiAA_epiDD_epiAD_full_cv${cv}.txt" &&
    echo '[GxE] A D epiAA epiDD epiAD model ok' &&


    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --A > "logs/g_model_A_full_cv${cv}.txt" &&
    echo '[G] A model ok' &&

    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --D > "logs/g_model_D_full_cv${cv}.txt" &&
    echo '[G] D model ok' &&

    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --epiAA --epiDD --epiAD > "logs/g_model_epiAA_epiDD_epiAD_full_cv${cv}.txt" &&
    echo '[G] epiAA epiDD epiAD model ok' &&

    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --A --D --epiAA --epiDD --epiAD > "logs/g_model_A_D_epiAA_epiDD_epiAD_full_cv${cv}.txt" &&
    echo '[G] A D epiAA epiDD epiAD model ok' && 


    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --A --E > "logs/g_model_A_E_full_cv${cv}.txt" &&
    echo '[G+E] A model ok' &&
 
    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --D --E > "logs/g_model_D_E_full_cv${cv}.txt" &&
    echo '[G+E] D model ok' &&
  
    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --epiAA --epiDD --epiAD --E > "logs/g_model_epiAA_epiDD_epiAD_E_full_cv${cv}.txt" &&
    echo '[G+E] epiAA epiDD epiAD model ok' &&
  
    python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --A --D --epiAA --epiDD --epiAD --E > "logs/g_model_A_D_epiAA_epiDD_epiAD_E_full_cv${cv}.txt" &&
    echo '[G+E] A D epiAA epiDD epiAD model ok'
done

