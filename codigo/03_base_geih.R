# =============================================================================
# 03_base_geih.R  ·  Grupo 2 (Sofia Cambas, Marien Lozano, Samuel Rodríguez)
# Arma una base de personas de Medellín y su área metropolitana (AREA == 5)
# a partir de los microdatos mensuales de la GEIH 2025 (DANE), solo con las
# variables del estudio.
#
# De dónde se baja: DANE, Archivo Nacional de Datos (ANDA), GEIH 2025,
#   https://microdatos.dane.gov.co/index.php/catalog/853 (módulos en CSV:
#   Datos del hogar y la vivienda, Características generales, Fuerza de
#   trabajo, Ocupados y Migración, de enero a diciembre).
# Estructura esperada:  datos/geih_raw/<mes>/<Módulo>_<Mes>.CSV
#                       (separador ';', codificación latin-1)
# Salida:               datos/geih_medellin_2025.csv
# =============================================================================

library(dplyr)
library(readr)

carpeta_raw <- "datos/geih_raw"
salida      <- "datos/geih_medellin_2025.csv"

llave_hogar   <- c("DIRECTORIO", "SECUENCIA_P", "HOGAR")
llave_persona <- c(llave_hogar, "ORDEN")

# Módulo (inicio del nombre del archivo) -> variables que conservamos
modulos <- list(
  "Datos del hogar"   = c("MES", "AREA", "FEX_C18",
                          "P5090",      # tenencia de la vivienda (3 arriendo, 5 ocupante de hecho)
                          "P4030S1A1",  # estrato
                          "P6008"),     # personas en el hogar
  "Caracter"          = c("P6050",      # parentesco (1 = jefe del hogar)
                          "P3271",      # sexo
                          "P6040",      # edad
                          "P3042"),     # nivel educativo
  "Fuerza de trabajo" = c("FT", "FFT", "PET"),
  "Ocupados"          = c("OCI",        # ocupado
                          "P6430",      # posición ocupacional
                          "P6920",      # cotiza a pensión (1 sí, 2 no, 3 pensionado)
                          "INGLABO"),   # ingreso laboral mensual
  "Migraci"           = c("P3373",      # dónde nació
                          "P3384",      # dónde vivía hace 12 meses
                          "P3386")      # motivo del cambio (4 = conflicto armado)
)

# Lee un módulo y deja solo la llave y las variables pedidas
leer_modulo <- function(archivo, variables, llave) {
  read_delim(archivo, delim = ";", locale = locale(encoding = "latin1"),
             col_select = any_of(c(llave, variables)),
             col_types = cols(.default = col_double()),
             na = c("", ".", "NA"), progress = FALSE, show_col_types = FALSE)
}

# Busca el archivo de un módulo dentro de la carpeta de un mes
buscar <- function(carpeta, inicio) {
  archivos <- list.files(carpeta, pattern = "\\.csv$", ignore.case = TRUE, full.names = TRUE)
  # Normaliza los nombres: algunos meses traen espacios "duros" (U+00A0) o guiones bajos
  nombres  <- gsub("#U00a0| |_", " ", basename(archivos))
  encontrado <- archivos[startsWith(nombres, inicio)]
  if (length(encontrado) != 1) stop("No encuentro el módulo '", inicio, "' en ", carpeta)
  encontrado
}

# Une los 5 módulos de un mes
procesar_mes <- function(carpeta) {
  vivienda <- leer_modulo(buscar(carpeta, "Datos del hogar"), modulos[["Datos del hogar"]], llave_hogar) |>
    filter(AREA == 5)                                  # Medellín A.M.

  base <- leer_modulo(buscar(carpeta, "Caracter"), modulos[["Caracter"]], llave_persona) |>
    inner_join(vivienda, by = llave_hogar)

  for (m in c("Fuerza de trabajo", "Ocupados", "Migraci")) {
    base <- base |>
      left_join(leer_modulo(buscar(carpeta, m), modulos[[m]], llave_persona), by = llave_persona)
  }
  base
}

meses <- list.dirs(carpeta_raw, recursive = FALSE)
geih  <- bind_rows(lapply(meses, procesar_mes))

# Variables derivadas
geih <- geih |>
  mutate(
    grupo = case_when(P5090 == 5 ~ "Ocupante sin título",
                      P5090 == 3 ~ "Arrendatario",
                      TRUE       ~ NA_character_),
    estrato_1a3            = P4030S1A1 %in% 1:3,
    jefe                   = P6050 == 1,
    ocupado                = OCI %in% 1,
    desocupado             = FT %in% 1 & !ocupado,
    informal               = ocupado & P6920 %in% 2,   # ocupado que no cotiza a pensión
    migrante_interno       = P3373 %in% 2,
    migrante_conflicto_12m = P3386 %in% 4,
    # Al juntar varios meses, el DANE indica dividir el factor por el número de meses
    FEX_anual = FEX_C18 / length(meses)
  )

write_csv(geih, salida)
cat("Meses:", length(meses), "| personas:", nrow(geih),
    "| hogares:", nrow(distinct(geih, MES, DIRECTORIO, SECUENCIA_P, HOGAR)), "\n")
