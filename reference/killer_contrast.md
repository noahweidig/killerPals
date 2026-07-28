# WCAG contrast ratio

WCAG contrast ratio

## Usage

``` r
killer_contrast(a, b)
```

## Arguments

- a, b:

  Character vectors of colours. Recycled against each other.

## Value

A numeric vector of contrast ratios, between 1 and 21. WCAG 2.2 asks for
at least 4.5 for body text, 3 for large text and for the boundaries of
graphical objects.

## Examples

``` r
killer_contrast("#FF524F", "white")
#> [1] 3.195462
killer_contrast(killer_pal("flash"), "black")
#> [1] 11.540490  3.790909  2.088473 13.840918 11.278229  3.515526  4.581047
#> [8]  6.469968
```
