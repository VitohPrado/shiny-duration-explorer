# app.R  (arquivo em UTF-8)
# ---------------------------------------------------------------
# Explorador interativo de duração segmental (Shiny).
# Usa os dados simulados (data/demo_data.rds) ou, se existir, o seu
# arquivo data/my_data.csv|tsv|rds (veja README.md e docs/data-format.md).
#
# Rodar:  abra este arquivo no RStudio e clique em "Run App",
#         ou use shiny::runApp() na pasta do projeto.
# Pacotes: shiny, bslib, dplyr, ggplot2, plotly, DT
#          (instale com source("install_packages.R"))
# ---------------------------------------------------------------

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)

# ---- Dados -------------------------------------------------------
# A leitura e a validação ficam em R/load_data.R
source("R/load_data.R", local = TRUE)

loaded     <- load_duration_data()
dat        <- loaded$data
using_demo <- loaded$using_demo
data_note  <- loaded$note

# segdur em segundos (mediana < 5) ou já em milissegundos?
seg_to_ms <- if (median(as.numeric(dat$segdur), na.rm = TRUE) < 5) 1000 else 1

# ---- Rótulos e ordem (edite aqui) ----
tree_levels   <- c("Ataque", "Núcleo", "Coda")
stress_levels <- c("não acentuada", "acentuada")

dat <- dat %>%
  mutate(
    part      = as.character(part),
    wordlabel = as.character(wordlabel),
    seglabel  = as.character(seglabel),
    stress_pt = factor(
      if_else(as.character(stress) == "stressed", "acentuada", "não acentuada"),
      levels = stress_levels
    ),
    tree_pt = factor(
      case_when(
        as.character(sylltree) %in% c("ons", "ons1", "ons2") ~ "Ataque",
        as.character(sylltree) == "N"                        ~ "Núcleo",
        as.character(sylltree) == "cd"                       ~ "Coda",
        TRUE                                                 ~ NA_character_
      ),
      levels = tree_levels
    ),
    pos_pt    = case_when(
      as.numeric(as.character(syl_from_end)) == 1 ~ "Última sílaba",
      as.numeric(as.character(syl_from_end)) == 2 ~ "Penúltima sílaba",
      TRUE                                        ~ NA_character_
    ),
    n_syll    = as.numeric(as.character(n_syll)),
    dur_ms    = as.numeric(segdur) * seg_to_ms
  )

seg_choices    <- sort(unique(dat$seglabel))
tree_choices   <- tree_levels
stress_choices <- stress_levels
pos_choices    <- c("Última sílaba", "Penúltima sílaba")
nsyll_choices  <- sort(unique(dat$n_syll))
part_choices   <- sort(unique(dat$part))

cores <- setNames(c("#2E8B70", "#D9622B"), stress_levels)   # 1ª cor = não acentuada, 2ª = acentuada

# ---- Interface ---------------------------------------------------
ui <- page_sidebar(
  title = "Duração segmental — explorador interativo",
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  sidebar = sidebar(
    width = 320,
    checkboxInput("only_target", "Somente palavras-alvo", TRUE),
    checkboxGroupInput("tree", "Posição na sílaba", tree_choices, selected = tree_choices),
    checkboxGroupInput("pos", "Posição na palavra", pos_choices, selected = pos_choices),
    checkboxGroupInput("stress", "Contexto acentual", stress_choices, selected = stress_choices),
    checkboxGroupInput("nsyll", "Sílabas na palavra", nsyll_choices, selected = nsyll_choices),
    selectizeInput("seg", "Segmentos", seg_choices, selected = seg_choices, multiple = TRUE),
    selectizeInput("part", "Participantes", part_choices, selected = part_choices, multiple = TRUE),
    hr(),
    radioButtons("resp", "Medida",
                 c("Duração (ms)" = "ms", "Duração normalizada (z)" = "z")),
    selectInput("facet", "Separar painéis por",
                c("Nenhum" = "none", "Segmento" = "seglabel",
                  "Posição na sílaba" = "tree_pt", "Posição na palavra" = "pos_pt")),
    actionButton("reset", "Restaurar filtros")
  ),

  div(class = if (using_demo) "alert alert-warning" else "text-muted small",
      data_note),

  layout_columns(
    fill = FALSE,
    value_box("Observações",    textOutput("n_obs")),
    value_box("Participantes",  textOutput("n_part")),
    value_box("Palavras",       textOutput("n_words")),
    value_box("Média da medida", textOutput("mean_y"))
  ),
  p(class = "text-muted", textOutput("part_list")),

  navset_card_tab(
    nav_panel("Distribuição", plotlyOutput("plot_dist", height = "480px")),
    nav_panel("Por falante",  plotOutput("plot_spk", height = "520px")),
    nav_panel("Resumo",       DTOutput("tbl_sum")),
    nav_panel("Dados",
              downloadButton("dl", "Baixar dados filtrados (.csv)"),
              DTOutput("tbl_raw")),
    nav_panel("Diagnóstico", verbatimTextOutput("diag"))
  )
)

# ---- Servidor ----------------------------------------------------
server <- function(input, output, session) {

  observeEvent(input$reset, {
    updateCheckboxInput(session, "only_target", value = TRUE)
    updateCheckboxGroupInput(session, "tree",   selected = tree_choices)
    updateCheckboxGroupInput(session, "pos",    selected = pos_choices)
    updateCheckboxGroupInput(session, "stress", selected = stress_choices)
    updateCheckboxGroupInput(session, "nsyll",  selected = nsyll_choices)
    updateSelectizeInput(session, "seg",  selected = seg_choices)
    updateSelectizeInput(session, "part", selected = part_choices)
  })

  filtered <- reactive({
    d <- dat
    if (isTRUE(input$only_target)) d <- filter(d, is_target)
    d <- filter(
      d,
      tree_pt   %in% input$tree,
      pos_pt    %in% input$pos,
      stress_pt %in% input$stress,
      n_syll    %in% as.numeric(input$nsyll),
      seglabel  %in% input$seg,
      part      %in% input$part
    )
    d$y <- if (input$resp == "ms") d$dur_ms else d$segdur_z
    d
  })

  y_lab <- reactive(if (input$resp == "ms") "Duração (ms)" else "Duração normalizada (z)")

  # Caixas de resumo
  output$n_obs   <- renderText(format(nrow(filtered()), big.mark = "."))
  output$n_part  <- renderText(as.character(n_distinct(filtered()$part)))
  output$n_words <- renderText(as.character(n_distinct(filtered()$wordlabel)))
  output$mean_y  <- renderText({
    d <- filtered()
    if (nrow(d) == 0) "—" else sprintf("%.1f", mean(d$y, na.rm = TRUE))
  })
  output$part_list <- renderText({
    p <- sort(unique(filtered()$part))
    paste0("Participantes neste recorte: ", if (length(p)) paste(p, collapse = ", ") else "nenhum")
  })

  # Distribuição
  output$plot_dist <- renderPlotly({
    d <- filtered()
    validate(need(nrow(d) > 0, "Nenhum dado com os filtros atuais."))
    d <- mutate(d, tip = paste0(part, " | ", wordlabel, " | [", seglabel, "]<br>",
                                round(y, 1)))

    p <- ggplot(d, aes(x = stress_pt, y = y, fill = stress_pt, color = stress_pt)) +
      geom_boxplot(outlier.shape = NA, alpha = 0.35, width = 0.5) +
      geom_jitter(aes(text = tip), width = 0.12, alpha = 0.6, size = 1.6) +
      scale_fill_manual(values = cores) +
      scale_color_manual(values = cores) +
      labs(x = "Contexto acentual", y = y_lab()) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "none")

    if (input$facet != "none") {
      p <- p + facet_wrap(vars(.data[[input$facet]]))
    }
    suppressWarnings(ggplotly(p, tooltip = "text"))
  })

  # Por falante
  output$plot_spk <- renderPlot({
    d <- filtered()
    validate(need(nrow(d) > 0, "Nenhum dado com os filtros atuais."))
    s <- d %>%
      group_by(part, stress_pt) %>%
      summarise(m = mean(y, na.rm = TRUE),
                se = sd(y, na.rm = TRUE) / sqrt(n()),
                .groups = "drop")
    ggplot(s, aes(x = m, y = reorder(part, m), color = stress_pt)) +
      geom_pointrange(aes(xmin = m - se, xmax = m + se),
                      position = position_dodge(width = 0.5)) +
      scale_color_manual(values = cores) +
      labs(x = paste0("Média ± erro-padrão — ", y_lab()), y = NULL,
           color = "Contexto acentual") +
      theme_minimal(base_size = 13)
  })

  # Resumo
  output$tbl_sum <- renderDT({
    d <- filtered()
    req(nrow(d) > 0)
    d %>%
      group_by(Segmento = seglabel, `Posição na sílaba` = tree_pt,
               `Contexto acentual` = stress_pt) %>%
      summarise(N = n(),
                Média   = round(mean(y, na.rm = TRUE), 1),
                DP      = round(sd(y, na.rm = TRUE), 1),
                Mediana = round(median(y, na.rm = TRUE), 1),
                .groups = "drop") %>%
      datatable(rownames = FALSE, options = list(pageLength = 15))
  })

  # Dados
  raw_view <- reactive({
    filtered() %>%
      transmute(participante = part, palavra = wordlabel, silaba = sylllabel,
                segmento = seglabel, posicao_silaba = tree_pt,
                acento = stress_pt, posicao_palavra = pos_pt,
                dur_ms = round(dur_ms, 1), dur_z = round(segdur_z, 2))
  })
  output$tbl_raw <- renderDT(datatable(raw_view(), rownames = FALSE,
                                       options = list(pageLength = 15)))
  # Diagnóstico: quantas linhas sobram após cada filtro, e que valores existem
  output$diag <- renderPrint({
    d <- dat
    cat("Linhas no total:", nrow(d), "\n")
    if (isTRUE(input$only_target)) {
      d <- filter(d, is_target)
      cat("Após 'somente palavras-alvo':", nrow(d), "\n")
    }
    d <- filter(d, tree_pt %in% input$tree)
    cat("Após posição na sílaba:", nrow(d), "\n")
    d <- filter(d, pos_pt %in% input$pos)
    cat("Após posição na palavra:", nrow(d), "\n")
    d <- filter(d, stress_pt %in% input$stress)
    cat("Após contexto acentual:", nrow(d), "\n")
    d <- filter(d, n_syll %in% as.numeric(input$nsyll))
    cat("Após número de sílabas:", nrow(d), "\n")
    d <- filter(d, seglabel %in% input$seg)
    cat("Após segmentos:", nrow(d), "\n")
    d <- filter(d, part %in% input$part)
    cat("Após participantes:", nrow(d), "\n")

    cat("\nValores existentes nos dados completos:\n")
    cat("\nis_target:\n");    print(table(dat$is_target, useNA = "ifany"))
    cat("\ntree_pt:\n");      print(table(dat$tree_pt,   useNA = "ifany"))
    cat("\npos_pt:\n");       print(table(dat$pos_pt,    useNA = "ifany"))
    cat("\nstress_pt:\n");    print(table(dat$stress_pt, useNA = "ifany"))
    cat("\nn_syll:\n");       print(table(dat$n_syll,    useNA = "ifany"))
    cat("\nUnidade de segdur: fator de conversão para ms =", seg_to_ms, "\n")
  })

  output$dl <- downloadHandler(
    filename = function() paste0("dados_filtrados_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(raw_view(), file, row.names = FALSE,
                                        fileEncoding = "UTF-8")
  )
}

shinyApp(ui, server)
