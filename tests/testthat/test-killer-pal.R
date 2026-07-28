test_that("killer_pal returns the requested number of colours", {
  expect_length(killer_pal("flash"), 8L)
  expect_length(killer_pal("flash", n = 3), 3L)
  expect_length(killer_pal("flash", n = 20, type = "sequential"), 20L)
  expect_length(killer_pal("flash", n = 2, type = "diverging"), 2L)
})

test_that("qualitative palettes keep their defined order and colours", {
  expect_equal(
    as.character(killer_pal("hot_space")),
    killer_palettes$hot_space$qualitative
  )
  expect_equal(
    as.character(killer_pal("hot_space", n = 3)),
    killer_palettes$hot_space$qualitative[1:3]
  )
})

test_that("direction = -1 reverses the palette", {
  expect_equal(
    as.character(killer_pal("miracle", direction = -1)),
    rev(as.character(killer_pal("miracle")))
  )
  expect_equal(
    as.character(killer_pal("miracle", n = 5, type = "sequential", direction = -1)),
    rev(as.character(killer_pal("miracle", n = 5, type = "sequential")))
  )
})

test_that("asking a qualitative palette for too many colours is an error", {
  n <- length(killer_palettes$flash$qualitative)
  expect_error(killer_pal("flash", n = n + 1L), "qualitative colours")
  # ...but the ramps will happily interpolate that far.
  expect_length(killer_pal("flash", n = n + 5L, type = "sequential"), n + 5L)
})

test_that("unknown palettes fail with a helpful message", {
  expect_error(killer_pal("not_an_album"), "Unknown palette")
  expect_error(killer_pal("flsh"), "Did you mean")
  expect_error(killer_pal(c("a", "b")), "single palette name")
  expect_error(killer_pal("flash", n = 0), "positive integer")
  expect_error(killer_pal("flash", direction = 2), "must be 1 or -1")
})

test_that("interpolation of a single colour gives the ramp midpoint", {
  seq7 <- killer_palettes$heavenly$sequential
  expect_equal(as.character(killer_pal("heavenly", 1, "sequential")),
               toupper(seq7[4]))
})

test_that("sequential ramps stay monotone in lightness at any length", {
  for (name in killer_names()) {
    for (n in c(5L, 7L, 13L, 30L)) {
      L <- killer_check(name, n = n, type = "sequential")$lightness
      expect_true(all(diff(L) < 0.001),
                  info = paste(name, "n =", n))
    }
  }
})

test_that("diverging ramps are light in the middle and dark at both ends", {
  for (name in killer_names()) {
    L <- killer_check(name, n = 11L, type = "diverging")$lightness
    expect_gt(L[6], L[1])
    expect_gt(L[6], L[11])
    # Each arm must be monotone, so the scale degrades sensibly to greyscale.
    expect_true(all(diff(L[1:6]) > 0), info = name)
    expect_true(all(diff(L[6:11]) < 0), info = name)
  }
})

test_that("killer_pal_fun is a palette function of n", {
  f <- killer_pal_fun("all_that_jazz", "sequential")
  expect_type(f, "closure")
  expect_length(f(4), 4L)
  expect_equal(f(6), as.character(killer_pal("all_that_jazz", 6, "sequential")))
  expect_error(killer_pal_fun("nope"), "Unknown palette")
})

test_that("print and plot methods work", {
  pal <- killer_pal("regina")
  expect_s3_class(pal, "killer_palette")
  expect_output(print(pal), "regina")
  expect_output(print(pal), "Queen")

  tmp <- tempfile(fileext = ".png")
  grDevices::png(tmp)
  on.exit(unlink(tmp), add = TRUE)
  expect_invisible(plot(pal))
  grDevices::dev.off()
  expect_true(file.exists(tmp))
})
