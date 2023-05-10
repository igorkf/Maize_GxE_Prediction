import argparse
from pathlib import Path

import pandas as pd
import lightgbm as lgbm

from preprocessing import process_test_data
from evaluate import create_df_eval, avg_rmse, feat_imp


parser = argparse.ArgumentParser()
parser.add_argument('--cv', type=int, choices={0, 1, 2})
args = parser.parse_args()

OUTPUT_PATH = Path(f'output/cv{args.cv}')
TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'


if __name__ == '__main__':
    df_sub = process_test_data(TEST_PATH).reset_index()[['Env', 'Hybrid']]

    xtrain = pd.read_csv(OUTPUT_PATH / 'xtrain.csv')
    xval = pd.read_csv(OUTPUT_PATH / 'xval.csv')
    xtest = pd.read_csv(OUTPUT_PATH / 'xtest.csv')
    ytrain = pd.read_csv(OUTPUT_PATH / 'ytrain.csv').set_index(['Env', 'Hybrid'])['Yield_Mg_ha']
    yval = pd.read_csv(OUTPUT_PATH / 'yval.csv').set_index(['Env', 'Hybrid'])['Yield_Mg_ha']

    # set index
    xtrain = xtrain.set_index(['Env', 'Hybrid'])
    xval = xval.set_index(['Env', 'Hybrid'])
    xtest = xtest.set_index(['Env', 'Hybrid'])

    # train model
    model = lgbm.LGBMRegressor(
        random_state=42,
        max_depth=2
    )
    model.fit(xtrain, ytrain)

    # feature importance
    df_feat_imp = feat_imp(model)
    df_feat_imp.to_csv(OUTPUT_PATH / 'feat_imp_e_model.csv', index=False)

    # predict
    ypred = model.predict(xval)

    # evaluate
    df_eval = create_df_eval(xval, yval, ypred)
    _ = avg_rmse(df_eval)

    # write
    outfile = OUTPUT_PATH / 'oof_e_model.csv'
    print('Writing:', outfile, '\n')
    df_eval.to_csv(outfile, index=False)

    # predict on test
    # df_sub['Yield_Mg_ha'] = model.predict(xtest)
    # df_sub.to_csv('output/submission.csv', index=False)
    
    # observed X predicted statistics
    # obs_vs_pred = pd.concat([
    #     df_eval['ytrue'].rename('observed').describe(),
    #     df_eval['yhat'].rename('predicted').describe(),
    #     df_sub['Yield_Mg_ha'].rename('submission').describe()
    # ], axis=1)
    # print(obs_vs_pred)
