import pandas as pd


FEATURES = ['weather_station_lat', 'weather_station_lon']


def process_metadata(path: str, encoding: str = 'latin-1'):
    df = pd.read_csv(path, encoding=encoding)
    df['City'] = df['City'].str.strip().replace({'College Station, Texas': 'College Station'})
    df = df.rename(columns={
        'Weather_Station_Latitude (in decimal numbers NOT DMS)': 'weather_station_lat',
        'Weather_Station_Longitude (in decimal numbers NOT DMS)': 'weather_station_lon'
    })
    return df


def process_test_data(path: str):
    df = pd.read_csv(path).drop(['Yield_Mg_ha'], axis=1)
    df['Field_Location'] = df['Env'].str.replace('(_).*', '', regex=True)
    return df


def feature_engineer(df, is_test: bool = False):
    if not is_test:
        return (
            df
            .groupby(['Env', 'Hybrid']).agg(
                weather_station_lat=('weather_station_lat', 'mean'),
                weather_station_lon=('weather_station_lon', 'mean'),
                mean_yield=('Yield_Mg_ha', 'mean')
            )
        )
    else:
        return (
            df
            .groupby(['Env', 'Hybrid']).agg(
                weather_station_lat=('weather_station_lat', 'mean'),
                weather_station_lon=('weather_station_lon', 'mean')
            )
        )



def split_trait_data(df, val_year: int, fillna: bool = False):
    '''
    Targets with NA are due to discarded plots (accordingly with Cyverse data)
    TODO: discard or impute?
    '''

    if fillna:
        raise NotImplementedError('"fillna" is not implemented.')

    xtrain = feature_engineer(df[df['Year'] < val_year])
    xtrain = xtrain.dropna(subset=['mean_yield'])

    xval = feature_engineer(df[df['Year'] == val_year])
    xval = xval.dropna(subset=['mean_yield'])
    
    ytrain = xtrain['mean_yield']
    yval = xval['mean_yield']

    # drop targets
    del xtrain['mean_yield'], xval['mean_yield']

    return xtrain, xval, ytrain, yval