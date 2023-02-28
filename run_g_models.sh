cv=$1

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --A --svd > "logs/g_model_A_svd_cv${cv}.txt" &&
echo '[G] A model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --D --svd > "logs/g_model_D_svd_cv${cv}.txt" &&
echo '[G] D model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --epiAA --epiDD --epiAD --svd > "logs/g_model_epiAA_epiDD_epiAD_svd_cv${cv}.txt" &&
echo '[G] epiAA epiDD epiAD model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --model=G --A --D --epiAA --epiDD --epiAD --svd > "logs/g_model_A_D_epiAA_epiDD_epiAD_svd_cv${cv}.txt" &&
echo '[G] A D epiAA epiDD epiAD model ok'