woe_train <- readRDS("data/woe_train.rds")
pilih <- readRDS("data/variabel_terpilih.rds")

m_penuh <- glm(reformulate(pilih, response = "default"),
               data = woe_train, family = binomial)
m_tanpa <- glm(reformulate(setdiff(pilih, "PAY_2"), response = "default"),
               data = woe_train, family = binomial)

data.frame(
  model= c("penuh", "tanpa PAY_2"),
  AIC = round(c(AIC(m_penuh), AIC(m_tanpa)), 1),
  BIC = round(c(BIC(m_penuh), BIC(m_tanpa)), 1),
  deviance = round(c(deviance(m_penuh), deviance(m_tanpa)), 1)
)

anova(m_tanpa, m_penuh, test="Chisq")

round(coef(summary(m_tanpa)), 4)