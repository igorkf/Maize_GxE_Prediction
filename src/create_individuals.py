from pathlib import Path

import pandas as pd


OUTPUT_PATH = Path('output')


def read_csvs(dataset):
    dfs = []
    for fold in range(5):
        for seed in range(10):
            df_temp = pd.concat(
                [pd.read_csv(OUTPUT_PATH / f'cv{cv}' / f'{dataset}_fold{fold}_seed{seed + 1}.csv', usecols=['Hybrid']) for cv in [0, 1, 2]]
            )
        dfs.append(df_temp)
    df = pd.concat(dfs, axis=0, ignore_index=True)
    return df


if __name__ == '__main__':
    ytrains = read_csvs('ytrain')
    yvals = read_csvs('yval')
    df = pd.concat([ytrains, yvals], axis=0, ignore_index=True)
    df.drop_duplicates().to_csv(OUTPUT_PATH / 'individuals.csv', index=False, header=False)
    print(f'Created list of {len(df)} of individuals.')
