import pandas as pd


def process_metadata(path: str, encoding: str = 'latin-1'):
    df = pd.read_csv(path, encoding=encoding)
    df['City'] = df['City'].str.strip().replace({'College Station, Texas': 'College Station'})
    df = df.rename(columns={
        'Weather_Station_Latitude (in decimal numbers NOT DMS)': 'weather_station_lat',
        'Weather_Station_Longitude (in decimal numbers NOT DMS)': 'weather_station_lon'
    })
    return df


def process_test_data(path: str):
    df = pd.read_csv(path)
    df['Field_Location'] = df['Env'].str.replace('(_).*', '', regex=True)
    return df


def feature_engineer(df):
    df_agg = (
        df
        .groupby(['Env', 'Hybrid']).agg(
            weather_station_lat=('weather_station_lat', 'mean'),
            weather_station_lon=('weather_station_lon', 'mean'),
            Yield_Mg_ha=('Yield_Mg_ha', 'mean')
        )
    )
    return df_agg


def feat_eng_weather(df):
    df = df.dropna(subset=[x for x in df.columns if x not in ['Env', 'Date']])
    df_agg = (
        df
        .groupby('Env')
        .agg(
            T2M_max=('T2M', 'max'),
            RH2M_max=('RH2M', 'max'),
            PRECTOTCORR_max=('PRECTOTCORR', 'max'),
            ALLSKY_SFC_PAR_TOT_max=('ALLSKY_SFC_PAR_TOT', 'max')
        )
    )
    return df_agg


def feat_eng_ec(df):
    df_agg = (
        df
        .groupby('Env')
        .agg('mean')
    )
    df_agg.columns = [f'{x}_mean' for x in df_agg.columns]
    return df_agg


# def feat_eng_target(df, ref_year, lag):
#     assert lag >= 1
#     df_year = df[df['Year'] <= ref_year - lag]
#     series = (
#         df_year
#         .groupby('Field_Location')
#         .agg(
#             **{f'last_yield_lag_{lag}': ('Yield_Mg_ha', 'last')}
#         )
#     )
#     return series


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

    xtrain = df[df['Year'] == val_year - 1].dropna(subset=['Yield_Mg_ha'])
    xval = df[df['Year'] == val_year].dropna(subset=['Yield_Mg_ha'])
    
    return xtrain, xval