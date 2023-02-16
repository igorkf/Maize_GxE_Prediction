for kinship in additive dominant epi_AA epi_DD epi_AD
do 
    for dataset in train val 
    do
        Rscript src/kronecker.R FALSE $dataset $kinship > "logs/kronecker_${kinship}_${dataset}.txt"
        echo "${kinship} for ${dataset} ok"
    done
done