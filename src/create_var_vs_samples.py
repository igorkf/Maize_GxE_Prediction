import time

import allel
import pandas as pd


if __name__ == '__main__':
    
    start_time = time.perf_counter()

    callset = allel.read_vcf(
        'data/Training_Data/5_Genotype_Data_All_Years.vcf',
        fields=['samples', 'GT']
    )
    samples = callset['samples']
    gt = allel.GenotypeArray(callset['calldata/GT'])
    del callset

    # variants VS samples (sampled to avoid OOM error)
    (
        pd.DataFrame(gt.values[:, :, 0] + gt.values[:, :, 1], columns=samples)  # ref + alt
        .sample(frac=0.15, random_state=42)
        .to_csv('output/variants_vs_samples_GT_ref_alt.csv', index=False)
    )

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))