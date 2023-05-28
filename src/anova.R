preprocess <- function(data, model) {
  data <- data[, c('Env', 'Hybrid', 'ypred')]
  data$Env <- gsub('_(.*)', '', data$Env)
  data$Model <- model
  return(data)
}

cvs <- c(0, 1, 2)
df_emm <- data.frame()
for (cv in cvs) {
  path <- paste0('output/cv', cv, '/')
  # gblup <- preprocess(read.csv(paste0(path, 'oof_gblup_env_hybrid_model.csv')), 'GBLUP')
  g_a <- preprocess(read.csv(paste0(path, 'oof_g_model_A_lag_features_svd100comps.csv')), 'G (A)')
  g_d <- preprocess(read.csv(paste0(path, 'oof_g_model_D_lag_features_svd100comps.csv')), 'G (D)')
  g_epi <- preprocess(read.csv(paste0(path, 'oof_g_model_epiAA_epiDD_epiAD_lag_features_svd250comps.csv')), 'G (epi)')
  g_all <- preprocess(read.csv(paste0(path, 'oof_g_model_A_D_epiAA_epiDD_epiAD_lag_features_svd100comps.csv')), 'G (all)')
  gxe_a <- preprocess(read.csv(paste0(path, 'oof_gxe_model_A_lag_features_svd100comps.csv')), 'GxE (A)')
  gxe_d <- preprocess(read.csv(paste0(path, 'oof_gxe_model_D_lag_features_svd150comps.csv')), 'GxE (D)')
  gxe_epi <- preprocess(read.csv(paste0(path, 'oof_gxe_model_epiAA_epiDD_epiAD_lag_features_svd250comps.csv')), 'GxE (epi)')
  gxe_all <- preprocess(read.csv(paste0(path, 'oof_gxe_model_A_D_epiAA_epiDD_epiAD_lag_features_svd250comps.csv')), 'GxE (all)')
  if (cv == 0) {
    data <- rbind(g_a, g_d, g_epi, g_all, gxe_a, gxe_d, gxe_epi, gxe_all)
  } else {
    data <- rbind(gxe_a, gxe_d, gxe_epi, gxe_all)
  }
  data$Env <- factor(data$Env)
  data$Hybrid <- factor(data$Hybrid)
  data$Model <- factor(data$Model)
  
  for (env in levels(data$Env)) {
    mod <- aov(ypred ~ Hybrid + Model, data = data, subset = data$Env == env)
    emm <- emmeans::emmeans(mod, pairwise ~ Model)
    df_contrasts <- as.data.frame(emm$contrasts)
    df_contrasts$Env <- env
    df_contrasts$CV <- cv
    df_emm <- rbind(df_emm, df_contrasts)
  }
}

write.csv(df_emm, 'output/mean_comparisons_pred.csv')

library(ggplot2)
df_emm[df_emm$CV == 0, ] |>
  ggplot(aes(x = estimate, y = contrast)) +
  geom_point() +
  geom_pointrange(aes(xmin = estimate - (1.96 * SE), xmax = estimate + (1.96 * SE))) + 
  facet_wrap(~ Env)

df_emm[df_emm$CV == 1, ] |>
  ggplot(aes(x = estimate, y = contrast)) +
  geom_point() +
  geom_pointrange(aes(xmin = estimate - (1.96 * SE), xmax = estimate + (1.96 * SE))) + 
  facet_wrap(~ Env)

df_emm[df_emm$CV == 2, ] |>
  ggplot(aes(x = estimate, y = contrast)) +
  geom_point() +
  geom_pointrange(aes(xmin = estimate - (1.96 * SE), xmax = estimate + (1.96 * SE))) + 
  facet_wrap(~ Env)
  

