# Title: Create ParlGov data set for government/opposition voting example
# Description:
#   - remove caretaker cabinets
#   - keep only cabinet formed after election
#   - add ESS party IDs


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)
library(glue)


## Read data sources ----

parlgov_raw <- read_csv("data-raw/parlgov_view_cabinet.csv")
pf_links_raw <- read_rds("data/03-party-facts-links.rds")


## Context data ----

cab_96 <-
  parlgov_raw |>
  filter(election_date >= "1996-01-01") |>
  rename(country = country_name_short)

countries <-
  pf_links_raw |>
  select(party_id = parlgov_id) |>
  inner_join(select(cab_96, country, party_id), multiple = "first") |>
  distinct(country)

cabinet_first <-
  cab_96 |>
  filter(caretaker == 0) |>
  slice(1, .by = c(country, election_date)) |>
  select(country, election_date, start_date)


## ParlGov cabinets with ESS IDs ----

pf_ess_parlgov <-
  pf_links_raw |>
  distinct(first_ess_id, parlgov_id) |>
  mutate(cntry = substr(first_ess_id, 1, 2)) |>
  rename(party_id = parlgov_id) |>
  na.omit()

# keep necessary many-to-many relations (use filters DEU and LTU)
parlgov <-
  cab_96 |>
  inner_join(countries) |>
  inner_join(cabinet_first, ) |>
  left_join(pf_ess_parlgov, relationship = "many-to-many") |>
  filter(!str_detect(first_ess_id, "lt2|lt3|de1"))

merge_check <-
  parlgov |>
  mutate(dup = n(), .by = c(country, election_date, party_name)) |>
  filter(dup >= 2) |>
  select(country, start_date, cabinet_name, party_name_short, first_ess_id)

if (nrow(merge_check >= 2)) {
  warning("Multiple matches for some cabinet parties")
  merge_check
}

write_rds(parlgov, "data/06-parlgov-cabinets.rds")
