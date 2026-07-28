# WCAG relative luminance

WCAG relative luminance

## Usage

``` r
killer_luminance(colours)
```

## Arguments

- colours:

  A character vector of colours.

## Value

A numeric vector of relative luminances, between 0 and 1.

## Examples

``` r
killer_luminance(c("white", "black", "#FF524F"))
#> [1] 1.000000 0.000000 0.278591
```
