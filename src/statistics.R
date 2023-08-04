y <- data.frame()
for (cv in 0:2) {
  for (fold in 0:4) {
    for (seed in 1:10) {
      ytrain <- read.csv(paste0('output/cv', cv, '/ytrain_fold', fold, '_seed', seed, '.csv'))
      ytrain$dataset <- 'train'
      yval <- read.csv(paste0('output/cv', cv, '/yval_fold', fold, '_seed', seed, '.csv'))
      yval$dataset <- 'val'
      temp <- rbind(ytrain, yval)
      temp$cv <- cv
      temp$fold <- fold + 1
      temp$seed <- seed
      y <- rbind(y, temp)
    }
  }
}

# fix order
y$Loc <- as.factor(sub('_(.*)', '', y$Env))
y$Year <- as.factor(sub('(.*)_', '', y$Env))
y <- y[order(y$Year, y$Loc), ]
y$Env <- as.factor(paste0(y$Loc, '_', y$Year))
y$Env <- factor(y$Env, levels = unique(y$Env[order(y$Year, y$Loc)]), ordered = TRUE)
head(y)
tail(y)
levels(y$Env)

# other factors
y$fold <- as.factor(y$fold)
y$dataset <- as.factor(y$dataset)
y$Hybrid <- as.factor(y$Hybrid)

# environments
cat('Envs CV0:', length(unique(droplevels(y[y$cv == 0, 'Env']))), '\n')
cat('Envs CV1:', length(unique(droplevels(y[y$cv == 1, 'Env']))), '\n')
cat('Envs CV2:', length(unique(droplevels(y[y$cv == 2, 'Env']))), '\n')
cat('Envs all:', length(unique(y$Env)), '\n')

# environments (validation)
cat('Envs CV0:', length(unique(droplevels(y[(y$dataset == 'val') & (y$cv == 0), 'Env']))), '\n')
cat('Envs CV0:', length(unique(droplevels(y[(y$dataset == 'val') & (y$cv == 1), 'Env']))), '\n')
cat('Envs CV0:', length(unique(droplevels(y[(y$dataset == 'val') & (y$cv == 2), 'Env']))), '\n')
unique_val_envs <- levels(droplevels(y[y$dataset == 'val', ])$Env)
cat('Unique envs in validation:', length(unique_val_envs))

# hybrids
cat('Ind CV0:', length(unique(droplevels(y[y$cv == 0, 'Hybrid']))), '\n')
cat('Ind CV1:', length(unique(droplevels(y[y$cv == 1, 'Hybrid']))), '\n')
cat('Ind CV2:', length(unique(droplevels(y[y$cv == 2, 'Hybrid']))), '\n')
cat('Ind all:', length(unique(y$Hybrid)), '\n')

# hybrids (validation)
cat('Ind CV0:', length(unique(droplevels(y[(y$dataset == 'val') & (y$cv == 0), 'Hybrid']))), '\n')
cat('Ind CV1:', length(unique(droplevels(y[(y$dataset == 'val') & (y$cv == 1), 'Hybrid']))), '\n')
cat('Ind CV2:', length(unique(droplevels(y[(y$dataset == 'val') & (y$cv == 2), 'Hybrid']))), '\n')
cat('Unique hybrids:', length(unique(droplevels(y[, 'Hybrid']))), '\n')
cat('Unique hybrids (validation):', length(unique(droplevels(y[y$dataset == 'val', 'Hybrid']))), '\n')

# year-dataset combinations
with(droplevels(y[y$cv == 0, ]), table(Year, dataset))
with(droplevels(y[y$cv == 1, ]), table(Year, dataset))
with(droplevels(y[y$cv == 2, ]), table(Year, dataset))


# library(ggplot2)
# library(dplyr)
# 
# y0 <- droplevels(y[y$cv == 0, ])
# ggplot(y0, aes(x = Env, y = Hybrid, fill = dataset)) +
#   geom_tile() +
#   theme(
#     axis.ticks.y = element_blank(),
#     axis.text.y = element_blank(),
#     axis.text.x = element_text(angle = 90)
#   )
# 
# 
# y1 <- droplevels(y[y$cv == 1, ])
# ggplot(y1, aes(x = Loc, y = Hybrid, fill = dataset)) +
#   geom_tile() +
#   theme(
#     axis.ticks.y = element_blank(),
#     axis.text.y = element_blank(),
#     axis.text.x = element_text(angle = 90)
#   )
# 
# 
# y2 <- droplevels(y[y$cv == 2, ])
# ggplot(y2, aes(x = Loc, y = Hybrid, fill = dataset)) +
#   geom_tile() +
#   theme(
#     axis.ticks.y = element_blank(),
#     axis.text.y = element_blank(),
#     axis.text.x = element_text(angle = 90)
#   )
  