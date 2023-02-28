cv=$1

python3 -u src/run_e_model.py --cv=${cv} > "logs/e_model_cv${cv}.txt" &&
echo '[E] model ok'
