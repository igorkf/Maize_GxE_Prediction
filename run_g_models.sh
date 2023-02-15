python3 src/run_g_or_gxe_model.py --model=G --A --svd > logs/g_model_A_svd.txt &&
echo 'A model ok' &&

python3 src/run_g_or_gxe_model.py --model=G --D --svd > logs/g_model_D_svd.txt &&
echo 'D model ok' &&

python3 src/run_g_or_gxe_model.py --model=G --epiAA --epiDD --epiAD --svd > logs/g_model_epiAA_epiDD_epiAD_svd.txt &&
echo 'epiAA epiDD epiAD model ok'