cv=$1

python3 -u src/create_datasets.py --cv=${cv} > "logs/datasets_cv${cv}.txt" &&

# very fast
./run_e_model.sh $cv &&  

# medium
./run_g_models.sh $cv &&

# take a while
./run_kroneckers.sh $cv 

# take a while
# ./run_gxe_models.sh $cv 