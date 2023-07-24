from math import floor

import pandas as pd
from sklearn.model_selection import GroupKFold


def create_field_location(df: pd.DataFrame):
    df['Field_Location'] = df['Env'].str.replace('(_).*', '', regex=True)
    return df


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
    df = create_field_location(df)
    return df


def lat_lon_to_bin(x, step: float):
    if pd.notnull(x):
        return floor(x / step) * step
    else:
        return x


def agg_yield(df: pd.DataFrame):
    df_agg = (
        df
        .groupby(['Env', 'Hybrid'])
        .agg(
            weather_station_lat=('weather_station_lat', 'mean'),
            weather_station_lon=('weather_station_lon', 'mean'),
            treatment_not_standard=('treatment_not_standard', 'mean'),
            Yield_Mg_ha=('Yield_Mg_ha', 'mean')  # unadjusted means per env/hybrid combination
        )
        .reset_index()
    )
    return df_agg


def process_blues(df: pd.DataFrame):
    df['predicted.value'] = df.apply(lambda x: x['Yield_Mg_ha'] if x['predicted.value'] < 0 else x['predicted.value'], axis=1)
    df = df.drop('Yield_Mg_ha', axis=1)
    df = df.rename(columns={'predicted.value': 'Yield_Mg_ha'})
    return df


def feat_eng_weather(df: pd.DataFrame):
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
            RH2M_p90=('RH2M', lambda x: x.quantile(0.9)),

            QV2M_mean=('QV2M', 'mean'),

            PRECTOTCORR_max=('PRECTOTCORR', 'max'),
            PRECTOTCORR_median=('PRECTOTCORR', 'median'),
            PRECTOTCORR_n_days_less_10_mm=('PRECTOTCORR', lambda x: sum(x < 10)),

            ALLSKY_SFC_PAR_TOT_std=('ALLSKY_SFC_PAR_TOT', 'std'),

        )
        .reset_index()
        .pivot(index='Env', columns='season')
    )
    df_agg.columns = ['_'.join(col) for col in df_agg.columns]
    return df_agg


def feat_eng_soil(df: pd.DataFrame):
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


def feat_eng_target(df: pd.DataFrame, ref_year: list, lag: int):
    assert lag >= 1
    df_year = df[df['Year'] <= ref_year - lag]
    col = f'yield_lag_{lag}'
    df_agg = (
        df_year
        .groupby('Field_Location')
        .agg(
            **{f'mean_{col}': ('Yield_Mg_ha', 'mean')},
            **{f'min_{col}': ('Yield_Mg_ha', 'min')},
            **{f'p1_{col}': ('Yield_Mg_ha', lambda x: x.quantile(0.01))},
            **{f'q1_{col}': ('Yield_Mg_ha', lambda x: x.quantile(0.25))},
            **{f'q3_{col}': ('Yield_Mg_ha', lambda x: x.quantile(0.75))},
            **{f'p90_{col}': ('Yield_Mg_ha', lambda x: x.quantile(0.90))},
        )
    )
    return df_agg


def extract_target(df: pd.DataFrame):
    y = df['Yield_Mg_ha']
    del df['Yield_Mg_ha']
    return y


def create_folds(df: pd.DataFrame, val_year: int, cv: int, fillna: bool = False):
    '''
    Targets with NA are due to discarded plots (accordingly with Cyverse data)
    Reference for CVs: "Genome-enabled Prediction Accuracies Increased by Modeling Genotype x Environment Interaction in Durum Wheat" (Sukumaran et. al, 2017)
    https://acsess.onlinelibrary.wiley.com/doi/10.3835/plantgenome2017.12.0112
    '''

    if fillna:
        raise NotImplementedError('"fillna" is not implemented.')
    
    assert cv in {0, 1, 2}, 'Select cv = 0, 1, or 2.'

    vcfed_hybrids = pd.read_csv('data/Training_Data/All_hybrid_names_info.csv')
    vcfed_hybrids = vcfed_hybrids[vcfed_hybrids['vcf'] == True]['Hybrid']

    # train in known hybrids, predict in unknown year
    if cv == 0:
        train = df[df['Year'] == val_year - 1].dropna(subset=['Yield_Mg_ha'])
        val = df[df['Year'] == val_year].dropna(subset=['Yield_Mg_ha'])
        known_hybrids = set(vcfed_hybrids) & set(train['Hybrid']) & set(val['Hybrid'])
        known_locations = set(train['Field_Location']) & set(val['Field_Location'])
        train = train[(train['Hybrid'].isin(known_hybrids)) & (train['Field_Location'].isin(known_locations))].reset_index(drop=True)
        val = val[(val['Hybrid'].isin(known_hybrids)) & (val['Field_Location'].isin(known_locations))].reset_index(drop=True)
        train = train.sample(frac=1, random_state=42).reset_index(drop=True)
        val = val.sample(frac=1, random_state=42).reset_index(drop=True)

        # k-fold
        # TODO: check CV0
        gkf = GroupKFold(n_splits=5)
        for i, (_, v) in enumerate(gkf.split(X=val, groups=val['Hybrid'])):
            val.loc[v, 'fold'] = i
        train['fold'] = 99.0  # only a placeholder 

        df_folds = pd.concat([train, val], axis=0, ignore_index=True)

    # train in known environments, predict in unknown hybrids
    elif cv == 1:
        train = df[df['Year'].isin([val_year - 1, val_year])].dropna(subset=['Yield_Mg_ha'])
        val = df[df['Year'] == val_year].dropna(subset=['Yield_Mg_ha'])
        known_hybrids = set(vcfed_hybrids) & set(train['Hybrid']) & set(val['Hybrid'])
        known_locations = set(train['Field_Location']) & set(val['Field_Location'])
        train = train[(train['Hybrid'].isin(known_hybrids)) & (train['Field_Location'].isin(known_locations))].reset_index(drop=True)
        val = val[(val['Hybrid'].isin(known_hybrids)) & (val['Field_Location'].isin(known_locations))].reset_index(drop=True)

        # k-fold
        df_folds = pd.concat([train, val], axis=0, ignore_index=True).sample(frac=1, random_state=42).reset_index(drop=True)
        gkf = GroupKFold(n_splits=5)
        for i, (_, v) in enumerate(gkf.split(X=df_folds, groups=df_folds['Hybrid'])):
            df_folds.loc[v, 'fold'] = i

    # some environment/hybrid combinations are unknown
    elif cv == 2:
        train = df[df['Year'].isin([val_year - 1, val_year])].dropna(subset=['Yield_Mg_ha'])
        val = df[df['Year'] == val_year].dropna(subset=['Yield_Mg_ha'])
        known_hybrids = set(vcfed_hybrids) & set(train['Hybrid']) & set(val['Hybrid'])
        known_locations = set(train['Field_Location']) & set(val['Field_Location'])
        train = train[(train['Hybrid'].isin(known_hybrids)) & (train['Field_Location'].isin(known_locations))].reset_index(drop=True)
        val = val[(val['Hybrid'].isin(known_hybrids)) & (val['Field_Location'].isin(known_locations))].reset_index(drop=True)
        train['Env_Hybrid'] = train['Env'] + ':' + train['Hybrid']
        val['Env_Hybrid'] = val['Env'] + ':' + val['Hybrid']

        # k-fold
        df_folds = pd.concat([train, val], axis=0, ignore_index=True).sample(frac=1, random_state=42).reset_index(drop=True)
        gkf = GroupKFold(n_splits=5)
        for i, (_, v) in enumerate(gkf.split(X=df_folds, groups=df_folds['Env_Hybrid'])):
            df_folds.loc[v, 'fold'] = i
        del df_folds['Env_Hybrid']

    else:
        raise NotImplementedError(f'cv = {cv} is not implemented.')

    del df_folds['Field_Location']
    df_folds['fold'] = df_folds['fold'].astype('int')
    return df_folds