# ESS parties

Code and supplementary material for:

- Bederke, P. and Döring, H. (2023) “Harmonizing and linking party information: The ESS as an example of complex data linking”. Zenodo (preprint). doi: [10.5281/zenodo.10061173](https://doi.org/10.5281/zenodo.10061173)
- Bederke, P. and Döring, H. (2023) “Linking European Social Survey (ESS) party information”. Zenodo (software). doi: [10.5281/zenodo.8421232](https://doi.org/10.5281/zenodo.8421232)

Website at <https://hdigital.github.io/ess-linking/>

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

## License

[MIT](https://choosealicense.com/licenses/mit/) – Copyright (c) 2023 Paul Bederke and Holger Döring
