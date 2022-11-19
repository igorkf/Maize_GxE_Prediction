import pandas as pd


VAL_YEAR = 2021


if __name__ == '__main__':

    trait = pd.read_csv(
        'data/Training_Data/1_Training_Trait_Data_2014_2021.csv',
        usecols=['Year', 'Field_Location', 'Yield_Mg_ha']
    )

    xtrain = trait[trait['Year'] < VAL_YEAR]
    yhat = xtrain.groupby('Field_Location')['Yield_Mg_ha'].mean().rename('yhat')
    
    yval = trait[trait['Year'] == VAL_YEAR][['Field_Location', 'Yield_Mg_ha']]
    yval = yval.merge(yhat, on='Field_Location', how='left')
    
    rmse_per_field = yval.groupby('Field_Location').apply(
        lambda x: (x['Yield_Mg_ha'] - x['yhat']).pow(2).mean() ** 0.5
    )
    rmse = sum(rmse_per_field) / len(rmse_per_field)
    print(rmse_per_field)
    print('RMSE (per location):')
    print(rmse_per_field.describe().to_frame('   ').T)
    print('RMSE:', rmse)
    
