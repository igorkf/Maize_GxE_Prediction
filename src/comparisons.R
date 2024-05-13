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

##############################################
# Prediction accuracy

pred <- data.table::fread("output/all_predictions.csv", data.table = F)
pred_agg <- pred |>
  group_by(CV, Model, Fold, Seed) |>
  summarise(pred_ab = cor(ytrue, ypred)) |>
  mutate(CV = as.factor(CV)) |> 
  mutate(Model = factor(Model, levels = c("FA", "E", "G(A)", "G(D)", "G(A)+E", "G(D)+E", "G(A)EI", "G(D)EI"))) |>
  ungroup()

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
