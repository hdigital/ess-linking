# Title: Create combined data set from all ESS rounds for selected variables
# Description:
#   - select ESS variables for inclusion (variables used in other scripts)
#   - add interview date based on different ESS interview date variables
#   - include ESS core variables to identify observations


library(conflicted)

library(tidyverse)
conflicts_prefer(dplyr::filter, .quiet = TRUE)


## Variable selection ----

variables_select <- c("pspwght", "gndr", "agea", "eduyrs", "lrscale", "stfdem")


## ESS waves ----

# ESS data files (rds export)
ess_files <- fs::dir_ls("data/ess-waves/", glob = "*/ESS*.rds")

# function to select variables from ESS data file
get_ess_parties <- function(ess_file) {
  read_rds(ess_file) |>
    select(
      "cntry", "essround", "idno", # identifiers (required)
      all_of(variables_select), # variables selected above
      starts_with("inw") # interview date and time variables
    )
}

# select variables ('variables_select') from all ESS data files
if (!exists("ess_raw")) {
  ess_raw <-
    map(ess_files, get_ess_parties, .progress = TRUE) |>
    bind_rows()
}


## Interview date ----

# create date strings in y-m-d format
ess_date_all <-
  ess_raw |>
  mutate(
    # full date known
    date1 = as_date(inwds) |> as.character(),
    date2 = as_date(inwde) |> as.character(),
    date3 = paste(inwyys, inwmms, inwdds, sep = "-"),
    date4 = paste(inwyye, inwmme, inwdde, sep = "-"),
    date5 = paste(inwyr, inwmm, inwdd, sep = "-"),
  ) |>
  select(essround, cntry, idno, starts_with("date"))

# create date for complete and valid date strings in y-m-d format
ess_date <-
  ess_date_all |>
  pivot_longer(starts_with("date")) |>
  mutate(date = ymd(value)) |>
  filter(!is.na(date)) |>
  summarise(inw_date = min(date), .by = c(essround, cntry, idno))

# add date variable to ESS data
ess <-
  ess_raw |>
  select(!starts_with("inw")) |>
  left_join(ess_date)

# select observations without date information
inw_na_date <-
  ess_raw |>
  left_join(ess_date) |>
  filter(is.na(inw_date)) |>
  select(cntry:idno, starts_with("inw"))


## ESS prt variables ----

prt_raw <- read_rds("data/01-ess-prtv-prtc.rds")

# add ESS party information
ess_out <-
  ess |>
  left_join(prt_raw) |>
  relocate(starts_with("inw"), .after = "idno")

write_rds(ess_out, "data/02-ess-select.rds")
