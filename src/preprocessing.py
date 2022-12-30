import pandas as pd


def process_metadata(path: str, encoding: str = 'latin-1'):
    df = pd.read_csv(path, encoding=encoding)
    df = df.rename(columns={
        'Weather_Station_Latitude (in decimal numbers NOT DMS)': 'weather_station_lat',
        'Weather_Station_Longitude (in decimal numbers NOT DMS)': 'weather_station_lon'
    })
    df['Env'] = df['Env'].str.replace('-(.*)', '', regex=True)
    df['City'] = df['City'].str.strip().replace({'College Station, Texas': 'College Station'})
    df['treatment_not_standard'] = (df['Treatment'].str.contains('Standard') == False).astype('int')

    # if 'Date_Planted' in df.columns:
    #     df['Date_Planted'] = pd.to_datetime(df['Date_Planted'])
    #     df['month_planted'] = df['Date_Planted'].dt.month 
    #     df['season_planted'] = df['month_planted'] % 12 // 3 + 1  # https://stackoverflow.com/a/44124490/11122513
    return df


def process_test_data(path: str):
    df = pd.read_csv(path)
    df['Field_Location'] = df['Env'].str.replace('(_).*', '', regex=True)
    return df


def process_trait_data(path: str):
    df = pd.read_csv(path)
    # df['Date_Planted'] = pd.to_datetime(df['Date_Planted'])
    # df['month_planted'] = df['Date_Planted'].dt.month 
    # df['season_planted'] = df['month_planted'] % 12 // 3 + 1  # https://stackoverflow.com/a/44124490/11122513
    return df


def process_soil_data(path: str):
    df = pd.read_csv(path)
    return df


def process_ec_data(path: str):
    null_std_cols = [
        'yield_pGerEme', 'yield_pEmeEnJ', 'yield_pEnJFlo', 'yield_pFloFla', 
        'Flux_pStGEnG_6', 'Flux_pEnGMat_6', 'Flux_pStGEnG_7', 'Flux_pEnGMat_7', 
        'Flux_pMatHar_7', 'Flux_pEnGMat_8', 'Flux_pMatHar_8'
    ]
    df = pd.read_csv(path)
    df = df.set_index('Env')
    df = df.drop(null_std_cols, axis=1, errors='ignore')
    return df


def process_agronomic_data():
    df = []
    for year in [2019, 2020, 2021]:
        df_temp = pd.read_csv(f'data/g2f_{year}_agronomic_information.csv')
        df_temp['Env'] = df_temp['Location'] + '_' + str(year + 1)  # to use in merging
        df.append(df_temp)

    df = pd.concat(df, ignore_index=True)
    df = df.rename(columns={'Location': 'Field_Location'})
    df['Application_or_treatment'] = df['Application_or_treatment'].str.lower().str.strip()
    df.loc[df['Application_or_treatment'].isin(['fertlizer', 'fertilizer', 'manure fertilizer', 'chemical fertilizer', 'fertigation']), 'Application_or_treatment'] = 'fertilize'
    df.loc[df['Application_or_treatment'].str.contains('herbicide'), 'Application_or_treatment'] = 'herbicide'

    df['herbicide'] = (df['Application_or_treatment'] == 'herbicide').astype('int')
    df['fertilize'] = (df['Application_or_treatment'] == 'fertilize').astype('int')
    df['insecticide_or_fungicide'] = (df['Application_or_treatment'].isin(['insecticide', 'fungicide'])).astype('int')
    df['irrigation'] = (df['Application_or_treatment'] == 'irrigation').astype('int')

    return df


def feature_engineer(df):
    df_agg = (
        df
        .groupby(['Env', 'Hybrid']).agg(
            weather_station_lat=('weather_station_lat', 'mean'),
            weather_station_lon=('weather_station_lon', 'mean'),
            treatment_not_standard=('treatment_not_standard', 'mean'),
            Yield_Mg_ha=('Yield_Mg_ha', 'mean')  # target
        )
    )
    return df_agg


def feat_eng_weather(df):
    df['Date'] = pd.to_datetime(df['Date'], format='%Y%m%d')
    df['month'] = df['Date'].dt.month 
    df['season'] = df['month'] % 12 // 3 + 1  # https://stackoverflow.com/a/44124490/11122513
    df['season'] = df['season'].map({1: 'winter', 2: 'spring', 3: 'summer', 4: 'fall'})
    df_agg = df.dropna(subset=[x for x in df.columns if x not in ['Env', 'Date']]).copy()
    df_agg = (
        df
        .groupby(['Env', 'season'])
        .agg(
            T2M_max=('T2M', 'max'),
            T2M_min=('T2M', 'min'),
            T2M_std=('T2M', 'std'),

            T2M_MIN_max=('T2M_MIN', 'max'),
            T2M_MIN_std=('T2M_MIN', 'std'),

            WS2M_max=('WS2M', 'max'),

            RH2M_max=('RH2M', 'max'),

            QV2M_mean=('QV2M', 'mean'),

            PRECTOTCORR_max=('PRECTOTCORR', 'max'),
            PRECTOTCORR_median=('PRECTOTCORR', 'median'),

            ALLSKY_SFC_PAR_TOT_std=('ALLSKY_SFC_PAR_TOT', 'std'),

        )
        .reset_index()
        .pivot('Env', 'season')
    )
    df_agg.columns = ['_'.join(col) for col in df_agg.columns]
    return df_agg


def feat_eng_soil(df):
    df_agg = (
        df
        .groupby('Env')
        .agg(
            Nitrate_N_ppm_N=('Nitrate-N ppm N', 'mean'),
            percentage_Sand=('% Sand', 'mean'),
            lbs_N_A=('lbs N/A', 'mean'),
            percentage_Ca_Sat=('%Ca Sat', 'mean')
        )
    )
    return df_agg


def feat_eng_agronomic(df):
    df_agg = (
        df
        .groupby('Env').agg(
            # TODO: try to add quantity (e.g. in lb)
            fertilize_previous_year=('fertilize', lambda x: sum(x) / len(x)),
            herbicide_previous_year=('herbicide', lambda x: sum(x) / len(x)),
            insecticide_or_fungicide_previous_year=('insecticide_or_fungicide', lambda x: sum(x) / len(x)),
            irrigation_previous_year=('irrigation', lambda x: sum(x) / len(x))
        )
    )
    return df_agg


def feat_eng_target(df, ref_year, lag):
    assert lag >= 1
    df_year = df[df['Year'] <= ref_year - lag]
    df_agg = (
        df_year
        .groupby('Field_Location')
        .agg(
            **{f'mean_yield_lag_{lag}': ('Yield_Mg_ha', 'mean')},
            **{f'min_yield_lag_{lag}': ('Yield_Mg_ha', 'min')}
        )
    )
    return df_agg


def extract_target(df):
    y = df['Yield_Mg_ha']
    del df['Yield_Mg_ha']
    return y


def split_trait_data(df, val_year: int, fillna: bool = False):
    '''
    Targets with NA are due to discarded plots (accordingly with Cyverse data)
    TODO: discard or impute?
    '''

    if fillna:
        raise NotImplementedError('"fillna" is not implemented.')

    train = df[df['Year'] == val_year - 1].dropna(subset=['Yield_Mg_ha'])
    val = df[df['Year'] == val_year].dropna(subset=['Yield_Mg_ha'])
    
    return train, val