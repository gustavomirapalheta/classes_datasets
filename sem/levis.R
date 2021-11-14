library(dplyr)
dados <- as_tibble(read.csv2("https://raw.githubusercontent.com/gustavomirapalheta/classes_datasets/master/levis.csv"))

library(psych)
fit = princomp(dados, cor = TRUE)
plot(fit, type="lines")

cargas = principal(dados, nfactors = 5, rotate = "varimax")
cargas$loadings

#Sim a validade convergente e discriminante
# As cargas fatorais de cada grupo de variáveis (ítens)
#  se concentram nos seus fatores específicos (>0,40) 
#  e nos outros fatores tem carga <0,40

