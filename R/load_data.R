# R/load_data.R  (arquivo em UTF-8)
# ---------------------------------------------------------------
# Carrega os dados do explorador:
#   1) o arquivo do usuário, se existir (data/my_data.rds|csv|tsv ou o
#      caminho indicado na variável de ambiente DURATION_DATA);
#   2) caso contrário, os dados simulados (data/demo_data.rds).
# Formato esperado das colunas: veja docs/data-format.md
# ---------------------------------------------------------------

REQUIRED_COLS <- c("part", "wordlabel", "seglabel", "sylltree", "stress",
                   "syl_from_end", "n_syll", "segdur")

# Caminho do arquivo do usuário, ou NA se não houver
user_data_path <- function(dir = "data") {
  env <- Sys.getenv("DURATION_DATA", unset = "")
  if (nzchar(env)) {
    if (!file.exists(env)) {
      stop("DURATION_DATA aponta para um arquivo que não existe: ", env, call. = FALSE)
    }
    return(env)
  }
  cand <- file.path(dir, c("my_data.rds", "my_data.csv", "my_data.tsv"))
  cand <- cand[file.exists(cand)]
  if (length(cand)) cand[1] else NA_character_
}

# Lê .rds, .csv (vírgula ou ponto e vírgula) ou .tsv
read_duration_file <- function(path) {
  ext <- tolower(tools::file_ext(path))

  if (ext == "rds") return(readRDS(path))

  if (ext == "tsv") {
    return(utils::read.delim(path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE))
  }

  if (ext == "csv") {
    first <- readLines(path, n = 1, warn = FALSE)
    if (!length(first)) stop("O arquivo está vazio: ", basename(path), call. = FALSE)
    n_semicolon <- lengths(regmatches(first, gregexpr(";", first)))
    n_comma     <- lengths(regmatches(first, gregexpr(",", first)))
    reader <- if (n_semicolon > n_comma) utils::read.csv2 else utils::read.csv
    return(reader(path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE))
  }

  stop("Formato não suportado (use .rds, .csv ou .tsv): ", basename(path), call. = FALSE)
}

# Interrompe com uma mensagem clara se faltarem colunas obrigatórias
check_columns <- function(dat, source_name) {
  missing <- setdiff(REQUIRED_COLS, names(dat))
  if (length(missing)) {
    stop("Colunas ausentes em '", source_name, "': ", paste(missing, collapse = ", "),
         ".\nVeja docs/data-format.md para o formato esperado.", call. = FALSE)
  }
}

# Se não houver segdur_z, calcula por participante x posição na sílaba x segmento
add_zscore_if_missing <- function(dat) {
  if ("segdur_z" %in% names(dat)) return(list(data = dat, computed = FALSE))

  dat <- dat %>%
    dplyr::group_by(part, sylltree, seglabel) %>%
    dplyr::mutate(segdur_z = (segdur - mean(segdur, na.rm = TRUE)) /
                             stats::sd(segdur, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(segdur_z = dplyr::coalesce(segdur_z, 0))

  list(data = dat, computed = TRUE)
}

# Função principal: devolve list(data, using_demo, note)
load_duration_data <- function(data_dir = "data") {
  path       <- user_data_path(data_dir)
  using_demo <- is.na(path)

  if (using_demo) {
    demo_path <- file.path(data_dir, "demo_data.rds")
    if (!file.exists(demo_path)) {
      # Primeira execução sem dados simulados: gera data/demo_data.rds
      source(file.path("data-raw", "simulate_data.R"), local = new.env())
    }
    dat  <- readRDS(demo_path)
    src  <- "demo_data.rds"
    note <- "Dados simulados, apenas para demonstração. Os efeitos mostrados são arbitrários."
  } else {
    dat  <- read_duration_file(path)
    src  <- basename(path)
    note <- paste0("Dados carregados de: ", src)
  }

  # Nomes alternativos de colunas vindos do script de limpeza original
  if (!"syl_from_end" %in% names(dat) && "syllpos" %in% names(dat))
    dat$syl_from_end <- dat$syllpos
  if (!"n_syll" %in% names(dat) && "wordsylln" %in% names(dat))
    dat$n_syll <- dat$wordsylln

  check_columns(dat, src)

  dat$segdur <- as.numeric(dat$segdur)
  if (!"is_target" %in% names(dat)) dat$is_target <- TRUE
  dat$is_target <- as.logical(dat$is_target)
  if (!"sylllabel" %in% names(dat)) dat$sylllabel <- NA_character_

  z   <- add_zscore_if_missing(dat)
  dat <- z$data
  if (z$computed) {
    note <- paste(note, "A coluna segdur_z não existe: foi calculada por participante,",
                  "posição na sílaba e segmento.")
  }

  list(data = dat, using_demo = using_demo, note = note)
}
