from pathlib import Path

import pandas as pd


OUTPUT_PATH = Path('output')


def read_csvs(dataset):
    dfs = []
    for fold in [0, 1, 2, 3, 4]:
        df_temp = pd.concat(
            [pd.read_csv(OUTPUT_PATH / f'cv{cv}' / f'{dataset}_fold{fold}.csv', usecols=['Hybrid']) for cv in [0, 1, 2]]
        )
        dfs.append(df_temp)
    df = pd.concat(dfs, axis=0, ignore_index=True)
    return df


if __name__ == '__main__':
    ytrains = read_csvs('ytrain')
    yvals = read_csvs('yval')
    df = pd.concat([ytrains, yvals], axis=0, ignore_index=True)
    df.drop_duplicates().to_csv(OUTPUT_PATH / 'individuals.csv', index=False, header=False)
    print('Created list of individuals.')
