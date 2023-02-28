cv=$1

python3 -u src/run_e_model.py > "logs/e_model_cv${cv}.txt" &&
echo '[E] model ok'
