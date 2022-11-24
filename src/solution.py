import pandas as pd
from sklearn import linear_model
from sklearn import ensemble

from preprocessing import (
    process_metadata,
    process_test_data,
    split_trait_data,
    feature_engineer,
    extract_target
)


VAL_YEAR = 2021

TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'

META_COLS = ['Env', 'weather_station_lat', 'weather_station_lon']


if __name__ == '__main__':

    # META
    meta = process_metadata(META_TRAIN_PATH)
    meta_test = process_metadata(META_TEST_PATH)

    # TEST
    test = process_test_data(TEST_PATH)
    xtest = test.merge(meta_test[META_COLS], on='Env', how='left').set_index(['Env', 'Hybrid']).drop(['Field_Location'], axis=1)
    
    # TRAIT
    trait = pd.read_csv(TRAIT_PATH)
    trait = trait.merge(meta[META_COLS], on='Env', how='left')

    # split train/val
    xtrain, xval = split_trait_data(trait, val_year=VAL_YEAR, fillna=False)

    # feat engineer
    xtrain = feature_engineer(xtrain)
    xval = feature_engineer(xval)
    xtest = feature_engineer(xtest)
    
    # extract targets
    ytrain = extract_target(xtrain)
    yval = extract_target(xval)
    _ = extract_target(xtest)

    print(xtrain.isnull().sum() / len(xtrain))
    print(xval.isnull().sum() / len(xval))
    print(xtest.isnull().sum() / len(xtest))

    print('xtrain shape:', xtrain.shape)
    print('xval shape:', xval.shape)
    print('xtest shape:', xtest.shape)
    print('ytrain shape:', ytrain.shape)
    print('yval shape:', yval.shape)
    print('ytrain nulls:', ytrain.isnull().sum() / len(ytrain))
    print('yval nulls:', yval.isnull().sum() / len(yval))

    # train model
    model = ensemble.HistGradientBoostingRegressor(
        random_state=42,
        max_depth=2
    )
    model.fit(xtrain, ytrain)

    # predict
    yhat = model.predict(xval)
    df_eval = pd.DataFrame({
        'Field_Location': yval.index.get_level_values(0).str.replace('(_).*', '', regex=True),
        'Env': yval.index.get_level_values(0),
        'Hybrid': yval.index.get_level_values(1),
        'ytrue': yval.values,
        'yhat': yhat
    })
    df_eval.to_csv('output/oof_solution.csv', index=False)
    
    # evaluate
    rmse_per_field = df_eval.groupby('Field_Location').apply(
        lambda x: (x['ytrue'] - x['yhat']).pow(2).mean() ** 0.5
    )
    rmse = sum(rmse_per_field) / len(rmse_per_field)
    print(rmse_per_field)
    print('RMSE (per location):\n', rmse_per_field.describe().to_frame('   ').T)
    print('RMSE:', rmse)

    # observed X predicted statistics
    obs_vs_pred = pd.concat([
        df_eval['ytrue'].rename('observed').describe(),
        pd.DataFrame(model.predict(xtest), columns=['predicted']).describe()
    ], axis=1)
    print(obs_vs_pred)
