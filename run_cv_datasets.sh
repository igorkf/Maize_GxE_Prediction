for cv in 0 1 2
do
    echo "CV=${cv}"
    for fold in 0 1 2 3 4
    do 
        python3 -u src/create_datasets.py --cv=${cv} --fold=${fold} > "logs/datasets_cv${cv}_fold${fold}.txt"
    done
done
