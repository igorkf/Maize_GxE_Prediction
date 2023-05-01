for cv in 0 1
do 
    echo "----------------------------------"
    echo "CV=${cv}"
    ./run_kroneckers.sh $cv &&
    ./run_gxe_models.sh $cv &&
    echo " "
done