python3 src/run_g_or_gxe_model.py --model=GxE --A --svd > logs/gxe_model_A_svd.txt
echo 'A model ok'

python3 src/run_g_or_gxe_model.py --model=GxE --D --svd --n_components=150 > logs/gxe_model_D_svd.txt
echo 'D model ok'

python3 src/run_g_or_gxe_model.py --model=GxE --epiAA --epiDD --epiAD --svd > logs/gxe_model_epiAA_epiDD_epiAD_svd.txt
echo 'epiAA epiDD epiAD model ok'