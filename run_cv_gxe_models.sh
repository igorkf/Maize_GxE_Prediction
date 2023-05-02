for cv in 0 1 2
do 
    echo "----------------------------------"
    echo "CV=${cv}"
    ./run_kroneckers.sh $cv &&
    ./run_gxe_models.sh $cv &&
    echo " "
done