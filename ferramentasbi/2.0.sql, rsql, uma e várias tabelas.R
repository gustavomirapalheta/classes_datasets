##################################################################################
# Introdução                                                                     #
##################################################################################
# O objetivo deste script (aula) é demonstrar o uso de SQL na obtenção de        #
#  informações a partir de bancos de dados. No caso utilizaremos o formato       #
#  SQLite. O SQLite é um formato de banco de dados orientado a arquivo,          #
#  tal como o Microsoft Access.                                                  #
#                                                                                #
# O R torna-se capaz de criar bancos de dados, inserir tabelas e realizar        #
#  consultas em arquivos no formato SQLite através do pacote RSQLite. A          #
#  criação dos arquivos SQLite, a inserção das tabelas e a realização das        #
#  consultas é feita através das funções dbConnect, dbWriteTable, dbListTables   #
#  e dbGetQuery do pacote DBI. O pacote DBI é um pacote genérico de conexão      #
#  a banco de dados.                                                             #
#                                                                                #
# O procedimento envolve abrir uma conexão a um arquivo SQLite através de        #
#  dbConnect, utilizando o "perfil" de conexão dado por RSQLite::SQLite() e      #
#  em seguida usar as demais funções do DBI (dbWriteTable, dbListTables,         #
#  dbGetQuery, entre outras) para executar as operações de banco de dados.       #
#                                                                                #
# Veja que desta forma, caso tenhamos o perfil (drive) de conexão adequado, as   #
#  funções do DBI permitem a conexão a qualquer banco de dados, seja ele         #
#  orientado a arquivo (como o SQLite e o Access) seja ele orientado a serviço   #
#  (como o SQL Server e o PostgreSQL)                                            #
#                                                                                #
# Também serão feitas comparações entre a linguagem SQL e a forma de gerar       #
#  relatórios a partir da dplyr (neste arquivo) e da pandas (no arquivo          #
#  rsql.py, em anexo)                                                            #
##################################################################################

##################################################################################
# 1o Exercício                                                                   #
# Acesso inicial a um banco de dados SQLite. Criação e inserção de dados em      #
#  tabelas. Consultas em tabela única. Dataset: mpg                              #
##################################################################################

# O pacote DBI contém um conjunto de funções genéricas para conexão e trabalho
#  com bancos de dados, sejam eles baseados em serviço (SQL Server, PostgreSQL),
#  ou baseados em arquivo (Access, SQLite). Utilizaremos deste pacote as funções
#  dbConnect, dbWriteTable, dbListTables e dbGetQuery para o acesso e utilização
#  dos arquivos do SQLite. Os arquivos serã criados com o tipo ".sqlite". 
library(DBI)

# O pacote RSQLite contém o perfil de conexão do SQLite. Este perfil será 
#  utilizado como parâmetro para a função dbConnect do DBI.
library(RSQLite)

# O primeiro data frame a ser utilizado será o "mpg", do pacote "ggplot2". 
#  Salvaremos este data frame em um arquivo SQLite.
library(ggplot2)

# Utiliza a função dbConnect com a opção SQLite. Iremos conectar em um banco
#  de dados de nome "mpg.sqlite", o qual será um arquivo sqlite. Caso o arquivo
#  não exista no diretório o mesmo será criado em vazio. Observe que a partir
#  de agora utilizaremos o objeto conexão (de nome conn) aqui criado para 
#  realizar operações com o arquivo de banco de dados "mpg.sqlite". Isto é 
#  necessário pois os dados poderiam estar presentes em um banco de dados 
#  orientado a serviço, como por exemplo o SQL Server ou PostgreSQL.
#  Para evitar a criação de arquivos no nosso diretório de trabalho, o arquivo
#  mpg.sqlite será criado como um arquivo temporário
temp <- tempfile(pattern='mpg', fileext='.sqlite')
conn <- dbConnect(RSQLite::SQLite(), temp)

# Usar a função dbWriteTable para escrever na conexão "conn", uma tabela de 
#  de banco de dados de nome "mpgTable", a qual receberá os valores presentes
#  no data frame "mpg"
dbWriteTable(conn, "mpgTable", mpg)

# Agora podemos listar as tabelas que compõe o banco de dados "mpg.sqlite"
dbListTables(conn)

# Vamos criar dois data frames similares (com os mesmos nomes de colunas)
#  e iremos incluir (append) os valores dos mesmos na tabela "models".
#  Utilizaremos neste momento a função data.frame do R básico, pois ainda 
#  não carregamos a biblioteca dplyr
model <- c("camaro","california","mustang","explorer")
manufacturer <- c("chevrolet","ferrari","ford","ford")
df1 <- data.frame(model, manufacturer)
df1

model <- c('corolla', 'lancer', 'sportage', 'xe')
manufacturer <- c('toyota', 'mitsubishi', 'kia', 'jaguar')
df2 <- data.frame(model, manufacturer)
df2

#  Observe que na primeira inclusão, como a tabela ainda não existe, a mesma
#  será criada. Na segunda inclusão, os valores serão colocados no final da
#  tabela. Este método de atualização de dados é obtido com a opção 
#  append = TRUE
dbWriteTable(conn, 'models', df1, append=TRUE)
dbWriteTable(conn, 'models', df2, append=TRUE)

# Confirmamos a inclusão da nova tabela no banco de dados executando mais
#  uma vez, o comando dbListTables(conexão)
dbListTables(conn)

# Caso já exista uma tabela de nome mpgTable no banco de dados, 
#  e desejamos reescrever a mesma (com os valores de mpg por exemplo)
#  utilizamos dbWriteTable com a opção overwrite=TRUE.
dbWriteTable(conn, "mpgTable", mpg, overwrite=TRUE)

# Agora começaremos a executar consultas (queries) SQL no nosso banco de
#  dados. Execução de queries: dbGetQuery(conexão, query)
#  Para obter todos os campos da tabela mpgTable
dbGetQuery(conn, "SELECT * FROM mpgTable")

# A query abaixo retorna as 10 primeiras linhas da tabela mpgTable
# Observe que existem linhas nas quais model = "a4"
dbGetQuery(conn, "SELECT * FROM mpgTable LIMIT 10")

# A query abaixo retorna os dados da tabela mpgTable nos quais
# model = "a4". Observe que existem sete linhas com model = 'a4'
dbGetQuery(conn, "SELECT * FROM mpgTable WHERE model = 'a4'")

# Para o conjunto de filtros a seguir, existe apenas um único 
#  registro no banco de dados
dbGetQuery(conn, "SELECT * FROM mpgTable WHERE manufacturer = 'audi' 
                  AND model = 'a4' AND displ = 1.8 AND year = 1999 
                  AND cyl = 4 AND trans = 'auto(l5)' AND drv = 'f'
                  AND cty = 18 AND hwy = 29 AND fl = 'p' 
                  AND class = 'compact'")

# Vamos deletar a linha na qual manufacturer = "audi", model = "a4", 
# displ = 1.8, year = 1999, cyl = 4, trans = "auto(l5)", drv = "f", 
# cty = 18, hwy = 29, fl = "p" e class = "compact" do db
dbExecute(conn, "DELETE FROM mpgTable WHERE manufacturer = 'audi' 
                  AND model = 'a4' AND displ = 1.8 AND year = 1999 
                  AND cyl = 4 AND trans = 'auto(l5)' AND drv = 'f'
                  AND cty = 18 AND hwy = 29 AND fl = 'p' 
                  AND class = 'compact'")

# Para comprovar a alteração no banco de dados vamos observar agora
#  o resultado de uma das queries anteriores. Por ela vemos que o 
#  número de linhas com model = 'a4' agora é de seis linhas.
dbGetQuery(conn, "SELECT * FROM mpgTable WHERE model = 'a4'")

# Reinserção dos valors no banco de dados
dbExecute(conn, 'INSERT INTO mpgTable VALUES 
                 ("audi", "a4", 1.8, 1999, 4, "auto(l5)", "f", 18,
                  29, "p", "compact")')

# Agora se pedirmos a listagem das linhas com model = 'a4' teremos
#  novamente um total de sete linhas
dbGetQuery(conn, "SELECT * FROM mpgTable where model ='a4'")

# Um parenteses importante sobre o desempenho no R
# A regra prática é a seguinte: o maior objeto que pode ser carrregado na 
#  memória do R, deve ter no máximo 1/4 da memória RAM da máquina.

# Retornando ao estudo de queries SQL em sqlite
# Carregamos a biblioteca dplyr para utilizar o recurso de pipe (%>%) e
#  a função as_tibble()
library(dplyr)
dbGetQuery(conn, "SELECT * FROM mpgTable LIMIT 10") %>% 
  as_tibble()

# Executamos em SQL uma seleção de campo (SELECT) seguida de um filtro (WHERE)
dbGetQuery(conn, "SELECT displ, cyl FROM mpgTable WHERE cyl = 8")

# Podemos também carregar a tabela toda do banco de dados e executar as 
#  seleções e filtragens no R através dos comandos da dplyr.
dbGetQuery(conn, "SELECT * FROM mpgTable") %>% 
  select(displ, cyl) %>% filter(cyl==8)

# Realizamos uma query com filtro mais sofisticado (IN)
dbGetQuery(conn, "SELECT displ, cyl FROM mpgTable
                  WHERE model LIKE 'M%' AND cyl IN (6,8)")

# Para executar a mesma query a partir da dplyr, carregamos também o 
#  pacote stringr, o qual permitirá o uso de regex. Seguimos neste caso 
#  a estratégia genérica de carregar a tabela toda do banco de dados e 
#  em seguida as filtragens e modificações dos dados no R via dplyr
library(stringr)
dbGetQuery(conn, "SELECT * from mpgTable") %>%
  filter(str_detect(model, regex("^[Mm]")), cyl %in% c(6,8)) %>%
  select(displ, cyl)

# Executamos agora uma query com filtros (WHERE) e classificação (ORDER BY)
dbGetQuery(conn, "SELECT model, displ, cyl FROM mpgTable
                  WHERE model LIKE 'M%' AND cyl IN (6,8)
                  ORDER BY model")

# A mesma query pode ser executada na dplyr com select, filter e arrange.
dbGetQuery(conn, "SELECT * from mpgTable") %>%
  select(model, displ, cyl) %>%
  filter(str_detect(model, regex("^[Mm]")), cyl %in% c(6,8)) %>%
  arrange(model)

# O exemplo abaixo é de uma query com agrupamento (GROUP BY) e resumo
#  dos dados (SUM(displ))
dbGetQuery(conn, "SELECT model, SUM(displ), cyl FROM mpgTable
                  WHERE model LIKE 'M%' AND cyl IN (6,8)
                  GROUP BY model, cyl
                  ORDER BY model")

# Este processo é executado na dplyr com dois comandos em separado
#  a saber: group_by e summarise.
dbGetQuery(conn, "SELECT * from mpgTable") %>%
  select(model, displ, cyl) %>% 
  filter(str_detect(model, regex("^[Mm]")), cyl %in% c(6,8)) %>%
  group_by(model, cyl) %>%
  summarise(SUM_displ = sum(displ))

# Observe o resultado que a query SQL trás do banco de dados. 
# Quando ocorre o resumo dos dados apenas por cyl, a coluna model deveria
#  ser descartada por não fazer sentido um resumo de uma coluna com dados
#  no formato de texto (strings). No entanto o SQLite devolve a mesma, porém
#  com um valor qualquer, sem sentido. Esta coluna deve portanto ser 
#  desprezada pelo analista.
dbGetQuery(conn, "SELECT model, SUM(displ), cyl FROM mpgTable
                  WHERE model LIKE 'M%' AND cyl IN (6,8)
                  GROUP BY cyl
                  ORDER BY model")

# Veja que quando executamos o group_by e summarise na dplyr, a coluna 
#  model é descartada automaticamente do resultado.
dbGetQuery(conn, "SELECT * from mpgTable") %>%
  select(model, displ, cyl) %>% 
  filter(str_detect(model, regex("^[Mm]")), cyl %in% c(6,8)) %>%
  group_by(cyl) %>%
  summarise(SUM_displ = sum(displ))

# Por último, devemos sempre encerrar a conexão com o arquivo SQLite. Caso 
#  contrário o mesmo permanecerá travado para uma série de operações por 
#  outros usuários e aplicativos.
dbDisconnect(conn)
unlink(temp)

###############################################################################
# 2o Exercício                                                                #
# Queries em uma tabela no banco de dados salesorders.sqlite (formato RSQLite)#
#  Resultados serão obtidos diretamente com com SQL (via dbGetQuery)          #
#  Dataset: salesorders.sqlite                                                    #
###############################################################################
library(DBI)
library(RSQLite)
library(dplyr)
library(tidyr)
library(ggplot2)

site <- "https://github.com/"
diretorio <- "gustavomirapalheta/classes_datasets/raw/master/ferramentasbi/"
arquivo_salesorders <- "salesorders.sqlite"
link_salesorders <- paste0(site, diretorio, arquivo_salesorders); link_salesorders
temp_salesorders <- tempfile()
download.file(link_salesorders, temp_salesorders)
conn_salesorders <- dbConnect(RSQLite::SQLite(), temp_salesorders)
dbListTables(conn_salesorders)
#dbDisconnect(conn_salesorders)
#unlink(temp_salesorders)

dbGetQuery(conn_salesorders, " SELECT EmpFirstName, EmpLastName, EmpStreetAddress, 
                                      EmpCity, EmpState, EmpZipCode FROM Employees")

dbGetQuery(conn_salesorders, " SELECT DISTINCT EmpState FROM Employees")

#/* Classificar todos os campos da tabela EMPLOYEES pelo sobrenome do funcionário */
dbGetQuery(conn_salesorders, " SELECT * FROM Employees ORDER BY EmpLastName")

#/* Classificar todos os campos da tabela Employees pela Cidade */
dbGetQuery(conn_salesorders, " SELECT * FROM Employees ORDER BY EmpCity")

#/* Sabendo que EmpState ASC classificará o campo em ordem Ascendente e
#    EmpCity DESC classificará o campo em ordem descendente, pede-se criar
#    uma consulta, a qual irá classificar todos os campos da tabela Employees
#    por ordem Ascendente de Estado e Descendente de Cidade */
dbGetQuery(conn_salesorders, " SELECT * FROM Employees ORDER BY EmpState ASC, EmpCity DESC")

#/* Mostre os nomes de todos os fornecedores */
dbGetQuery(conn_salesorders, " SELECT VendName from Vendors")

#/* Quais são os nomes e os preços de todos os produtos da empresa? */
dbGetQuery(conn_salesorders, " SELECT ProductName, RetailPrice FROM Products")

#/* Formatando o resultado proveniente da query */
dbGetQuery(conn_salesorders, " SELECT CAST(EmployeeID as INT) AS EmployeeNum, 
                               (EmpFirstName || ' ' || EmpLastName) AS Nome FROM Employees")

# /* A  AND B 
#    0      0   =   0
#    0      1   =   0
#    1      0   =   0
#    1      1   =   1
#    0   NULL   =   0
#    1   NULL   =   NULL
#    
#    A  OR  B
#    0      0   =   0
#    0      1   =   1
#    1      0   =   1
#    1      1   =   1
#    0   NULL   =   NULL
#    1   NULL   =   1
#    
#    NOT(A)
#        0      =   1
# 	   1      =   0
#    NOT(NULL)  =   NULL	*/
  
#/* Quantos dias levou para atender cada pedido? */
#/* (CAST(ShipDate AS INT) - CAST(OrderDate AS INT)) AS DiasParaEnvio FROM ORDERS */
dbGetQuery(conn_salesorders, " SELECT OrderNumber, ShipDate, OrderDate, 
                               CAST(julianday(ShipDate) - julianday(OrderDate) AS INT) AS DiasParaEnviar 
                               FROM Orders")

#-- Quais os clientes que são do estado "WA"
dbGetQuery(conn_salesorders, " SELECT CustFirstName, CustLastName, CustState 
                               FROM Customers WHERE CustState = 'WA'")

#-- Apresente uma lista dos nomes e telefones dos fornecedores, à exceção daqueles que são
#--  da cidade de nome "Bellevue"
dbGetQuery(conn_salesorders, ' SELECT VendName, VendPhoneNumber, VendCity 
                               FROM Vendors WHERE VendCity <> "Bellevue"')

dbDisconnect(conn_salesorders)
unlink(temp_salesorders)

#/* Resumo dos comandos SQL de uma única tabela vistos até o momento
# dbGetQuery(conn_salesorders, " SELECT Campo1, Campo2, ..., CampoN 
#                                FROM Tabela 
#                                ORDER BY Campo1 ASC, Campo2 DESC 
#                                WHERE Campo3 = 'Cidade1' AND Campo4 LIKE 'string'" */

#####################################################################################
# 3o Exercício                                                                      #
# Conexão a banco de dados, consulta SQL a duas tabelas (através de INNER JOIN)     #
#  e reformatação do resultado da query através de tidyr (no R)                     #
#  Dataset: adventureworksgcm.xlsx                                                  #
#####################################################################################

# Nosso objetivo: gerar um relatório similar ao produzido por uma tabela dinâmica
#  no qual iremos dividir as vendas por Categoria de Produto e Ocupação do Cliente
# Neste caso ao invés de criar um banco de dados novo, vamos importar os dados
#  de uma planilha Excel ("adventureworksgcm.xlsx") para vários data frames. 
#  Esta planilha contém apenas abas com dados dispostos em colunas tal como se 
#  fossem tabelas em um banco de dados "normal". Para acessar a planilha Excel 
#  utilizaremos o pacote "rio" (de R Input Output)
library(rio)

# Plano de Trabalho
# Conectar na planilha "adventureworksgcm.xlsx" e carregar as abas (isto é tabelas) 
# de nome sqlSales (sales), sqlCustomers (customers), sqlProducts (products)
site = "https://github.com/"
diretorio = "gustavomirapalheta/classes_datasets/raw/master/ferramentasbi/"
arquivo = "adventureworksgcm.xlsx"
link = paste0(site, diretorio, arquivo)

library(dplyr)
import(file = link, sheet="sqlSales") %>% as_tibble() -> sales; sales
names(sales) # ProductKey, CustomerKey, SalesAmount

import(file = link, sheet="sqlCustomers") %>% as_tibble() -> customers; customers 
names(customers) # CustomerKey, Occupation

import(file = link, sheet="sqlProducts") %>% as_tibble() -> products; products
names(products) # ProductKey, Category

# Os comandos a seguir mostram como criar um relatório similar a uma tabela
#  dinâmica no Excel. Neste caso vamos criar uma tabela com os totais de 
#  SalesAmount divididos em Categoria (de produto) e Ocupação (de cliente).
# O relatório será criado no R a partir dos data frames sales, products e 
#  customers com o uso das funções inner_join, group_by e summarise (do
#  pacote dplyr) e spread (do pacote tidyr)
library(tidyr)
select(sales, ProductKey, CustomerKey, SalesAmount) %>%
  inner_join(select(products, ProductKey, Category), 
             by=c("ProductKey"="ProductKey")) %>%
  inner_join(select(customers, CustomerKey, Occupation),
             by=c("CustomerKey"="CustomerKey")) %>%
  group_by(Category, Occupation) %>%
  summarise(Total = sum(SalesAmount)) %>%
  spread(key=Occupation, value=Total)

# Vamos agora salvar os data frames sales, products e customers (importados da
#  planilha Excel na etapa anterior) em tabelas de um novo banco de dados SQLite
#  o qual passará a se chamar "adventureworksgcm.sqlite". Utilizaremos um 
#  arquivo temporário para esta tarefa.
library(RSQLite)

temp <- tempfile(pattern = "adventureworksgcm", fileext = ".sqlite")
dbConnect(RSQLite::SQLite(), temp) -> conn

dbWriteTable(conn, "sales", sales)
dbWriteTable(conn, "customers", customers)
dbWriteTable(conn, "products", products)
dbListTables(conn)

# Executamos uma query SQL no banco de dados da conexão conn, a qual faz uma
#  mesclagem das tabelas sales, products e customers. O resultado é passado
#  para a função group_by (da dplyr) e spread (da tidyr) para gerar o 
#  relatório em formato de uma tabela pivô (Tabela Dinâmica do Excel).
consulta = "SELECT sales.ProductKey, sales.CustomerKey, sales.SalesAmount,
                   products.Category, customers.Occupation
            FROM sales
            JOIN products ON sales.ProductKey = products.ProductKey
            JOIN customers ON sales.CustomerKey = customers.CustomerKey"
dbGetQuery(conn, consulta) %>%
  group_by(Category, Occupation) %>%
  summarise(Total = sum(SalesAmount)) %>%
  spread(key = Occupation, value = Total)

# A mesma query pode ser vista abaixo, agora sem explicitamente indicar as
#  tabelas de origem dos campos. Isto é possível pois não existem campos de 
#  mesmo nome nas três tabelas que devam ser passados para o resultado final.
# Observe que os campos de junção das tabelas (primarykeys e foreignkeys) não
#  precisam aparecer no SELECT, mas precisam estar corretamente indicados na 
#  parte ON do JOIN
consulta = "SELECT Category, Occupation, sum(SalesAmount) AS Total
            FROM sales
            JOIN products ON sales.ProductKey = products.ProductKey
            JOIN customers ON sales.CustomerKey = customers.CustomerKey
            GROUP BY Category, Occupation"
dbGetQuery(conn, consulta) %>%
  select(Category, Occupation, Total) %>%
  spread(key=Occupation, value=Total)

dbDisconnect(conn)
unlink(temp)

###############################################################################
# 4o Exercício                                                                #
# Query em três tabelas. Resultado nesta etapa será obtido com dplyr.         #
# Determinar todos ingredientes das receitas que contém cenoura (Carrot)      #
# Datasets: Consulta_Ingredients.csv, Consulta_Recipe_Ingredients.csv         #
#           Consulta_Recipes.csv (tabelas da base recipes)                    #                                 
###############################################################################

library(dplyr)

# nome do site e do diretório onde estão os arquivos .csv com as tabelas
site <- "https://raw.githubusercontent.com/"
diretorio <- "gustavomirapalheta/classes_datasets/master/ferramentasbi/"

# carregamento da tabela ingredients a partir de um .csv no github
nome <- "Consulta_Ingredients.csv"
arquivo <- paste(site, diretorio, nome, sep="")
ingredients <- read.csv2(arquivo) %>% as_tibble()
ingredients

# carregamento da tabela recipe_ingredients a partir de um .csv no github
nome <- "Consulta_Recipe_Ingredients.csv"
arquivo <- paste(site, diretorio, nome, sep="")
recipe_ingredients <- read.csv2(arquivo) %>% as_tibble()
recipe_ingredients

# carregamento da tabela recipes a partir de um .csv no github
nome <- "Consulta_Recipes.csv"
arquivo <- paste(site, diretorio, nome, sep="")
recipes <- read.csv2(arquivo) %>% as_tibble()
recipes

# determinação em ingredients do IngredientID de "Carrot" 
ingredients
ingredients %>% filter(IngredientName == "Carrot") %>%
  select(IngredientID)

# determinação dos RecipeID com IngredientID de "Carrot"
recipe_ingredients
ingredients %>% filter(IngredientName == "Carrot") %>%
  select(IngredientID) %>% inner_join(recipe_ingredients, 
                                      by=c("IngredientID"="IngredientID")) %>%
  select(RecipeID)

# determinação dos RecipeID e RecipeTitle com IngredientID de "Carrot"  
recipes
ingredients %>% filter(IngredientName == "Carrot") %>%
  select(IngredientID) %>% inner_join(recipe_ingredients, 
                                      by=c("IngredientID"="IngredientID")) %>%
  select(RecipeID) %>% inner_join(recipes,
                                  by=c("RecipeID"="RecipeID")) %>%
  select(RecipeID, RecipeTitle)

# determinação dos RecipeID, RecipeTitle e IngredientID para os RecipeID 
# com IngredientID de "Carrot" 
ingredients %>% filter(IngredientName == "Carrot") %>%
  select(IngredientID) %>% inner_join(recipe_ingredients, 
                                      by=c("IngredientID"="IngredientID")) %>%
  select(RecipeID) %>% inner_join(recipes,
                                  by=c("RecipeID"="RecipeID")) %>%
  select(RecipeID, RecipeTitle) %>%
  inner_join(recipe_ingredients,
             by=c("RecipeID"="RecipeID")) %>%
  select(RecipeID, RecipeTitle, IngredientID) %>%
  inner_join(ingredients,
             by=c("IngredientID"="IngredientID"))

# determinação dos RecipeTile e IngredientName para os RecipeTile com o 
# IngredientID de "Carrot" 
ingredients %>% filter(IngredientName == "Carrot") %>%
  select(IngredientID) %>% inner_join(recipe_ingredients, 
                                      by=c("IngredientID"="IngredientID")) %>%
  select(RecipeID) %>% inner_join(recipes,
                                  by=c("RecipeID"="RecipeID")) %>%
  select(RecipeID, RecipeTitle) %>%
  inner_join(recipe_ingredients,
             by=c("RecipeID"="RecipeID")) %>%
  select(RecipeID, RecipeTitle, IngredientID) %>%
  inner_join(ingredients,
             by=c("IngredientID"="IngredientID")) %>%
  select(RecipeTitle, IngredientName)

dbDisconnect(conn)

###############################################################################
# 5o Exercício                                                                #
# Queries em três tabelas no banco de dados recipes.sqlite em formato RSQLite #
#  Resultados serão obtidos diretamente com SQL (via dbGetQuery)              #
#  Dataset: recipes.sqlite                                                    #
###############################################################################
site <- "https://github.com/"
diretorio <- "gustavomirapalheta/classes_datasets/raw/master/ferramentasbi/"
arquivo_recipes <- "recipes.sqlite"
link_recipes <- paste0(site, diretorio, arquivo_recipes); link_recipes
temp_recipes <- tempfile()
download.file(link_recipes, temp_recipes)
conn_recipes <- dbConnect(RSQLite::SQLite(), temp_recipes)
dbListTables(conn_recipes)
#dbDisconnect(conn_recipes)
#unlink(temp_recipes)

#-- Comandos para MESCLAR tabelas

# /* Apresentar uma listagem com todos os valores presentes nos campos 
#    RecipeTitle e Preparation (tabela Recipes) e RecipeClassDescription 
#    (tabela Recipe_Classes). As tabelas estão ligadas pelo campo RecipeClassID,
#    o qual é PrimaryKey de Recipe_Classes e ForeignKey de Recipes */
   
#/* Por comparação, um INNER_JOIN no R (através da biblioteca dplyr) teria a 
#   seguinte estrutura:
#    inner_join(Recipes, Recipe_Classes, by=c("RecipeClassID"="RecipeClassID")) %>%
# 		select(RecipeTitle, Preparation, RecipeClassDescription) -> nova_tabela; 
#     nova_tabela
# */
dbGetQuery(conn_recipes, " SELECT Recipes.RecipeTitle, Recipes.Preparation, 
                                  Recipe_Classes.RecipeClassDescription  
                           FROM Recipes INNER JOIN Recipe_Classes
                           ON Recipes.RecipeClassID = Recipe_Classes.RecipeClassID")

# /* Apresente as receitas que contenham como ingredientes os valores "Beef" ou 
#    "Garlic"; tabelas de interesse: Recipes e Recipes_Ingredients
#     caso você saiba o código do "beef" e do "garlic" */
#-- SELECT * FROM Ingredients e descubro que Beef é 1 e Garlic é 9
#-- SELECT Recipes.RecipeTitle,  Recipe_Ingredients.IngredientID 
dbGetQuery(conn_recipes, ' SELECT DISTINCT Recipes.RecipeTitle
                           FROM Recipes INNER JOIN Recipe_Ingredients
                           ON Recipes.RecipeID = Recipe_Ingredients.RecipeID
                           WHERE Recipe_Ingredients.IngredientID IN ("1","9")')

dbGetQuery(conn_recipes, ' SELECT DISTINCT Recipes.RecipeTitle
                           FROM Recipes INNER JOIN Recipe_Ingredients
                           ON Recipes.RecipeID = Recipe_Ingredients.RecipeID
                           WHERE Recipe_Ingredients.IngredientID = "1" OR 
                                 Recipe_Ingredients.IngredientID = "9"')

dbDisconnect(conn_recipes)
unlink(temp_recipes)

###############################################################################
# 6o Exercício                                                                #
# O objetivo deste exercício é realizar uma classificação de produtos pelo    #
#  método ABC. Este método classifica os produtos a partir do seu total de    #
#  vendas. Na categoria A estão os produtos que geram até 70% do total de     #
#  vendas da empresa, na categoria B os que geram até 20% e na categoria C    #
#  um total de até 10%. Realizar o exercício com dplyr e sql                  #
#  Dataset: adventureworksgcm.xlsx                                            #
###############################################################################

###############################################################################
# 7o Exercício                                                                #
# Basket Analysis: Neste exercício vamos contar quantas vezes os produtos com #
#  ProdKey 222 e 237 foram vendidos em conjunto. Realizar o exercício com     #
#  dplyr e sql                                                                #
#  Dataset: adventureworksgcm.xlsx                                            #
###############################################################################
