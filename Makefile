.PHONY: help covers palettes swatches logo document test check site all clean

R      ?= Rscript
PYTHON ?= python3

help:
	@echo "covers    - download + standardise the album covers into data-raw/covers"
	@echo "palettes  - re-derive the palettes and refresh R/palettes-generated.R"
	@echo "swatches  - render the palette swatch images used by the README and site"
	@echo "readme    - knit README.Rmd to README.md"
	@echo "logo      - render man/figures/logo.png"
	@echo "document  - roxygen2::roxygenise()"
	@echo "test      - testthat"
	@echo "check     - R CMD check --as-cran"
	@echo "site      - pkgdown::build_site()"
	@echo "all       - palettes + document + test + swatches"

covers:
	$(PYTHON) data-raw/download_covers.py

palettes: covers
	$(PYTHON) data-raw/build_palettes.py
	$(R) data-raw/make_data.R

swatches:
	$(R) data-raw/render_swatches.R

readme:
	$(R) -e 'knitr::knit("README.Rmd", "README.md")'

logo:
	$(R) data-raw/make_logo.R

document:
	$(R) -e 'roxygen2::roxygenise()'

test: document
	$(R) -e 'testthat::test_local()'

check: document
	$(R) -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'

site: document
	$(R) -e 'pkgdown::build_site()'

all: palettes document test swatches readme

clean:
	rm -rf docs ..Rcheck *.tar.gz man/*.Rd
