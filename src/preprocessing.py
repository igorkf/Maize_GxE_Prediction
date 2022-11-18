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
    df = pd.read_csv(path).drop(['Yield_Mg_ha'], axis=1)
    df['Field_Location'] = df['Env'].str.replace('(_).*', '', regex=True)
    return df