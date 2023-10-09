# ESS parties

Code and supplementary information for: Paul Bederke and Holger Döring. 2023. “Harmonizing and Linking Party Information: The ESS as an Example of Complex Data Linking.” doi: [10.5281/zenodo.8421233](https://doi.org/10.5281/zenodo.8421233) — see [manuscript](Bederke_Doering_2023.pdf)

## Notes

Reproducible documents created with [Tidyverse-R](https://www.tidyverse.org/) and [Quarto](https://quarto.org/) — see `*.qmd` files.

Data sets used in analysis are created with `0*.R` scripts. Non-public data in folders `data-raw` and `data` not included in git repository – see [data-raw_files.csv](/data/00-data-raw_files.csv).

- `01-ess-prt-data.R` based on [Party Facts import](https://github.com/hdigital/partyfactsdata/blob/main/import/essprtv/01-ess-prt-raw.R)
- `04-party-facts-links.R` based on [Party Facts tidyverse example](https://partyfacts.herokuapp.com/download/)

Required R packages in [Dockerfile](/Dockerfile) (install2.r section) and information of all packages used with version numbers in [renv.lock](/renv.lock).

## How-to

### Run all

```R
callr::rscript("z-run-all.R", stdout="z-run-all.log")  # R console
```

```sh
Rscript z-run-all.R > "z-run-all.log"                  # terminal
```

set `FULL_RECREATE = TRUE` to include time intense processing

- recreate ESS rds-files from dta-sources
- calculate ESS-Parlgov government-opposition matches

### Rocker container

Use [Docker](https://docs.docker.com/get-docker/) to run RStudio in a browser

<http://localhost:8787/>

```sh
docker-compose up -d  # start container in detached mode

docker-compose down   # shut down container
```
