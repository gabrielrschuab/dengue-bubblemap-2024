# dengue-bubblemap-2024
Bubble map de casos de dengue (SINAN) por região — 2024 (R)

## Dados

Este projeto utiliza dados do **SINAN** (notificações de dengue), provenientes de fonte oficial/pública.

Para manter o repositório leve e reproduzível, o arquivo CSV de entrada não está incluído.  
Para reproduzir a análise, forneça um arquivo **agregado por UF** no formato:

- Coluna 1: `Ano.notificação`
- Colunas seguintes: siglas das UFs (`AC`, `AL`, `AM`, ...)

No script `scripts/bubble_map_regioes_2024.R`, altere o nome do arquivo informado no código para corresponder ao nome do seu arquivo local, por exemplo:

```r
input_file <- "data/seu_arquivo.csv"
