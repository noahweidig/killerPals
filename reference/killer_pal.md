# Draw colours from a Queen album palette

The workhorse behind every killerPals scale. Qualitative palettes return
their colours in a fixed order chosen so that consecutive colours
contrast strongly; sequential and diverging palettes are interpolated
through CIELAB to whatever length you ask for.

## Usage

``` r
killer_pal(
  palette = "greatest_hits",
  n = NULL,
  type = c("qualitative", "sequential", "diverging"),
  direction = 1
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

## Value

A character vector of `n` hex colour strings, of class `killer_palette`
so it prints as swatches.

## See also

[`scale_colour_killer_d()`](https://noahweidig.github.io/killerpals/reference/scale_killer.md)
and friends for ggplot2 scales,
[`killer_check()`](https://noahweidig.github.io/killerpals/reference/killer_check.md)
to audit a palette's accessibility.

## Examples

``` r
killer_pal("flash")
#> <killer_palette> flash (qualitative, 8 colours)
#>   Flash Gordon (1980) - Ah-ah! Saviour of the universe: comic-strip red, gold and void.
#>   #EDB900 #416D8C #75291A #D8D3AD #8CC5E9 #755E5D #687E11 #9A8D7B
killer_pal("opera_night", n = 4)
#> <killer_palette> opera_night (qualitative, 4 colours)
#>   A Night at the Opera (1975) - Heraldic crest colours: cream, gilt and deep operatic red.
#>   #933EB4 #AAB567 #64C1FB #4F4104
killer_pal("heavenly", n = 9, type = "sequential")
#> <killer_palette> heavenly (sequential, 9 colours)
#>   Made in Heaven (1995) - Montreux at dusk: lake blue, alpine grey and the last light.
#>   #F1F2FF #CDD7FF #9EBEFE #64A7FF #0091FA #007AD0 #0563A3 #004C7D #00385A
killer_pal("innuendo", n = 5, type = "diverging", direction = -1)
#> <killer_palette> innuendo (diverging, 5 colours)
#>   Innuendo (1991) - Grandville's Victorian engraving, hand-tinted and ornate.
#>   #722CA1 #B98CD3 #EEF6F9 #54AF7C #005D33

# All 48 palettes at a glance:
head(killer_palette_info())
#>            name              album year        type  n
#> 33       regina              Queen 1973   diverging 11
#> 1        regina              Queen 1973 qualitative  8
#> 17       regina              Queen 1973  sequential  7
#> 35 heart_attack Sheer Heart Attack 1974   diverging 11
#> 3  heart_attack Sheer Heart Attack 1974 qualitative  8
#> 19 heart_attack Sheer Heart Attack 1974  sequential  7
#>                                                           blurb
#> 33       Smoke, spotlight and stage-purple from the 1973 debut.
#> 1        Smoke, spotlight and stage-purple from the 1973 debut.
#> 17       Smoke, spotlight and stage-purple from the 1973 debut.
#> 35 Oiled, exhausted and lit in sickly green - the 1974 pile-up.
#> 3  Oiled, exhausted and lit in sickly green - the 1974 pile-up.
#> 19 Oiled, exhausted and lit in sickly green - the 1974 pile-up.
```
