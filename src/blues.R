library(asreml)

asreml.options(
  workspace = '4gb',
  pworkspace = '4gb',
  maxit = 300
)

plot_field <- function(env) {
  desplot::desplot(
    data[data$Env == env, ],
    Block ~ Range + Pass,
    out1 = Experiment,
    text = Replicate,
    cex = 1,
    ticks = T,
    main = env
  )
}

envs2019 <- c('DEH1_2019', 'TXH2_2019', 'NCH1_2019', 'SCH1_2019', 'IAH3_2019', 'MNH1_2019', 'IAH2_2019', 'TXH3_2019', 'NYH3_2019', 'ILH1_2019',
              'WIH1_2019', 'GAH1_2019', 'WIH2_2019', 'TXH1_2019', 'IAH4_2019', 'MIH1_2019', 'INH1_2019', 'GEH1_2019', 'IAH1_2019', 'NYH2_2019', 
              'GAH2_2019', 'NEH2_2019', 'NEH1_2019')

envs2020 <- c('DEH1_2020', 'GAH1_2020', 'GAH2_2020', 'GEH1_2020', 'IAH1_2020', 'INH1_2020', 'MIH1_2020', 'MNH1_2020', 'NCH1_2020', 'NEH1_2020', 'NEH2_2020',
              'NEH3_2020', 'NYH2_2020', 'NYH3_2020', 'NYS1_2020', 'SCH1_2020','TXH1_2020', 'TXH2_2020', 'TXH3_2020', 'WIH1_2020', 'WIH2_2020', 'WIH3_2020')

envs2021 <- c('COH1_2021', 'DEH1_2021', 'GAH1_2021', 'GAH2_2021', 'GEH1_2021', 'IAH1_2021', 'IAH2_2021', 'IAH3_2021', 'IAH4_2021', 'ILH1_2021', 'INH1_2021', 'MIH1_2021',
              'MNH1_2021', 'NCH1_2021', 'NEH1_2021', 'NEH2_2021', 'NEH3_2021', 'NYH2_2021', 'NYH3_2021', 'NYS1_2021', 'SCH1_2021', 'TXH1_2021', 'TXH2_2021', 'TXH3_2021',
              'WIH1_2021', 'WIH2_2021', 'WIH3_2021')

envs <- c(envs2019, envs2020, envs2021)

data <- read.csv('data/Training_Data/1_Training_Trait_Data_2014_2021.csv')
data <- data[data$Env %in% envs, c(1:10, 24)]
data$Field_Location <- NULL
data <- data[data$Hybrid != 'LOCAL_CHECK', ]
data <- data[order(data$Experiment), ]  # to use heterogeneous variances if needed
rownames(data) <- NULL 
data$rep <- interaction(data$Replicate, data$Block)
for (variable in c('Env', 'Experiment', 'Replicate', 'Block', 'rep', 'Plot', 'Range', 'Pass', 'Hybrid')) {
  data[, variable] <- factor(data[, variable])
}

# droplevels(data[(grepl('^W10', data$Hybrid) == FALSE) & (data$Year == 2020), ])$Hybrid 
# with(droplevels(data[data$Env == 'WIH1_2021', ]), table(Hybrid, Block))
plot_field('NCH1_2020')

# NYS1_2020 has one block only
# plot_field('NYS1_2020')

# trial
data_NCH1_2020 <- data[data$Env == 'NCH1_2020', ]
data_NCH1_2020 <- droplevels(data_NCH1_2020)
with(data_NCH1_2020, table(Range))
with(data_NCH1_2020, table(Pass))
with(data_NCH1_2020, table(Block))
with(data_NCH1_2020, table(Replicate))
with(data_NCH1_2020, table(Replicate, Block))
with(data_NCH1_2020, table(Hybrid))
data_NCH1_2020[data_NCH1_2020$Hybrid == '2369/LH123HT', ]

# ----------------------------------------------------------------

# single-environment models
# Y = mu + Hybrid + Rep + (1 | Rep:Block + Column + Row) + e

blues <- data.frame()
cvs_h2s <- data.frame()
for (env in envs) {
  cat(env, '\n')
  
  # for blues
  fixed <- as.formula('Yield_Mg_ha ~ Hybrid + Replicate')
  random <- c('Replicate:Block', 'Range', 'Pass')

  # for heritability
  fixed_h2 <- as.formula('Yield_Mg_ha ~ Replicate')
  random_h2 <- c('Hybrid', 'Replicate:Block', 'Range', 'Pass')
  
  data_env <- droplevels(data[data$Env == env, ])
  if (all(is.na(data_env$Range)) == T) {
    cat('Removing Range factor', '\n')
    random <- random[random != 'Range']
    random_h2 <- random_h2[random_h2 != 'Range']
  }
  if (all(is.na(data_env$Pass)) == T) {
    cat('Removing Pass factor', '\n')
    random <- random[random != 'Pass']
    random_h2 <- random_h2[random_h2 != 'Pass']
  }
  if (length(unique(data_env$Block)) == 1) {
    cat('Removing nesting Block factor', '\n')
    random[random == 'Replicate:Block'] <- 'Replicate'
    random_h2[random_h2 == 'Replicate:Block'] <- 'Replicate'
  }
  if (env == 'WIH1_2021') {
    cat('Removing Range due singularity with block', '\n')
    random <- random[random != 'Range']
    random_h2 <- random_h2[random_h2 != 'Range']
  }
  
  # blues
  random <- as.formula(paste0('~', paste0(random, collapse = '+')))
  mod <- asreml(
    fixed = fixed, random = random, data = data, subset = data$Env == env, 
    na.action = na.method(x = 'omit', y = 'include')
  )
  pred <- predict.asreml(mod, classify = 'Hybrid')$pvals[, 1:2]
  pred$Env <- env
  cat('BLUEs:\n')
  print(summary(pred$predicted.value))
  cat('\n')
  blues <- rbind(blues, pred)
  
  # CV
  res_var <- summary(mod)$varcomp[which(rownames(summary(mod)$varcomp) == 'units!R'), 'component']
  cv <- sqrt(res_var) / mean(pred$predicted.value, na.rm = TRUE)
  cat('CV:', cv)
  cat('\n')
  cv_h2 <- data.frame(Env = env, cv = cv)
  
  # heritability
  random_h2 <- as.formula(paste0('~', paste0(random_h2, collapse = '+')))
  mod <- asreml(
    fixed = fixed_h2, random = random_h2, data = data, subset = data$Env == env,
    predict = predict.asreml(classify = 'Hybrid', sed = TRUE),
    na.action = na.method(x = 'omit', y = 'include')
  )
  h2 <- 1 - ((mod$predictions$avsed['mean'] ^ 2) / (2 * summary(mod)$varcomp['Hybrid', 'component']))
  h2 <- unname(h2)
  cat('H2:', h2)
  cat('\n')
  cv_h2$h2 <- h2
  cvs_h2s <- rbind(cvs_h2s, cv_h2)
  
  cat('-----------------------------\n\n')
}


cat('Corr(CV, h2):', cor(cvs_h2s$cv, cvs_h2s$h2))
plot(cvs_h2s$cv, cvs_h2s$h2, xlab = 'CV', ylab = 'h2')


# write results
blues$Env <- as.factor(blues$Env)
write.csv(blues[, c('Env', 'Hybrid', 'predicted.value')], 'output/blues.csv', row.names = F)

cvs_h2s$Env <- as.factor(cvs_h2s$Env)
write.csv(cvs_h2s, 'output/cvs_h2s.csv', row.names = F)


# compare unadjusted means
# ytrain <- rbind(read.csv('output/cv0/ytrain.csv'), read.csv('output/cv1/ytrain.csv'))
# y <- merge(ytrain, blues, by = c('Env', 'Hybrid')) 
# cor(y$Yield_Mg_ha, y$predicted.value)
# cor(y$Yield_Mg_ha, y$predicted.value, method = 'spearman')
# plot(y$Yield_Mg_ha, y$predicted.value)

