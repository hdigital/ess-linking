# Title: Add ParlGov government/opposition data to combined ESS rounds
# Description: Determine government/opposition status for first cabinet after
#              election before interview date


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)
library(glue)


## Read data sources ----

ess_raw <- read_rds("data/02-ess-select.rds")
pf_ess_raw <- read_csv("data-raw/pf-essprtv.csv")
cabinets_raw <- read_rds("data/06-parlgov-cabinets.rds")


## Prepare datasets ----

cntry_ess_parlgov <-
  pf_ess_raw |>
  filter(country %in% cabinets_raw$country) |>
  pull(ess_cntry) |>
  unique()

ess <-
  ess_raw |>
  filter(cntry %in% cntry_ess_parlgov) |>
  select(!starts_with("prtc")) |>
  left_join(pf_ess_raw |> select(prtv = ess_id, first_ess_id), multiple = "first")

prtv_inw <-
  ess_raw |>
  left_join(select(pf_ess_raw, prtv = ess_id, first_ess_id), multiple = "first") |>
  distinct(cntry, inw_date, prtv, prtv_party, first_ess_id) |>
  na.omit()

pf_parties <-
  cabinets_raw |>
  distinct(party_id, party_name) |>
  rename(parlgov_id = party_id, parlgov_name = party_name)


## Determine cabinet status ----

get_cabinet <- function(ess_cntry, ess_inw_date) {
  if (!ess_cntry %in% cabinets_raw$cntry || is.na(ess_inw_date)) {
    return(NA)
  }

  cabinet <-
    cabinets_raw |>
    filter(
      cntry == ess_cntry,
      start_date < ess_inw_date
    ) |>
    filter(start_date == max(start_date)) |>
    select(
      cabinet_id,
      cabinet_name,
      cabinet_start = start_date,
      cabinet_party,
      parlgov_id = party_id,
      parlgov_name = party_name_short,
      first_ess_id
    )

  if (length(cabinet == 1)) {
    return(cabinet)
  } else {
    return(NA)
  }
}

get_cabinet("DE", "2019-07-01")

ess_cabinets <-
  ess |>
  distinct(cntry, inw_date) |>
  # sample_n(100) |>
  mutate(parties = map2(cntry, inw_date, get_cabinet, .progress = TRUE)) |>
  unnest(parties)


## Final dataset ----

ess_cab_out <-
  ess |>
  filter(!is.na(inw_date), !is.na(prtv)) |>
  left_join(ess_cabinets, multiple = "first") |>
  select(
    cntry,
    essround,
    idno,
    inw_date,
    prtv,
    prtv_party,
    first_ess_id,
    cabinet_id:parlgov_name
  )

write_rds(ess_cab_out, "data/07-parlgov-ess_cabinets.rds")
