# Title: Add CHES left-right positions to combined ESS rounds data
# Description:
#   - select last CHES left-right position before ESS round
#   - combine ESS and CHES based on party ID and year


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)


## Data raw ----

ess_raw <- read_rds("data/02-ess-select.rds")
ches_raw <- read_rds("data/04-ches-lrgen.rds")
pf_raw <- read_rds("data/03-party-facts-links.rds")


## Data preparation ----

### ESS ----

ess <-
  ess_raw |>
  mutate(
    year = essround * 2 + 2000, # approximate year by round number
    lrscale = as.integer(lrscale) - 1, # correct readstata13 factor conversion
  ) |>
  select(!starts_with("prtc"))

# get last CHES year before ESS
years <-
  expand_grid(
    ess_year = unique(ess$year),
    ches_year = unique(ches_raw$year)
  ) |>
  filter(ches_year <= ess_year, ches_year %in% unique(ches_raw$year)) |>
  summarise(ches_year = max(ches_year), .by = ess_year)

### CHES ----

ches <-
  ches_raw |>
  select(ches_id = party_id, ches_party = party, ches_year = year, ches_lr = lrgen)

### Party Facts ----

pf <-
  pf_raw |>
  rename(pf_id = partyfacts_id, pf_party = partyfacts_name) |>
  select(ess_id, pf_id, pf_party, ches_id) |>
  distinct(ess_id, .keep_all = TRUE)


## Combined data ----

ess_com <-
  ess |>
  left_join(pf, by = join_by(prtv == ess_id)) |>
  left_join(years, by = join_by(year == ess_year)) |>
  left_join(ches) |>
  relocate(ches_party, .after = ches_id)

# filter cntry-essround not in CHES
ess_out <-
  ess_com |>
  filter(!all(is.na(ches_party)), .by = c(cntry, essround))

write_rds(ess_out, "data/05-ess-ches.rds")


## Check missing CHES IDs ----

check_ess_ches <-
  ess_out |>
  select(cntry, prtv, prtv_party, year, pf_id, pf_party, ches_id, ches_party, ches_year) |>
  # filter(is.na(ches_party) & ! is.na(prtv)) |>
  filter(!is.na(prtv)) |>
  mutate(n = n(), .by = c(prtv, year)) |>
  distinct()

write_csv(check_ess_ches, "data/05-check-ids_ess-ches.csv", na = "")

check_ess_ches_sum <-
  check_ess_ches |>
  filter(is.na(ches_party)) |>
  mutate(missing_n = sum(n, na.rm = TRUE), .by = c(cntry, year)) |>
  select(cntry, year, missing_n) |>
  distinct()
