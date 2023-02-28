### How to reproduce the results

#### Download the data

Download the data [here](https://drive.google.com/drive/folders/1leYJY4bA3341S-JxjBIgmmAWMwVDHYRb), extract it, and put both `Training_Data` and `Testing_Data` folders on the `data` folder. Unzip the vcf file too.

#### Setup conda and R packages

We runned the models in a cluster, so you can skip this chunk of code:   

```
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2 vcftools plink
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh

# setup R files needed to install packages
cat ~/.Rprofile
# options(repos = c(CRAN = "https://mirrors.nics.utk.edu/cran"))

cat ~/.Renviron 
# R_LIBS_USER=~/R/%p/%v
```

Install R packages:
```
# from CRAN
install.packages("devtools")
install.packages("data.table")
install.packages("arrow")

# from github source
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES", build_vignettes = TRUE)
```

Now install the conda environment (only first time):
```
conda env create -f environment.yml
```

Activate the conda environment:
```
conda deactivate  # if base conda is activated
conda activate maize_gxe_prediction
```

#### Preprocessing vcf
Create kinships matrices (you will need `vcftools` and `plink` here):
```
./run_vcf_filtering.sh
./run_kinships.sh
```

#### Run models
Run CV0:   
```
./run_cv.sh 0
```