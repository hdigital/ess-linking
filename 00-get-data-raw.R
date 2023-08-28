# Title: Get raw data used in project and add to "data-raw" folder
# Description:
#   - download raw data if accessible (use option to run)
#   - keep copy of data sources in "data-raw" folder (not in git repository)
#   - provide information about manual download source for ESS data
#   - provide information about used data files (file name and hash)

library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)
library(glue)


# option to download accessible data files
# (set default 'FALSE' to avoid re-downloading in run all script)
DOWNLOAD_AGAIN <- FALSE

# create data raw folder if not exists
fs::dir_create("data-raw/")


## Party Facts ----

if (DOWNLOAD_AGAIN) {
  url <- "https://partyfacts.herokuapp.com/download/"
  map(
    c("core-parties-csv", "external-parties-csv"),
    \(.fi) download.file(
      glue("{url}{.fi}/"),
      glue("data-raw/pf-{.fi}.csv")
    )
  )
  download.file(
    "https://raw.githubusercontent.com/hdigital/partyfactsdata/main/import/essprtv/02-ess-harmonize.csv",
    "data-raw/pf-essprtv.csv"
  )
}


## ESS ----

# manual download of ESS Rounds 1–10 from ESS Data Portal needed
# https://ess-search.nsd.no/

doi_url <- "https://doi.org"
doi_prefix <- "10.21338"
doi_suffix <-
  c(
    "ess1e06_6",
    "ess2e03_6",
    "ess3e03_7",
    "ess4e04_5",
    "ess5e03_4",
    "ess7e02_2",
    "ess8e02_2",
    "ess9e03_1",
    "ess10e03_1",
    "ess10sce03_0"
  )

print("Download ESS data files manually with DOI url")

map_chr(doi_suffix, \(.x) glue("{doi_url}/{doi_prefix}/{.x}"))

glue("{doi_url}/10.18712/ess6e02_5")


## CHES ----

if (DOWNLOAD_AGAIN) {
  url <- "https://www.chesdata.eu/s/"
  ches_dataset <- "1999-2019_CHES_dataset_meansv3-td4m.dta"
  ches_codebook <- "1999-2019_CHES_codebook-yj99.pdf"

  map(
    ches_dataset, ches_codebook,
    \(.fi) download.file(
      glue("{url}{.fi}/"),
      glue("data-raw/ches-{.fi}")
    )
  )
}


## ParlGov ----

if (DOWNLOAD_AGAIN) {
  download.file(
    "https://parlgov.org/data/parlgov-development_csv-utf-8/view_cabinet.csv",
    "data-raw/parlgov_view_cabinet.csv"
  )
}


## Data files index ----

data_files <-
  tibble(data_file = fs::dir_ls("data-raw/", regexp = "(.+)(\\.)(csv|dta)")) |>
  mutate(
    size = fs::file_size(data_file),
    hash = rlang::hash_file(data_file)
  ) |>
  arrange(data_file)

fs::dir_create("data/")
write_csv(data_files, "data/00-data-raw_files.csv")
