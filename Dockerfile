# parent image — R/tidyverse version specified
# https://cran.r-project.org/doc/manuals/r-release/NEWS.html
FROM rocker/tidyverse:4.3.1

# install R packages — development tools and code style
RUN install2.r lintr renv styler

# install R packages — data analysis
RUN install2.r \
    broom.mixed \
    estimatr \
    ggeffects \
    ggforce \
    lme4 \
    modelsummary \
    patchwork \
    reactable \
    readstata13 \
    rmarkdown \
    skimr

# install Quarto with specified version
ARG QUARTO_VERSION=1.3.450
RUN apt-get -y update && apt-get install -y --no-install-recommends curl gdebi-core
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb
RUN gdebi --non-interactive quarto-${QUARTO_VERSION}-linux-amd64.deb
RUN install2.r markdown reticulate
RUN quarto install tinytex

WORKDIR /home/rstudio
