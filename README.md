### How to reproduce the results

#### Download the data

Download the data [here](https://drive.google.com/drive/folders/1leYJY4bA3341S-JxjBIgmmAWMwVDHYRb), extract it, and put both `Training_Data` and `Testing_Data` folders on the `data` folder. Unzip the vcf file too.

#### Setup conda and R packages

We runned the models in a cluster, so you can skip this part:   
```
module load gcc mkl R vcftools plink
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
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

Set up R packages:
```
# from CRAN
install.packages("devtools")
install.packages("data.table")
install.packages("arrow")

# from github source
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES", build_vignettes = TRUE)
```

#### Run models

##### Environment model:
```
./run_e_models.sh
```

##### Genetic models:
```
./run_g_models.sh
```

##### GxE models:
Create kinships matrices (you will need `vcftools` and `plink` here):
```
./run_kinships.sh
```

Create kronecker matrices:
```
./run_kroneckers.sh
```

Now run the models:
```
./run_gxe_models.sh
```