import time

import pandas as pd
from sklearn.model_selection import GroupKFold
from sklearn.decomposition import TruncatedSVD


if __name__ == '__main__':

    start_time = time.perf_counter()

    xtrain = pd.read_csv('output/xtrain.csv')
    xval = pd.read_csv('output/xval.csv')
    xtest = pd.read_csv('output/xtest.csv')

    # hybrids only on test
    only_in_test = set(xtest['Hybrid']) - set(xtrain['Hybrid']) - set(xval['Hybrid'])
    print('Unique genotypes ONLY in test:', len(only_in_test))

    df_genos = pd.read_csv(
        'output/variants_vs_samples_GT_ref_alt.csv',
        usecols=lambda x: x not in only_in_test
    )
    print('Shape:', df_genos.shape)
    df_genos = df_genos.T.reset_index().rename(columns={'index': 'Hybrid'})  # transpose

    # SVDs in a group k fold manner to avoid overfitting
    n_components = 200
    svd_cols = [f'geno_svd_{i}' for i in range(n_components)]
    xtrain_svd = pd.DataFrame(columns=svd_cols)
    xval_svd = pd.DataFrame(columns=svd_cols)

    svds = []
    gkf = GroupKFold(n_splits=2)
    for fold, (tr_idx, val_idx) in enumerate(
            gkf.split(df_genos.drop('Hybrid', axis=1), groups=df_genos['Hybrid'])
        ):
        geno_train = df_genos.loc[tr_idx, :].set_index('Hybrid')
        geno_val = df_genos.loc[val_idx, :].set_index('Hybrid')
        assert set(geno_train.index) & set(geno_val.index) == set()  # assert non-overlapping groups

        # reduce
        svd = TruncatedSVD(n_components=n_components, n_iter=20, random_state=42)
        svd.fit(geno_train)
        svds.append(svd)
        print(fold, 'SVD explained variance:', svd.explained_variance_ratio_.sum())
        xtrain_svd = pd.concat([xtrain_svd, pd.DataFrame(svd.transform(geno_train), columns=svd_cols, index=geno_train.index)])
        xval_svd = pd.concat([xval_svd, pd.DataFrame(svd.transform(geno_val), columns=svd_cols, index=geno_val.index)])

    # write to datasets
    xtrain_svd.reset_index().rename(columns={'index': 'Hybrid'}).to_csv('output/xtrain_geno.csv', index=False)
    xval_svd.reset_index().rename(columns={'index': 'Hybrid'}).to_csv('output/xval_geno.csv', index=False)
    del df_genos, geno_train, geno_val, xtrain_svd, xval_svd

    # do blending (mean of predictions) to unseen test genotypes
    df_genos_test = pd.read_csv(
        'output/variants_vs_samples_GT_ref_alt.csv',
        usecols=lambda x: x in only_in_test
    )
    df_genos_test = df_genos_test.T

    # blend test predictions
    xtest_svd = pd.DataFrame(
        sum([model.transform(df_genos_test) for model in svds]) / gkf.n_splits,
        columns=svd_cols,
        index=df_genos_test.index
    )
    xtest_svd.reset_index().rename(columns={'index': 'Hybrid'}).to_csv('output/xtest_geno.csv', index=False)

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))

