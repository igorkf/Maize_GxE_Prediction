cv=$1

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --A --svd > "logs/gxe_model_A_svd_cv${cv}.txt" &&
echo '[GxE] A model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --D --svd --n_components=150 > "logs/gxe_model_D_svd_cv${cv}.txt" &&
echo '[GxE] D model ok' &&

python3 src/run_g_or_gxe_model.py --cv=${cv} --model=GxE --epiAA --epiDD --epiAD --svd --n_components=250 > "logs/gxe_model_epiAA_epiDD_epiAD_svd_cv${cv}.txt" &&
echo '[GxE] epiAA epiDD epiAD model ok'
