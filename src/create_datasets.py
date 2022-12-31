import time

import pandas as pd
from sklearn.decomposition import MiniBatchSparsePCA, TruncatedSVD 

from preprocessing import (
    process_metadata,
    process_test_data,
    process_trait_data,
    process_soil_data,
    process_ec_data,
    process_agronomic_data,
    split_trait_data,
    feature_engineer,
    feat_eng_weather,
    feat_eng_soil,
    feat_eng_agronomic,
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
GENO_COLS = ['Hybrid', 'GT_count_het', 'GT_count_hom', 'GT_alt_mean', 'GT_ref_max']
AGRO_COLS = [
    'fertilize_previous_year',
    'herbicide_previous_year',
    'insecticide_or_fungicide_previous_year',
    'irrigation_previous_year'
]
CAT_COLS = []  # to avoid mean imputation


if __name__ == '__main__':
    start_time = time.perf_counter()

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

    # AGRONOMIC
    agro = process_agronomic_data()

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
    samples_variants = pd.read_csv('output/variants_vs_samples_GT_ref_alt.csv').T  # transpose
    print('min:', samples_variants.min().min())
    print('max:', samples_variants.max().max())
    samples_variants.columns = [str(i) for i in range(samples_variants.shape[1])]
    xtrain_geno = samples_variants[samples_variants.index.isin(xtrain.index.get_level_values(1))]  # hybrids
    xval_geno = samples_variants[samples_variants.index.isin(xval.index.get_level_values(1))]
    xtest_geno = samples_variants[samples_variants.index.isin(xtest.index.get_level_values(1))]
    del samples_variants

    n_components = 200
    mbspca = MiniBatchSparsePCA(n_components=n_components, random_state=42)
    mbspca.fit(xtrain_geno.values)
    # print('Sparsity:', sum([x == 0 for x in mbspca.components_]) / len(mbspca.components_))

    xtrain_geno = pd.DataFrame(mbspca.transform(xtrain_geno), index=xtrain_geno.index)
    component_cols = [f'geno_sparsepca_comp{i}' for i in range(xtrain_geno.shape[1])]
    xtrain_geno.columns = component_cols
    xval_geno = pd.DataFrame(mbspca.transform(xval_geno), columns=component_cols, index=xval_geno.index)
    xtest_geno = pd.DataFrame(mbspca.transform(xtest_geno), columns=component_cols, index=xtest_geno.index)

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
    del weather, weather_test

    # feat eng (soil)
    xtrain = xtrain.merge(feat_eng_soil(soil), on='Env', how='left')
    xval = xval.merge(feat_eng_soil(soil), on='Env', how='left')
    xtest = xtest.merge(feat_eng_soil(soil_test), on='Env', how='left')
    del soil, soil_test

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

    # feat eng (agronomic)
    xtrain = xtrain.merge(feat_eng_agronomic(agro), on='Env', how='left')
    xval = xval.merge(feat_eng_agronomic(agro), on='Env', how='left')
    xtest = xtest.merge(feat_eng_agronomic(agro), on='Env', how='left')
    xtrain[AGRO_COLS] = xtrain[AGRO_COLS].fillna(0)
    xval[AGRO_COLS] = xval[AGRO_COLS].fillna(0)
    xtest[AGRO_COLS] = xtest[AGRO_COLS].fillna(0)
    del agro

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

    # generate datasets
    xtrain.to_csv('output/xtrain.csv', index=True)
    xval.to_csv('output/xval.csv', index=True)
    xtest.to_csv('output/xtest.csv', index=True)
    ytrain.to_csv('output/ytrain.csv', index=True)
    yval.to_csv('output/yval.csv', index=True)

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))
