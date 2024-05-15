library(dplyr)
library(emmeans)
library(kableExtra)

p_text <- function(x) {
  case_when(
    x >= 0.05 ~ "",
    x < 0.001 ~ "***",
    x < 0.01 ~ "**",
    x < 0.05 ~ "*"
  )
}

fisher_z <- function(r) {
  0.5 * log((1 + r) / (1 - r))
}

##############################################
# Prediction accuracy
pred <- data.table::fread("output/all_predictions.csv", data.table = F) |>
  rename(Field_Location = `Field Location`) |>
  mutate(Model = factor(Model, levels = c("FA", "E", "G(A)", "G(D)", "G(A)+E", "G(D)+E", "G(A)EI", "G(D)EI")))
  # mutate(Model = gsub("\\(|\\)|\\+", "_", Model))

# DEPRECATED
# pred_agg <- pred |>
#   group_by(CV, Model, Fold, Seed) |>
#   summarise(pred_ab = cor(ytrue, ypred)) |>
#   mutate(CV = as.factor(CV)) |> 
#   mutate(Model = factor(Model, levels = c("FA", "E", "G(A)", "G(D)", "G(A)+E", "G(D)+E", "G(A)EI", "G(D)EI"))) |>
#   ungroup()

pred_wider0 <- pred |>
  # TODO: check sample size
  group_by(Field_Location, Hybrid, Model, CV) |> 
  summarise(ytrue = mean(ytrue), ypred = mean(ypred)) |>
  filter(CV == 0) |>
  arrange(Field_Location, Hybrid) |>
  group_by(Model) |>
  mutate(row = row_number()) |>
  select(row, Field_Location, Hybrid, Model, ytrue, ypred) |>
  tidyr::pivot_wider(names_from = c(Model), values_from = c(ytrue, ypred)) |>
  select(Field_Location, Hybrid, ytrue_E, contains("ypred")) |>
  rename(ytrue = ytrue_E) |>
  rename_at(vars(contains("ypred")), ~sub("ypred_", "", .))

# comparing two correlated correlations
# https://doi.org/10.1037/0033-2909.111.1.172
pw_comps <- data.frame()
N <- nrow(pred_wider0)  # TODO: check sample size
r <- cor(pred_wider0[, -c(1:2)])
z <- fisher_z(r)
combs <-  combn(colnames(r)[2:ncol(r)], 2, simplify = F)
for (comb in combs) {
  x1 <- comb[1]
  x2 <- comb[2]
  idx_x1 <- which(colnames(r) == x1)
  idx_x2 <- which(colnames(r) == x2)
  z_y_x1 <- z[1, idx_x1]
  z_y_x2 <- z[1, idx_x2]
  r_y_x1 <- r[1, idx_x1]
  r_y_x2 <- r[1, idx_x2]
  r_x1_x2 <- r[idx_x1, idx_x2]
  r2_bar <- ((r_y_x1 ^ 2) + (r_y_x2 ^ 2)) / 2
  f <- (1 - r_x1_x2) / (2 * (1 - r2_bar))
  f <- min(1, f)
  h <- (1 - (f * r_x1_x2)) / (1 - r2_bar)
  estimate <- (z_y_x1 - z_y_x2)
  Z <- estimate * sqrt((N - 3) / (2 * (1 - r_x1_x2) * h))
  pvalue <- 2 * (1 - pnorm(abs(Z)))
  pw_comp <- data.frame(contrast = paste(x1, "-", x2), estimate = estimate, pvalue = pvalue)
  pw_comps <- rbind(pw_comps, pw_comp)
}

# TODO: adjust pvalues for multiple testing correction?
pw_comps$pvalue_adj <- p.adjust(pw_comps$pvalue, method = "bonferroni")
pw_comps$signif <- p_text(pw_comps$pvalue_adj)

##################################################################



mod0 <- aov(pred_ab ~ Model, data = pred_agg[pred_agg$CV == 0, ])
emm0 <- emmeans(mod0, "Model")
pairs0 <- as.data.frame(pairs(emm0)) |> 
  select(estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

mod1 <- aov(pred_ab ~ Model, data = pred_agg[pred_agg$CV == 1, ])
emm1 <- emmeans(mod1, "Model")
pairs1 <- as.data.frame(pairs(emm1)) |> 
  select(estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

mod2 <- aov(pred_ab ~ Model, data = pred_agg[pred_agg$CV == 2, ])
emm2 <- emmeans(mod2, "Model")
pairs2 <- as.data.frame(pairs(emm2)) |>
  select(contrast, estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

# latex table
all_pairs <- cbind(pairs2, pairs1, pairs0)
all_pairs[, c(3, 5, 7)] <- lapply(all_pairs[, c(3, 5, 7)], p_text)
kable(all_pairs, format = "latex", booktabs = T, escape = F, 
      linesep = "", caption = "...", label = "paircomp") |>
  kable_classic() |>
  add_header_above(c(" " = 1, "CV2" = 2, "CV1" = 2, "CV0" = 2))

##############################################


##############################################
# Coincidence index

ci_agg <- read.csv("output/coincidence_index.csv") |>
  mutate(CV = as.factor(CV)) |> 
  mutate(Model = factor(Model, levels = c("FA", "E", "G(A)", "G(D)", "G(A)+E", "G(D)+E", "G(A)EI", "G(D)EI"))) |>
  ungroup()

mod0 <- aov(CI ~ Model, data = ci_agg[ci_agg$CV == 0, ])
emm0 <- emmeans(mod0, "Model")
pairs0 <- as.data.frame(pairs(emm0)) |> 
  select(estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

mod1 <- aov(CI ~ Model, data = ci_agg[ci_agg$CV == 1, ])
emm1 <- emmeans(mod1, "Model")
pairs1 <- as.data.frame(pairs(emm1)) |> 
  select(estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

mod2 <- aov(CI ~ Model, data = ci_agg[ci_agg$CV == 2, ])
emm2 <- emmeans(mod2, "Model")
pairs2 <- as.data.frame(pairs(emm2)) |> 
  select(contrast, estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

# latex table
all_pairs <- cbind(pairs2, pairs1, pairs0)
all_pairs[, c(3, 5, 7)] <- lapply(all_pairs[, c(3, 5, 7)], p_text)
kable(all_pairs, format = "latex", booktabs = T, escape = F, 
      linesep = "", caption = "...", label = "paircomp") |>
  kable_classic() |>
  add_header_above(c(" " = 1, "CV2" = 2, "CV1" = 2, "CV0" = 2))

##############################################
