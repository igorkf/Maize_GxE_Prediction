cv=$1
fold=$2

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A > "logs/g_model_A_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --svd > "logs/g_model_A_svd_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --svd --lag_features > "logs/g_model_A_svd_cv${cv}_fold${fold}_lag_features.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --E --svd --lag_features > "logs/g_model_A_E_svd_cv${cv}_fold${fold}_lag_features.txt" &&
echo '[G] A model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --D > "logs/g_model_D_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --D --svd > "logs/g_model_D_svd_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --D --svd --lag_features > "logs/g_model_D_svd_cv${cv}_fold${fold}_lag_features.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --D --E --svd --lag_features > "logs/g_model_D_E_svd_cv${cv}_fold${fold}_lag_features.txt" &&
echo '[G] D model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --epiAA --epiDD --epiAD --n_components=250 > "logs/g_model_epiAA_epiDD_epiAD_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --epiAA --epiDD --epiAD --svd --n_components=250 > "logs/g_model_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --epiAA --epiDD --epiAD --svd --n_components=250 --lag_features > "logs/g_model_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}_lag_features.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --epiAA --epiDD --epiAD --E --svd --n_components=250 --lag_features > "logs/g_model_epiAA_epiDD_epiAD_E_svd_cv${cv}_fold${fold}_lag_features.txt" &&
echo '[G] epiAA epiDD epiAD model ok' &&

python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --D --epiAA --epiDD --epiAD --n_components=250 > "logs/g_model_A_D_epiAA_epiDD_epiAD_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --D --epiAA --epiDD --epiAD --svd --n_components=250 > "logs/g_model_A_D_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --D --epiAA --epiDD --epiAD --svd --n_components=250 --lag_features > "logs/g_model_A_D_epiAA_epiDD_epiAD_svd_cv${cv}_fold${fold}_lag_features.txt" &&
python3 -u src/run_g_or_gxe_model.py --cv=${cv} --fold=${fold} --model=G --A --D --epiAA --epiDD --epiAD --E --svd --n_components=250 --lag_features > "logs/g_model_A_D_epiAA_epiDD_epiAD_E_svd_cv${cv}_fold${fold}_lag_features.txt" &&
echo '[G] A D epiAA epiDD epiAD model ok'
