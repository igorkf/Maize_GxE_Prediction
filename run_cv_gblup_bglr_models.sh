for cv in 0 1 2
do
    for fold in 0 1 2 3 4
    do 
        echo "----------------------------------"
        echo "CV=${cv}"
        ./run_gblup_bglr_model.sh $cv $fold &&
        echo " "
    done
done

