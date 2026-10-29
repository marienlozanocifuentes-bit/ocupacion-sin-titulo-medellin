# ¿Por qué una familia invade en vez de arrendar? · Grupo 2 (Sofia Cambas, Marien Lozano, Samuel Rodríguez)
Repositorio: <https://github.com/marienlozanocifuentes-bit/ocupacion-sin-titulo-medellin>


Paper del curso Haciendo Economía (Universidad EAFIT): compara hogares ocupantes sin título y arrendatarios de estratos 1 a 3 en Medellín con la ECV 2025 y la GEIH 2025.

1. **Datos (no vienen en el repositorio por su tamaño).** ECV 2025: descargar los microdatos en <https://www.medellin.gov.co/es/centro-documental/encuesta-calidad-de-vida/> y guardarlos como `datos/ECV_2025.xlsx`. GEIH 2025: descargar en <https://microdatos.dane.gov.co/index.php/catalog/853> los módulos de vivienda, características generales, fuerza de trabajo, ocupados y migración de cada mes, en `datos/geih_raw/<mes>/`. La base ya procesada de la GEIH sí viene en `datos/geih_medellin_2025.csv`.
2. **Scripts (en R, con `dplyr`, `readr`, `readxl` y `tidyr`), desde la carpeta del repositorio y en orden:** `codigo/01_filtro_ecv.R` (debe imprimir 74 y 2.565), `codigo/02_tabla_h1_h2.R`, `codigo/03_base_geih.R` (solo si se tienen los CSV de la GEIH) y `codigo/04_h2_geih.R`.
3. **Compilar:** con Quarto y TinyTeX instalados (`quarto install tinytex`), ejecutar `quarto render paper.qmd`. Las tablas de la sección 4 se leen de `datos/tabla_h1_h2.csv` y `datos/tabla_h2_geih.csv`, que dejan los scripts.
4. **Archivos:** `paper.qmd` (texto), `referencias.bib` (referencias), `apa.csl` (estilo APA 7), `codigo/` (scripts) y `datos/` (salidas de los scripts).
