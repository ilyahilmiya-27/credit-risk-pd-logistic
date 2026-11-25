library(readxl)
library(dplyr)

df <- read_excel("data/default of credit card clients.xls", skip=1)
df <- df %>% rename(default ='default payment next month')

dim(df)
sum(is.na(df))
prop.table(table(df$default))
df <- df %>%
  mutate(
    EDUCATION =ifelse(EDUCATION %in% c(0, 5, 6), 4, EDUCATION),
    MARRIAGE = ifelse(MARRIAGE == 0, 3, MARRIAGE)
  )
table(df$EDUCATION)
table(df$MARRIAGE)

set.seed(123)
idx1 <- which(df$default == 1)
idx0 <- which(df$default == 0)
train_idx <- c(sample(idx1, round(0.7*length(idx1))),
               sample(idx0, round(0.7*length(idx0))))
train <- df[train_idx,]
test <- df[-train_idx,]

dim(train)
dim(test)
prop.table(table(train$default))
prop.table(table(test$default))

dir.create("data", showWarnings = FALSE)
saveRDS(train, "data/train.rds")
saveRDS(test, "data/test.rds")
