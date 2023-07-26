cv=$1
fold=$2
debug=FALSE
invert=FALSE

Rscript src/gblup.R $cv $fold $debug $invert > "logs/gblup_cv${cv}_fold${fold}.txt" &&
# Rscript src/gblup_bglr.R $cv > "logs/gblup_bglr_cv${cv}.txt" &&
echo "[GBLUP] model ok"
