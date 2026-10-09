# Explorador de duração segmental (R Shiny)

Aplicativo Shiny para explorar, de forma interativa, a duração de segmentos da fala por segmento, posição na sílaba, posição na palavra e contexto acentual. Foi feito para dados de pesquisa em fonologia/fonética e pode ser usado com os **seus próprios dados**.

> Os dados que acompanham este repositório são **simulados**. Os efeitos mostrados são arbitrários e **não são resultados de pesquisa**.

🇬🇧 [English version](README.en.md)

<!-- Quando tiver um print do app, salve em docs/screenshot.png e descomente a linha abaixo:
![Captura de tela do app](docs/screenshot.png)
-->

## O que o app faz

- **Filtros:** posição na sílaba, posição na palavra, contexto acentual, número de sílabas, segmentos e participantes.
- **Medida:** duração em milissegundos ou duração normalizada (z).
- **Abas:** distribuição (gráfico interativo), média por falante, tabela-resumo por grupo, dados filtrados (com download em `.csv`) e diagnóstico dos filtros.

## Como rodar

1. Instale o [R](https://www.r-project.org/) e, de preferência, o [RStudio](https://posit.co/download/rstudio-desktop/).
2. Baixe ou clone este repositório e abra a pasta no RStudio.
3. Instale os pacotes (uma vez só):
   ```r
   source("install_packages.R")
   ```
4. Gere os dados simulados (uma vez só):
   ```r
   source("data-raw/simulate_data.R")
   ```
5. Abra `app.R` e clique em **Run App**, ou rode `shiny::runApp()`.

## Usando seus próprios dados

1. Organize seus dados em uma tabela com **uma linha por segmento**, seguindo o formato descrito em [`docs/data-format.md`](docs/data-format.md). O arquivo [`data/template.csv`](data/template.csv) é um modelo.
2. Salve a tabela como `data/my_data.csv` (ou `.tsv` / `.rds`).
3. Rode o app. Ele detecta o arquivo sozinho e mostra de onde vieram os dados.

Alternativa: defina a variável de ambiente `DURATION_DATA` com o caminho completo do arquivo.

O arquivo `data/my_data.*` é ignorado pelo Git (veja `.gitignore`), então os seus dados **não são enviados ao GitHub** por engano. Se faltarem colunas obrigatórias, o app informa quais são.

## Estrutura do projeto

```
.
├── app.R                  # interface e servidor do app
├── R/load_data.R          # leitura e validação dos dados
├── data/
│   ├── demo_data.rds      # dados simulados (gerado por data-raw/simulate_data.R)
│   └── template.csv       # modelo do formato de dados
├── data-raw/
│   └── simulate_data.R    # gerador dos dados simulados
├── docs/data-format.md    # dicionário de dados
└── install_packages.R     # instala os pacotes necessários
```

## Limitações

- Os códigos de posição na sílaba (`ons`, `ons1`, `ons2`, `N`, `cd`) e de acento (`stressed`, `unstressed`) seguem a convenção do projeto original. Se os seus dados usam outros códigos, recodifique-os (exemplo em [`docs/data-format.md`](docs/data-format.md)).
- A posição na palavra considera apenas a última e a penúltima sílabas.
- A interface está em português. Rótulos e cores podem ser editados no bloco "Rótulos e ordem" do `app.R`.
- Se a coluna `segdur_z` não existir, ela é calculada por participante, posição na sílaba e segmento.

## Autoria e licença

Vitor Antônio Morais Prado, UFMG. Licença [MIT](LICENSE).
