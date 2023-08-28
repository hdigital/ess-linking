library(callr)
library(fs)
library(purrr)


FULL_RECREATE <- TRUE


## Lock package versions ----

# package versions project into 'renv.lock' (no renv-project used)
renv::snapshot(prompt = FALSE)


## Format and check code ----

# format project code with tidyverse style guide
styler::style_dir(exclude_dirs = c(".cache", "renv"))

# check code style, syntax errors and semantic issues
lintr::lint_dir()


## Run all scripts ----

# remove folder with data created in project
if (FULL_RECREATE && dir_exists("data")) {
  dir_delete("data")
}

# run R scripts in subfolders
r_files <- dir_ls(".", glob = "*.R", recurse = 1)
r_files <- r_files[r_files != "z-run-all.R"]
if (!FULL_RECREATE) { # ignore time intense files
  r_files <- r_files[!r_files %in% c("01-ess-prt.R", "07-parlgov-ess_cabinets.R")]
}
map(r_files, rscript)
dir_ls("data/")


## Render notebooks ----

dir_delete("figures-tables/")
dir_create("figures-tables/")

# render Quarto project
if (FULL_RECREATE) {
  map(c("_book/", "_freeze/"), \(.dir) if (dir_exists(.dir)) dir_delete(.dir))
}
system("quarto render")

# remove Rplots created with print()
if (file_exists("Rplots.pdf")) {
  file_delete("Rplots.pdf")
}


## Log session info ----

# add session info: R version, tidyverse packages, platform
library(tidyverse)
sessionInfo()
