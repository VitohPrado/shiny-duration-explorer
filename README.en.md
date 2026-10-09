# Segmental duration explorer (R Shiny)

An interactive Shiny app to explore speech segment durations by segment, syllable position, word position and stress context. It was built for phonology/phonetics research data and can be used with **your own data**.

> The data included in this repository are **simulated**. The effects shown are arbitrary and are **not research results**.

🇧🇷 [Versão em português](README.md)

<!-- When you have a screenshot, save it as docs/screenshot.png and uncomment the line below:
![App screenshot](docs/screenshot.png)
-->

## What the app does

- **Filters:** syllable position, word position, stress context, number of syllables, segments and participants.
- **Measure:** duration in milliseconds or normalized duration (z-score).
- **Tabs:** distribution (interactive plot), mean per speaker, summary table by group, filtered data (with `.csv` download) and a filter diagnostics tab.

## How to run

1. Install [R](https://www.r-project.org/) and, preferably, [RStudio](https://posit.co/download/rstudio-desktop/).
2. Download or clone this repository and open the folder in RStudio.
3. Install the packages (once):
   ```r
   source("install_packages.R")
   ```
4. Generate the simulated data (once):
   ```r
   source("data-raw/simulate_data.R")
   ```
5. Open `app.R` and click **Run App**, or run `shiny::runApp()`.

## Using your own data

1. Arrange your data as a table with **one row per segment**, following the format in [`docs/data-format.md`](docs/data-format.md). [`data/template.csv`](data/template.csv) is a template.
2. Save it as `data/my_data.csv` (or `.tsv` / `.rds`).
3. Run the app. It detects the file automatically and shows where the data came from.

Alternatively, set the `DURATION_DATA` environment variable to the full path of your file.

`data/my_data.*` is ignored by Git (see `.gitignore`), so your data will **not be pushed to GitHub** by accident. If required columns are missing, the app tells you which ones.

## Limitations

- Syllable-position codes (`ons`, `ons1`, `ons2`, `N`, `cd`) and stress codes (`stressed`, `unstressed`) follow the original project's convention. If your data use other codes, recode them (example in [`docs/data-format.md`](docs/data-format.md)).
- Word position only covers the last and penultimate syllables.
- The interface is in Portuguese. Labels and colors can be edited in the "Rótulos e ordem" block of `app.R`.
- If the `segdur_z` column is missing, it is computed per participant, syllable position and segment.

## Author and license

Vitor Antônio Morais Prado, UFMG. [MIT](LICENSE) license.
