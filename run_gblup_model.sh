cv=$1
debug=$2
invert=$3

Rscript src/gblup.R $cv $debug $invert > "logs/gblup_cv${cv}.txt" &&
echo "[GBLUP] model ok"
