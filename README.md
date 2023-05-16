## How to reproduce the results

### Download the data

Download the data [here](https://drive.google.com/drive/folders/1leYJY4bA3341S-JxjBIgmmAWMwVDHYRb), extract it, and put both `Training_Data` and `Testing_Data` folders on the `data` folder. Unzip the vcf file too.

We runned the models in a cluster, so you can skip the next hidden block: 
<details>
<summary>Click to expand</summary>

```
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2 vcftools/0.1.15 plink/5.2
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh

# create .Rprofile
cat ~/.Rprofile
# options(repos = c(CRAN = "https://mirrors.nics.utk.edu/cran"))

# create .Renviron
cat ~/.Renviron 
# R_LIBS_USER=~/R/%p/%v

# create R folders
cd
mkdir -p R
mkdir -p R/x86_64-pc-linux-gnu
mkdir -p R/x86_64-pc-linux-gnu/4.2

# set cpp 17 variables
mkdir -p ~/.R
cat ~/.R/Makevars
# echo "CC = $(which gcc) -fPIC"
# echo "CXX17 = $(which g++) -fPIC"
# echo "CXX17STD = -std=c++17"
# echo "CXX17FLAGS = ${CXX11FLAGS}"
```

</details>

<br>

### Setup conda and R packages
Install the conda environment:
```
conda env create -f environment.yml
```

Activate the conda environment:
```
conda deactivate  # if base conda is activated
conda activate maize_gxe_prediction
```

Install R packages:
```
# from CRAN
install.packages("arrow")
install.packages("data.table")
install.packages("AGHmatrix")
install.packages("devtools")

# from github source
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES")
```


### Preprocessing
Create all datasets:
```
./run_cv_datasets.sh
```

Create a list of individuals to be used:
```
python3 src/create_individuals.py
```

Filter VCF and create kinships matrices (you will need `vcftools` and `plink` here):
```
./run_vcf_filtering.sh
```
```
./run_kinships.sh
```

### Run models

Run all CVs for E and G models:   
```
./run_cv_e_g_models.sh
```

Run all CVs for GxE models:   
```
./run_cv_gxe_models.sh
```

Run all CVs for GBLUP models:
```
./run_cv_gblup_models.sh
```

Some files in `output` will be big (+40GB), particularly the Kronecker files, so you might want to exclude them later.

Notes: 

- All G and GxE LGBM models can run with lagged yield features if you add the '--lag_features' option.