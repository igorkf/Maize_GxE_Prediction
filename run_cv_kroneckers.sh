for cv in 0 1 2
do 
    echo "----------------------------------"
    echo "CV=${cv}"
    ./run_kroneckers.sh $cv &&
    echo " "
done
