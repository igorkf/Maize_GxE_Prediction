# How to reproduce the results

_Disclaimer: You will need a lot of space (~400GB) to run all experiments._

<br>


## Clone repository and download the data

After cloning the repository, download the data [here](https://doi.org/10.25739/tq5e-ak26), extract it, and put both `Training_Data` and `Testing_Data` folders inside the `data` folder. Unzip the VCF file `Training_Data/5_Genotype_Data_All_Years.vcf.zip`.

The folder structure should look as follows:
```
Maize_GxE_Prediction/
├── data/
│   ├── Training_Data/
│   └── Testing_Data/
├── src/
├── logs/
├── output/
│   ├── cv0/
|   |   └── BGLR/
│   ├── cv1/
|   |   └── BGLR/
├── |── cv2/
|   |   └── BGLR/
```

<br><br>

## Setup conda and R packages
Install the conda environment:
```
conda env create -f environment.yml
```

Install R packages:
```
# from CRAN
install.packages("arrow")
install.packages("data.table")
install.packages("AGHmatrix")
install.packages("devtools")
install.packages("asreml")  # for BLUEs
install.packages("BGLR")  # for FA

# from github source
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES")
```

</details>

<br><br>

## Preprocessing

1. Create BLUEs:
```
JOB_BLUES=$(sbatch --parsable 1-job_blues.sh)
```

2. Create datasets for cross-validation schemes:
```
JOB_DATASETS=$(sbatch --dependency=afterok:$JOB_BLUES --parsable 2-job_datasets.sh)
```

3. Filter VCF and create kinships matrices (you will need `vcftools` and `plink` here):
```
JOB_GENOMICS=$(sbatch --dependency=afterok:$JOB_DATASETS --parsable 3-job_genomics.sh)
```

4. Create Kronecker products between environmental and genomic matrices (will take some hours):
```
JOB_KRON=$(sbatch --dependency=afterok:$JOB_GENOMICS --parsable 4-job_kroneckers.sh)
```


<br><br>


## Models
5. Fit E models:
```
for i in {1..10}; do sbatch --export=seed=${i} --job-name=Eseed${i} --output=logs/job_e_seed${i}.txt 5-job_e.sh; done
```

6. Fit G and G+E models:
```
for i in {1..10}; do sbatch --export=seed=${i} --job-name=Gseed${i} --output=logs/job_g_seed${i}.txt 6-job_g.sh; done
```

7. Fit GxE models (will take several hours):
```
for i in {1..10}; do sbatch --export=seed=${i} --job-name=GxEs${i} --output=logs/job_gxe_seed${i}.txt --dependency=afterok:$JOB_KRON --parsable 7-job_gxe.sh; done
```

8. fit GBLUP FA(1) models (will take some hours):
```
for i in {1..10}; do sbatch --export=seed=${i} --job-name=gblupS${i} --output=logs/job_gblup_seed${i}.txt 8-job_gblup.sh; done
```

_Some files in `output` will be big, particularly the Kronecker files, so you might want to exclude them later._

<br><br>


### Fun part
We can check some results directly from the terminal. Here are some examples:

Check some GxE results:
```
find logs/ -name 'gxe_*' | xargs grep -E 'RMSE:*' | head
```

Store SVD explained variances:
```
find logs/ -name '*cv*' | xargs grep -E '*variance*' > logs/svd_explained_variance.txt
```

Check time spent to fit some GBLUP FA(1) models:
```
find logs/ -name 'gblup*' | xargs grep -E 'Time to fit:*' | head
```

Check accuracy of some GBLUP FA(1) models:
```
find logs/ -name 'gblup*' | xargs grep -E 'cor:*' | head
```

Check accuracy of some GBLUP FA(1) models for CV1 scheme:
```
find logs/ -name 'gblup*' | xargs grep -E 'cor:*' | grep cv1
```

Check which models are done for GxE in one of the repetitions:
```
cat logs/job_gxe_seed6.txt
```

