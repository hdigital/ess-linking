# Title: Get all ESS party variables (prt*)
# Description:
#   - create data set with all prtv/prtc variables from ESS rounds
#   - add ESS unique party identifier
#   - include party name from variable label


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)

library(readstata13)


# ess9 <- read.dta13("data-raw/ESS9e03_1.dta")


## ESS waves ----

ess_dta_path <- "data-raw/" # path of ESS rounds Stata data

# data files for ESS rounds
ess_dta_files <-
  fs::dir_ls(ess_dta_path, glob = "*ESS*.dta") |>
  str_remove(ess_dta_path)

ess_rds_path <- "data/ess-waves/"
fs::dir_create(ess_rds_path)


## Read all ESS files ----

# function to get party name and party id
get_ess_parties <- function(ess_dta) {
  data_path <- paste0(ess_dta_path, ess_dta)

  # read data and create rds version of ESS data set
  ess_data <- read.dta13(data_path)
  write_rds(
    ess_data,
    paste0(ess_rds_path, str_replace(ess_dta, "dta", "rds"))
  )

  # extract party and ESS core information
  party <-
    ess_data |>
    select(cntry, essround, idno, starts_with(c("prtv", "prtc"))) |>
    pivot_longer(c(-cntry, -essround, -idno),
      names_to = "variable",
      values_to = "party"
    )

  # extract party IDs
  party_id <-
    read.dta13(data_path, convert.factors = FALSE) |>
    select(cntry, essround, starts_with(c("prtv", "prtc"))) |>
    pivot_longer(c(-cntry, -essround),
      names_to = "variable",
      values_to = "party_id"
    ) |>
    pull(party_id)

  party["party_id"] <- party_id

  return(party)
}

# party name and party id for ESS rounds -- time intense so avoiding rereading
if (!exists("ess_prt_raw")) {
  ess_prt_raw <-
    map(ess_dta_files, get_ess_parties, .progress = TRUE) |>
    bind_rows()
}

# temporary copy of ESS data -- not run
if (FALSE) {
  write_rds(ess_prt_raw, "z-tmp_ess-raw.rds")
  ess_prt_raw <- read_rds("z-tmp_ess-raw.rds")
}


## ESS data long ----

# combine and create unique 'ess_id'
prt_long <-
  ess_prt_raw |>
  drop_na(party) |>
  mutate(ess_id = case_when(
    cntry %in% c("DE", "LT") & str_detect(variable, "prtv") ~ paste(
      cntry,
      essround,
      party_id,
      substr(variable, 4, 4),
      str_sub(variable, -3, -1),
      sep = "-"
    ),
    TRUE ~ paste(
      cntry,
      essround,
      party_id,
      substr(variable, 4, 4),
      sep = "-"
    )
  )) |>
  arrange(essround, cntry, idno, variable, party_id, party)

write_rds(prt_long, "data/01-ess-prt.rds")


## ESS data wide ----

prt_vars <-
  prt_long |>
  summarise(
    n = n(),
    first = min(essround),
    last = max(essround),
    .by = variable
  )

# drop secondary variables based on codes, keep only national level votes
# (Germany second tier vote ("de2") and Lithuania first vote "lt1")
prt_long2 <-
  prt_long |>
  filter(!str_detect(variable, "de1|lt[23]")) |>
  mutate(prt_var = substr(variable, 1, 4)) |>
  select(-variable, -party_id) |>
  distinct(cntry, essround, idno, prt_var, .keep_all = TRUE)

prt_wide <-
  prt_long2 |>
  pivot_wider(
    names_from = prt_var,
    names_glue = "{prt_var}_{.value}",
    values_from = c(ess_id, party)
  ) |>
  rename_with(\(.x) str_remove(.x, fixed("_ess_id"))) |>
  relocate(prtv_party, .after = prtv) |>
  arrange(essround, cntry, idno)

write_rds(prt_wide, "data/01-ess-prtv-prtc.rds")
