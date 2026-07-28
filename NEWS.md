# killerPals 0.1.0

First release.

* 48 palettes: a `qualitative`, `sequential` and `diverging` palette for each of
  Queen's fifteen studio albums, plus a `greatest_hits` family drawn from the
  whole catalogue.
* Palettes are derived from the album covers by `data-raw/build_palettes.py`,
  which optimises each one for worst-case CIEDE2000 separation under simulated
  deuteranopic, protanopic and tritanopic vision, subject to WCAG contrast and
  lightness constraints.
* `killer_pal()` and `killer_pal_fun()` to get colours; `killer_names()` and
  `killer_palette_info()` to browse them.
* ggplot2 scales for discrete (`_d`), continuous (`_c`) and binned (`_b`)
  aesthetics, in `scale_colour_*` / `scale_fill_*` form with `scale_color_*`
  aliases.
* Accessibility tooling: `killer_check()`, `killer_cvd()`, `killer_cvd_grid()`,
  `killer_distance()`, `killer_distance_matrix()`, `killer_contrast()` and
  `killer_luminance()` — all of which work on arbitrary colours, not just this
  package's.
