import argparse
import os
import contextlib
from pathlib import Path

import pandas as pd
import lightgbm as lgbm
from sklearn.decomposition import TruncatedSVD
import optuna

from evaluate import create_df_eval, avg_rmse
from tune import objective


parser = argparse.ArgumentParser()
parser.add_argument('--cv', type=int, choices={0, 1, 2})
parser.add_argument('--model', choices={'G', 'GxE'})
parser.add_argument('--A', action='store_true', default=False)
parser.add_argument('--D', action='store_true', default=False)
parser.add_argument('--epiAA', action='store_true', default=False)
parser.add_argument('--epiDD', action='store_true', default=False)
parser.add_argument('--epiAD', action='store_true', default=False)
parser.add_argument('--svd', action='store_true', default=False)
parser.add_argument('--n_components', type=int, default=100)
args = parser.parse_args()

OUTPUT_PATH = Path(f'output/cv{args.cv}')

if args.model == 'G':
    outfile = OUTPUT_PATH / 'oof_g_model'
    print('Using G model.')
else:
    print('Using GxE model.')
    outfile = OUTPUT_PATH / 'oof_gxe_model'

if args.cv == 0:
    print('Using CV0')
    YTRAIN_YEAR = 2020
    YVAL_YEAR = 2021
    YTEST_YEAR = 2022
elif args.cv == 1:
    print('Using CV1')
    YTRAIN_YEAR = 2021  # for split it uses 2020 and 2021
    YVAL_YEAR = 2021
    YTEST_YEAR = 2022
elif args.cv == 2:
    pass


def preprocess_g(df, kinship):
    df.columns = [x[:len(x) // 2] for x in df.columns]  # fix duplicated column names
    df.index = df.columns
    df.index.name = 'Hybrid'
    df.columns = [f'{x}_{kinship}' for x in df.columns]
    return df


def preprocess_gxe(df, year, kinship):
    df[['Env', 'Hybrid']] = df['id'].str.split(':', expand=True)
    df['Env'] += f'_{year}'
    df = df.drop('id', axis=1).set_index(['Env', 'Hybrid'])
    df.columns = [f'{x}_{kinship}' for x in df.columns]
    return df


def prepare_train_val_gxe(kinship):
    xtrain = pd.read_feather(OUTPUT_PATH / f'kronecker_{kinship}_train.feather')
    xtrain = preprocess_gxe(xtrain, year=YTRAIN_YEAR, kinship=kinship)
    xval = pd.read_feather(OUTPUT_PATH / f'kronecker_{kinship}_val.feather')
    xval = preprocess_gxe(xval, year=YVAL_YEAR, kinship=kinship)
    return xtrain, xval


if __name__ == '__main__':
    
    # load targets
    ytrain = pd.read_csv(OUTPUT_PATH / 'ytrain.csv')
    yval = pd.read_csv(OUTPUT_PATH / 'yval.csv')

    # load kinships or kroneckers
    kinships = []
    kroneckers_train = []
    kroneckers_val = []
    if args.A:
        print('Using A matrix.')
        outfile = f'{outfile}_A'
        if args.model == 'G':
            A = pd.read_csv('output/kinship_additive.txt', sep='\t')
            A = preprocess_g(A, 'A')
            kinships.append(A)
        else:
            xtrain, xval = prepare_train_val_gxe('additive')
            kroneckers_train.append(xtrain)
            del xtrain
            kroneckers_val.append(xval)
            del xval

    if args.D:
        print('Using D matrix.')
        outfile = f'{outfile}_D'
        if args.model == 'G':
            D = pd.read_csv('output/kinship_dominant.txt', sep='\t')
            D = preprocess_g(D, 'D')
            kinships.append(D)
        else:
            xtrain, xval = prepare_train_val_gxe('dominant')
            kroneckers_train.append(xtrain)
            del xtrain
            kroneckers_val.append(xval)
            del xval

    if args.epiAA:
        print('Using epiAA matrix.')
        outfile = f'{outfile}_epiAA'
        if args.model == 'G':
            epiAA = pd.read_csv('output/kinship_epi_AA.txt', sep='\t')
            epiAA = preprocess_g(epiAA, 'epi_AA')
            kinships.append(epiAA)
        else:
            xtrain, xval = prepare_train_val_gxe('epi_AA')
            kroneckers_train.append(xtrain)
            del xtrain
            kroneckers_val.append(xval)
            del xval

    if args.epiDD:
        print('Using epiDD matrix.')
        outfile = f'{outfile}_epiDD'
        if args.model == 'G':
            epiDD = pd.read_csv('output/kinship_epi_DD.txt', sep='\t')
            epiDD = preprocess_g(epiDD, 'epi_DD')
            kinships.append(epiDD)
        else:
            xtrain, xval = prepare_train_val_gxe('epi_DD')
            del xtrain
            kroneckers_train.append(xtrain)
            del xval
            kroneckers_val.append(xval)

    if args.epiAD:
        print('Using epiAD matrix.')
        outfile = f'{outfile}_epiAD'
        if args.model == 'G':
            epiAD = pd.read_csv('output/kinship_epi_AD.txt', sep='\t')
            epiAD = preprocess_g(epiAD, 'epi_AD')
            kinships.append(epiAD)
        else:
            xtrain, xval = prepare_train_val_gxe('epi_AD')
            kroneckers_train.append(xtrain)
            del xtrain
            kroneckers_val.append(xval)
            del xval

    if (args.model == 'G' and len(kinships) == 0) or (args.model == 'GxE' and len(kroneckers_train) == 0):
        raise Exception('Choose at least one matrix.')
    
    # concat dataframes and bind target
    if args.model == 'G':
        K = pd.concat(kinships, axis=1)
        xtrain = pd.merge(ytrain, K, on='Hybrid', how='left').dropna().set_index(['Env', 'Hybrid'])
        xval = pd.merge(yval, K, on='Hybrid', how='left').dropna().set_index(['Env', 'Hybrid'])
        del kinships
    else:
        xtrain = pd.concat(kroneckers_train, axis=1)
        xtrain = xtrain.merge(ytrain, on=['Env', 'Hybrid'], how='inner')
        xval = pd.concat(kroneckers_val, axis=1)
        xval = xval.merge(yval, on=['Env', 'Hybrid'], how='inner')
        del kroneckers_train, kroneckers_val

    # split x, y
    ytrain = xtrain['Yield_Mg_ha']
    del xtrain['Yield_Mg_ha']
    yval = xval['Yield_Mg_ha']
    del xval['Yield_Mg_ha']

    # bind lagged yield features
    no_lags_cols = [x for x in xtrain.columns.tolist() if x not in ['Env', 'Hybrid']]
    xtrain_lag = pd.read_csv(OUTPUT_PATH / 'xtrain.csv', usecols=lambda x: 'yield_lag' in x or x in ['Env', 'Hybrid']).set_index(['Env', 'Hybrid'])
    xval_lag = pd.read_csv(OUTPUT_PATH / 'xval.csv', usecols=lambda x: 'yield_lag' in x or x in ['Env', 'Hybrid']).set_index(['Env', 'Hybrid'])
    xtrain = xtrain.copy().merge(xtrain_lag, on=['Env', 'Hybrid'], how='inner')
    xval.copy().merge(xval_lag, on=['Env', 'Hybrid'], how='inner')
    
    if args.model == 'GxE':
        xtrain = xtrain.set_index(['Env', 'Hybrid'])
        xval = xval.set_index(['Env', 'Hybrid'])
    
    # run model
    if not args.svd:
        del xtrain_lag, xval_lag

        outfile = f'{outfile}_full'
        print('Using full set of features.')
        print('# Features:', xtrain.shape[1])

        # fit
        model = lgbm.LGBMRegressor(random_state=42)
        model.fit(xtrain, ytrain)

        # predict
        ypred = model.predict(xval)

        # validate
        df_eval = create_df_eval(xval, yval, ypred)
        _ = avg_rmse(df_eval)
        
    else:
        outfile = f'{outfile}_svd{args.n_components}comps'
        print('Using svd.')
        print('# Components:', args.n_components)
        svd = TruncatedSVD(n_components=args.n_components, random_state=42)
        svd.fit(xtrain[no_lags_cols])  # fit but without lagged yield features
        print('Explained variance:', svd.explained_variance_ratio_.sum())

        # transform from the fitted svd
        svd_cols = [f'svd{i}' for i in range(args.n_components)]
        xtrain_svd = pd.DataFrame(svd.transform(xtrain[no_lags_cols]), columns=svd_cols, index=xtrain[no_lags_cols].index)
        xval_svd = pd.DataFrame(svd.transform(xval[no_lags_cols]), columns=svd_cols, index=xval[no_lags_cols].index)

        # bind lagged yield features
        xtrain = xtrain_svd.merge(xtrain_lag, on=['Env', 'Hybrid'], how='inner')
        xval = xval_svd.merge(xval_lag, on=['Env', 'Hybrid'], how='inner')
        del xtrain_lag, xval_lag

    # tune model if using svd features
    if args.svd:
        print('Tunning.')

        # silent lgbm warnings
        with open(os.devnull, 'w') as f, contextlib.redirect_stdout(f):
            optuna.logging.set_verbosity(optuna.logging.WARNING)  # silent optuna results
            study = optuna.create_study(direction='minimize', sampler=optuna.samplers.TPESampler(seed=42))
            func = lambda trial: objective(trial, xtrain, ytrain, xval, yval)
            study.optimize(func, n_trials=200)

            # fit again with best parameters
            model = lgbm.LGBMRegressor(**study.best_trial.params, random_state=42)
            model.fit(xtrain, ytrain)
            
        print('# Trials:', len(study.trials))
        print('Best trial:', study.best_trial.params)
        print('Best RMSE:', study.best_value)

        # predict
        ypred = model.predict(xval)

        # validate
        df_eval = create_df_eval(xval, yval, ypred)
        _ = avg_rmse(df_eval)

    # write OOF results
    outfile = f'{outfile}.csv'
    print('Writing file:', outfile, '\n')
    df_eval.to_csv(outfile, index=False)