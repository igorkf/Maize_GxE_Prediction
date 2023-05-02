for cv in 0 1 2
do 
    echo "----------------------------------"
    echo "CV=${cv}"
    python3 -u src/create_datasets.py --cv=${cv} > "logs/datasets_cv${cv}.txt" &&
    ./run_e_model.sh $cv &&
    ./run_g_models.sh $cv &&
    echo " "
done