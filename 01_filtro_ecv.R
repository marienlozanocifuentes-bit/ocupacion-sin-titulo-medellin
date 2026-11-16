# =============================================================================
# 01_filtro_ecv.R  ·  Grupo 2 (Sofia Cambas, Marien Lozano, Samuel Rodríguez)
#
# De dónde se baja: Alcaldía de Medellín, Departamento Administrativo de
#   Planeación, Encuesta de Calidad de Vida 2025, microdatos.
#   https://www.medellin.gov.co/es/centro-documental/encuesta-calidad-de-vida/
# Qué archivo lee: datos/ECV_2025.xlsx (26.553.654 bytes,
#   MD5 680dbcaf35e744db76ce9740f3b16027), una fila por persona.
# Fecha de descarga: 13 de octubre de 2026
#
# Qué hace:
#   1. Cuenta los hogares de la base antes de filtrar.
#   2. Muestra la tabla de frecuencias de J.36 (tenencia de la vivienda) y la
#      verifica con las preguntas de pago que la siguen en el cuestionario.
#   3. Filtra ocupantes sin título (J.36 = 5) y arrendatarios (J.36 = 1) de
#      estratos 1 a 3 e imprime los dos conteos (74 y 2.565).
# Salida: datos/ecv_filtrada.csv (hogares de los dos grupos, todos los estratos;
#   02_tabla_h1_h2.R aplica el filtro de estrato).
# =============================================================================

library(dplyr)
library(readxl)
library(readr)

entrada <- "datos/ECV_2025.xlsx"
salida  <- "datos/ecv_filtrada.csv"

variables <- c("NoForm", "Hogar", "A.10", "B.5", "C.1", "C.3",
               "H.31", "H.43", "F.2", "J.36", "J.37", "J.38", "J.39",
               "K.11", "FEH")

personas <- read_excel(entrada) |>
  select(all_of(variables)) |>
  mutate(across(everything(), as.numeric))

# ---- 1. Hogares antes de filtrar ---------------------------------------------
# Cada hogar tiene un único jefe (B.5 = 1), así que contar jefes es contar hogares.
jefes <- personas |> filter(B.5 == 1)
cat("Personas en la base:", nrow(personas), "\n")
cat("Hogares en la base (antes de filtrar):", nrow(jefes), "\n\n")

# ---- 2. Tabla de frecuencias de J.36 y su verificación -----------------------
# El diccionario de datos no trae las etiquetas de J.36. Se verifican con las
# preguntas que el cuestionario hace según la respuesta:
#   J.37 = pago del alquiler (solo debe tenerlo quien arrienda)
#   J.38 = cuota de la vivienda (solo quien la está pagando)
#   J.39 = arriendo estimado (para quien no paga arriendo ni cuota: opciones 3 a 6)
etiquetas <- c("1" = "En arriendo (paga alquiler, J.37)",
               "2" = "Propia, la están pagando (paga cuota, J.38)",
               "3" = "Propia, totalmente pagada",
               "4" = "En usufructo",
               "5" = "Ocupante de hecho, sin título",
               "6" = "Otra")

frecuencias_j36 <- jefes |>
  group_by(J.36) |>
  summarise(hogares       = n(),
            pct           = round(100 * n() / nrow(jefes), 1),
            paga_alquiler = sum(J.37 > 0, na.rm = TRUE),
            paga_cuota    = sum(J.38 > 0, na.rm = TRUE),
            arriendo_estimado = sum(J.39 > 0, na.rm = TRUE),
            .groups = "drop") |>
  mutate(etiqueta = etiquetas[as.character(J.36)], .after = J.36)

cat("Tabla de frecuencias de J.36 (hogares):\n")
print(as.data.frame(frecuencias_j36), row.names = FALSE)
write_csv(frecuencias_j36, "datos/frecuencias_j36.csv")

stopifnot(sum(frecuencias_j36$hogares) == nrow(jefes))
cat("\nVerificación: todos los hogares con J.36 = 1 pagan alquiler y ninguno de",
    "J.36 = 3 a 6 lo paga:",
    with(frecuencias_j36, paga_alquiler[J.36 == 1] == hogares[J.36 == 1] &
                          all(paga_alquiler[J.36 >= 3] == 0)), "\n\n")

# ---- 3. Filtro --------------------------------------------------------------
# Un hogar es desplazado si al menos uno de sus miembros llegó a Medellín por
# razones de orden público (C.3 = 1).
desplazamiento <- personas |>
  group_by(NoForm, Hogar) |>
  summarise(desplazado = any(C.3 == 1, na.rm = TRUE),
            personas   = n(), .groups = "drop")

filtrada <- jefes |>
  filter(J.36 %in% c(1, 5)) |>
  left_join(desplazamiento, by = c("NoForm", "Hogar")) |>
  mutate(grupo = if_else(J.36 == 5, "Ocupantes sin título", "Arrendatarios"),
         estrato = A.10)

write_csv(filtrada, salida)

conteo <- filtrada |> filter(estrato %in% 1:3) |> count(grupo)
cat("Hogares de estratos 1 a 3 por grupo:\n")
print(as.data.frame(conteo), row.names = FALSE)
# Resultado esperado: Arrendatarios 2565, Ocupantes sin título 74
