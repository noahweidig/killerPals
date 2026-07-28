# Render man/figures/logo.png -- the hex sticker for killerPals.
#
# The design is original and Queen-*inspired*: a crown whose tines are built
# from the package's own palette colours, over a deep stage-purple hex. It
# deliberately does not reproduce Queen's crest, which is a trademark.
#
# Run with: make logo

library(grid)

load(file.path("data", "killer_palettes.rda"))

W <- 1200L
H <- as.integer(round(W * 2 / sqrt(3)))  # standard hex-sticker aspect ratio
OUT <- file.path("man", "figures", "logo.png")
dir.create(dirname(OUT), recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------- geometry ---

# A pointy-top hexagon filling the canvas. Because the canvas already has the
# hex aspect ratio, the vertices in npc are exact constants: the two points sit
# at the vertical extremes and the four shoulders a quarter of the way in.
hex_x <- c(0.5, 1, 1, 0.5, 0, 0)
hex_y <- c(1, 0.75, 0.25, 0, 0.25, 0.75)

# Inset copy of the hexagon, for the border and vignette.
hex_inset <- function(f) {
  list(x = 0.5 + (hex_x - 0.5) * f, y = 0.5 + (hex_y - 0.5) * f)
}

# ------------------------------------------------------------------ palette ---

# The crown tines are the most colourful swatches the package ships, ordered
# around the hue wheel, so the logo is literally made of killerPals colours.
all_qual <- unlist(lapply(killer_palettes, `[[`, "qualitative"), use.names = FALSE)
lab <- grDevices::convertColor(t(grDevices::col2rgb(all_qual)) / 255,
                               from = "sRGB", to = "Lab")
chroma <- sqrt(lab[, 2]^2 + lab[, 3]^2)
hue <- atan2(lab[, 3], lab[, 2]) %% (2 * pi)

# Take the most chromatic colour from each of five hue sectors, so the crown
# spans the wheel instead of clustering in one corner.
sector <- cut(hue, breaks = seq(0, 2 * pi, length.out = 6), labels = FALSE)
pick <- vapply(1:5, function(s) {
  idx <- which(sector == s)
  idx[which.max(chroma[idx])]
}, integer(1))
crown_cols <- all_qual[pick[order(hue[pick])]]

gold <- "#E8C15A"
ink <- "#0B0712"
deep <- "#241033"

grDevices::png(OUT, width = W, height = H, bg = "transparent", res = 300)
pushViewport(viewport())

# --- hex body ---------------------------------------------------------------
grid.polygon(hex_x, hex_y, gp = gpar(fill = ink, col = NA))
# A soft vignette: a few concentric translucent hexes, brightest in the middle.
for (f in seq(0.95, 0.15, length.out = 14)) {
  h <- hex_inset(f)
  grid.polygon(h$x, h$y,
               gp = gpar(fill = grDevices::adjustcolor(deep, alpha.f = 0.06),
                         col = NA))
}

# --- the crown --------------------------------------------------------------
# Five tapering tines on a solid band: reads as a crown, and as a bar chart.
n <- length(crown_cols)
cx <- 0.5
span <- 0.46
bw <- span / n
heights <- c(0.15, 0.21, 0.26, 0.21, 0.15)
base_y <- 0.545
band_h <- 0.052
taper <- 0.42  # tine top width, as a fraction of its base

for (i in seq_len(n)) {
  x0 <- cx - span / 2 + (i - 1) * bw
  xm <- x0 + bw / 2
  half_top <- bw * taper / 2
  grid.polygon(
    x = c(x0 + bw * 0.04, x0 + bw * 0.96, xm + half_top, xm - half_top),
    y = c(base_y, base_y, base_y + heights[i], base_y + heights[i]),
    gp = gpar(fill = crown_cols[i], col = NA)
  )
  # A gold orb capping each tine, overlapping it so it reads as attached.
  grid.circle(xm, base_y + heights[i] + 0.011, r = 0.0135,
              gp = gpar(fill = gold, col = NA))
}

# Crown band, rimmed in gold top and bottom.
band_w <- span + bw * 0.35
grid.rect(cx, base_y - band_h / 2, width = band_w, height = band_h,
          gp = gpar(fill = deep, col = NA))
for (y in c(base_y, base_y - band_h)) {
  grid.rect(cx, y, width = band_w, height = 0.007,
            gp = gpar(fill = gold, col = NA))
}
# Three gems set into the band, from the crown's own colours.
for (i in c(2, 3, 4)) {
  grid.circle(cx + (i - 3) * bw, base_y - band_h / 2, r = 0.011,
              gp = gpar(fill = crown_cols[i], col = NA))
}

# --- wordmark ---------------------------------------------------------------
grid.text("killerPals", x = 0.5, y = 0.375,
          gp = gpar(col = "white", fontsize = 34, fontface = "bold",
                    fontfamily = "sans"))
grid.text("QUEEN ALBUM PALETTES", x = 0.5, y = 0.315,
          gp = gpar(col = gold, fontsize = 8.6, fontface = "bold",
                    fontfamily = "sans"))

# --- a swatch strip, as a footer --------------------------------------------
# The crown's own five colours, in wide blocks: the full greatest_hits strip
# includes near-neutrals that blur into a smudge at favicon size.
sw <- 0.30 / length(crown_cols)
for (i in seq_along(crown_cols)) {
  grid.rect(0.5 - 0.15 + (i - 0.5) * sw, 0.25, width = sw * 0.92, height = 0.019,
            gp = gpar(fill = crown_cols[i], col = NA))
}

# --- hex border -------------------------------------------------------------
grid.polygon(hex_x, hex_y, gp = gpar(fill = NA, col = gold, lwd = 6))

popViewport()
grDevices::dev.off()

cat("wrote ", OUT, " (", W, "x", H, ")\n", sep = "")
