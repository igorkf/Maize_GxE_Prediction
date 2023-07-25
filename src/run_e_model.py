import argparse
from pathlib import Path

import pandas as pd
import lightgbm as lgbm

from preprocessing import process_test_data, create_field_location
from evaluate import create_df_eval, avg_rmse, feat_imp


parser = argparse.ArgumentParser()
parser.add_argument('--cv', type=int, choices={0, 1, 2}, required=True)
parser.add_argument('--fold', type=int, choices={0, 1, 2, 3, 4}, required=True)
args = parser.parse_args()

OUTPUT_PATH = Path(f'output/cv{args.cv}')
TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'


if __name__ == '__main__':
    # df_sub = process_test_data(TEST_PATH).reset_index()[['Env', 'Hybrid']]

    xtrain = pd.read_csv(OUTPUT_PATH / f'xtrain_fold{args.fold}.csv')
    xval = pd.read_csv(OUTPUT_PATH / f'xval_fold{args.fold}.csv')
    # xtest = pd.read_csv(OUTPUT_PATH / 'xtest.csv')
    ytrain = pd.read_csv(OUTPUT_PATH / f'ytrain_fold{args.fold}.csv').set_index(['Env', 'Hybrid'])['Yield_Mg_ha']
    yval = pd.read_csv(OUTPUT_PATH / f'yval_fold{args.fold}.csv').set_index(['Env', 'Hybrid'])['Yield_Mg_ha']

    # add factor
    xtrain = create_field_location(xtrain)
    xtrain['Field_Location'] = xtrain['Field_Location'].astype('category')
    xval = create_field_location(xval)
    xval['Field_Location'] = xval['Field_Location'].astype('category')
    # xtest = create_field_location(xtest)
    # xtest['Field_Location'] = xtest['Field_Location'].astype('category')

    # set index
    xtrain = xtrain.set_index(['Env', 'Hybrid'])
    xval = xval.set_index(['Env', 'Hybrid'])
    # xtest = xtest.set_index(['Env', 'Hybrid'])

    # fit
    model = lgbm.LGBMRegressor(random_state=42, max_depth=3)
    model.fit(xtrain, ytrain)

    # feature importance
    df_feat_imp = feat_imp(model)
    df_feat_imp.to_csv(OUTPUT_PATH / f'feat_imp_e_model_fold{args.fold}.csv', index=False)

    # predict
    ypred_train = model.predict(xtrain)
    ypred = model.predict(xval)

    # evaluate
    df_eval_train = create_df_eval(xtrain, ytrain, ypred_train)
    df_eval = create_df_eval(xval, yval, ypred)
    _ = avg_rmse(df_eval)

    # write
    outfile = OUTPUT_PATH / f'oof_e_model_fold{args.fold}.csv'
    print('Writing:', outfile, '\n')
    df_eval.to_csv(outfile, index=False)
    df_eval_train.to_csv(OUTPUT_PATH / f'pred_train_e_model_fold{args.fold}.csv')

    # predict on test
    # df_sub['Yield_Mg_ha'] = model.predict(xtest)
    # df_sub.to_csv('output/submission.csv', index=False)
    