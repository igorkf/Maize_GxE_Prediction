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

pred <- data.table::fread("output/all_predictions.csv", data.table = F)

# predictive ability
pred_agg <- pred |>
  group_by(CV, Model, Fold, Seed) |>
  summarise(pred_ab = cor(ytrue, ypred)) |>
  mutate(CV = as.factor(CV)) |> 
  mutate(Model = factor(Model, levels = c("FA", "E", "G(A)", "G(D)", "G(A)+E", "G(D)+E", "G(A)EI", "G(D)EI"))) |>
  ungroup()

# pairwise comparisons
mod0 <- aov(pred_ab ~ Model, data = pred_agg[pred_agg$CV == 0, ])
emm0 <- emmeans(mod0, "Model")
pairs0 <- as.data.frame(pairs(emm0)) |> 
  select(contrast, estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

mod1 <- aov(pred_ab ~ Model, data = pred_agg[pred_agg$CV == 1, ])
emm1 <- emmeans(mod1, "Model")
pairs1 <- as.data.frame(pairs(emm1)) |> 
  select(estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

mod2 <- aov(pred_ab ~ Model, data = pred_agg[pred_agg$CV == 2, ])
emm2 <- emmeans(mod2, "Model")
pairs2 <- as.data.frame(pairs(emm2)) |> 
  select(estimate, p.value) |>
  mutate(estimate = round(estimate, 3))

# latex table
all_pairs <- cbind(pairs0, pairs1, pairs2)
all_pairs[, c(3, 5, 7)] <- lapply(all_pairs[, c(3, 5, 7)], p_text)
kable(all_pairs, format = "latex", booktabs = T, escape = F, linesep = "",
      caption = "Estimate and p-value for the predictive ability pairwise comparisons among models for the different cross-validation (CV) schemes. Empty cells represent a non-significant difference using a 0.05 significance level.",
      label = "paircomp") |>
  kable_classic() |>
  add_header_above(c(" " = 1, "CV0" = 2, "CV1" = 2, "CV2" = 2))
