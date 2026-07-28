# Overview of every palette

Overview of every palette

## Usage

``` r
killer_palette_info(type = NULL)
```

## Arguments

- type:

  Optionally restrict to one palette type. One of `"qualitative"`,
  `"sequential"` or `"diverging"`.

## Value

A data frame with one row per palette, containing the palette `name`,
the source `album` and `year`, a short `blurb`, the number of colours
defined (`n`) and the palette `type`.

## Examples

``` r
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
killer_palette_info(type = "diverging")
#>             name                album year      type  n
#> 1         regina                Queen 1973 diverging 11
#> 3   heart_attack   Sheer Heart Attack 1974 diverging 11
#> 2   mirror_queen             Queen II 1974 diverging 11
#> 4    opera_night A Night at the Opera 1975 diverging 11
#> 5       race_day   A Day at the Races 1976 diverging 11
#> 6     robot_news    News of the World 1977 diverging 11
#> 7  all_that_jazz                 Jazz 1978 diverging 11
#> 9          flash         Flash Gordon 1980 diverging 11
#> 8        game_on             The Game 1980 diverging 11
#> 16 greatest_hits        Greatest Hits 1981 diverging 11
#> 10     hot_space            Hot Space 1982 diverging 11
#> 11     the_works            The Works 1984 diverging 11
#> 12 kind_of_magic      A Kind of Magic 1986 diverging 11
#> 13       miracle          The Miracle 1989 diverging 11
#> 14      innuendo             Innuendo 1991 diverging 11
#> 15      heavenly       Made in Heaven 1995 diverging 11
#>                                                              blurb
#> 1           Smoke, spotlight and stage-purple from the 1973 debut.
#> 3     Oiled, exhausted and lit in sickly green - the 1974 pile-up.
#> 2  The mirrored Mick Rock portrait: side White against side Black.
#> 4       Heraldic crest colours: cream, gilt and deep operatic red.
#> 5            The crest again, inverted - black lacquer and silver.
#> 6        Frank Kelly Freas's robot: pulp-magazine blues and steel.
#> 7         Berlin Wall stencil geometry in flat, graphic primaries.
#> 9  Ah-ah! Saviour of the universe: comic-strip red, gold and void.
#> 8      Chrome, leather and cool monochrome with a flash of colour.
#> 16      The most separable colours from all fifteen studio covers.
#> 10    Four flat pop-art blocks - the most graphic cover they made.
#> 11   George Hurrell's Hollywood monochrome, warmed by sepia light.
#> 12    Roger Chiasson's cartoon night sky: neon over midnight blue.
#> 13              Four faces morphed into one, in cold studio light.
#> 14       Grandville's Victorian engraving, hand-tinted and ornate.
#> 15    Montreux at dusk: lake blue, alpine grey and the last light.
```
