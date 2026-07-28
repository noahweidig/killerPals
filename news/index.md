# Changelog

## killerPals 0.1.0

First release.

- 48 palettes: a `qualitative`, `sequential` and `diverging` palette for
  each of Queen’s fifteen studio albums, plus a `greatest_hits` family
  drawn from the whole catalogue.
- Palettes are derived from the album covers by
  `data-raw/build_palettes.py`, which optimises each one for worst-case
  CIEDE2000 separation under simulated deuteranopic, protanopic and
  tritanopic vision, subject to WCAG contrast and lightness constraints.
- [`killer_pal()`](https://noahweidig.github.io/killerpals/reference/killer_pal.md)
  and
  [`killer_pal_fun()`](https://noahweidig.github.io/killerpals/reference/killer_pal_fun.md)
  to get colours;
  [`killer_names()`](https://noahweidig.github.io/killerpals/reference/killer_names.md)
  and
  [`killer_palette_info()`](https://noahweidig.github.io/killerpals/reference/killer_palette_info.md)
  to browse them.
- ggplot2 scales for discrete (`_d`), continuous (`_c`) and binned
  (`_b`) aesthetics, in `scale_colour_*` / `scale_fill_*` form with
  `scale_color_*` aliases.
- Accessibility tooling:
  [`killer_check()`](https://noahweidig.github.io/killerpals/reference/killer_check.md),
  [`killer_cvd()`](https://noahweidig.github.io/killerpals/reference/killer_cvd.md),
  [`killer_cvd_grid()`](https://noahweidig.github.io/killerpals/reference/killer_cvd_grid.md),
  [`killer_distance()`](https://noahweidig.github.io/killerpals/reference/killer_distance.md),
  [`killer_distance_matrix()`](https://noahweidig.github.io/killerpals/reference/killer_distance_matrix.md),
  [`killer_contrast()`](https://noahweidig.github.io/killerpals/reference/killer_contrast.md)
  and
  [`killer_luminance()`](https://noahweidig.github.io/killerpals/reference/killer_luminance.md)
  — all of which work on arbitrary colours, not just this package’s.
