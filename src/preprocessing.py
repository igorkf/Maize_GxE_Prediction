import pandas as pd


def process_metadata(path: str, encoding: str = 'latin-1'):
    df = pd.read_csv(path, encoding=encoding)
    df['City'] = df['City'].str.strip().replace({'College Station, Texas': 'College Station'})
    df = df.rename(columns={
        'Weather_Station_Latitude (in decimal numbers NOT DMS)': 'weather_station_lat',
        'Weather_Station_Longitude (in decimal numbers NOT DMS)': 'weather_station_lon'
    })
    df['treatment_not_standard'] = (df['Treatment'] != 'Standard').astype('int')
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
            treatment_not_standard=('treatment_not_standard', 'mean'),
            Yield_Mg_ha=('Yield_Mg_ha', 'mean')  # the target
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
            T2M_mean=('T2M', 'mean'),

            T2M_MIN_max=('T2M_MIN', 'max'),
            T2M_MIN_std=('T2M_MIN', 'std'),
            T2M_MIN_cv=('T2M_MIN', lambda x: x.std() / x.mean()),

            WS2M_max=('WS2M', 'max'),

            RH2M_max=('RH2M', 'max'),

            QV2M_mean=('QV2M', 'mean'),

            PRECTOTCORR_max=('PRECTOTCORR', 'max'),
            PRECTOTCORR_median=('PRECTOTCORR', 'median'),
            PRECTOTCORR_n_days_less_10_mm=('PRECTOTCORR', lambda x: sum(x < 10)),

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
            lbs_N_A=('lbs N/A', 'mean'),
            percentage_Ca_Sat=('%Ca Sat', 'mean')
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