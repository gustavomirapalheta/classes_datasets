# ==============================================================================
# IA APLICADA À GESTÃO DE INVESTIMENTOS
# EXERCÍCIO — AVALIAÇÃO DE UMA ESTRATÉGIA PROPOSTA POR UMA CONSULTORIA
# Versão para os alunos
# ==============================================================================
#
# CONTEXTO
# Uma consultoria propôs um modelo que, a cada pregão, escolhe entre investir
# em BOVA11 ou permanecer aplicado à taxa Selic. A consultoria forneceu a base,
# os indicadores, o modelo e o backtest reproduzidos abaixo.
#
# OBJETIVO
# Reproduzir os resultados apresentados e emitir uma recomendação ao comitê de
# investimentos. O grupo não precisa desenvolver outro modelo nesta etapa.
# ==============================================================================


# ==============================================================================
# 0. CONFIGURAÇÃO
# ==============================================================================

PACOTES <- c("tidyverse", "readxl", "tidymodels")

pacotes_ausentes <- PACOTES[
  !vapply(PACOTES, requireNamespace, logical(1), quietly = TRUE)
]

if (length(pacotes_ausentes) > 0) {
  stop(
    "Instale antes de executar: ",
    paste(pacotes_ausentes, collapse = ", "),
    call. = FALSE
  )
}

library(tidyverse)
library(readxl)
library(tidymodels)

tidymodels_prefer()
set.seed(123)

ARQUIVO_XLSX <- "base_estrategia_consultoria_alunos.xlsx"
LIMIAR <- 0.50
DIAS_ANO <- 252

if (!file.exists(ARQUIVO_XLSX)) {
  stop(
    "A planilha não foi encontrada. Coloque o arquivo na pasta do projeto ",
    "RStudio ou ajuste ARQUIVO_XLSX.",
    call. = FALSE
  )
}


# ==============================================================================
# 1. LEITURA DA PLANILHA
# ==============================================================================

excel_sheets(ARQUIVO_XLSX)

base <- read_excel(
  path = ARQUIVO_XLSX,
  sheet = "Base_exercicio"
) |>
  arrange(data) |>
  mutate(
    data = as.Date(data),
    supera_selic_d1 = factor(
      if_else(supera_selic_d1, "supera", "nao_supera", missing = NA_character_),
      levels = c("supera", "nao_supera")
    )
  )

dicionario <- read_excel(
  path = ARQUIVO_XLSX,
  sheet = "Dicionario"
)

glimpse(base)
count(base, amostra)
summary(select(base, fechamento_bova, ptax_venda, selic_dia))


# ==============================================================================
# 2. VARIÁVEIS INFORMADAS PELA CONSULTORIA
# ==============================================================================

variaveis_consultoria <- c(
  "ret_bova_1d",
  "ret_bova_5d",
  "ret_bova_20d",
  "ret_ivvb_1d",
  "ret_smal_1d",
  "ret_dolar_1d",
  "razao_medias",
  "volatilidade_20d",
  "volume_relativo_20d",
  "amplitude_intradiaria",
  "momentum_curto",
  "volatilidade_centrada_20d",
  "pressao_compradora",
  "zscore_fechamento_global",
  "sinal_externo"
)

dicionario |>
  filter(variavel %in% variaveis_consultoria) |>
  select(variavel, descricao, unidade, disponibilidade, fonte)

dados_modelo <- base |>
  select(
    data,
    supera_selic_d1,
    retorno_bova_futuro,
    selic_futura,
    all_of(variaveis_consultoria)
  ) |>
  drop_na(supera_selic_d1)


# ==============================================================================
# 3. PROCEDIMENTO DE ESTIMAÇÃO INFORMADO PELA CONSULTORIA
# ==============================================================================

particao <- initial_split(
  dados_modelo,
  prop = 0.80,
  strata = supera_selic_d1
)

treino <- training(particao)
teste <- testing(particao)

tibble(
  conjunto = c("Treino", "Teste"),
  observacoes = c(nrow(treino), nrow(teste)),
  inicio = c(min(treino$data), min(teste$data)),
  fim = c(max(treino$data), max(teste$data))
)


# ==============================================================================
# 4. MODELO PREDITIVO
# ==============================================================================

receita <- recipe(
  supera_selic_d1 ~ .,
  data = treino
) |>
  update_role(data, retorno_bova_futuro, selic_futura, new_role = "id") |>
  step_impute_median(all_numeric_predictors()) |>
  step_normalize(all_numeric_predictors())

modelo <- logistic_reg() |>
  set_engine("glm") |>
  set_mode("classification")

fluxo <- workflow() |>
  add_recipe(receita) |>
  add_model(modelo)

ajuste <- fit(
  fluxo,
  data = treino
)

previsoes <- teste |>
  select(data, supera_selic_d1, retorno_bova_futuro, selic_futura) |>
  bind_cols(
    predict(ajuste, teste, type = "class"),
    predict(ajuste, teste, type = "prob")
  ) |>
  arrange(data)

metricas_preditivas <- bind_rows(
  accuracy(previsoes, supera_selic_d1, .pred_class),
  sens(previsoes, supera_selic_d1, .pred_class),
  spec(previsoes, supera_selic_d1, .pred_class),
  roc_auc(previsoes, supera_selic_d1, .pred_supera)
)

print(metricas_preditivas)
conf_mat(previsoes, supera_selic_d1, .pred_class)

roc_curve(previsoes, supera_selic_d1, .pred_supera) |>
  autoplot() +
  labs(title = "Curva ROC do modelo apresentado") +
  theme_minimal(base_size = 12)


# ==============================================================================
# 5. TRANSFORMAÇÃO DAS PREVISÕES EM DECISÕES DE INVESTIMENTO
# ==============================================================================

metricas_financeiras <- function(retornos, estrategia, dias_ano = DIAS_ANO) {
  retornos <- retornos[is.finite(retornos)]

  if (length(retornos) < 2 || sd(retornos) == 0) {
    return(tibble(
      estrategia = estrategia,
      observacoes = length(retornos),
      retorno_anualizado = NA_real_,
      volatilidade_anualizada = NA_real_,
      sharpe = NA_real_,
      max_drawdown = NA_real_
    ))
  }

  patrimonio <- cumprod(1 + retornos)
  drawdown <- patrimonio / cummax(patrimonio) - 1

  tibble(
    estrategia = estrategia,
    observacoes = length(retornos),
    retorno_anualizado = prod(1 + retornos)^(dias_ano / length(retornos)) - 1,
    volatilidade_anualizada = sd(retornos) * sqrt(dias_ano),
    sharpe = mean(retornos) / sd(retornos) * sqrt(dias_ano),
    max_drawdown = min(drawdown)
  )
}

resultados_diarios <- previsoes |>
  mutate(
    sinal = as.integer(.pred_supera >= LIMIAR),
    retorno_modelo =
      sinal * retorno_bova_futuro +
      (1 - sinal) * selic_futura,
    retorno_bova = retorno_bova_futuro,
    retorno_selic = selic_futura
  )

resultados_financeiros <- bind_rows(
  metricas_financeiras(resultados_diarios$retorno_modelo, "Modelo da consultoria"),
  metricas_financeiras(resultados_diarios$retorno_bova, "Sempre BOVA11"),
  metricas_financeiras(resultados_diarios$retorno_selic, "Sempre Selic")
)

print(resultados_financeiros)

patrimonios <- resultados_diarios |>
  select(data, retorno_modelo, retorno_bova, retorno_selic) |>
  pivot_longer(
    cols = starts_with("retorno_"),
    names_to = "estrategia",
    values_to = "retorno"
  ) |>
  group_by(estrategia) |>
  arrange(data, .by_group = TRUE) |>
  mutate(patrimonio = cumprod(1 + retorno)) |>
  ungroup()

ggplot(patrimonios, aes(data, patrimonio, color = estrategia)) +
  geom_line(linewidth = 0.9) +
  labs(
    title = "Desempenho acumulado apresentado pela consultoria",
    subtitle = "Limiar de decisão igual a 0,50",
    x = NULL,
    y = "Patrimônio acumulado",
    color = "Estratégia"
  ) +
  theme_minimal(base_size = 12)


# ==============================================================================
# 6. MEMORANDO AO COMITÊ DE INVESTIMENTOS
# ==============================================================================
#
# Preparem um memorando de até uma página respondendo:
#
# 1. Qual é a recomendação do grupo?
#    - aprovar a estratégia;
#    - realizar um piloto controlado;
#    - solicitar esclarecimentos adicionais;
#    - rejeitar a proposta.
#
# 2. Quais resultados sustentam a recomendação?
# 3. Quais são os três principais riscos ou pontos ainda não verificados?
# 4. Que informações adicionais a consultoria deveria fornecer?
# 5. O grupo autorizaria a utilização de recursos reais? Por quê?
#
# Registrem a decisão antes da discussão coletiva.

