## How to reproduce the results

### Download the data

Download the data [here](https://doi.org/10.25739/tq5e-ak26), extract it, and put both `Training_Data` and `Testing_Data` folders inside the `data` folder. Unzip the VCF file `Training_Data/5_Genotype_Data_All_Years.vcf.zip`.

The folder structure should look as follows:
```
├── data/
│   ├── Training_Data/
│   └── Testing_Data/
├── src/
├── logs/
├── output/
│   ├── cv0/
│   ├── cv1/
│   └── cv2/
```

We runned the models in a cluster, so you can skip the next hidden block: 
<details>
<summary>Click to expand</summary>

```
module load gcc/9.3.1 mkl/19.0.5 R/4.2.2 vcftools/0.1.15 plink/5.2
module load python/anaconda-3.10
source /share/apps/bin/conda-3.10.sh
conda deactivate  # if base conda is activated
conda activate maize_gxe_prediction

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
install.packages("asreml")  # for blues and gblup

# from github source
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES")
```


### Preprocessing

1. Create BLUEs:
```
Rscript src/blues.R
```

2. Create all datasets:
```
./run_cv_datasets.sh
```

3. Create a list of individuals to be used:
```
python3 src/create_individuals.py
```

4. Filter VCF and create kinships matrices (you will need `vcftools` and `plink` here):
```
./run_vcf_filtering.sh
```
```
./run_kinships.sh
```

### Run models

Run all CVs for E models:   
```
./run_cv_e_models.sh
```

Run all CVs for Kroneckers:
```
./run_cv_kroneckers.sh
```

Run all CVs for GxE models:   
```
./run_cv_gxe_models.sh
```

Run all CVs for GBLUP models:
```
./run_cv_gblup_models.sh
```

Some files in `output` will be big, particularly the Kronecker files, so you might want to exclude them later.

### If running in a cluster
We used SLURM to schedule the jobs. To run all the jobs do:
```
JOBID1=$(sbatch --parsable run_job1.sh)
sbatch --dependency=afterok:$JOBID1 run_job_gblupcv0.sh
sbatch --dependency=afterok:$JOBID1 run_job_gblupcv1.sh
sbatch --dependency=afterok:$JOBID1 run_job_gblupcv2.sh
JOBID2=$(sbatch --dependency=afterok:$JOBID1 --parsable run_job_kroneckers.sh)
sbatch --dependency=afterok:$JOBID2 run_job2.sh
```

