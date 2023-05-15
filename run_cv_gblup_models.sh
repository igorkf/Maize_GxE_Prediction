debug=FALSE
invert=FALSE

for cv in 0 1 2
do 
    echo "----------------------------------"
    echo "CV=${cv}"
    ./run_gblup_model.sh $cv $debug $invert &&
    echo " "
done
