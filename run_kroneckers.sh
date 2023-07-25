cv=$1
fold=$2
debug=FALSE

for kinship in additive dominant epi_AA epi_DD epi_AD
do 
    for dataset in train val 
    do
        Rscript src/kronecker.R $cv $fold $debug $dataset $kinship > "logs/kronecker_${kinship}_${dataset}_cv${cv}_fold${fold}.txt" &&
        echo "[Kronecker] ${kinship} for ${dataset} ok"
    done
done
