import pandas as pd

from preprocessing import process_metadata, process_test_data


VAL_YEAR = 2021
TRAIT_PATH = 'data/Training_Data/1_Training_Trait_Data_2014_2021.csv'
META_TRAIN_PATH = 'data/Training_Data/2_Training_Meta_Data_2014_2021.csv'
META_TEST_PATH = 'data/Testing_Data/2_Testing_Meta_Data_2022.csv'
TEST_PATH = 'data/Testing_Data/1_Submission_Template_2022.csv'
META_COLS = ['Env', 'City', 'weather_station_lat', 'weather_station_lon']
FEATURES = ['weather_station_lat', 'weather_station_lon']


if __name__ == '__main__':

    # META
    meta = process_metadata(META_TRAIN_PATH)
    meta_test = process_metadata(META_TEST_PATH)

    # TRAIT
    trait = pd.read_csv(TRAIT_PATH)
    trait = trait.merge(meta[META_COLS], on='Env', how='left')

    # split train/val
    df_train = trait[trait['Year'] < VAL_YEAR].reset_index(drop=True)
    df_val = trait[trait['Year'] == VAL_YEAR].reset_index(drop=True)
    xtrain = df_train[['Env'] + FEATURES]
    xval = df_val[['Env'] + FEATURES]
    ytrain = df_train['Yield_Mg_ha']
    yval = df_val['Yield_Mg_ha']

    print('Train:', df_train['Year'].min(), '->', df_train['Year'].max())
    print('Val:', df_val['Year'].min())
    print('Train shape:', xtrain.shape)
    print('Val shape:', xval.shape)

    # TEST
    test = process_test_data(TEST_PATH)
    test = test.merge(meta_test[META_COLS], on='Env', how='left')
    print(test.head())