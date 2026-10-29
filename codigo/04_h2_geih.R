# =============================================================================
# 04_h2_geih.R  ·  Grupo 2 (Sofia Cambas, Marien Lozano, Samuel Rodríguez)
#
# Comprobación de H2 con la GEIH 2025 (total anual). Lee la base que deja
# 03_base_geih.R y calcula, para ocupantes sin título (P5090 = 5) y
# arrendatarios (P5090 = 3) de estratos 1 a 3, el porcentaje de jefes
# desempleados o informales, con el conteo de la muestra al lado, y el
# ingreso laboral mensual mediano de los jefes ocupados.
#
# Entrada: datos/geih_medellin_2025.csv   ·   Salida: datos/tabla_h2_geih.csv
# =============================================================================

library(dplyr)
library(readr)

ESTRATOS <- 1:3

miles <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")
celda <- function(x, w) {
  p <- 100 * sum(w[x]) / sum(w)
  paste0(formatC(p, format = "f", digits = 1, decimal.mark = ","), " % (",
         miles(sum(x)), " de ", miles(length(x)), ")")
}
mediana_p <- function(x, w) {
  ok <- !is.na(x); x <- x[ok]; w <- w[ok]
  o <- order(x); x <- x[o]; w <- w[o]
  x[which(cumsum(w) >= sum(w) / 2)[1]]
}

jefes <- read_csv("datos/geih_medellin_2025.csv", show_col_types = FALSE) |>
  filter(jefe, P5090 %in% c(3, 5), P4030S1A1 %in% ESTRATOS) |>
  mutate(grupo  = if_else(P5090 == 5, "Ocupantes sin título", "Arrendatarios"),
         activo = ocupado | desocupado,
         desemp_o_inf = desocupado | informal)

tabla <- jefes |>
  group_by(grupo) |>
  summarise(
    `Hogares en la muestra (12 meses)` = miles(n()),
    `H2 · Jefes desempleados o informales` =
      celda(desemp_o_inf[activo], FEX_anual[activo]),
    `H2a · Jefes desempleados` =
      celda(desocupado[activo], FEX_anual[activo]),
    `H2b · Jefes ocupados informales` = celda(informal[ocupado], FEX_anual[ocupado]),
    `Ingreso laboral mediano del jefe ocupado` =
      miles(round(mediana_p(INGLABO[ocupado], FEX_anual[ocupado]) / 1000) * 1000),
    .groups = "drop") |>
  tidyr::pivot_longer(-grupo, names_to = "Indicador") |>
  tidyr::pivot_wider(names_from = grupo, values_from = value) |>
  select(Indicador, `Ocupantes sin título`, Arrendatarios)

write_csv(tabla, "datos/tabla_h2_geih.csv")
print(as.data.frame(tabla), right = FALSE, row.names = FALSE)
# Resultado esperado: 64 ocupantes y 5.186 arrendatarios en la muestra
