library(asreml)

asreml.options(
  workspace = '4gb',
  pworkspace = '4gb',
  maxit = 300,
  na.action = na.method(y = 'include', x = 'omit')
)

plot_predictions <- function(env, pred) {
  plot((droplevels(data[data$Env == env, ]) |> group_by(Hybrid) %>% summarise(mean = mean(Yield_Mg_ha)) |> pull(mean)), pred$predicted.value)
}

envs2020 <- c('DEH1_2020', 'GAH1_2020', 'GAH2_2020', 'GEH1_2020', 'IAH1_2020', 'INH1_2020', 'MIH1_2020', 'MNH1_2020', 'NCH1_2020', 'NEH1_2020', 'NEH2_2020',
          'NEH3_2020', 'NYH2_2020', 'NYH3_2020', 'NYS1_2020', 'SCH1_2020','TXH1_2020', 'TXH2_2020', 'TXH3_2020', 'WIH1_2020', 'WIH2_2020', 'WIH3_2020')

envs2021 <- c('COH1_2021', 'DEH1_2021', 'GAH1_2021', 'GAH2_2021', 'GEH1_2021', 'IAH1_2021', 'IAH2_2021', 'IAH3_2021', 'IAH4_2021', 'ILH1_2021', 'INH1_2021', 'MIH1_2021',
              'MNH1_2021', 'NCH1_2021', 'NEH1_2021', 'NEH2_2021', 'NEH3_2021', 'NYH2_2021', 'NYH3_2021', 'NYS1_2021', 'SCH1_2021', 'TXH1_2021', 'TXH2_2021',
              'TXH3_2021', 'WIH1_2021', 'WIH2_2021', 'WIH3_2021')

envs <- c(envs2020, envs2021)


data <- read.csv('data/Training_Data/1_Training_Trait_Data_2014_2021.csv')
data <- data[data$Env %in% envs, c(1:10, 24)]
data$Field_Location <- NULL
data <- data[data$Hybrid != 'LOCAL_CHECK', ]
data <- data[order(data$Experiment), ]  # to use heterogeneous variances
rownames(data) <- NULL 
data$rep <- interaction(data$Replicate, data$Block)
for (variable in c('Env', 'Experiment', 'Replicate', 'Block', 'rep', 'Plot', 'Range', 'Pass', 'Hybrid')) {
  data[, variable] <- factor(data[, variable])
}


data |>
  filter(Env == envs[3]) |>
  ggplot(aes(x = Yield_Mg_ha, color = Experiment)) +
  geom_histogram()



desplot::desplot(
  data[data$Env == envs[1], ],
  Block ~ Range + Pass,
  out1 = Experiment,
  text = Replicate,
  cex = 1.5,
  ticks = T
)



# single-environment models
deh1 <- asreml(
  Yield_Mg_ha ~ Experiment:Block + Hybrid,
  random = ~ Range + Pass + units,
  data = data,
  subset = data$Env == envs[1]
)
pred_deh1 <- predict.asreml(deh1, classify = 'Hybrid')$pvals[, 1:2]
pred_deh1$Env <- envs[1]


gah1 <- asreml(
  Yield_Mg_ha ~ rep + Hybrid,
  random = ~ Range + Pass,
  data = data,
  subset = data$Env == envs[2]
)
pred_gah1 <- predict.asreml(gah1, classify = 'Hybrid')$pvals[, 1:2]
pred_gah1$Env <- envs[2]


gah2 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range,
  data = data,
  subset = data$Env == envs[3]
)
pred_gah2 <- predict.asreml(gah2, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_gah2$Env <- envs[3]


geh1 <- asreml(
  Yield_Mg_ha ~ rep + Hybrid,
  data = data,
  subset = data$Env == envs[4]
)
pred_geh1 <- predict.asreml(geh1, classify = 'Hybrid')$pvals[, 1:2]
pred_geh1$Env <- envs[4]


iah1 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[5]
)
iah1 <- update.asreml(iah1)
pred_iah1 <- predict.asreml(iah1, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_iah1$Env <- envs[5]


inh1 <- asreml(
  Yield_Mg_ha ~ Experiment + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[6]
)
inh1 <- update.asreml(inh1)
pred_inh1 <- predict.asreml(inh1, classify = 'Hybrid')$pvals[, 1:2]
pred_inh1$Env <- envs[6]


mih1 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[7]
)
pred_mih1 <- predict.asreml(mih1, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_mih1$Env <- envs[7]


mnh1 <- asreml(
  Yield_Mg_ha ~ Experiment + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[8]
)
mnh1 <- update.asreml(mnh1)
pred_mnh1 <- predict.asreml(mnh1, classify = 'Hybrid')$pvals[, 1:2]
pred_mnh1$Env <- envs[8]


nch1 <- asreml(
  Yield_Mg_ha ~ Experiment + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[9]
)
pred_nch1 <- predict.asreml(nch1, classify = 'Hybrid')$pvals[, 1:2]
pred_nch1$Env <- envs[9]


neh1 <- asreml(
  Yield_Mg_ha ~ Experiment + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[10]
)
pred_neh1 <- predict.asreml(neh1, classify = 'Hybrid')$pvals[, 1:2]
pred_neh1$Env <- envs[10]


neh2 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[11]
)
pred_neh2 <- predict.asreml(neh2, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_neh2$Env <- envs[11]


neh3 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[12]
)
neh3 <- update.asreml(neh3)
neh3 <- update.asreml(neh3)
neh3 <- update.asreml(neh3)
neh3 <- update.asreml(neh3)
pred_neh3 <- predict.asreml(neh3, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_neh3$Env <- envs[12]


nyh2 <- asreml(
  Yield_Mg_ha ~ Block + Hybrid,
  random = ~ Range + Pass,
  data = data,
  subset = data$Env == envs[13]
)
nyh2 <- update.asreml(nyh2)
pred_nyh2 <- predict.asreml(nyh2, classify = 'Hybrid')$pvals[, 1:2]
pred_nyh2$Env <- envs[13]


nyh3 <- asreml(
  Yield_Mg_ha ~ Block + Hybrid,
  random = ~ Range + Pass,
  data = data,
  subset = data$Env == envs[14]
)
pred_nyh3 <- predict.asreml(nyh3, classify = 'Hybrid')$pvals[, 1:2]
pred_nyh3$Env <- envs[14]


nys1 <- asreml(
  Yield_Mg_ha ~ rep + Hybrid,
  random = ~ Range + Pass,
  data = data,
  subset = data$Env == envs[15]
)
pred_nys1 <- predict.asreml(nys1, classify = 'Hybrid')$pvals[, 1:2]
pred_nys1$Env <- envs[15]


sch1 <- asreml(
  Yield_Mg_ha ~ rep + Hybrid,
  random = ~ Range + Pass,
  data = data,
  subset = data$Env == envs[16]
)
sch1 <- update.asreml(sch1)
pred_sch1 <- predict.asreml(sch1, classify = 'Hybrid')$pvals[, 1:2]
pred_sch1$Env <- envs[16]


txh1 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[17]
)
pred_txh1 <- predict.asreml(txh1, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_txh1$Env <- envs[17]


txh2 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[18]
)
pred_txh2 <- predict.asreml(txh2, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_txh2$Env <- envs[18]


txh3 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[19]
)
pred_txh3 <- predict.asreml(txh3, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_txh3$Env <- envs[19]


wih1 <- asreml(
  Yield_Mg_ha ~ rep + Hybrid,
  random = ~ Range + Pass,
  data = data,
  subset = data$Env == envs[20]
)
wih1 <- update.asreml(wih1)
pred_wih1 <- predict.asreml(wih1, classify = 'Hybrid')$pvals[, 1:2]
pred_wih1$Env <- envs[20]


wih2 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  residual = ~dsum(~units|Experiment),
  data = data,
  subset = data$Env == envs[21]
)
wih2 <- update.asreml(wih2)
pred_wih2 <- predict.asreml(wih2, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_wih2$Env <- envs[21]


wih3 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[22]
)
wih3 <- update.asreml(wih3)
pred_wih3 <- predict.asreml(wih3, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_wih3$Env <- envs[22]

# bind BLUEs
blues <- rbind(
  pred_deh1, pred_gah1, pred_gah2, pred_geh1, pred_iah1, pred_inh1, pred_mih1, pred_mnh1, pred_mnh1, pred_nch1, pred_neh1, pred_neh2, 
  pred_neh3, pred_nyh2, pred_nyh3, pred_nys1, pred_sch1, pred_txh1, pred_txh2, pred_txh3, pred_wih1, pred_wih2, pred_wih3
)
colnames(blues) <- c('Hybrid', 'Yield_Mg_ha', 'Env')
assertthat::are_equal(length(unique(blues$Env)), 22)
write.csv(blues[, c('Env', 'Hybrid', 'Yield_Mg_ha')], 'output/cv0/y2020_1st_stage.csv')

# compare
y <- merge(ytrain, blues, by = c('Env', 'Hybrid')) 


# to check contingency tables and BLUEs
with(droplevels(data[data$Env == envs[1], ]), table(Experiment, rep))
# plot_predictions('WIH3_2020', pred_wih3)


