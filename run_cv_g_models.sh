for cv in 0 1 2
do 
    echo "CV=${cv}"
    for fold in 0 1 2 3 4
    do
        ./run_g_models.sh $cv $fold
    done
done