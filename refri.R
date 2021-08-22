# Carga de dados
library(dplyr)
refri <- as_tibble(read.csv2("https://raw.githubusercontent.com/gustavomirapalheta/classes_datasets/master/refri.csv"))

# Validade convergente: o quanto os itens designados para
#  medir um mesmo constructo estão correlacionados. Isto 
#  ocorre quando as cargas fatoriais são maiores que 0.40

#  3 constructos (componentes principais): Sabor, Saúde, Sede
#  Itens divididos por constructos são apresentados abaixo:
#-------------------------------------------------------------
# Sabor
#   X1. A marca Y tem um sabor refrescante 
#   X4. Eu gosto do sabor suave da marca Y 
#   X6. A marca Y tem sabor único 
#-------------------------------------------------------------
# Saude
#   X2. Eu prefiro a marca Y porque tem menos calorias 
#       que outras bebidas 
#   X5. Eu prefiro tomar a marca Y após os exercícios 
#       e esportes porque ela me dá energia 
#-------------------------------------------------------------
# Sede
#   X3. A marca Y sacia minha sede imediatamente 
#   X7. Eu prefiro tomar a marca Y quando eu estou 
#       com muita sede 
#-------------------------------------------------------------

# Verificar a dimensionalidade dos constructos
library(psych)
fit = princomp(refri[ ,3:9], cor = TRUE)
plot(fit, type="lines")

# Cargas fatoriais
# Observe RC1(X1,X4,X6) = (0.887, 0.970, 0.944)
#         RC2(X2,X5)    = (0.960, 0.938)
#         RC3(X3,X7)    = (0.886, 0.929)
# As cargas fatoriais dos constructos e itens de interesse
#  (isto é suas correlações) são maiores que 0.40. Logo há
#  validade convergente
# A variância cumulativa (explicação total) dos 
#  três é de 94,9% 
cargas = principal(refri[ ,3:9], nfactors = 3, rotate = "varimax")
cargas$loadings

# Validade discriminante
# Observe nas cargas fatoriais que cada um dos itens 
#  tem carga maior que 0,4 apenas em relação ao constructo
#  fator que ele quer medir. Logo existe validade discriminante

# Em resumo:
#   Convergente: item x seu constructo > 0.4
#   Discriminante: item x outros constructos < 0.4

# Equações estruturais: entender a existência de possíveis
#  relacionamentos entre variáveis observáveis (itens) e
#  constructos latentes (fatores ou componentes principais)

# Notação
# variável latente =~ item1 + item2 + item3
# =~ "é mensurado por"          #variável latente
# ~  "está relacionado com"     #regressão
# ~~ "está correlacionado com"  #covariância
# ~1 "intercepto"               #intercepto

# Sabor =~ X1 + X4 + X6
# Saude =~ X2 + X5
# Sede  =~ X3 + X7

# Carregamento dos dados
library(dplyr)
dados <- as_tibble(read.csv2("https://raw.githubusercontent.com/gustavomirapalheta/classes_datasets/master/refri.csv"))

# Modelo
modelo ='
 sabor =~ X4 + X1 + X6
 saude =~ X5 + X2 
 sede =~ X3 + X7
'

# Modelagem e resultados
library(lavaan)
resultados = sem(model=modelo, data=dados)
summary(resultados, standardized=TRUE)

# O software sempre fixa uma relação de 1 para 1 
#  com alguma variável. Exemplos: 
#   Em sabor: X4
#   Em saúde: X5
#   Em sede: X3
# Os outros valores são analisados como os 
#  impactos de cada variável sobre os constructos.

# Além disso, estima as covariâncias entre os constructos. 
#  Exemplos: 
#  Entre sabor e saúde: valor-p = 0,507 (irrelevante)
#  Entre sabor e sede: valor-p = 0,021 (relevante)
#  Entre saúde e sede: valor-p = 0,001 (relevante)

# Alpha de Cronbach
#  medida de confiabilidade dos itens de um fator 
#  Aplicado às escalas refletivas de múltiplos itens.
#  Todos os itens precisam estar em ordem direta.
#  Alpha = k/(k-1)*(1 - soma da variância dos itens / 
#                       variância da soma dos itens)
#          k é o número de itens que forma um fator.

# α ≥ 0,9  : Excelente
# 0,9 > α ≥ 0,8 : Bom
# 0,8 > α ≥ 0,7 : Aceitável
# 0,7 > α ≥ 0,6 : Questionável
# 0,6 > α ≥ 0,5 : Fraco
# 0,5 > α : Não aceitável

