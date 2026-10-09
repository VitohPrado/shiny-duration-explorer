# Instala os pacotes necessários que ainda não estão instalados.
# Rode uma vez:  source("install_packages.R")

pkgs <- c("shiny", "bslib", "dplyr", "ggplot2", "plotly", "DT",
          "purrr", "tibble")   # purrr e tibble: só para gerar os dados simulados

faltam <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(faltam)) install.packages(faltam) else message("Todos os pacotes já estão instalados.")

