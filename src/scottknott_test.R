cv <- 0

data <- read.csv('output/all_predictions.csv')
data <- transform(data, Field.Location = as.factor(Field.Location), CV = as.factor(CV))
data_cv <- droplevels(data[data$CV == cv, ])
data_cv$error <- -data_cv$error ^ 2  # to be similar to what RMSE does
data_cv$Model <-as.factor(sub(' ', '_', data_cv$Model))
envs <- levels(data_cv$Field.Location)
models <- levels(data_cv$Model)

# run scott-knot test
sink(paste0('output/scottknott_cv', cv, '.txt'))
for (env in envs) {
  df_env <- droplevels(data_cv[data_cv$Field.Location == env, ])
  
  # anova
  mod <- aov(error ~ Model, data = df_env)
  summod <- summary(mod)
  DFE <- summod[[1]]$Df[2]
  SSE <- summod[[1]]$`Sum Sq`[2]
  
  # more about this test: http://listas.inf.ufpr.br/pipermail/r-br/attachments/20110721/566a9248/attachment.pdf
  sck <- ExpDes::scottknott(df_env$error, df_env$Model, DFE, SSE)
}
sink()

# parse scott-knott comparisons and build dataframe
complines <- readLines(paste0('output/scottknott_cv', cv, '.txt'))
complines <- complines[complines != '']
complines <- complines[complines != 'Scott-Knott test']
complines <- complines[complines != '------------------------------------------------------------------------']
complines <- complines[grepl('Groups', complines) == F]
comps <- data.frame()
for (i in 1:length(complines)) {
  temp <- read.table(textConnection(complines[[i]]))
  comps <- rbind(comps, temp)
}
comps$Env <- rep(envs, each = length(models))
comps$V1 <- NULL
colnames(comps) <- c('group', 'model', 'mean', 'Env')
comps$model <- sub('_', ' ', comps$model)
comps <- transform(comps, group = as.factor(group), model = as.factor(model), Env = as.factor(Env))
comps$model <- forcats::fct_relevel(comps$model, c('E', 'G (A)', 'G (D)', 'G (epi)', 'G (all)', 'G+E (A)', 'G+E (D)', 'G+E (epi)', 'G+E (all)', 'GxE (A)', 'GxE (D)', 'GxE (epi)', 'GxE (all)'))


COLORS <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")

# create heatmap
library(ggplot2)
ggplot(comps, aes(model, Env, fill = group)) + 
  geom_tile() +
  geom_text(aes(label = group)) +
  labs(x = 'Model', y = 'Location', fill = 'Group') +
  scale_fill_manual(values = COLORS)


with(comps, table(Env, group))
with(comps, table(model, group))
