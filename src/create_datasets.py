import argparse
from pathlib import Path
import random

import pandas as pd
from sklearn.decomposition import TruncatedSVD

from preprocessing import (
    process_metadata,
    process_test_data,
    lat_lon_to_bin,
    create_folds,
    agg_yield,
    process_blues,
    feat_eng_weather,
    feat_eng_soil,
    feat_eng_target,
    extract_target,
    create_field_location
)


parser = argparse.ArgumentParser()
parser.add_argument('--cv', type=int, choices={0, 1, 2}, required=True)
parser.add_argument('--fold', type=int, choices={0, 1, 2, 3, 4}, required=True)
args = parser.parse_args()

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
    print('Using CV2')
    YTRAIN_YEAR = 2021  # for split it uses 2020 and 2021
    YVAL_YEAR = 2021
    YTEST_YEAR = 2022
print('Using fold', args.fold)

OUTPUT_PATH = Path(f'output/cv{args.cv}')
TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'

META_COLS = ['Env', 'weather_station_lat', 'weather_station_lon', 'treatment_not_standard']
CAT_COLS = ['Env', 'Hybrid']  # to avoid NA imputation

LAT_BIN_STEP = 1.2
LON_BIN_STEP = LAT_BIN_STEP * 3


if __name__ == '__main__':

    # META
    meta = process_metadata(META_TRAIN_PATH)
    meta_test = process_metadata(META_TEST_PATH)

    # TEST
    test = process_test_data(TEST_PATH)
    xtest = test.merge(meta_test[META_COLS], on='Env', how='left').drop(['Field_Location'], axis=1)
    df_sub = xtest.reset_index()[['Env', 'Hybrid']]

    # TRAIT
    trait = pd.read_csv(TRAIT_PATH)
    trait = trait.merge(meta[META_COLS], on='Env', how='left')
    trait = create_field_location(trait)

    # agg yield (unadjusted means)
    trait = agg_yield(trait)

    # WEATHER
    weather = pd.read_csv('data/Training_Data/4_Training_Weather_Data_2014_2021.csv')
    weather_test = pd.read_csv('data/Testing_Data/4_Testing_Weather_Data_2022.csv')
    
    # SOIL
    soil = pd.read_csv('data/Training_Data/3_Training_Soil_Data_2015_2021.csv')
    soil_test = pd.read_csv('data/Testing_Data/3_Testing_Soil_Data_2022.csv')

    # EC
    ec = pd.read_csv('data/Training_Data/6_Training_EC_Data_2014_2021.csv').set_index('Env')
    ec_test = pd.read_csv('data/Testing_Data/6_Testing_EC_Data_2022.csv').set_index('Env')

    # fold assignment
    random.seed(42)
    df_folds = create_folds(trait, val_year=YVAL_YEAR, cv=args.cv, fillna=False)
    xval = df_folds[df_folds['fold'] == args.fold].drop('fold', axis=1).reset_index(drop=True)
    if args.cv == 0:
        xtrain = df_folds[df_folds['fold'] == 99].drop('fold', axis=1).reset_index(drop=True)
        print('val to train ratio:', len(set(xval['Hybrid'])) / len(set(xtrain['Hybrid'])))
        candidates = list(set(df_folds['Hybrid']) - set(xval['Hybrid']))
        selected = random.choices(candidates, k=int(len(candidates) * 0.6))
        xtrain = xtrain[xtrain['Hybrid'].isin(selected + xval['Hybrid'].tolist())].reset_index(drop=True)
        assert set(xtrain['Year']) & set(xval['Year']) == set()
        assert set(xtrain['Field_Location']) == set(xval['Field_Location'])
        print('val to train ratio:', len(set(xval['Hybrid'])) / len(set(xtrain['Hybrid'])))
    else:
        xtrain = df_folds[df_folds['fold'] != args.fold].drop('fold', axis=1).reset_index(drop=True)
    del xtrain['Field_Location'], xval['Field_Location']
    del xtrain['Year'], xval['Year']

    # replace unadjusted means by BLUEs
    blues = pd.read_csv('output/blues.csv')
    xtrain = xtrain.merge(blues, on=['Env', 'Hybrid'], how='left')
    xtrain = process_blues(xtrain)
    xval = xval.merge(blues, on=['Env', 'Hybrid'], how='left')
    xval = process_blues(xval)

    # feat eng (weather)
    weather_feats = feat_eng_weather(weather)
    weather_test_feats = feat_eng_weather(weather_test)
    xtrain = xtrain.merge(weather_feats, on='Env', how='left')
    xval = xval.merge(weather_feats, on='Env', how='left')
    xtest = xtest.merge(weather_test_feats, on='Env', how='left')

    # feat eng (soil)
    xtrain = xtrain.merge(feat_eng_soil(soil), on='Env', how='left')
    xval = xval.merge(feat_eng_soil(soil), on='Env', how='left')
    xtest = xtest.merge(feat_eng_soil(soil_test), on='Env', how='left')

    # feat eng (EC)
    xtrain_ec = ec[ec.index.isin(xtrain['Env'])].copy()
    xval_ec = ec[ec.index.isin(xval['Env'])].copy()
    xtest_ec = ec_test[ec_test.index.isin(xtest['Env'])].copy()

    n_components = 15
    svd = TruncatedSVD(n_components=n_components, n_iter=20, random_state=42)
    svd.fit(xtrain_ec)
    print('SVD explained variance:', svd.explained_variance_ratio_.sum())

    xtrain_ec = pd.DataFrame(svd.transform(xtrain_ec), index=xtrain_ec.index)
    component_cols = [f'EC_svd_comp{i}' for i in range(xtrain_ec.shape[1])]
    xtrain_ec.columns = component_cols
    xval_ec = pd.DataFrame(svd.transform(xval_ec), columns=component_cols, index=xval_ec.index)
    xtest_ec = pd.DataFrame(svd.transform(xtest_ec), columns=component_cols, index=xtest_ec.index)

    xtrain = xtrain.merge(xtrain_ec, on='Env', how='left')
    xval = xval.merge(xval_ec, on='Env', how='left')
    xtest = xtest.merge(xtest_ec, on='Env', how='left')

    # feat eng (target)
    xtrain = create_field_location(xtrain)
    xval = create_field_location(xval)
    xtest = create_field_location(xtest)
    xtrain = xtrain.merge(feat_eng_target(trait, ref_year=YTRAIN_YEAR, lag=2), on='Field_Location', how='left')
    xval = xval.merge(feat_eng_target(trait, ref_year=YVAL_YEAR, lag=2), on='Field_Location', how='left')
    xtest = xtest.merge(feat_eng_target(trait, ref_year=YTEST_YEAR, lag=2), on='Field_Location', how='left')
    del xtrain['Field_Location'], xval['Field_Location'], xtest['Field_Location']

    # weather-location interaction and lat/lon binning
    for dfs in [xtrain, xval, xtest]:
        dfs['T2M_std_spring_X_weather_station_lat'] = dfs['T2M_std_spring'] * dfs['weather_station_lat']
        dfs['T2M_std_fall_X_weather_station_lat'] = dfs['T2M_std_fall'] * dfs['weather_station_lat']
        dfs['T2M_min_fall_X_weather_station_lat'] = dfs['T2M_min_fall'] * dfs['weather_station_lat']

        # binning lat/lon seems to help reducing noise
        dfs['weather_station_lat'] = dfs['weather_station_lat'].apply(lambda x: lat_lon_to_bin(x, LAT_BIN_STEP))
        dfs['weather_station_lon'] = dfs['weather_station_lon'].apply(lambda x: lat_lon_to_bin(x, LON_BIN_STEP))

    print('lat/lon unique bins:')
    print('lat:', sorted(set(xtrain['weather_station_lat'].unique())))
    print('lon:', sorted(set(xtrain['weather_station_lon'].unique())))

    # set index
    xtrain = xtrain.set_index(['Env', 'Hybrid'])
    xval = xval.set_index(['Env', 'Hybrid'])
    xtest = xtest.set_index(['Env', 'Hybrid'])

    # remove NA phenotype if needed
    xtrain = xtrain[~xtrain['Yield_Mg_ha'].isnull()].reset_index(drop=True)
    xval = xval[~xval['Yield_Mg_ha'].isnull()].reset_index(drop=True)
    xtest = xtest[~xtest['Yield_Mg_ha'].isnull()].reset_index(drop=True)

    # extract targets
    ytrain = extract_target(xtrain)
    yval = extract_target(xval)
    _ = extract_target(xtest)

    print(xtrain.isnull().sum() / len(xtrain))
    print(xval.isnull().sum() / len(xval))
    print(xtest.isnull().sum() / len(xtest))

    # NA imputing
    for col in [x for x in xtrain.columns if x not in CAT_COLS]:
        mean = xtrain[col].mean()
        xtrain[col].fillna(mean, inplace=True)
        xval[col].fillna(mean, inplace=True)
        xtest[col].fillna(mean, inplace=True)

    print('xtrain shape:', xtrain.shape)
    print('xval shape:', xval.shape)
    print('xtest shape:', xtest.shape)
    print('ytrain shape:', ytrain.shape)
    print('yval shape:', yval.shape)
    print('ytrain nulls:', ytrain.isnull().sum() / len(ytrain))
    print('yval nulls:', yval.isnull().sum() / len(yval))

    # write datasets
    xtrain.reset_index().to_csv(OUTPUT_PATH / f'xtrain_fold{args.fold}.csv', index=False)
    xval.reset_index().to_csv(OUTPUT_PATH / f'xval_fold{args.fold}.csv', index=False)
    xtest.reset_index().to_csv(OUTPUT_PATH / 'xtest.csv', index=False)
    ytrain.reset_index().to_csv(OUTPUT_PATH / f'ytrain_fold{args.fold}.csv', index=False)
    yval.reset_index().to_csv(OUTPUT_PATH / f'yval_fold{args.fold}.csv', index=False)
