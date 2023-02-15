import pandas as pd
import lightgbm as lgbm
from sklearn.metrics import mean_squared_error

from preprocessing import process_test_data
from evaluate import create_df_eval, avg_rmse


TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'


if __name__ == '__main__':
    df_sub = process_test_data(TEST_PATH).reset_index()[['Env', 'Hybrid']]

    xtrain = pd.read_csv('output/xtrain.csv')
    xval = pd.read_csv('output/xval.csv')
    xtest = pd.read_csv('output/xtest.csv')
    ytrain = pd.read_csv('output/ytrain.csv').set_index(['Env', 'Hybrid'])['Yield_Mg_ha']
    yval = pd.read_csv('output/yval.csv').set_index(['Env', 'Hybrid'])['Yield_Mg_ha']

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
    # feat_imp = dict(zip(model.feature_name_, model.feature_importances_))
    # feat_imp = dict(sorted(feat_imp.items(), key=lambda x: -x[1]))
    # print(feat_imp)

    # predict
    ypred = model.predict(xval)

    # evaluate
    df_eval = create_df_eval(xval, yval, ypred)
    _ = avg_rmse(df_eval)

    # write
    outfile = 'output/oof_e_model.csv'
    print('Writing:', outfile)
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
