import pandas as pd
from sklearn.decomposition import TruncatedSVD
import lightgbm as lgbm
from sklearn.metrics import r2_score

from preprocessing import process_test_data

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

    # bind SVD genotypic features
    xtrain_geno = pd.read_csv('output/xtrain_geno.csv')
    xval_geno = pd.read_csv('output/xval_geno.csv')
    xtest_geno = pd.read_csv('output/xtest_geno.csv')
    xtrain = xtrain.merge(xtrain_geno, on='Hybrid', how='left')
    xval = xval.merge(xval_geno, on='Hybrid', how='left')
    xtest = xtest.merge(xtest_geno, on='Hybrid', how='left')

    # set index
    xtrain = xtrain.set_index(['Env', 'Hybrid'])
    xval = xval.set_index(['Env', 'Hybrid'])
    xtest = xtest.set_index(['Env', 'Hybrid'])

    # train model
    model = lgbm.LGBMRegressor(
        random_state=42,
        max_depth=2,
        n_estimators=280
    )
    model.fit(xtrain, ytrain)

    # feature importance
    # feat_imp = dict(zip(model.feature_name_, model.feature_importances_))
    # feat_imp = dict(sorted(feat_imp.items(), key=lambda x: -x[1]))
    # print(feat_imp)

    # predict
    yhat = model.predict(xval)
    df_eval = pd.DataFrame({
        'Field_Location': yval.index.get_level_values(0).str.replace('(_).*', '', regex=True),
        'Env': yval.index.get_level_values(0),
        # 'Hybrid': yval.index.get_level_values(1),
        'ytrue': yval,
        'yhat': yhat
    })
    df_eval.to_csv('output/oof_solution_4th_sub.csv', index=False)

    # predict on test
    df_sub['Yield_Mg_ha'] = model.predict(xtest)
    df_sub.to_csv('output/submission_4th_sub.csv', index=False)
    
    # evaluate
    rmse_per_field = df_eval.groupby('Field_Location').apply(
        lambda x: (x['ytrue'] - x['yhat']).pow(2).mean() ** 0.5
    )
    rmse = sum(rmse_per_field) / len(rmse_per_field)
    print(rmse_per_field)
    print('RMSE (per location):\n', rmse_per_field.describe().to_frame('   ').T)
    print('RMSE:', rmse)
    r2 = r2_score(df_eval['ytrue'], df_eval['yhat'])
    adj_r2 = 1 - (1 - r2) * (len(df_eval) - 1) / (len(df_eval) - df_eval.shape[1] - 1)
    print('Adj. R2:', adj_r2)

    # observed X predicted statistics
    obs_vs_pred = pd.concat([
        df_eval['ytrue'].rename('observed').describe(),
        df_eval['yhat'].rename('predicted').describe(),
        df_sub['Yield_Mg_ha'].rename('submission').describe()
    ], axis=1)
    print(obs_vs_pred)
