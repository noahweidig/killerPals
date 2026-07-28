# Render the palette swatch images used by the README and the pkgdown site.
#
# These generated graphics are what the package ships to illustrate the
# palettes. The album covers themselves are copyrighted artwork and are *not*
# redistributed: they are only ever read locally, by the derivation script.
#
# Run with: make swatches

library(grid)

load(file.path("data", "killer_palettes.rda"))

OUT <- file.path("man", "figures")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

pal_names <- names(killer_palettes)

#' Draw one labelled row of swatches.
swatch_row <- function(colours, y, h, x0, w, label = NULL, label_w = 0.22) {
  n <- length(colours)
  sw <- w / n
  for (i in seq_len(n)) {
    grid.rect(x0 + (i - 0.5) * sw, y, width = sw, height = h,
              gp = gpar(fill = colours[i], col = NA), default.units = "npc")
  }
  if (!is.null(label)) {
    grid.text(label, x = x0 - 0.012, y = y, just = "right",
              gp = gpar(fontsize = 7.6, fontfamily = "sans", col = "grey20"))
  }
}

# ------------------------------------------- one image: all palettes, all types

render_overview <- function(type, file, title) {
  n <- length(pal_names)
  grDevices::png(file.path(OUT, file), width = 1600, height = 40 * n + 90,
                 res = 150, bg = "white")
  pushViewport(viewport(y = 0.5))
  grid.text(title, x = 0.02, y = unit(1, "npc") - unit(14, "pt"), just = "left",
            gp = gpar(fontsize = 11, fontface = "bold", fontfamily = "sans"))

  top <- 0.90
  step <- top / n
  for (i in seq_along(pal_names)) {
    nm <- pal_names[i]
    swatch_row(killer_palettes[[nm]][[type]],
               y = top - (i - 0.5) * step,
               h = step * 0.66, x0 = 0.28, w = 0.70, label = nm)
  }
  popViewport()
  grDevices::dev.off()
  cat("wrote", file.path(OUT, file), "\n")
}

render_overview("qualitative", "palettes-qualitative.png",
                "Qualitative - unordered categories")
render_overview("sequential", "palettes-sequential.png",
                "Sequential - ordered, low to high")
render_overview("diverging", "palettes-diverging.png",
                "Diverging - either side of a midpoint")

# --------------------------------------- one image per palette: all three types

for (nm in pal_names) {
  p <- killer_palettes[[nm]]
  grDevices::png(file.path(OUT, paste0("pal-", nm, ".png")),
                 width = 1400, height = 300, res = 150, bg = "white")
  pushViewport(viewport())
  grid.text(paste0(nm, "  -  ", p$album, " (", p$year, ")"),
            x = 0.02, y = 0.93, just = "left",
            gp = gpar(fontsize = 10, fontface = "bold", fontfamily = "sans"))
  ys <- c(0.60, 0.40, 0.20)
  for (k in seq_along(c("qualitative", "sequential", "diverging"))) {
    ty <- c("qualitative", "sequential", "diverging")[k]
    swatch_row(p[[ty]], y = ys[k], h = 0.13, x0 = 0.22, w = 0.76, label = ty)
  }
  popViewport()
  grDevices::dev.off()
}
cat("wrote", length(pal_names), "per-palette swatch images\n")

# ------------------------------------------------- colour-vision comparison

grDevices::png(file.path(OUT, "cvd-greatest-hits.png"),
               width = 1400, height = 460, res = 150, bg = "white")
pushViewport(viewport())
cols <- killer_palettes$greatest_hits$qualitative
kinds <- c("normal", "deutan", "protan", "tritan")
grid.text("greatest_hits under simulated colour vision deficiency",
          x = 0.02, y = 0.94, just = "left",
          gp = gpar(fontsize = 10, fontface = "bold", fontfamily = "sans"))
for (i in seq_along(kinds)) {
  swatch_row(killerPals::killer_cvd(cols, kinds[i]),
             y = 0.76 - (i - 1) * 0.20, h = 0.15,
             x0 = 0.16, w = 0.80, label = kinds[i])
}
popViewport()
grDevices::dev.off()
cat("wrote", file.path(OUT, "cvd-greatest-hits.png"), "\n")
