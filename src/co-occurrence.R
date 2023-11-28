envs2019 <- c('DEH1_2019', 'TXH2_2019', 'NCH1_2019', 'SCH1_2019', 'IAH3_2019', 'MNH1_2019', 'IAH2_2019', 'TXH3_2019', 'NYH3_2019', 'ILH1_2019',
              'WIH1_2019', 'GAH1_2019', 'WIH2_2019', 'TXH1_2019', 'IAH4_2019', 'MIH1_2019', 'INH1_2019', 'GEH1_2019', 'IAH1_2019', 'NYH2_2019', 
              'GAH2_2019', 'NEH2_2019', 'NEH1_2019')

envs2020 <- c('DEH1_2020', 'GAH1_2020', 'GAH2_2020', 'GEH1_2020', 'IAH1_2020', 'INH1_2020', 'MIH1_2020', 'MNH1_2020', 'NCH1_2020', 'NEH1_2020', 'NEH2_2020',
              'NEH3_2020', 'NYH2_2020', 'NYH3_2020', 'NYS1_2020', 'SCH1_2020','TXH1_2020', 'TXH2_2020', 'TXH3_2020', 'WIH1_2020', 'WIH2_2020', 'WIH3_2020')

envs2021 <- c('COH1_2021', 'DEH1_2021', 'GAH1_2021', 'GAH2_2021', 'GEH1_2021', 'IAH1_2021', 'IAH2_2021', 'IAH3_2021', 'IAH4_2021', 'ILH1_2021', 'INH1_2021', 'MIH1_2021',
              'MNH1_2021', 'NCH1_2021', 'NEH1_2021', 'NEH2_2021', 'NEH3_2021', 'NYH2_2021', 'NYH3_2021', 'NYS1_2021', 'SCH1_2021', 'TXH1_2021', 'TXH2_2021', 'TXH3_2021',
              'WIH1_2021', 'WIH2_2021', 'WIH3_2021')
unique_envs <- c(envs2019, envs2020, envs2021)

indiv <- read.csv("output/individuals.csv", header = F)$V1
data <- read.csv("data/Training_Data/1_Training_Trait_Data_2014_2021.csv")[, c("Hybrid", "Env")]
data <- data[data$Hybrid %in% indiv, ]
data <- data[data$Env %in% unique_envs, ]
rownames(data) <- NULL

# co-occurrence matrix
cooc <- crossprod(table(data))
diag(cooc) <- 0
cooc <- cooc[unique_envs, unique_envs]
pheatmap::pheatmap(cooc, cluster_rows = F, cluster_cols = F, cellwidth = 12, colorRampPalette(c("white", "#F7BA3C", "#7D0025"))(100))
pheatmap::pheatmap(cooc[c(envs2020, envs2021), c(envs2020, envs2021)], cluster_rows = F, cluster_cols = F, cellwidth = 17, colorRampPalette(c("white", "#F7BA3C", "#7D0025"))(100))
