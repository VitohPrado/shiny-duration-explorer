# Formato dos dados / Data format

Uma linha por segmento. / One row per segment.
Modelo / Template: [`../data/template.csv`](../data/template.csv) (valores ilustrativos / illustrative values).

## Colunas / Columns

| Coluna / Column | Obrigatória / Required | Descrição / Description |
|---|---|---|
| `part` | sim / yes | ID do participante, ex.: `P001` / participant ID |
| `wordlabel` | sim / yes | Palavra / word |
| `seglabel` | sim / yes | Rótulo do segmento, em qualquer convenção / segment label, any convention |
| `sylltree` | sim / yes | Posição do segmento na sílaba / position in the syllable: `ons`, `ons1`, `ons2` (ataque / onset), `N` (núcleo / nucleus), `cd` (coda) |
| `stress` | sim / yes | `stressed` ou / or `unstressed` |
| `syl_from_end` | sim / yes | Posição da sílaba contando do fim da palavra: `1` = última / last, `2` = penúltima / penultimate |
| `n_syll` | sim / yes | Número de sílabas da palavra / number of syllables in the word |
| `segdur` | sim / yes | Duração do segmento, em segundos ou milissegundos. O app detecta a unidade: se a mediana for menor que 5, assume segundos / segment duration in seconds or milliseconds (auto-detected: median < 5 means seconds) |
| `segdur_z` | não / no | Duração normalizada (z). Se ausente, é calculada por `part` × `sylltree` × `seglabel` / normalized duration; computed per participant × syllable position × segment if absent |
| `sylllabel` | não / no | Rótulo da sílaba / syllable label |
| `is_target` | não / no | `TRUE`/`FALSE`: palavra-alvo / target word. Padrão / default: `TRUE` |

As colunas `syllpos` e `wordsylln` também são aceitas no lugar de `syl_from_end` e `n_syll`. / `syllpos` and `wordsylln` are also accepted in place of `syl_from_end` and `n_syll`.

## Arquivos aceitos / Accepted files

- `.csv`: separado por vírgula ou por ponto e vírgula (detecção automática), codificação UTF-8 / comma- or semicolon-separated (auto-detected), UTF-8
- `.tsv`: separado por tabulação, UTF-8 / tab-separated, UTF-8
- `.rds`: um data frame do R / an R data frame

Salve como `data/my_data.csv` (ou `.tsv`, `.rds`). / Save as `data/my_data.csv` (or `.tsv`, `.rds`).

## Recodificando seus dados / Recoding your data

Se os seus códigos são diferentes, recodifique antes de salvar (nomes de colunas e valores abaixo são hipotéticos). / If your codes differ, recode before saving (column names and values below are hypothetical).

```r
library(dplyr)

dados <- dados %>%
  mutate(
    sylltree = recode(posicao_silaba, "ataque" = "ons", "nucleo" = "N", "coda" = "cd"),
    stress   = if_else(tonica, "stressed", "unstressed")
  )

write.csv(dados, "data/my_data.csv", row.names = FALSE, fileEncoding = "UTF-8")
```
