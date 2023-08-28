# Title: Create CHES data set for left-right validation example
# Description: Select subset of CHES variables used in analysis


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)
library(glue)

library(readstata13)


ches_data_file <- "1999-2019_CHES_dataset_meansv3-td4m.dta"
ches_raw <- read.dta13(glue("data-raw/ches-{ches_data_file}"))

ches <-
  ches_raw |>
  select(country, year, party_id, party, lrgen) |>
  arrange(country, party_id, year)

write_rds(ches, "data/04-ches-lrgen.rds")
