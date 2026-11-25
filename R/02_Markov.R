train <- readRDS("data/train.rds")

state2 <- function(x) {
  factor(ifelse(x >= 1, "telat", "lancar"), levels = c("lancar", "telat"))
}

pasangan <- data.frame(
  awal = c("PAY_6", "PAY_5", "PAY_4", "PAY_3", "PAY_2"),
  akhir = c("PAY_5", "PAY_4", "PAY_3", "PAY_2", "PAY_0"),
  transisi = c("Apr->Mei", "Mei->Jun", "Jun->Jul", "Jul->Ags", "Ags->Sep"),
  stringsAsFactors = FALSE
)

stopifnot(all(pasangan$awal %in% names(train)),
          all(pasangan$akhir %in% names(train)))

hasil <- data.frame()
for(i in 1:nrow(pasangan)) {
  awal <- state2(train[[pasangan$awal[i]]])
  akhir <- state2(train[[pasangan$akhir[i]]])
  tab <- table(awal, akhir)
  P <- prop.table(tab, 1)
  
  a <- P["lancar", "telat"]
  b <- P["telat", "lancar"]
  
  hasil <- rbind(hasil, data.frame(
    transisi = pasangan$transisi[i],
    n_lancar = sum(tab["lancar", ]),
    n_telat = sum(tab["telat", ]),
    lancar_ke_telat = round(a, 4),
    telat_ke_lancar = round(b, 4),
    pi_telat = round(a/(a+b), 4),
    lama_telat_blm = round(1/b, 2)
  ))
}
print(hasil)

