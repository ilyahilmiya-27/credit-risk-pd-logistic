source("R/fungsi.R")

train <- readRDS("data/train.rds")
test <- readRDS("data/test.rds")

batas <- list(
  LIMIT_BAL = buat_batas(train$LIMIT_BAL),
  AGE = buat_batas(train$AGE),
  BILL_AMT1 = buat_batas(train$BILL_AMT1),
  PAY_AMT1 = buat_batas(train$PAY_AMT1)
)

kandidat <- buat_kandidat(train, batas)

table(nilai_mentah = train$PAY_0, kelompok = kandidat$PAY_0)
table(nilai_mentah = train$PAY_2, kelompok = kandidat$PAY_2)

ringkas <- data.frame(
  variabel = names(kandidat),
  jumlah_kelompok = sapply(kandidat, function(k) length(unique(k))),
  n_terkecil = sapply(kandidat, function(k) min(table(k)[table(k)>0])),
  IV = round(sapply(kandidat, function(k) woe_iv(k, train$default)$IV), 4)
)
ringkas <- ringkas[order(-ringkas$IV), ]
rownames(ringkas) <- NULL
print(ringkas)

pay_kol <- c("PAY_0", "PAY_2", "PAY_2", "PAY_3", "PAY_4", "PAY_5", "PAY_6")
cek_iv <- data.frame(
  variabel = pay_kol,
  IV_kelompok = round(sapply(pay_kol, function(v) woe_iv(kandidat[[v]], train$default)$IV),4),
  IV_mentah = round(sapply(pay_kol, function(v) woe_iv(factor(train[[v]]), train$default)$IV), 4)
)
rownames(cek_iv) <- NULL
print(cek_iv)

tabel_woe <- list()
for(v in names(kandidat)) {
  tabel_woe[[v]] <- woe_iv(kandidat[[v]], train$default)$tabel
  cat("\n==", v, "==\n")
  print(tabel_woe[[v]])
}

r <- woe_iv(kandidat$PAY_0, train$default)
kl_gb <- sum(r$g * log(r$g/r$b))
kl_bg <- sum(r$b * log(r$b/r$g))
c(IV = r$IV, jumlah_KL = kl_gb + kl_bg)

kandidat_test <- buat_kandidat(test, batas)
sapply(kandidat_test, function(k) sum(is.na(k)))

for(v in names(kandidat_test)) {
  tak_cocok <- setdiff(as.character(unique(kandidat_test[[v]])),
                       tabel_woe[[v]]$kelompok)
  cat(v, ":",
      if(length(tak_cocok)==0) "OK"
      else paste("Kelompok di test yang tidak ada di train ->",
                 paste(tak_cocok, collapse = ",")),
      "\n")
}

saveRDS(batas, "data/batas_bin.rds")
saveRDS(tabel_woe, "data/tabel_woe.rds")