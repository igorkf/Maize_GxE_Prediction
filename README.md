# Maize_GxE_Prediction

## How to run the solution
1. [Download data](https://drive.google.com/drive/folders/1leYJY4bA3341S-JxjBIgmmAWMwVDHYRb), extract it, and put both `Training_Data` and `Testing_Data` folders on the `data` folder.

2. Build a new `conda` environment and activate it:
    ```
    conda env create -f environment.yml
    ```

    ```
    conda activate maize_gxe_prediction
    ```

3. Run following files to generate the solution in `output/submission_4th_sub.csv`:
    ```
    python3 src/create_datasets.py
    ```
    ```
    python3 src/solution.py
    ```

Make sure that `RMSE=2.134953769066483`


## Tested with:   
- Python 3.8.10    
- Ubuntu 20.04.5 LTS (Focal Fossa)



