test_that("every album has a palette family with all three types", {
  expect_length(killer_palettes, 16L)
  for (name in killer_names()) {
    p <- killer_palettes[[name]]
    expect_named(p, c("album", "year", "blurb", "qualitative", "sequential", "diverging"),
                 info = name)
    expect_type(p$album, "character")
    expect_type(p$year, "integer")
    expect_true(nzchar(p$blurb), info = name)
    for (ty in c("qualitative", "sequential", "diverging")) {
      expect_gte(length(p[[ty]]), 7L)
    }
  }
})

test_that("all fifteen studio albums are represented", {
  albums <- vapply(killer_palettes, `[[`, character(1), "album")
  expect_setequal(
    setdiff(albums, "Greatest Hits"),
    c("Queen", "Queen II", "Sheer Heart Attack", "A Night at the Opera",
      "A Day at the Races", "News of the World", "Jazz", "The Game",
      "Flash Gordon", "Hot Space", "The Works", "A Kind of Magic",
      "The Miracle", "Innuendo", "Made in Heaven")
  )
})

test_that("every colour is a valid 6-digit uppercase hex string", {
  for (name in killer_names()) {
    for (ty in c("qualitative", "sequential", "diverging")) {
      cols <- killer_palettes[[name]][[ty]]
      expect_true(all(grepl("^#[0-9A-F]{6}$", cols)),
                  info = paste(name, ty))
      # A duplicate colour inside one palette would silently merge two groups.
      expect_false(anyDuplicated(cols) > 0, info = paste(name, ty))
    }
  }
})

test_that("palette names are unique, snake_case, and album-flavoured", {
  expect_false(anyDuplicated(killer_names()) > 0)
  expect_true(all(grepl("^[a-z][a-z_]*[a-z]$", killer_names())))
})

test_that("diverging palettes have an odd length and a light midpoint", {
  for (name in killer_names()) {
    div <- killer_palettes[[name]]$diverging
    expect_true(length(div) %% 2L == 1L, info = name)
    mid <- div[(length(div) + 1L) / 2L]
    # The midpoint must read as "no signal": near-white and low chroma.
    expect_gt(killer_luminance(mid), 0.8)
    expect_lt(max(killer_distance_matrix(c(mid, "#FFFFFF")), na.rm = TRUE), 12)
  }
})

test_that("killer_palette_info covers every palette and type", {
  info <- killer_palette_info()
  expect_s3_class(info, "data.frame")
  expect_equal(nrow(info), 16L * 3L)
  expect_setequal(info$type, c("qualitative", "sequential", "diverging"))
  expect_setequal(unique(info$name), killer_names())

  one <- killer_palette_info(type = "diverging")
  expect_equal(nrow(one), 16L)
  expect_true(all(one$type == "diverging"))
})
