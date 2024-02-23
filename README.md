# Maize_GxE_Prediction

This is the source code for our preprint:    
```
@article{fernandes2024,
  author = {Igor K. Fernandes and Caio C. Vieira and Kaio O. G. Dias and Samuel B. Fernandes},
  title = {Using machine learning to integrate genetic and environmental data 
	   to model genotype-by-environment interactions},
  year = {2024},
  doi = {10.1101/2024.02.08.579534},
  journal = {bioRxiv}
}
```

<br>

# How to reproduce the results

Before starting reproducing, here are some important notes: 
- You will need a lot of space to run all experiments
- The scripts ran in a HPC cluster using SLURM, thus you may need to rename job partitions accordingly to the HPC cluster you use (check the `.sh` files)


## Clone repository and download the data

After cloning the repository, download the data [here](https://doi.org/10.25739/tq5e-ak26), extract it, and put both `Training_Data` and `Testing_Data` folders inside the `data` folder. Unzip the VCF file `Training_Data/5_Genotype_Data_All_Years.vcf.zip`.

The folder structure should be as follows:
```
Maize_GxE_Prediction/
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

<br>

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
install.packages("asreml")  # for BLUEs and FA

# from github source
setRepositories(ind = 1:2)
devtools::install_github("samuelbfernandes/simplePHENOTYPES")
```

<br>

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

4. Create Kronecker products between environmental and genomic relationship matrices (will take some hours):
```
JOB_KRON=$(sbatch --dependency=afterok:$JOB_GENOMICS --parsable 4-job_kroneckers.sh)
```

<br>

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

8. fit GBLUP FA(1) models (will take several hours):
```
for i in {1..10}; do sbatch --export=seed=${i} --job-name=faS${i} --output=logs/job_fa_seed${i}.txt 8-job_fa.sh; done
```

_Some files in `output` will be big, particularly the Kronecker files, so you might want to exclude them later._

<br>


# Results (optional)
We can check some results directly from the terminal. Here are some examples:

Check some GxE results:
```
find logs/ -name 'gxe_*' | xargs grep -E 'RMSE:*' | head
```

Store SVD explained variances:
```
find logs/ -name '*cv*' | xargs grep -E '*variance*' > logs/svd_explained_variance.txt
```

Check accuracy of GBLUP FA(1) models in CV0:
```
grep \\[1\\] logs/fa_cv0*
```

Check which models are done for GxE in one of the repetitions:
```
cat logs/job_gxe_seed6.txt
```

