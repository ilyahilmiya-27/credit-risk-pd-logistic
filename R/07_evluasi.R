woe_train <- readRDS("data/woe_train.rds")
woe_test <- readRDS("data/woe_test.rds")
pilih_final <- readRDS("data/variabel_final.rds")
beta_nr <- readRDS("data/beta_nr.rds")

hitung_pd <- function(d) {
  X <- cbind(1, as.matrix(d[, pilih_final]))
  as.vector(plogis(X %*% beta_nr))
}
pd_train <- hitung_pd(woe_train)
pd_test <- hitung_pd(woe_test)
y_train <- woe_train$default
y_test <- woe_test$default

summary(pd_test)

auc_rank <- function(skor, y) {
  r <- rank(skor)
  n1 <- sum(y == 1)
  n0 <- sum( y == 0)
  (sum(r[y == 1]) - n1*(n1+1)/2)/ (n1*n0)
}

auc_pasangan <- function(skor, y) {
  s1 <- skor[y == 1]
  s0 <- skor[y == 0]
  mean(sapply(s1, function(a) mean(a>s0) + 0.5*mean(a == s0)))
}

ks_stat <- function(skor, y) {
  t <- sort(unique(skor))
  max(abs(ecdf(skor[y == 0])(t) - ecdf(skor[y == 1])(t)))
}

kalibrasi <- function(pd, y, k=10) {
  brks <- unique(quantile(pd, probs= seq(0, 1, length.out = k+ 1)))
  grup <- cut(pd, breaks=brks,, include.lowest= TRUE)
  data.frame(
    kelompok = 1:nlevels(grup),
    n = as.vector(table(grup)),
    rerata_prediksi = round(as.vector(tapply(pd, grup, mean)), 4),
    rerata_aktual = round(as.vector(tapply(y, grup, mean)), 4)
  )
}

auc_tr <- auc_rank(pd_train, y_train)
auc_te <- auc_rank(pd_test, y_test)

hasil <- data.frame(
  data = c("train", "test"),
  AUC = round(c(auc_tr, auc_te), 4),
  Gini = round(c(2*auc_tr - 1, 2*auc_te -1), 4),
  KS = round(c(ks_stat(pd_train, y_train), ks_stat(pd_test, y_test)), 4)
)
print(hasil)

c(AUC_peringkat = auc_te, AUC_pasangan=auc_pasangan(pd_test, y_test))

if(requireNamespace("pROC", quietly = TRUE)) {
  r_roc <- pROC :: roc(response = y_test, predictor = pd_test,
                       levels = c(0,1), direction = "<", quiet = TRUE)
  c(AUC_pROC = as.numeric(pROC::auc(r_roc)))
}

tab_kal <- kalibrasi(pd_test, y_test)
print(tab_kal)

c(rerata_PD_test = mean(pd_test), proporsi_default_test = mean(y_test))

dir.create("output", showWarnings = FALSE)
ord <- order(pd_test, decreasing = TRUE)
tpr <- c(0, cumsum(y_test[ord] == 1)/ sum(y_test == 1))
fpr <- c(0, cumsum(y_test[ord] == 0)/ sum(y_test == 0))

png("output/roc_test.png", width=800, height=800, res =120)
plot(fpr, tpr, type="l", lwd = 2,
     xlab = "False positive rate", ylabe = "True positive rate",
     main = paste0("Kurva ROC (data test), AUC = ", round(auc_te, 3)))
abline(0, 1, lty = 2)
dev.off()

saveRDS(hasil, "data/hasil_evaluasi.rds")
saveRDS(tab_kal, "data/tabel_kalibrasi.rds")
