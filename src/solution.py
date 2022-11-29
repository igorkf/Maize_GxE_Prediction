import pandas as pd
from sklearn import linear_model
from sklearn import ensemble
from sklearn.decomposition import TruncatedSVD

from preprocessing import (
    process_metadata,
    process_test_data,
    split_trait_data,
    feature_engineer,
    feat_eng_weather,
    feat_eng_ec,
    extract_target
)

YTRAIN_YEAR = 2020
YVAL_YEAR = 2021
YTEST_YEAR = 2022

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

    # WEATHER
    weather = pd.read_csv('data/Training_Data/4_Training_Weather_Data_2014_2021.csv')
    weather_test = pd.read_csv('data/Testing_Data/4_Testing_Weather_Data_2022.csv')

    # EC
    ec = pd.read_csv('data/Training_Data/6_Training_EC_Data_2014_2021.csv').set_index('Env')
    ec_test = pd.read_csv('data/Testing_Data/6_Testing_EC_Data_2022.csv').set_index('Env')

    # split train/val
    xtrain, xval = split_trait_data(trait, val_year=YVAL_YEAR, fillna=False)

    # feat eng (trait)
    xtrain = feature_engineer(xtrain)
    xval = feature_engineer(xval)
    xtest = feature_engineer(xtest)

    # feat eng (weather)
    xtrain = xtrain.merge(feat_eng_weather(weather), on='Env', how='left')
    xval = xval.merge(feat_eng_weather(weather), on='Env', how='left')
    xtest = xtest.merge(feat_eng_weather(weather_test), on='Env', how='left')

    # feat eng (EC)
    xtrain_ec = feat_eng_ec(ec)
    xtrain_ec = xtrain_ec[xtrain_ec.index.isin(xtrain.index)]
    xval_ec = feat_eng_ec(ec)
    xval_ec = xval_ec[xval_ec.index.isin(xval.index)]
    xtest_ec = feat_eng_ec(ec_test)
    xtest_ec = xtest_ec[xtest_ec.index.isin(xtest.index)]

    # TODO: try other dim reduction methods
    n_components = 15
    svd = TruncatedSVD(n_components=n_components, n_iter=20, random_state=42)
    svd.fit(xtrain_ec.values)
    print('SVD explained variance:', svd.explained_variance_ratio_.sum())

    xtrain_ec = pd.DataFrame(svd.transform(xtrain_ec), index=xtrain_ec.index)
    component_cols = [f"EC_svd_comp{i}" for i in range(xtrain_ec.shape[1])]
    xtrain_ec.columns = component_cols
    xval_ec = pd.DataFrame(svd.transform(xval_ec), columns=component_cols, index=xval_ec.index)
    xtest_ec = pd.DataFrame(svd.transform(xtest_ec), columns=component_cols, index=xtest_ec.index)

    xtrain = xtrain.merge(xtrain_ec, on='Env', how='left')
    xval = xval.merge(xval_ec, on='Env', how='left')
    xtest = xtest.merge(xtest_ec, on='Env', how='left')

    # feat eng (target)
    # xtrain['Field_Location'] = xtrain.index.get_level_values(0).str.replace('(_).*', '', regex=True)
    # xval['Field_Location'] = xval.index.get_level_values(0).str.replace('(_).*', '', regex=True)
    # xtest['Field_Location'] = xtest.index.get_level_values(0).str.replace('(_).*', '', regex=True)
    # xtrain = xtrain.merge(feat_eng_target(trait, ref_year=YTRAIN_YEAR, lag=1), on='Field_Location', how='left').set_index(xtrain.index)
    # xval = xval.merge(feat_eng_target(trait, ref_year=YVAL_YEAR, lag=1), on='Field_Location', how='left').set_index(xval.index)
    # xtest = xtest.merge(feat_eng_target(trait, ref_year=YTEST_YEAR, lag=1), on='Field_Location', how='left').set_index(xtest.index)
    # del xtrain['Field_Location'], xval['Field_Location'], xtest['Field_Location']

    print(xtrain.corr())
    
    # extract targets
    ytrain = extract_target(xtrain)
    yval = extract_target(xval)
    _ = extract_target(xtest)

    print(xtrain.isnull().sum() / len(xtrain))
    print(xval.isnull().sum() / len(xval))
    print(xtest.isnull().sum() / len(xtest))

    # NA imputing
    for col in xtrain.columns:
        mean = xtrain[col].mean()
        std = xtrain[col].std()

        xtrain[col].fillna(mean, inplace=True)
        xval[col].fillna(mean, inplace=True)
        xtest[col].fillna(mean, inplace=True)

        # xtrain[col] = (xtrain[col] - mean) / std
        # xval[col] = (xval[col] - mean) / std
        # xtest[col] = (xtest[col] - mean) / std

    print('xtrain shape:', xtrain.shape)
    print('xval shape:', xval.shape)
    print('xtest shape:', xtest.shape)
    print('ytrain shape:', ytrain.shape)
    print('yval shape:', yval.shape)
    print('ytrain nulls:', ytrain.isnull().sum() / len(ytrain))
    print('yval nulls:', yval.isnull().sum() / len(yval))

    # train model
    # model = linear_model.LinearRegression()
    model = ensemble.HistGradientBoostingRegressor(random_state=42, max_depth=2)
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
        df_eval['yhat'].rename('validation').describe(),
        pd.DataFrame(model.predict(xtest), columns=['test']).describe()
    ], axis=1)
    print(obs_vs_pred)
