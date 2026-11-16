# =============================================================================
# 02_tabla_h1_h2.R  ·  Grupo 2 (Sofia Cambas, Marien Lozano, Samuel Rodríguez)
#
# Lee la base que deja 01_filtro_ecv.R y calcula, por grupo, los indicadores
# de la sección 4: H1 (hogares con algún miembro desplazado), H2 (jefes
# desempleados o informales) y el gasto mensual del hogar como aproximación
# al ingreso. Cada porcentaje va ponderado con el factor de expansión (FEH) y
# acompañado del conteo de hogares de la muestra.
#
# Entrada: datos/ecv_filtrada.csv   ·   Salida: datos/tabla_h1_h2.csv
# Para cambiar el filtro de estrato, modifique ESTRATOS (por ejemplo, 1:2).
# =============================================================================

library(dplyr)
library(readr)

ESTRATOS <- 1:3

base <- read_csv("datos/ecv_filtrada.csv", show_col_types = FALSE) |>
  filter(estrato %in% ESTRATOS) |>
  mutate(
    ocupado     = H.31 %in% 1:4,                 # trabaja
    desempleado = H.31 %in% 5 & H.43 %in% 1,     # no trabaja y busca empleo
    activo      = ocupado | desempleado,         # jefes en la fuerza laboral
    informal    = ocupado & F.2 %in% 2,          # trabaja y no cotiza a pensión
    desemp_o_inf = desempleado | informal,
    gasto_pc    = K.11 / personas
  )

# Porcentaje ponderado con el conteo de la muestra al lado: "72,8 % (19 de 26)"
miles <- function(n) formatC(n, format = "d", big.mark = ".", decimal.mark = ",")
celda <- function(x, w) {
  p <- 100 * sum(w[x]) / sum(w)
  paste0(formatC(p, format = "f", digits = 1, decimal.mark = ","), " % (",
         miles(sum(x)), " de ", miles(length(x)), ")")
}

# Mediana ponderada
mediana_p <- function(x, w) {
  o <- order(x); x <- x[o]; w <- w[o]
  x[which(cumsum(w) >= sum(w) / 2)[1]]
}
pesos <- function(x) miles(round(x / 1000) * 1000)

tabla <- base |>
  group_by(grupo) |>
  summarise(
    `Hogares en la muestra` = miles(n()),
    `H1 · Hogares con algún miembro desplazado` = celda(desplazado, FEH),
    `H2 · Jefes desempleados o informales` =
      celda(desemp_o_inf[activo], FEH[activo]),
    `H2a · Jefes desempleados` =
      celda(desempleado[activo], FEH[activo]),
    `H2b · Jefes ocupados informales` = celda(informal[ocupado], FEH[ocupado]),
    `Gasto mensual mediano del hogar` = pesos(mediana_p(K.11, FEH)),
    `Gasto mensual mediano por persona` = pesos(mediana_p(gasto_pc, FEH)),
    .groups = "drop")

# Una fila por indicador y una columna por grupo
tabla_larga <- tabla |>
  tidyr::pivot_longer(-grupo, names_to = "Indicador") |>
  tidyr::pivot_wider(names_from = grupo, values_from = value) |>
  select(Indicador, `Ocupantes sin título`, Arrendatarios)

write_csv(tabla_larga, "datos/tabla_h1_h2.csv")
cat("Estratos:", paste(ESTRATOS, collapse = ", "), "\n")
print(as.data.frame(tabla_larga), right = FALSE, row.names = FALSE)

# Dato complementario para la interpretación de H1 (conteo de la muestra)
nacidos_fuera <- base |> group_by(grupo) |>
  summarise(jefes_nacidos_fuera = sum(C.1 %in% 2), hogares = n(), .groups = "drop")
write_csv(nacidos_fuera, "datos/jefes_nacidos_fuera.csv")
cat("\nJefes de hogar que no han vivido siempre en Medellín (C.1 = 2):\n")
print(as.data.frame(nacidos_fuera), row.names = FALSE)
