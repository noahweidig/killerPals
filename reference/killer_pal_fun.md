# Palette functions for programmatic use

Returns a function of `n`, which is the shape ggplot2 and scales expect.
Rarely needed directly: the `scale_*_killer_*()` family calls this for
you.

## Usage

``` r
killer_pal_fun(
  palette = "greatest_hits",
  type = c("qualitative", "sequential", "diverging"),
  direction = 1
)
```

## Arguments

- palette:

  Palette name, e.g. `"flash"` or `"opera_night"`. See
  [`killer_names()`](https://noahweidig.github.io/killerpals/reference/killer_names.md).

- type:

  Palette type: `"qualitative"` for unordered categories, `"sequential"`
  for ordered low-to-high values, `"diverging"` for values spread either
  side of a meaningful midpoint.

- direction:

  `1` for the palette's natural order, `-1` to reverse it.

## Value

A function taking a single argument `n` and returning that many hex
colours.

## Examples

``` r
pal <- killer_pal_fun("hot_space", type = "sequential")
pal(3)
#> [1] "#BBFFE4" "#009FA3" "#00394B"
pal(11)
#>  [1] "#BBFFE4" "#54F7D1" "#00E3C5" "#00CBBC" "#0BB4B1" "#009FA3" "#008993"
#>  [8] "#007382" "#005F70" "#004C5D" "#00394B"
```
