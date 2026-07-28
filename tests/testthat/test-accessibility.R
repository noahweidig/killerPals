# These tests are the package's contract: if a future change to the palette
# derivation regresses colourblind separation or contrast, these fail.

test_that("qualitative palettes stay separable under every vision type", {
  for (name in killer_names()) {
    chk <- killer_check(name, type = "qualitative")
    for (kind in names(chk$min_distance)) {
      # 10 CIEDE2000 units is comfortably "different at a glance".
      expect_gt(chk$min_distance[[kind]], 10)
    }
  }
})

test_that("the per-album palettes clear the stricter build-time threshold", {
  # `greatest_hits` trades a little separation for having the most colours, so
  # it is held to the looser bar above rather than this one.
  for (name in setdiff(killer_names(), "greatest_hits")) {
    chk <- killer_check(name, type = "qualitative")
    expect_gt(min(chk$min_distance), 15)
  }
})

test_that("every qualitative colour has usable contrast on light or dark", {
  for (name in killer_names()) {
    chk <- killer_check(name, type = "qualitative")
    # WCAG 2.2 non-text contrast minimum is 3:1 against the background; each
    # swatch must clear it against white or black, so the palette works on both.
    expect_gte(min(pmax(chk$contrast_white, chk$contrast_black)), 3.0)
  }
})

test_that("qualitative palettes avoid extremes of lightness", {
  for (name in killer_names()) {
    L <- killer_check(name, type = "qualitative")$lightness
    expect_gte(min(L), 25)
    expect_lte(max(L), 87)
  }
})

test_that("sequential ramps span a wide lightness range", {
  for (name in killer_names()) {
    L <- killer_check(name, type = "sequential")$lightness
    # A narrow range would make the ramp unreadable in greyscale.
    expect_gt(max(L) - min(L), 55)
  }
})

test_that("diverging arms remain distinguishable under every vision type", {
  for (name in killer_names()) {
    div <- as.character(killer_pal(name, 11L, "diverging"))
    lo <- div[1]
    hi <- div[11]
    for (kind in c("normal", "deutan", "protan", "tritan")) {
      d <- killer_distance(killer_cvd(lo, kind), killer_cvd(hi, kind))
      # The arms are dark and saturated, where CIEDE2000 compresses; 18 is the
      # bar the derivation actually achieves for all 16 families, with the
      # tightest (miracle, all_that_jazz) around 21.
      expect_gt(d, 18)
    }
  }
})

test_that("no two albums ship the same sequential ramp or diverging pair", {
  seqs <- vapply(killer_names(),
                 function(n) paste(killer_palettes[[n]]$sequential, collapse = ""),
                 character(1))
  expect_false(anyDuplicated(seqs) > 0)

  divs <- vapply(killer_names(), function(n) {
    d <- killer_palettes[[n]]$diverging
    paste(d[1], d[length(d)])
  }, character(1))
  expect_false(anyDuplicated(divs) > 0)
})

test_that("killer_cvd simulates and respects severity", {
  pal <- as.character(killer_pal("flash"))
  expect_equal(killer_cvd(pal, "normal"), pal)
  expect_equal(killer_cvd(pal, "deutan", severity = 0), pal)

  sim <- killer_cvd(pal, "deutan")
  expect_true(all(grepl("^#[0-9A-F]{6}$", sim)))
  expect_length(sim, length(pal))
  expect_false(identical(sim, pal))

  # Deuteranopia should collapse red/green separation, never widen it.
  red_green <- c("#FF0000", "#00FF00")
  expect_lt(
    killer_distance(killer_cvd(red_green[1], "deutan"),
                    killer_cvd(red_green[2], "deutan")),
    killer_distance(red_green[1], red_green[2])
  )

  expect_error(killer_cvd(pal, "deutan", severity = 2), "between 0 and 1")
})

test_that("killer_distance matches known CIEDE2000 behaviour", {
  expect_equal(killer_distance("#FF0000", "#FF0000"), 0, tolerance = 1e-8)
  # Identical colours are 0; wildly different ones are large.
  expect_gt(killer_distance("#FF0000", "#00FF00"), 50)
  # Sharma et al. (2005) test pair 1: dE00 = 2.0425
  expect_equal(
    ciede2000(matrix(c(50.0000, 2.6772, -79.7751), nrow = 1),
              matrix(c(50.0000, 0.0000, -82.7485), nrow = 1)),
    2.0425,
    tolerance = 1e-3
  )
  # Further pairs from the same reference data set.
  expect_equal(
    ciede2000(matrix(c(50.0000, -1.3802, -84.2814), nrow = 1),
              matrix(c(50.0000, 0.0000, -82.7485), nrow = 1)),
    1.0000,
    tolerance = 1e-3
  )
  expect_equal(
    ciede2000(matrix(c(22.7233, 20.0904, -46.6940), nrow = 1),
              matrix(c(23.0331, 14.9730, -42.5619), nrow = 1)),
    2.0373,
    tolerance = 1e-3
  )
  # Near-black pair, where the lightness weighting dominates.
  expect_equal(
    ciede2000(matrix(c(2.0776, 0.0795, -1.1350), nrow = 1),
              matrix(c(0.9033, -0.0636, -0.5514), nrow = 1)),
    0.9082,
    tolerance = 1e-3
  )
})

test_that("contrast and luminance match the WCAG definitions", {
  expect_equal(killer_luminance("white"), 1, tolerance = 1e-6)
  expect_equal(killer_luminance("black"), 0, tolerance = 1e-6)
  # White on black is the maximum possible ratio, 21:1.
  expect_equal(killer_contrast("white", "black"), 21, tolerance = 1e-6)
  expect_equal(killer_contrast("red", "red"), 1, tolerance = 1e-6)
  expect_length(killer_contrast(killer_pal("flash"), "white"), 8L)
})

test_that("killer_check works on arbitrary colours and prints", {
  chk <- killer_check(colours = c("red", "green", "blue"))
  expect_s3_class(chk, "killer_check")
  expect_length(chk$colours, 3L)
  expect_true(is.na(chk$palette))
  expect_output(print(chk), "custom colours")

  expect_output(print(killer_check("flash")), "flash")
  expect_true(killer_check("heavenly", type = "sequential")$monotone_lightness)
  expect_false(killer_check("heavenly", type = "diverging")$monotone_lightness)
})

test_that("killer_cvd_grid draws and returns the simulated colours", {
  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp)
  on.exit(unlink(tmp), add = TRUE)
  sim <- killer_cvd_grid("greatest_hits")
  grDevices::dev.off()

  expect_equal(dim(sim), c(4L, length(killer_pal("greatest_hits"))))
  expect_equal(rownames(sim), c("normal", "deutan", "protan", "tritan"))
})
