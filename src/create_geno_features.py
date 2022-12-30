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

    df = pd.DataFrame()
    df['Hybrid'] = samples
    df['GT_count_het'] = gt.count_het(axis=0)  # 0/1 = heterozygote
    df['GT_count_hom'] = gt.count_hom(axis=0)  # 0/0 or 1/1 = homozygous
    df['GT_ref_max'] = gt.values[:, :, 0].max(axis=0)
    df['GT_alt_mean'] = gt.values[:, :, 1].mean(axis=0)  # sum(0/.) / n_variants
    df.to_csv('output/geno_features.csv', index=False)

    # variants VS samples (sampled)
    (
        pd.DataFrame(gt.values[:, :, 0] + gt.values[:, :, 1], columns=samples)  # ref + alt
        .sample(frac=0.15, random_state=42)
        .to_csv('output/variants_vs_samples_GT_ref_alt.csv', index=False)
    )

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))
