# Queen album palette scales for ggplot2

Drop-in `scale_*` replacements using the killerPals palettes.

## Usage

``` r
scale_colour_killer_d(
  palette = "greatest_hits",
  type = "qualitative",
  direction = 1,
  ...,
  aesthetics = "colour",
  na.value = "grey50"
)

scale_fill_killer_d(
  palette = "greatest_hits",
  type = "qualitative",
  direction = 1,
  ...,
  aesthetics = "fill",
  na.value = "grey50"
)

scale_colour_killer_c(
  palette = "greatest_hits",
  type = c("sequential", "diverging"),
  direction = 1,
  ...,
  aesthetics = "colour",
  na.value = "grey50",
  guide = "colourbar"
)

scale_fill_killer_c(
  palette = "greatest_hits",
  type = c("sequential", "diverging"),
  direction = 1,
  ...,
  aesthetics = "fill",
  na.value = "grey50",
  guide = "colourbar"
)

scale_colour_killer_b(
  palette = "greatest_hits",
  type = c("sequential", "diverging"),
  direction = 1,
  ...,
  aesthetics = "colour",
  na.value = "grey50",
  guide = "coloursteps"
)

scale_fill_killer_b(
  palette = "greatest_hits",
  type = c("sequential", "diverging"),
  direction = 1,
  ...,
  aesthetics = "fill",
  na.value = "grey50",
  guide = "coloursteps"
)

scale_color_killer_d(
  palette = "greatest_hits",
  type = "qualitative",
  direction = 1,
  ...,
  aesthetics = "colour",
  na.value = "grey50"
)

scale_color_killer_c(
  palette = "greatest_hits",
  type = c("sequential", "diverging"),
  direction = 1,
  ...,
  aesthetics = "colour",
  na.value = "grey50",
  guide = "colourbar"
)

scale_color_killer_b(
  palette = "greatest_hits",
  type = c("sequential", "diverging"),
  direction = 1,
  ...,
  aesthetics = "colour",
  na.value = "grey50",
  guide = "coloursteps"
)
```

## Arguments

- palette:

  Palette name, e.g. `"flash"`. See
  [`killer_names()`](https://noahweidig.github.io/killerpals/reference/killer_names.md).

- type:

  Palette type to draw from. Discrete scales default to `"qualitative"`;
  continuous and binned scales default to `"sequential"` and accept
  `"diverging"` for data with a meaningful midpoint.

- direction:

  `1` for the palette's natural order, `-1` to reverse it.

- ...:

  Passed on to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html),
  [`ggplot2::continuous_scale()`](https://ggplot2.tidyverse.org/reference/continuous_scale.html)
  or
  [`ggplot2::binned_scale()`](https://ggplot2.tidyverse.org/reference/binned_scale.html).

- aesthetics:

  Character string or vector of aesthetics to apply the scale to. Useful
  for e.g. `c("colour", "fill")`.

- na.value:

  Colour for missing values.

- guide:

  Guide to use. See
  [`ggplot2::guides()`](https://ggplot2.tidyverse.org/reference/guides.html).

## Value

A ggplot2 scale, to be added to a plot with `+`.

## Details

The suffix follows the ggplot2 convention:

- `_d`:

  **discrete** - one colour per category, from the palette's qualitative
  colours.

- `_c`:

  **continuous** - a smooth gradient, interpolated through CIELAB.

- `_b`:

  **binned** - a continuous variable cut into bins.

`scale_color_*` spellings are provided as aliases for every
`scale_colour_*`.

## See also

[`killer_pal()`](https://noahweidig.github.io/killerpals/reference/killer_pal.md)
for the underlying colours.

## Examples

``` r
library(ggplot2)

# Discrete / qualitative
ggplot(mpg, aes(displ, hwy, colour = class)) +
  geom_point() +
  scale_colour_killer_d("greatest_hits")


# Continuous / sequential
ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_raster() +
  scale_fill_killer_c("heavenly")


# Continuous / diverging, centred on zero
df <- data.frame(x = 1:20, y = 1:20, z = seq(-5, 5, length.out = 20))
ggplot(df, aes(x, y, colour = z)) +
  geom_point(size = 4) +
  scale_colour_killer_c("innuendo", type = "diverging",
                        limits = c(-5, 5))


# Binned
ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_raster() +
  scale_fill_killer_b("flash")
```
