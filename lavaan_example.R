library(dplyr)
library(lavaan)
as_tibble(PoliticalDemocracy)


cfa1 <- '
    ind60 =~ x1 + x2 + x3'

cfa2 <- '
    dem60 =~ y1 + y2 + y3 + y4'

cfa3 <- '
    dem65 =~ y5 + y6 + y7 + y8'

cfa_all <- '
    ind60 =~ x1 + x2 + x3
    dem60 =~ y1 + y2 + y3 + y4
    dem65 =~ y5 + y6 + y7 + y8'

fit_cfa1 <- cfa(model = cfa1, data = PoliticalDemocracy)

fit_cfa2 <- cfa(model = cfa2, data = PoliticalDemocracy)

fit_cfa3 <- cfa(model = cfa3, data = PoliticalDemocracy)

fit_cfa_all <- cfa(model = cfa_all, data = PoliticalDemocracy)

summary(fit_cfa1, fit.measures = TRUE)

summary(fit_cfa2, fit.measures = TRUE)

summary(fit_cfa3, fit.measures = TRUE)

summary(fit_cfa_all, fit.measures = TRUE)

model <- '
  # measurement model
    ind60 =~ x1 + x2 + x3
    dem60 =~ y1 + y2 + y3 + y4
    dem65 =~ y5 + y6 + y7 + y8
  # regressions
    dem60 ~ a*ind60
    dem65 ~ c*ind60 + b*dem60
  # residual correlations
    y1 ~~ y5
    y2 ~~ y4 + y6
    y3 ~~ y7
    y4 ~~ y8
    y6 ~~ y8
  # indirect/mediating effect
    ab := a*b
  # Total effct
    total := c + (a*b)
'

fit <- sem(model, data = PoliticalDemocracy)

summary(fit, fit.measures = TRUE, standardized=TRUE)

library(semPlot)
semPlot::semPaths(fit, what = c("paths", "est"), whatLabels = "est", layout = "tree2")
