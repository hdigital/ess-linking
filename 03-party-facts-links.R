# Title: Create Party Facts based linking data set for ESS, CHES, and ParlGov
# Description:
#   - get Party Facts core and external parties data
#   - use ESS party IDs harmonized across rounds from Party Facts GitHub
#   - create a combined data set with party IDs from Party Facts, ESS, CHES, ParlGov


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)
library(glue)


# Party Facts tables
pf_info_raw <- read_csv("data-raw/pf-core-parties-csv.csv")
pf_mapping_raw <- read_csv("data-raw/pf-external-parties-csv.csv", guess_max = 50000)
pf_ess_raw <- read_csv("data-raw/pf-essprtv.csv")

pf_info <-
  pf_info_raw |>
  select(partyfacts_id, partyfacts_name = name_short, technical)

pf_mapping <-
  pf_mapping_raw |>
  filter(!is.na(partyfacts_id))


## ESS ----

# link datasets (select only linked parties)
ess <-
  pf_mapping |>
  filter(dataset_key == "essprtv") |>
  select(
    partyfacts_id,
    first_ess_id = dataset_party_id
  )


# CHES ----

ches <-
  pf_mapping |>
  filter(dataset_key == "ches") |>
  mutate(ches_id = as.integer(dataset_party_id)) |>
  select(partyfacts_id, ches_id, ches_name = name_short) |>
  distinct(partyfacts_id, .keep_all = TRUE)


# ParlGov ----

parlgov <-
  pf_mapping |>
  filter(dataset_key == "parlgov") |>
  mutate(parlgov_id = as.integer(dataset_party_id)) |>
  select(partyfacts_id, parlgov_id, parlgov_name = name_short) |>
  distinct(partyfacts_id, .keep_all = TRUE)


## Merged dataset ----

ess_id <-
  pf_ess_raw |>
  filter(str_detect(ess_variable, "prtv")) |>
  select(ess_id, first_ess_id)

link_table <-
  ess_id |>
  left_join(ess, by = c("first_ess_id" = "first_ess_id")) |>
  left_join(ches, by = c("partyfacts_id" = "partyfacts_id")) |>
  left_join(parlgov, by = c("partyfacts_id" = "partyfacts_id")) |>
  left_join(pf_info, by = c("partyfacts_id" = "partyfacts_id")) |>
  filter(is.na(technical) | partyfacts_name == "ally") |>
  select(!technical) |>
  relocate(partyfacts_name, .after = partyfacts_id)

link_table_technical <-
  ess_id |>
  left_join(ess, by = c("first_ess_id" = "first_ess_id")) |>
  left_join(pf_info, by = c("partyfacts_id" = "partyfacts_id")) |>
  filter(!is.na(technical))

write_rds(link_table, "data/03-party-facts-links.rds")
write_rds(link_table_technical, "data/03-party-facts-links-technical.rds")
