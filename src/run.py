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

    model = xgb.XGBRegressor(
        random_state=42,
        max_depth=2
    )  # RMSE=2.0809258420827947
    model.fit(xtrain, ytrain)

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

    # predict on test
    df_sub = process_test_data(TEST_PATH).set_index(['Env', 'Hybrid'])
    df_sub['Yield_Mg_ha'] = model.predict(xtest)
    df_sub.to_csv('output/submission_3rd_sub.csv', index=False)
    
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
    print(obs_vs_pred, '\n')

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))
