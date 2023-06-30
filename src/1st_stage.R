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


envs <- c('DEH1_2020', 'GAH1_2020', 'GAH2_2020', 'GEH1_2020', 'IAH1_2020', 'INH1_2020', 'MIH1_2020', 'MNH1_2020', 'NCH1_2020', 'NEH1_2020', 'NEH2_2020',
          'NEH3_2020', 'NYH2_2020', 'NYH3_2020', 'NYS1_2020', 'SCH1_2020','TXH1_2020', 'TXH2_2020', 'TXH3_2020', 'WIH1_2020', 'WIH2_2020', 'WIH3_2020')


data <- read.csv('data/Training_Data/1_Training_Trait_Data_2014_2021.csv')
data <- data[data$Env %in% envs, c(1:10, 24)]
data$Field_Location <- NULL
data <- data[data$Hybrid != 'LOCAL_CHECK', ]
data$rep <- interaction(data$Replicate, data$Block)
for (variable in c('Env', 'Experiment', 'Replicate', 'Block', 'rep', 'Plot', 'Range', 'Pass', 'Hybrid')) {
  data[, variable] <- factor(data[, variable])
}

# single-environment models
deh1 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[1]
)
pred_deh1 <- predict.asreml(deh1, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
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


nch1 <- asreml(
  Yield_Mg_ha ~ Experiment + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[9]
)
pred_nch1 <- predict.asreml(nch1, classify = 'Hybrid', present = 'Experiment')$pvals[, 1:2]
pred_nch1$Env <- envs[9]


neh1 <- asreml(
  Yield_Mg_ha ~ Experiment + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[10]
)
pred_neh1 <- predict.asreml(neh1, classify = 'Hybrid', present = 'Experiment')$pvals[, 1:2]
pred_neh1$Env <- envs[10]


neh2 <- asreml(
  Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
  random = ~ Experiment:Range + Experiment:Pass,
  data = data,
  subset = data$Env == envs[11]
)
pred_neh2 <- predict.asreml(neh2, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
pred_neh2$Env <- envs[11]



with(droplevels(data[data$Env == envs[11], ]), table(Experiment, rep))
plot_predictions('NEH2_2020', pred_neh2)








envs <- unique(data$Env)
for (env in envs) {
  cat(env, '\n')
  data_env <- data[data$Env == env, ]
  data_env <- droplevels(data_env)
  rownames(data_env) <- NULL
  
  if (length(levels(data_env$Experiment)) == 1) {
    cat('!!!!!!!!!!!!\n')
  } 
  
  mod1 <- asreml(
    Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
    data = data_env
  )
  
  if (all(is.na(data_env$Range)) & all(is.na(data_env$Pass))) {
    mod2 <- mod1
  } else if (all(is.na(data_env$Pass))) {
    mod2 <- asreml(
      Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
      random = ~ Range,
      data = data_env
    )
  } else if (all(is.na(data_env$Range))) {
    mod2 <- asreml(
      Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
      random = ~ Pass,
      data = data_env
    )
  } else {
    mod2 <- asreml(
      Yield_Mg_ha ~ Experiment + Experiment:rep + Hybrid,
      random = ~ Range + Pass,
      data = data_env
    )
  }
  
  # cat(mod1$loglik, '\n')
  # cat(mod2$loglik, '\n')
  lrt_test <- lrt.asreml(mod1, mod2)
  # cat(unlist(lrt_test), '\n')
  if (lrt_test$`Pr(Chisq)` < 0.05) {
    final_mod <- mod2
  } else {
    final_mod <- mod1
  }
  pred <- predict.asreml(final_mod, classify = 'Hybrid', present = c('Experiment', 'rep'))$pvals[, 1:2]
  colnames(pred) <- c('Hybrid', 'Yield_Mg_ha') 
  pred <- cbind(Env = env, pred)
  blues <- rbind(blues, pred)
  cat('\n')
}
blues$Env <- as.factor(blues$Env)


# analisar caso GAH1_2020
# mod2 <- asreml(
#   Yield_Mg_ha ~ at(Replicate, '1'):Experiment + Hybrid,
#   random = ~ Range + Pass,
#   data = data_env
# )
# predict.asreml(mod2, classify = 'Hybrid')
