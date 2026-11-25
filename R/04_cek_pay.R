train <- readRDS("data/train.rds")

pay_kol <- c("PAY_0", "PAY_2", "PAY_3", "PAY_4", "PAY_5", "PAY_6")

for (v in pay_kol) {
  sub <- train[train[[v]] <= 0, ]
  n <- table(sub[[v]])
  rate <- tapply(sub$default, sub[[v]], mean)
  cat("\n==", v, "==\n")
  print(data.frame(nilai = names(n),
                   n = as.vector(n),
                   default_rate = round(as.vector(rate), 4)))
}

round(cor(as.matrix(train[, pay_kol]), method="spearman"), 2)