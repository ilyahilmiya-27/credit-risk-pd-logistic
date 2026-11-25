woe_iv <- function(kelompok, target) {
  tab <- table(kelompok, target)                 # kolom "0" = good, "1" = bad
  tab <- tab[rowSums(tab) > 0, , drop = FALSE]   # buang kelompok yang kosong
  good <- tab[, "0"]
  bad  <- tab[, "1"]
  
  g <- (good + 0.5) / sum(good + 0.5)
  b <- (bad  + 0.5) / sum(bad  + 0.5)
  
  woe    <- log(g / b)
  iv_bin <- (g - b) * woe
  
  tabel <- data.frame(
    kelompok     = names(good),
    n            = as.vector(good + bad),
    good         = as.vector(good),
    bad          = as.vector(bad),
    default_rate = round(as.vector(bad / (good + bad)), 4),
    woe          = round(as.vector(woe), 4),
    iv           = round(as.vector(iv_bin), 4)
  )
  list(tabel = tabel, IV = sum(iv_bin), g = g, b = b)
}

buat_batas <- function(x, k = 5) {
  brks <- unique(quantile(x, probs = seq(0, 1, length.out = k + 1)))
  brks[1] <- -Inf
  brks[length(brks)] <- Inf
  brks
}

bin_pakai <- function(x, batas) {
  cut(x, breaks = batas, include.lowest = TRUE)
}

bin_pay0 <- function(x) {
  k <- rep(">=3", length(x))
  k[x %in% c(-2, 0)] <- "-2/0"
  k[x == -1]         <- "-1"
  k[x == 1]          <- "1"
  k[x == 2]          <- "2"
  factor(k, levels = c("-2/0", "-1", "1", "2", ">=3"))
}

bin_pay_old <- function(x) {
  k <- rep(">=3", length(x))
  k[x %in% c(-2, 0)] <- "-2/0"
  k[x == -1]         <- "-1"
  k[x %in% c(1, 2)]  <- "1-2"
  factor(k, levels = c("-2/0", "-1", "1-2", ">=3"))
}

buat_kandidat <- function(d, batas) {
  list(
    LIMIT_BAL = bin_pakai(d$LIMIT_BAL, batas$LIMIT_BAL),
    AGE       = bin_pakai(d$AGE,       batas$AGE),
    EDUCATION = factor(d$EDUCATION, levels = c(1, 2, 3, 4)),
    PAY_0     = bin_pay0(d$PAY_0),
    PAY_2     = bin_pay_old(d$PAY_2),
    PAY_3     = bin_pay_old(d$PAY_3),
    PAY_4     = bin_pay_old(d$PAY_4),
    PAY_5     = bin_pay_old(d$PAY_5),
    PAY_6     = bin_pay_old(d$PAY_6),
    BILL_AMT1 = bin_pakai(d$BILL_AMT1, batas$BILL_AMT1),
    PAY_AMT1  = bin_pakai(d$PAY_AMT1,  batas$PAY_AMT1)
  )
}

ke_woe <- function(kandidat, woe_map) {
  hasil <- lapply(names(woe_map), function(v) {
    as.numeric(woe_map[[v]][as.character(kandidat[[v]])])
  })
  names(hasil) <- names(woe_map)
  as.data.frame(hasil)
}

hitung_vif <- function(X) {
  v <- diag(solve(cor(X)))
  names(v) <- colnames(X)
  v
}