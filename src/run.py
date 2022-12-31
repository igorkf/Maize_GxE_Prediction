import time

import pandas as pd
import xgboost as xgb
from sklearn.metrics import r2_score

from preprocessing import process_test_data
from create_datasets import TEST_PATH


if __name__ == '__main__':
    start_time = time.perf_counter()

    xtrain = pd.read_csv('output/xtrain.csv').set_index('Env')
    xval = pd.read_csv('output/xval.csv').set_index('Env')
    xtest = pd.read_csv('output/xtest.csv').set_index('Env')
    ytrain = pd.read_csv('output/ytrain.csv').set_index('Env')['Yield_Mg_ha']
    yval = pd.read_csv('output/yval.csv').set_index('Env')['Yield_Mg_ha']
    print('Features:', xtrain.shape[1])

    # removing decreases RMSE (after applying LOFO)
    del_cols = [
        'geno_sparsepca_comp65',  # 2.070510438860331
        'EC_svd_comp1',  # 2.067904025856213
        'geno_sparsepca_comp44',  # 2.0669395964159567
        'geno_sparsepca_comp193',  # 2.0659597803230767
        'EC_svd_comp0',  # 2.064576910907656
    ]
    xtrain = xtrain.drop(del_cols, axis=1)
    xval = xval.drop(del_cols, axis=1)
    xtest = xtest.drop(del_cols, axis=1)
    print('Features:', xtrain.shape[1])

    model = xgb.XGBRegressor(
        random_state=42,
        max_depth=2,
        n_estimators=125
    )  # RMSE=2.063423185218701
    model.fit(xtrain, ytrain)

    df_feat_imp = pd.DataFrame()
    df_feat_imp['feature'] = model.get_booster().feature_names
    df_feat_imp['score'] = model.feature_importances_
    df_feat_imp = df_feat_imp.sort_values('score', ascending=False)

    # predict
    yhat = model.predict(xval)
    df_eval = pd.DataFrame({
        'Field_Location': yval.index.get_level_values(0).str.replace('(_).*', '', regex=True),
        'Env': yval.index.get_level_values(0),
        # 'Hybrid': yval.index.get_level_values(1),
        'ytrue': yval.values,
        'yhat': yhat
    })
    df_eval.to_csv('output/oof_solution_3rd_sub.csv', index=False)

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

    # predict on test
    df_sub = process_test_data(TEST_PATH).set_index(['Env', 'Hybrid'])
    df_sub['Yield_Mg_ha'] = model.predict(xtest)
    df_sub.to_csv('output/submission_3rd_sub.csv', index=False)    

    # observed X predicted statistics
    obs_vs_pred = pd.concat([
        df_eval['ytrue'].rename('observed').describe(),
        df_eval['yhat'].rename('predicted').describe(),
        df_sub['Yield_Mg_ha'].rename('submission').describe()
    ], axis=1)
    print(obs_vs_pred, '\n')

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))
