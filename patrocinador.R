# Ler dados
library(dplyr)
dados <- read.csv2("https://raw.githubusercontent.com/gustavomirapalheta/classes_datasets/master/patrocinador.csv")
Patrocinador = as_tibble(dados)

modelo ='patro =~ Pat01 + Pat03 + Pat05 + Pat06
marca =~ Pat08 + Pat09 + Pat02
Aw01 ~ patro + marca'

resultados = sem(model=modelo, data=Patrocinador)
summary(resultados, standardized=TRUE)
