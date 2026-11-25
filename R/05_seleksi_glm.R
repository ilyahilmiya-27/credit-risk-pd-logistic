source("R/fungsi.R")

train <- readRDS("data/train.rds")
test <- readRDS("data/test.rds")
batas <- readRDS("data/batas_bin.rds")

kandidat_train <- buat_kandidat(train, batas)
kandidat_test <- buat_kandidat(test, batas)

woe_map <- list()
for(v in names(kandidat_train)) {
  r <- woe_iv(kandidat_train[[v]], train$default)
  woe_map[[v]] <- log(r$g/r$b)
}

woe_train <- ke_woe(kandidat_train, woe_map)
woe_test <- ke_woe(kandidat_test, woe_map)
woe_train$default <- train$default
woe_test$default <- test$default

sum(is.na(woe_train))
sum(is.na(woe_test))
dim(woe_train)
dim(woe_test)

var_kandidat <- c("PAY_0", "PAY_2", "PAY_3", "PAY_4", "PAY_5", "PAY_6", "LIMIT_BAL", "PAY_AMT1", "EDUCATION")

round(cor(woe_train[, var_kandidat]), 2)

round(hitung_vif(woe_train[, var_kandidat]), 2)

pilih <- var_kandidat
while(TRUE) {
  v <- hitung_vif(woe_train[, pilih])
  if(max(v) < 5|| length(pilih) <= 2) break
  buang <- names(wich.max(v))
  cat("Buang", buang, "(VIF =", round(max(v), 2), ")\n")
  pilih <- setdiff(pilih, buang)
}
cat("\nVariabel terpilih:", paste(pilih, collapse = ", "), "\n")
round(hitung_vif(woe_train[pilih]), 2)

rumus <- as.formula(paste("default ~", paste(pilih, collapse = " + ")))
model_glm <- glm(rumus, data = woe_train, family = binomial)
summary(model_glm)

model_glm$iter

round(coef(model_glm), 4)
coef(model_glm)[-1]<0

c(rerata_PD=mean(fitted(model_glm)), proporsi_default = mean(woe_train$default))

saveRDS(woe_map, "data/woe_map.rds")
saveRDS(woe_train, "data/woe_train.rds")
saveRDS(woe_test, "data/woe_test.rds")
saveRDS(pilih, "data/variabel_terpilih.rds")

