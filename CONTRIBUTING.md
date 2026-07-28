# Contributing to killerPals

Thanks for your interest in improving killerPals.

## Reporting a problem

Please file an issue with a minimal
[reprex](https://reprex.tidyverse.org/). For a colour problem,
[`killer_check()`](https://noahweidig.github.io/killerpals/reference/killer_check.md)
output is usually the most useful thing to include.

## Pull requests

- Please raise an issue first for anything larger than a typo, so we can
  agree on the approach before you spend time on it.
- Run `make document test` before pushing. `make check` runs the full
  `R CMD check --as-cran`.
- Match the surrounding code style; `make lint` uses the project
  `.lintr`.
- Add a bullet to `NEWS.md` for any user-facing change.

## Changing the palettes

The palette colours are **generated**, not hand-edited.
`data/killer_palettes.rda` is built from
`data-raw/palettes-generated.R`, which is written by
`data-raw/build_palettes.py`. To change a colour, change the derivation:

``` sh
make palettes   # downloads covers, re-derives, rebuilds data/
make test       # the accessibility tests are the contract
```

The tests in `tests/testthat/test-accessibility.R` encode the package’s
central promise: worst-case CIEDE2000 separation under every simulated
vision type, minimum contrast against light and dark backgrounds, and
monotone lightness for the ramps. A change that lowers any of those bars
needs a clear justification, not a lowered threshold.

The `derive-palettes` workflow re-runs the derivation on any change
under `data-raw/` and fails if the committed palettes would change, so
please commit the regenerated files together with the code that produced
them.

## Album covers

The covers are copyrighted artwork and are deliberately **not**
committed. They are downloaded locally by `data-raw/download_covers.py`
and are git-ignored. Please do not add them to the repository, or to the
built package.

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://noahweidig.github.io/killerpals/CODE_OF_CONDUCT.md). By
participating you agree to abide by its terms.
