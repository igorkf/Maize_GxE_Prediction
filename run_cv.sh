cv=$1
python3 -u src/create_datasets.py --cv=${cv} > "logs/datasets_cv${cv}.txt" &&

./run_e_model.sh $cv &&  # very fast
./run_g_models.sh $cv &&  # fast
./run_kroneckers.sh $cv &&  # take a while
./run_gxe_models.sh $cv  # take a while