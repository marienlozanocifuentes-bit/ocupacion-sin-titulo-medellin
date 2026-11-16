# =============================================================================
# 05_grafica_comunas.R  ·  Grupo 2 (Sofia Cambas, Marien Lozano, Samuel Rodríguez)
#
# Prepara la figura 1 de la sección 4: para cada comuna y corregimiento de
# Medellín (A.7), el porcentaje ponderado de hogares que ocupan su vivienda sin
# título (J.36 = 5), con el conteo de la muestra. Se usan todos los estratos,
# porque la figura muestra dónde está el fenómeno en la ciudad.
#
# Entrada: datos/ECV_2025.xlsx
# Salidas: datos/ocupantes_por_comuna.csv y figuras/ocupantes_por_comuna.png
# =============================================================================

library(dplyr)
library(readxl)
library(readr)
library(ggplot2)

nombres <- c("1" = "Popular", "2" = "Santa Cruz", "3" = "Manrique",
             "4" = "Aranjuez", "5" = "Castilla", "6" = "Doce de Octubre",
             "7" = "Robledo", "8" = "Villa Hermosa", "9" = "Buenos Aires",
             "10" = "La Candelaria", "11" = "Laureles-Estadio",
             "12" = "La América", "13" = "San Javier", "14" = "El Poblado",
             "15" = "Guayabal", "16" = "Belén", "50" = "Palmitas",
             "60" = "San Cristóbal", "70" = "Altavista",
             "80" = "San Antonio de Prado", "90" = "Santa Elena")

jefes <- read_excel("datos/ECV_2025.xlsx") |>
  select(A.7, B.5, J.36, FEH) |>
  mutate(across(everything(), as.numeric)) |>
  filter(B.5 == 1)

comunas <- jefes |>
  group_by(codigo = A.7) |>
  summarise(hogares_muestra     = n(),
            ocupantes_muestra   = sum(J.36 == 5),
            ocupantes_estimados = round(sum(FEH[J.36 == 5])),
            pct_ocupantes       = round(100 * sum(FEH[J.36 == 5]) / sum(FEH), 2),
            .groups = "drop") |>
  mutate(nombre = nombres[as.character(codigo)],
         tipo   = if_else(codigo < 50, "Comuna", "Corregimiento"),
         .after = codigo) |>
  arrange(desc(pct_ocupantes))

write_csv(comunas, "datos/ocupantes_por_comuna.csv")
print(as.data.frame(comunas), row.names = FALSE)
cat("\nTotal de hogares ocupantes en la muestra:", sum(comunas$ocupantes_muestra), "\n")

# ---- Figura 1 ----------------------------------------------------------------
grafica <- ggplot(comunas,
                  aes(pct_ocupantes, reorder(nombre, pct_ocupantes),
                      fill = pct_ocupantes)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = paste0(ocupantes_muestra, " de ", hogares_muestra)),
            hjust = -0.1, size = 2.6, colour = "#2F3A1F") +
  scale_fill_gradient(low = "#DCE2B5", high = "#3F4C17", guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.18)),
                     labels = function(x) paste0(format(x, decimal.mark = ","), " %")) +
  labs(x = "Hogares que ocupan sin título (% ponderado)", y = NULL) +
  theme_minimal(base_size = 9)

dir.create("figuras", showWarnings = FALSE)
ggsave("figuras/ocupantes_por_comuna.png", grafica,
       width = 6.5, height = 3.66, dpi = 300, bg = "white")
