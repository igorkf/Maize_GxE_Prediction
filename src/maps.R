# install rgdal
# requires module load gdal/1.11.1
# packageurl <- 'https://cran.r-project.org/src/contrib/Archive/rgdal/rgdal_1.6-3.tar.gz'
# install.packages(packageurl, repos = NULL, type = 'source')

library(usmap)
library(ggplot2)
library(dplyr)

# read data and filter non US
xtrain <- read.csv('output/cv0/xtrain.csv')
ytrain <- read.csv('output/cv0/ytrain.csv')
df <- left_join(xtrain, ytrain, by = c('Env', 'Hybrid'))
df <- filter(df, stringr::str_detect(Env, 'GEH1') == F)
df$Loc <- stringr::str_sub(df$Env, end = 3)

# create x, y to plot points
df_trans <- usmap_transform(
  df[, c('weather_station_lon', 'weather_station_lat')], 
  input_names = c('weather_station_lon', 'weather_station_lat')
)
df_trans <- left_join(df, df_trans, by = c("weather_station_lat", "weather_station_lon"))

# plot trial points
plot_usmap(regions = 'states', labels = T) + 
  geom_point(data = distinct(df_trans[, c('x', 'y')]), aes(x = x, y = y), fill = 'red', color = 'black', pch = 21, size = 3)


# mean yield per field
df_mean_yield <- df_trans |> 
  group_by(weather_station_lat, weather_station_lon) |> 
  summarise(yield = mean(Yield_Mg_ha), x= mean(x), y = mean(y)) |>
  ungroup()

plot_usmap(regions = 'state', labels = T) +
  geom_point(data = df_mean_yield, aes(x = x, y = y, fill = yield), color = 'black', pch = 21, size = 3) +
  scale_fill_gradient(low = 'red', high = 'green') +
  labs(fill = 'Mean yield\n (Mg/ha)') +
  theme(
    legend.position = 'top',
    legend.justification = 'right',
    legend.margin = margin(0, 0, 0, 0),
    legend.box.margin = margin(10, 10, 10, 10),
  )


