woe_train <- readRDS("data/woe_train.rds")
pilih_awal <- readRDS("data/variabel_terpilih.rds")

pilih_final <- setdiff(pilih_awal, "PAY_2")
pilih_final

X <- cbind("(Intercept)"= 1, as.matrix(woe_train[, pilih_final]))
y <- woe_train$default
n <- nrow(X)
k <- ncol(X)
dim(X)

loglik <- function(beta) {
  eta <- as.vector(X %*% beta)
  sum(y*eta - log1p(exp(eta)))
}

gradien <- function(beta) {
  p <- plogis(as.vector(X %*% beta))
  as.vector(t(X) %*% (y-p))
}

info <- function(beta) {
  p <- plogis(as.vector(X %*% beta))
  w <- p*(1-p)
  t(X) %*% (X*w)
}

beta <- rep(0, k)
names(beta) <- colnames(X)
riwayat <- data.frame()

for(iter in 1:25) {
  g <- gradien(beta)
  langkah <- as.vector(solve(info(beta), g))
  riwayat <- rbind(riwayat,
                   data.frame(iter = iter,
                              loglik = loglik(beta),
                              maks_gradien = max(abs(g)),
                              maks_langkah = max(abs(langkah))))
  beta <- beta+langkah
  if(max(abs(langkah)) < 1e-10) break
}
print(riwayat)
beta_nr <- beta

model_glm <- glm(reformulate(pilih_final, response = "default"),
                 data= woe_train, family = binomial)

cbind(NR = beta_nr, glm = coef(model_glm))
max(abs(beta_nr - coef(model_glm)))

se_nr <- sqrt(diag(solve(info(beta_nr))))
cbind(SE_NR = se_nr,
      SE_glm = summary(model_glm)$coefficients[, "Std. Error"])

c(loglik_NR = loglik(beta_nr), loglik_glm = as.numeric(logLik(model_glm)))
c(deviance_NR = -2*loglik(beta_nr), deviance_glm = deviance(model_glm))

round(gradien(beta_nr), 8)
sum(y- plogis(as.vector(X %*% beta_nr)))

min(eigen(info(beta_nr), symmetric = TRUE)$values)

set.seed(1)
beta_acak <- lapply(1:5, function(i) rnorm(k, sd=1))
sapply(beta_acak, function(b) min(eigen(info(b), symmetric = TRUE)$values))

langkah_newton <- function(beta) {
  beta+as.vector(solve(info(beta), gradien(beta)))
}
langkah_irls <- function(beta) {
  eta <- as.vector(X %*% beta)
  p <- plogis(eta)
  w <- p*(1-p)
  z <- eta + (y-p)/w
  as.vector(solve(t(X) %*% (X*w), t(X) %*% (w*z)))
}

b0 <- rep(0, k)
max(abs(langkah_newton(b0) - langkah_irls(b0)))
max(abs(langkah_newton(beta_acak[[1]]) - langkah_irls(beta_acak[[1]])))

saveRDS(pilih_final, "data/variabel_final.rds")
saveRDS(beta_nr, "data/beta_nr.rds")

