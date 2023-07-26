cv=$1
fold=$2
debug=FALSE

for kinship in additive dominant epi_AA epi_DD epi_AD
do 
    Rscript src/kronecker.R $cv $fold $debug $kinship > "logs/kronecker_${kinship}_cv${cv}_fold${fold}.txt" &&
    echo "[Kronecker] ${kinship}"
done
