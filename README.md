# Maize_GxE_Prediction

## How to run the solution
1. [Download data](https://drive.google.com/drive/folders/1leYJY4bA3341S-JxjBIgmmAWMwVDHYRb), extract it and put both `Training_Data` and `Testing_Data` folders on `data` folder. Extract `5_Genotype_Data_All_Years.vcf.zip` file as well.

2. Build a new python environment and activate it
    ```
    python3 -m venv .venv
    source .venv/bin/activate
    ```

3. Run following files:
    ```
    python3 src/create_datasets.py
    ```

    ```
    python3 src/create_var_vs_samples.py
    ```

    ```
    python3 src/create_genotype_features.py
    ```

    ```
    python3 src/solution.py
    ```



