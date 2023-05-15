from pathlib import Path

import pandas as pd

OUTPUT_PATH = Path('output')


def read_csvs(filename):
    dfs = pd.concat(
        [pd.read_csv(OUTPUT_PATH / f'cv{x}' / filename, usecols=['Hybrid']) for x in [0, 1, 2]],
        axis=0,
        ignore_index=True
    )
    return dfs


if __name__ == '__main__':
    ytrains = read_csvs('ytrain.csv')
    yvals = read_csvs('yval.csv')
    df = pd.concat([ytrains, yvals], axis=0, ignore_index=True)
    df.drop_duplicates().to_csv(OUTPUT_PATH / 'individuals.csv', index=False, header=False)
    print('Created list of individuals.')
