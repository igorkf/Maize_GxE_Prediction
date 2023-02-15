import argparse
import os
import contextlib

import pandas as pd
import lightgbm as lgbm
from sklearn.decomposition import TruncatedSVD
from sklearn.metrics import mean_squared_error
import optuna

from evaluate import create_df_eval, avg_rmse
from tune import objective


parser = argparse.ArgumentParser()
parser.add_argument('--A', action='store_true', default=False)
parser.add_argument('--D', action='store_true', default=False)
parser.add_argument('--epiAA', action='store_true', default=False)
parser.add_argument('--epiDD', action='store_true', default=False)
parser.add_argument('--epiAD', action='store_true', default=False)
parser.add_argument('--svd', action='store_true', default=False)
parser.add_argument('--n_components', default=100)
args = parser.parse_args()


outfile = 'output/oof_g_model'


def preprocess(df, kinship: str):
    df.columns = [x[:len(x) // 2] for x in df.columns]  # fix duplicated column names
    df.index = df.columns
    df.index.name = 'Hybrid'
    df.columns = [f'{x}_{kinship}' for x in df.columns]
    return df


if __name__ == '__main__':
    
    # load targets
    ytrain = pd.read_csv('output/ytrain.csv')
    yval = pd.read_csv('output/yval.csv')

    # load kinships
    kinships = []
    if args.A:
        print('Using A kinship matrix.')
        A = pd.read_csv('output/kinship_additive.txt', sep='\t')
        A = preprocess(A, 'A')
        kinships.append(A)
        outfile += '_A'

    if args.D:
        print('Using D kinship matrix.')
        D = pd.read_csv('output/kinship_dominant.txt', sep='\t')
        D = preprocess(D, 'D')
        kinships.append(D)
        outfile += '_D'

    if args.epiAA:
        print('Using epi AA kinship matrix.')
        epiAA = pd.read_csv('output/kinship_epi_AA.txt', sep='\t')
        epiAA = preprocess(epiAA, 'epiAA')
        kinships.append(epiAA)
        outfile += '_epiAA'

    if args.epiDD:
        print('Using epi DD kinship matrix.')
        epiDD = pd.read_csv('output/kinship_epi_DD.txt', sep='\t')
        epiDD = preprocess(epiDD, 'epiDD')
        kinships.append(epiDD)
        outfile += '_epiDD'

    if args.epiAD:
        print('Using epi AD kinship matrix.')
        epiAD = pd.read_csv('output/kinship_epi_AD.txt', sep='\t')
        epiAD = preprocess(epiAD, 'epiAD')
        kinships.append(epiAD)
        outfile += '_epiAD'

    if len(kinships) == 0:
        raise Exception('Choose at least one kinship matrix.')
    else:
        K = pd.concat(kinships, axis=1)

    # merge target and features
    xtrain = pd.merge(ytrain, K, on='Hybrid', how='left').dropna().set_index(['Env', 'Hybrid'])
    ytrain = xtrain['Yield_Mg_ha']
    del xtrain['Yield_Mg_ha']
    xval = pd.merge(yval, K, on='Hybrid', how='left').dropna().set_index(['Env', 'Hybrid'])
    yval = xval['Yield_Mg_ha']
    del xval['Yield_Mg_ha']

    # bind lagged yield features
    xtrain_lag = pd.read_csv('output/xtrain.csv', usecols=lambda x: 'yield_lag' in x or x in ['Env', 'Hybrid']).set_index(['Env', 'Hybrid'])
    xval_lag = pd.read_csv('output/xval.csv', usecols=lambda x: 'yield_lag' in x or x in ['Env', 'Hybrid']).set_index(['Env', 'Hybrid'])
    xtrain = xtrain.copy().merge(xtrain_lag, on=['Env', 'Hybrid'], how='inner')
    xval = xval.copy().merge(xval_lag, on=['Env', 'Hybrid'], how='inner')
    
    # run model
    if not args.svd:
        outfile += '_full'
        print('Using full set of features.')
        print('# Features:', xtrain.shape[1])

        # fit
        model = lgbm.LGBMRegressor(random_state=42, verbose=-1)
        model.fit(xtrain, ytrain)

        # predict
        ypred = model.predict(xval)

        # validate
        df_eval = create_df_eval(xval, yval, ypred)
        _ = avg_rmse(df_eval)
    else:
        lag_cols = [x for x in xtrain.columns if 'yield_lag' in x]
        xtrain_no_lags = xtrain.drop(lag_cols, axis=1)
        xval_no_lags = xval.drop(lag_cols, axis=1)
        outfile += f'_svd{args.n_components}comps'
        print('Using svd.')
        print('# Components:', args.n_components)
        svd = TruncatedSVD(n_components=args.n_components, random_state=42)
        svd.fit(xtrain_no_lags)  # fit but without lagged yield features
        print('Explained variance:', svd.explained_variance_ratio_.sum())

        # transform from the fitted svd
        svd_cols = [f'svd{i}' for i in range(args.n_components)]
        xtrain_svd = pd.DataFrame(svd.transform(xtrain_no_lags), columns=svd_cols, index=xtrain_no_lags.index)
        xval_svd = pd.DataFrame(svd.transform(xval_no_lags), columns=svd_cols, index=xval_no_lags.index)

        # bind lagged yield features
        xtrain = xtrain_svd.merge(xtrain_lag, on=['Env', 'Hybrid'], how='inner')
        xval = xval_svd.merge(xval_lag, on=['Env', 'Hybrid'], how='inner')

    # tune model if using svd features
    if args.svd:
        print('Tunning.')

        # silent lgbm warnings
        with open(os.devnull, 'w') as f, contextlib.redirect_stdout(f):
            optuna.logging.set_verbosity(optuna.logging.WARNING)  # silent optuna results
            study = optuna.create_study(direction='minimize', sampler=optuna.samplers.TPESampler(seed=42))
            func = lambda trial: objective(trial, xtrain, ytrain, xval, yval)
            study.optimize(func, n_trials=200)
            print('# Trials:', len(study.trials))
            print('Best trial:', study.best_trial.params)
            print('Best RMSE:', study.best_value)

            # fit again with best parameters
            model = lgbm.LGBMRegressor(**study.best_trial.params, random_state=42)
            model.fit(xtrain, ytrain)

        # predict
        ypred = model.predict(xval)

        # validate
        df_eval = create_df_eval(xval, yval, ypred)
        _ = avg_rmse(df_eval)

    # write OOF results
    outfile += '.csv'
    print('Writing file:', outfile, '\n')
    df_eval.to_csv(outfile, index=False)