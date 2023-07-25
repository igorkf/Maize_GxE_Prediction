cv=$1
fold=$2

python3 -u src/run_e_model.py --cv=${cv} --fold=${fold} > "logs/e_model_cv${cv}_fold${fold}.txt" &&
echo '[E] model ok'
