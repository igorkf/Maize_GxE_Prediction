cv=$1
fold=$2

Rscript src/gblup_bglr.R $cv $fold > "logs/gblup_bglr_cv${cv}_fold${fold}.txt" &&
echo "[GBLUP BGLR] model ok"
