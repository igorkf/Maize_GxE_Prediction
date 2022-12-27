import pandas as pd
from sklearn.decomposition import TruncatedSVD
import lightgbm as lgbm
from sklearn.metrics import r2_score

from preprocessing import (
    process_metadata,
    process_test_data,
    process_trait_data,
    process_soil_data,
    process_ec_data,
    split_trait_data,
    feature_engineer,
    feat_eng_weather,
    feat_eng_soil,
    feat_eng_target,
    extract_target
)


YTRAIN_YEAR = 2020
YVAL_YEAR = 2021
YTEST_YEAR = 2022

TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'

META_COLS = ['Env', 'weather_station_lat', 'weather_station_lon', 'treatment_not_standard']
META_COLS_TEST = ['Env', 'weather_station_lat', 'weather_station_lon', 'treatment_not_standard']
GENO_COLS = ['Hybrid', 'count_het', 'count_hom', 'GT_pos1_mean', 'GT_pos0_max']
CAT_COLS = []  # to avoid mean imputation


if __name__ == '__main__':

    # META
    meta = process_metadata(META_TRAIN_PATH)
    meta_test = process_metadata(META_TEST_PATH)

    # TEST
    test = process_test_data(TEST_PATH)
    xtest = test.merge(meta_test[META_COLS_TEST], on='Env', how='left').set_index(['Env', 'Hybrid']).drop(['Field_Location'], axis=1)
    df_sub = xtest.reset_index()[['Env', 'Hybrid']]

    # TRAIT
    trait = process_trait_data(TRAIT_PATH)
    trait = trait.merge(meta[META_COLS], on='Env', how='left')

    # WEATHER
    weather = pd.read_csv('data/Training_Data/4_Training_Weather_Data_2014_2021.csv')
    weather_test = pd.read_csv('data/Testing_Data/4_Testing_Weather_Data_2022.csv')

    # SOIL
    soil = process_soil_data('data/Training_Data/3_Training_Soil_Data_2015_2021.csv')
    soil_test = process_soil_data('data/Testing_Data/3_Testing_Soil_Data_2022.csv')

    # EC
    ec = process_ec_data('data/Training_Data/6_Training_EC_Data_2014_2021.csv')
    ec_test = process_ec_data('data/Testing_Data/6_Testing_EC_Data_2022.csv')

    # split train/val
    xtrain, xval = split_trait_data(trait, val_year=YVAL_YEAR, fillna=False)

    # feat eng (trait)
    xtrain = feature_engineer(xtrain)
    xval = feature_engineer(xval)
    xtest = feature_engineer(xtest)

    # feat eng (geno)
    geno = pd.read_csv('output/geno_features.csv', usecols=GENO_COLS)
    xtrain = xtrain.merge(geno, on='Hybrid', how='left').set_index(xtrain.index)
    xval = xval.merge(geno, on='Hybrid', how='left').set_index(xval.index)
    xtest = xtest.merge(geno, on='Hybrid', how='left').set_index(xtest.index)
    del xtrain['Hybrid'], xval['Hybrid'], xtest['Hybrid']

    # feat end (geno 2)
    samples_variants = pd.concat([
        pd.read_csv('output/variants_vs_samples_GT_pos0.csv').T,
        pd.read_csv('output/variants_vs_samples_GT_pos1.csv').T
    ], axis=1)
    print('min:', samples_variants.min().min())
    print('max:', samples_variants.max().max())
    samples_variants.columns = [str(i) for i in range(samples_variants.shape[1])]
    xtrain_geno = samples_variants[samples_variants.index.isin(xtrain.index.get_level_values(1))]
    xval_geno = samples_variants[samples_variants.index.isin(xval.index.get_level_values(1))]
    xtest_geno = samples_variants[samples_variants.index.isin(xtest.index.get_level_values(1))]

    n_components = 200
    svd1 = TruncatedSVD(n_components=n_components, n_iter=20, random_state=42)
    svd1.fit(xtrain_geno.values)
    print('SVD explained variance:', svd1.explained_variance_ratio_.sum())

    xtrain_geno = pd.DataFrame(svd1.transform(xtrain_geno), index=xtrain_geno.index)
    component_cols = [f'geno_svd_comp{i}' for i in range(xtrain_geno.shape[1])]
    xtrain_geno.columns = component_cols
    xval_geno = pd.DataFrame(svd1.transform(xval_geno), columns=component_cols, index=xval_geno.index)
    xtest_geno = pd.DataFrame(svd1.transform(xtest_geno), columns=component_cols, index=xtest_geno.index)

    xtrain_geno = xtrain_geno.reset_index().rename(columns={'index': 'Hybrid'})
    xval_geno = xval_geno.reset_index().rename(columns={'index': 'Hybrid'})
    xtest_geno = xtest_geno.reset_index().rename(columns={'index': 'Hybrid'})

    xtrain = xtrain.merge(xtrain_geno, on='Hybrid', how='left').set_index(xtrain.index.get_level_values(0))
    xval = xval.merge(xval_geno, on='Hybrid', how='left').set_index(xval.index.get_level_values(0))
    xtest = xtest.merge(xtest_geno, on='Hybrid', how='left').set_index(xtest.index.get_level_values(0))
    del xtrain['Hybrid'], xval['Hybrid'], xtest['Hybrid']

    # feat eng (weather)
    xtrain = xtrain.merge(feat_eng_weather(weather), on='Env', how='left')
    xval = xval.merge(feat_eng_weather(weather), on='Env', how='left')
    xtest = xtest.merge(feat_eng_weather(weather_test), on='Env', how='left')

    # feat eng (soil)
    xtrain = xtrain.merge(feat_eng_soil(soil), on='Env', how='left')
    xval = xval.merge(feat_eng_soil(soil), on='Env', how='left')
    xtest = xtest.merge(feat_eng_soil(soil_test), on='Env', how='left')

    # feat eng (EC)
    xtrain_ec = ec[ec.index.isin(xtrain.index)].copy()
    xval_ec = ec[ec.index.isin(xval.index)].copy()
    xtest_ec = ec_test[ec_test.index.isin(xtest.index)].copy()

    n_components = 15
    svd = TruncatedSVD(n_components=n_components, n_iter=20, random_state=42)
    svd.fit(xtrain_ec.values)
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
    xtrain['Field_Location'] = xtrain.index.get_level_values(0).str.replace('(_).*', '', regex=True)
    xval['Field_Location'] = xval.index.get_level_values(0).str.replace('(_).*', '', regex=True)
    xtest['Field_Location'] = xtest.index.get_level_values(0).str.replace('(_).*', '', regex=True)
    xtrain = xtrain.merge(feat_eng_target(trait, ref_year=YTRAIN_YEAR, lag=2), on='Field_Location', how='left').set_index(xtrain.index)
    xval = xval.merge(feat_eng_target(trait, ref_year=YVAL_YEAR, lag=2), on='Field_Location', how='left').set_index(xval.index)
    xtest = xtest.merge(feat_eng_target(trait, ref_year=YTEST_YEAR, lag=2), on='Field_Location', how='left').set_index(xtest.index)
    del xtrain['Field_Location'], xval['Field_Location'], xtest['Field_Location']

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
        std = xtrain[col].std()
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

    model = lgbm.LGBMRegressor(
        random_state=42, 
        max_depth=2
    )  # RMSE=2.1479212182847944
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
    print(obs_vs_pred)
