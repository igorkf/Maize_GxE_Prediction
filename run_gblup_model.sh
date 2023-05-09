cv=$1

Rscript src/gblup.R $cv > "logs/gblup_cv${cv}.txt" &&
echo "[GBLUP] model ok"
