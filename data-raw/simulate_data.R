# data-raw/simulate_data.R
# ---------------------------------------------------------------
# Generates SIMULATED segment-duration data with the same column
# structure as the real dataset. Use it for the public GitHub repo:
# no real participant data is ever published.
#
# The effects below are arbitrary (just so the plots show something).
# They are NOT results from the research.
#
# Run from the project root:  source("data-raw/simulate_data.R")
# Output: data/demo_data.rds
# ---------------------------------------------------------------

library(dplyr)
library(purrr)
library(tibble)

set.seed(2026)

palavras <- c(
  "raspa", "raspar", "caspa", "gaspar", "aspa", "aspar",
  "basta", "gastar", "pasta", "pastar", "vasta", "bastar",
  "casca", "cascar", "lasca", "lascar", "masca", "mascar"
)
participantes <- sprintf("P%03d", 1:12)

# ortografia -> rotulo do segmento (mesma convencao dos seus dados)
seg_map <- c(r = "h/", c = "k", g = "g", b = "b", p = "p",
             v = "v", l = "l", m = "m", t = "t")

# Estrutura de cada palavra: [onset1] a s | [onset2] a [r]
make_word <- function(w) {
  pat <- "^([rcgbpvlm]?)as([ptc])a(r?)$"
  on1 <- sub(pat, "\\1", w)
  on2 <- sub(pat, "\\2", w)
  has_r <- sub(pat, "\\3", w) == "r"

  s1 <- tibble(
    sylllabel    = paste0(on1, "as"),
    seglabel     = c(if (on1 != "") unname(seg_map[on1]), "a", "s"),
    sylltree     = c(if (on1 != "") "ons", "N", "cd"),
    syl_from_end = 2
  )
  s2 <- tibble(
    sylllabel    = paste0(on2, "a", if (has_r) "r" else ""),
    seglabel     = c(unname(seg_map[on2]), "a", if (has_r) "4"),
    sylltree     = c("ons", "N", if (has_r) "cd"),
    syl_from_end = 1
  )
  bind_rows(s1, s2) %>% mutate(wordlabel = w, oxitona = has_r)
}

estrutura <- map_dfr(palavras, make_word)

falantes <- tibble(
  part  = participantes,
  fator = exp(rnorm(length(participantes), 0, 0.12))   # velocidade de cada falante
)

sim <- cross_join(tibble(part = participantes), estrutura) %>%
  left_join(falantes, by = "part") %>%
  mutate(
    stress = if_else(
      (oxitona & syl_from_end == 1) | (!oxitona & syl_from_end == 2),
      "stressed", "unstressed"
    ),
    segtype = if_else(seglabel == "a", "V", "C"),
    base_ms = case_when(
      seglabel == "a"                          ~ 80,
      seglabel == "s"                          ~ 105,
      seglabel %in% c("p", "t", "k", "b", "g") ~ 65,
      seglabel == "4"                          ~ 40,
      TRUE                                     ~ 65
    ),
    efeito_acento = case_when(
      stress == "stressed" & segtype == "V"    ~  25,
      stress == "stressed" & sylltree == "cd"  ~  -8,
      TRUE                                     ~   0
    ),
    dur_ms = (base_ms + efeito_acento) * fator * exp(rnorm(n(), 0, 0.18)),
    # ~1% de erros de segmentacao simulados (duracao inflada)
    dur_ms = if_else(runif(n()) < 0.01, dur_ms * 2.5, dur_ms),
    segdur = dur_ms / 1000
  ) %>%
  group_by(part, wordlabel, sylllabel) %>%
  mutate(sylldur = sum(segdur)) %>%
  group_by(part, wordlabel) %>%
  mutate(worddur = sum(segdur)) %>%
  group_by(part, sylltree, seglabel) %>%
  mutate(segdur_z = (segdur - mean(segdur)) / sd(segdur)) %>%
  ungroup() %>%
  mutate(
    segdur_z  = coalesce(segdur_z, 0),
    n_syll    = 2,
    is_target = TRUE
  ) %>%
  select(part, wordlabel, sylllabel, seglabel, segtype, sylltree, stress,
         syl_from_end, n_syll, segdur, sylldur, worddur, segdur_z, is_target)

dir.create("data", showWarnings = FALSE)
saveRDS(sim, "data/demo_data.rds")
message("Salvo: data/demo_data.rds (", nrow(sim), " linhas, ",
        n_distinct(sim$part), " participantes simulados)")

