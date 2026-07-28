# Queen album palette definitions

The colour data behind every
[`killer_pal()`](https://noahweidig.github.io/killerpals/reference/killer_pal.md)
palette. One element per palette family, named after the palette (not
the album), in release order, with `greatest_hits` last.

## Usage

``` r
killer_palettes
```

## Format

A named list of 16 palette families. Each element is a list of:

- album:

  Album title, as a string.

- year:

  Release year, as an integer.

- blurb:

  One-line description of the palette's character.

- qualitative:

  Character vector of 8 hex colours (11 for `greatest_hits`) for
  unordered categories.

- sequential:

  Character vector of 7 hex anchor stops, light to dark, strictly
  monotone in lightness.

- diverging:

  Character vector of 11 hex anchor stops with a light neutral midpoint
  and a symmetric lightness profile.

## Details

Colours are derived from the fifteen Queen studio album covers by
`data-raw/build_palettes.py`: covers are quantised in CIELAB, then each
palette is optimised so that its worst-case pairwise
[CIEDE2000](https://noahweidig.github.io/killerpals/reference/killer_distance.md)
separation under normal, deuteranopic, protanopic and tritanopic vision
stays above threshold, subject to WCAG contrast and lightness
constraints. See
[`vignette("killerPals")`](https://noahweidig.github.io/killerpals/articles/killerPals.md)
for the full derivation and the accessibility report.

## See also

[`killer_pal()`](https://noahweidig.github.io/killerpals/reference/killer_pal.md)
to draw colours from these definitions,
[`killer_palette_info()`](https://noahweidig.github.io/killerpals/reference/killer_palette_info.md)
for a tidy overview.

## Examples

``` r
names(killer_palettes)
#>  [1] "regina"        "mirror_queen"  "heart_attack"  "opera_night"  
#>  [5] "race_day"      "robot_news"    "all_that_jazz" "game_on"      
#>  [9] "flash"         "hot_space"     "the_works"     "kind_of_magic"
#> [13] "miracle"       "innuendo"      "heavenly"      "greatest_hits"
killer_palettes$flash$qualitative
#> [1] "#EDB900" "#416D8C" "#75291A" "#D8D3AD" "#8CC5E9" "#755E5D" "#687E11"
#> [8] "#9A8D7B"
killer_palettes$opera_night$album
#> [1] "A Night at the Opera"
```
