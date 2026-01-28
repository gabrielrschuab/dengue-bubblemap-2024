library(sf)
library(dplyr)
library(ggplot2)
library(geobr)
library(readr)
library(patchwork)
library(scales)
library(rnaturalearth)
library(rnaturalearthdata)
library(tidyr)

sf::sf_use_s2(FALSE)

#dados
dengue_raw <- read.csv(
  "sinan_2024_anos.csv",
  sep = ";",
  stringsAsFactors = FALSE,
  fileEncoding = "ISO-8859-1"
)

#
# Transformar para "long"
dengue_2024_uf <- dengue_raw %>%
  rename(ano = Ano.notificação) %>%
  pivot_longer(
    cols = -ano,
    names_to = "uf",
    values_to = "total"
  ) %>%
  mutate(
    uf = as.character(uf),
    total = as.numeric(gsub("\\.", "", total)) # se vier com separador de milhar
  )

# Shapefiles

sa <- ne_countries(continent = "South America", returnclass = "sf") %>%
  st_transform(4674) %>%
  st_make_valid()

ufs <- read_state(year = 2020) %>%
  st_transform(4674) %>%
  st_make_valid()

ufs_linhas <- st_boundary(ufs)

# Extensão do mapa
bb_sa <- st_bbox(sa)
xlim <- c(bb_sa["xmin"], bb_sa["xmax"])
ylim <- c(bb_sa["ymin"], bb_sa["ymax"])


# Mapa com bolhas por regioes

uf_regiao <- tibble::tribble(
  ~uf, ~regiao,
  "AC","Norte","AP","Norte","AM","Norte","PA","Norte","RO","Norte","RR","Norte","TO","Norte",
  "AL","Nordeste","BA","Nordeste","CE","Nordeste","MA","Nordeste","PB","Nordeste","PE","Nordeste","PI","Nordeste","RN","Nordeste","SE","Nordeste",
  "DF","Centro Oeste","GO","Centro Oeste","MT","Centro Oeste","MS","Centro Oeste",
  "ES","Sudeste","MG","Sudeste","RJ","Sudeste","SP","Sudeste",
  "PR","Sul","RS","Sul","SC","Sul"
)

dengue_2024_reg <- dengue_2024_uf %>%
  left_join(uf_regiao, by = "uf") %>%
  group_by(regiao) %>%
  summarise(total = sum(total, na.rm = TRUE), .groups = "drop")

reg_sf <- geobr::read_region(year = 2020) %>%
  st_transform(4674) %>%
  st_make_valid()


reg_sf <- reg_sf %>%
  rename(regiao = name_region)

pontos_reg <- reg_sf %>%
  left_join(dengue_2024_reg, by = "regiao") %>%
  mutate(total = ifelse(is.na(total), 0, total)) %>%
  st_point_on_surface()

plot_bolhas_reg <- function(pontos_sf, titulo, legenda_size, cor_fill) {
  ggplot() +
    geom_sf(data = sa, fill = "grey95", color = "grey80", linewidth = 0.25) +
    geom_sf(data = reg_sf, fill = NA, color = "grey30", linewidth = 0.6) +
    geom_sf(
      data = pontos_sf,
      aes(size = total),
      shape = 21,
      color = "black",
      fill = cor_fill,
      alpha = 0.45,
      stroke = 0.25
    ) +
    scale_size_area(
      name = legenda_size,
      max_size = 18,
      breaks = pretty_breaks(n = 6)
    ) +
    coord_sf(xlim = xlim, ylim = ylim, expand = FALSE, clip = "off") +
    labs(title = titulo) +
    theme_minimal() +
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      legend.position = "right",
      legend.title = element_text(size = 8, face = "bold"),
      legend.text  = element_text(size = 7),
      plot.title   = element_text(hjust = 0.5, face = "bold", size = 14)
    )
}

map_reg_2024 <- plot_bolhas_reg(
  pontos_sf = pontos_reg,
  titulo = "Dengue cases (SINAN) — bubble map by Brazilian region (2024)",
  legenda_size = "Number of cases",
  cor_fill = "#1f77b4"
)


print(map_reg_2024)
