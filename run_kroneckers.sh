cv=$1
debug=FALSE

for kinship in additive dominant epi_AA epi_DD epi_AD
do 
    for dataset in train val 
    do
        Rscript src/kronecker.R $cv $debug $dataset $kinship > "logs/kronecker_${kinship}_${dataset}_cv${cv}.txt" &&
        echo "[Kronecker] ${kinship} for ${dataset} ok"
    done
done