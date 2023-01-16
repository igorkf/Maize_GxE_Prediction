# Maize_GxE_Prediction

## How to run the solution
1. [Download data](https://drive.google.com/drive/folders/1leYJY4bA3341S-JxjBIgmmAWMwVDHYRb), extract it, and put both `Training_Data` and `Testing_Data` folders on the `data` folder.

2. Build a new python environment, activate it, and install dependencies:
    ```
    python3 -m venv .venv
    ```
    ```
    source .venv/bin/activate
    ```
    ```
    pip3 install -r requirements.txt
    ```

3. Run following files to generate the solution in `output/submission_4th_sub.csv`:
    ```
    python3 src/create_datasets.py
    ```
    ```
    python3 src/solution.py
    ```



