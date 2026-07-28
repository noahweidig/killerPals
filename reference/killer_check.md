# Audit a palette's accessibility

Reports the numbers behind the package's colourblind- and
contrast-friendly claims, so you can verify them rather than take them
on trust.

## Usage

``` r
killer_check(
  palette = "greatest_hits",
  n = NULL,
  type = c("qualitative", "sequential", "diverging"),
  direction = 1,
  colours = NULL
)
```

## Arguments

- palette:

  Palette name, e.g. `"flash"` or `"opera_night"`. See
  [`killer_names()`](https://noahweidig.github.io/killerpals/reference/killer_names.md).

- n:

  Number of colours to return. Defaults to every colour the palette
  defines. For `type = "qualitative"` this cannot exceed the number of
  colours available, because inventing extra categorical colours would
  silently break the palette's colourblind-safe separation.

- type:

  Palette type: `"qualitative"` for unordered categories, `"sequential"`
  for ordered low-to-high values, `"diverging"` for values spread either
  side of a meaningful midpoint.

- direction:

  `1` for the palette's natural order, `-1` to reverse it.

- colours:

  Optionally audit an arbitrary vector of colours instead of a named
  palette. If supplied, `palette`, `n`, `type` and `direction` are
  ignored.

## Value

A list of class `killer_check` with components:

- colours:

  The colours audited.

- min_distance:

  Named numeric vector: the worst-case pairwise CIEDE2000 separation
  under each vision type. For a qualitative palette these should all
  comfortably exceed 10.

- contrast_white,contrast_black:

  Contrast ratio of each colour against a white and a black background.

- lightness:

  CIELAB lightness of each colour.

- monotone_lightness:

  `TRUE` if lightness increases or decreases steadily across the
  palette - the property that lets a sequential palette survive being
  printed in greyscale.

## Examples

``` r
killer_check("greatest_hits")
#> <killer_check> greatest_hits (qualitative) 
#>   colours: 11 
#>   worst-case CIEDE2000 separation by vision type:
#>     normal    14.6
#>     deutan    13.3
#>     protan    12.7
#>     tritan    12.5
#>   contrast vs white: 1.52 - 10.08
#>   contrast vs black: 2.08 - 13.80
#>   lightness (L*):    27.9 - 83.9
#>   monotone lightness: FALSE 
killer_check("heavenly", n = 9, type = "sequential")
#> <killer_check> heavenly (sequential) 
#>   colours: 9 
#>   worst-case CIEDE2000 separation by vision type:
#>     normal     7.1
#>     deutan     7.0
#>     protan     6.4
#>     tritan     4.6
#>   contrast vs white: 1.11 - 12.26
#>   contrast vs black: 1.71 - 18.89
#>   lightness (L*):    22.1 - 95.8
#>   monotone lightness: TRUE 

# Audit any colours at all, not just ours
killer_check(colours = c("red", "green", "blue"))
#> <killer_check> custom colours 
#>   colours: 3 
#>   worst-case CIEDE2000 separation by vision type:
#>     normal    53.1
#>     deutan    19.5
#>     protan    42.4
#>     tritan    46.6
#>   contrast vs white: 1.37 - 8.59
#>   contrast vs black: 2.44 - 15.30
#>   lightness (L*):    32.2 - 87.6
#>   monotone lightness: FALSE 
```
