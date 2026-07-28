skip_if_not_installed("ggplot2")

library(ggplot2)

test_that("discrete scales build and use the palette colours", {
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) +
    geom_point() +
    scale_colour_killer_d("flash")
  built <- ggplot_build(p)
  used <- unique(built$data[[1]]$colour)
  expect_true(all(used %in% killer_palettes$flash$qualitative))
  expect_length(used, 3L)
})

test_that("fill and colour discrete scales apply to the right aesthetic", {
  d <- data.frame(g = c("a", "b", "c"), y = 1:3)
  fills <- unique(ggplot_build(
    ggplot(d, aes(g, y, fill = g)) + geom_col() + scale_fill_killer_d("hot_space")
  )$data[[1]]$fill)
  expect_true(all(fills %in% killer_palettes$hot_space$qualitative))
})

test_that("direction reverses the mapping", {
  d <- data.frame(g = c("a", "b", "c"), y = 1:3)
  fwd <- ggplot_build(ggplot(d, aes(g, y, fill = g)) + geom_col() +
                        scale_fill_killer_d("regina"))$data[[1]]$fill
  rev_ <- ggplot_build(ggplot(d, aes(g, y, fill = g)) + geom_col() +
                         scale_fill_killer_d("regina", direction = -1))$data[[1]]$fill
  expect_false(identical(fwd, rev_))
})

test_that("continuous scales build for sequential and diverging", {
  d <- data.frame(x = 1:10, y = 1:10, z = seq(-3, 3, length.out = 10))

  p <- ggplot(d, aes(x, y, colour = z)) + geom_point() +
    scale_colour_killer_c("heavenly")
  expect_s3_class(ggplot_build(p), "ggplot_built")

  p2 <- ggplot(d, aes(x, y, colour = z)) + geom_point() +
    scale_colour_killer_c("innuendo", type = "diverging", limits = c(-3, 3))
  cols <- ggplot_build(p2)$data[[1]]$colour
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", cols)))
  # Symmetric limits put the palette's light midpoint at z = 0.
  mid <- cols[which.min(abs(d$z))]
  expect_gt(killer_luminance(mid), 0.7)
})

test_that("diverging continuous scales nudge the user about limits", {
  d <- data.frame(x = 1:5, y = 1:5, z = c(-2, -1, 0, 1, 5))
  expect_message(
    ggplot(d, aes(x, y, colour = z)) + geom_point() +
      scale_colour_killer_c("innuendo", type = "diverging"),
    "midpoint"
  )
  expect_silent(
    ggplot(d, aes(x, y, colour = z)) + geom_point() +
      scale_colour_killer_c("innuendo", type = "diverging", limits = c(-5, 5))
  )
  # Sequential scales have no midpoint to get wrong, so they stay quiet.
  expect_silent(
    ggplot(d, aes(x, y, colour = z)) + geom_point() +
      scale_colour_killer_c("innuendo")
  )
})

test_that("binned scales build", {
  d <- data.frame(x = 1:20, y = 1:20, z = 1:20)
  p <- ggplot(d, aes(x, y, fill = z)) + geom_raster() + scale_fill_killer_b("flash")
  expect_s3_class(ggplot_build(p), "ggplot_built")
  p2 <- ggplot(d, aes(x, y, colour = z)) + geom_point() +
    scale_colour_killer_b("flash")
  expect_s3_class(ggplot_build(p2), "ggplot_built")
})

test_that("continuous scales reject the qualitative type", {
  expect_error(scale_colour_killer_c("flash", type = "qualitative"), "'arg'")
  expect_error(scale_fill_killer_b("flash", type = "qualitative"), "'arg'")
})

test_that("US spellings are aliases of the British ones", {
  expect_identical(scale_color_killer_d, scale_colour_killer_d)
  expect_identical(scale_color_killer_c, scale_colour_killer_c)
  expect_identical(scale_color_killer_b, scale_colour_killer_b)
})

test_that("scales pass ... through to ggplot2", {
  d <- data.frame(g = c("a", "b"), y = 1:2)
  p <- ggplot(d, aes(g, y, fill = g)) + geom_col() +
    scale_fill_killer_d("flash", name = "My legend")
  expect_equal(ggplot_build(p)$plot$scales$scales[[1]]$name, "My legend")
})

test_that("a bad palette name fails when the scale is created, not at draw time", {
  expect_error(scale_colour_killer_d("no_such_album"), "Unknown palette")
  expect_error(scale_fill_killer_c("no_such_album"), "Unknown palette")
})

test_that("scales can be applied to several aesthetics at once", {
  d <- data.frame(g = c("a", "b", "c"), y = 1:3)
  p <- ggplot(d, aes(g, y, colour = g, fill = g)) + geom_col() +
    scale_colour_killer_d("miracle", aesthetics = c("colour", "fill"))
  built <- ggplot_build(p)$data[[1]]
  expect_equal(built$colour, built$fill)
})
