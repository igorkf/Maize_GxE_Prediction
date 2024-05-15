library(dplyr)
library(kableExtra)

to_wider <- function(tab, cv) {
  tab |>
    group_by(Field_Location, Hybrid, Model, CV) |>
    summarise(ytrue = mean(ytrue), ypred = mean(ypred)) |>
    filter(CV == cv) |>
    arrange(Field_Location, Hybrid) |>
    group_by(Model) |>
    mutate(row = row_number()) |>
    select(row, Field_Location, Hybrid, Model, ytrue, ypred) |>
    tidyr::pivot_wider(names_from = c(Model), values_from = c(ytrue, ypred)) |>
    select(Field_Location, Hybrid, ytrue_E, contains("ypred")) |>
    rename(ytrue = ytrue_E) |>
    rename_at(vars(contains("ypred")), ~sub("ypred_", "", .)) |>
    ungroup() |>
    as.data.frame()
}

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

models <- c("FA", "E", "G(A)", "G(D)", "G(A)+E", "G(D)+E", "G(A)EI", "G(D)EI")
combs <- combn(models, 2, simplify = F)
pred <- data.table::fread("output/all_predictions.csv", data.table = F) |>
  rename(Field_Location = `Field Location`) |>
  mutate(Model = factor(Model, levels = models))

pred_wider0 <- to_wider(pred, 0)
pred_wider1 <- to_wider(pred, 1)
pred_wider2 <- to_wider(pred, 2)

# comparing two correlated correlations
# https://doi.org/10.1037/0033-2909.111.1.172
compare_two_cor_cor <- function(tab) {
  pw_comps <- data.frame()
  N <- nrow(tab)
  r <- cor(tab[, -c(1:2)])
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
    h <- (1 - (f * r2_bar)) / (1 - r2_bar)
    diff <- (z_y_x1 - z_y_x2)
    Z <- diff * sqrt((N - 3) / (2 * (1 - r_x1_x2) * h))
    pvalue <- 2 * (1 - pnorm(abs(Z)))
    pw_comp <- data.frame(
      contrast = paste(x1, "-", x2),
      r1 = r_y_x1,
      r2 = r_y_x2,
      estimate = r_y_x1 - r_y_x2,  # original scale (same as tanh(z_y_x1) - tanh(z_y_x2))
      pvalue = pvalue
    )
    pw_comps <- rbind(pw_comps, pw_comp)
  }
  pw_comps$pvalue_adj <- p.adjust(pw_comps$pvalue, method = "bonferroni")  # p-value * m
  pw_comps$signif <- p_text(pw_comps$pvalue_adj)
  return(pw_comps)
}

pairs0 <- compare_two_cor_cor(pred_wider0) |> mutate_at(vars(r1, r2, estimate), ~round(.x, 2))
pairs1 <- compare_two_cor_cor(pred_wider1) |> mutate_at(vars(r1, r2, estimate), ~round(.x, 2))
pairs2 <- compare_two_cor_cor(pred_wider2) |> mutate_at(vars(r1, r2, estimate), ~round(.x, 2))

# boost over FA
pairs0 |> filter(startsWith(contrast, "FA")) |> mutate(boost = (r2 / r1) - 1) |> select(contrast, boost)
pairs1 |> filter(startsWith(contrast, "FA")) |> mutate(boost = (r2 / r1) - 1) |> select(contrast, boost)
pairs2 |> filter(startsWith(contrast, "FA")) |> mutate(boost = (r2 / r1) - 1) |> select(contrast, boost)

# latex table
all_pairs <- cbind(
  select(pairs2, c(contrast, estimate, signif)), 
  select(pairs1, c(estimate, signif)),
  select(pairs0, c(estimate, signif))
)
kable(all_pairs, format = "latex", booktabs = T, escape = F, 
      linesep = "", caption = "...", label = "paircomp") |>
  kable_classic() |>
  add_header_above(c(" " = 1, "CV2" = 2, "CV1" = 2, "CV0" = 2))
