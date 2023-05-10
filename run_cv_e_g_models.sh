for cv in 0 1 2
do 
    echo "----------------------------------"
    echo "CV=${cv}"
    ./run_e_model.sh $cv &&
    ./run_g_models.sh $cv &&
    echo " "
done