#' Palette types recognised by killerPals
#'
#' @keywords internal
#' @noRd
KILLER_TYPES <- c("qualitative", "sequential", "diverging")

#' Names of all available palettes
#'
#' @return A character vector of palette names, in album release order, with
#'   `"greatest_hits"` last.
#' @examples
#' killer_names()
#' @seealso [killer_palette_info()] for names alongside album and year.
#' @export
killer_names <- function() names(killer_palettes)

#' Overview of every palette
#'
#' @param type Optionally restrict to one palette type. One of
#'   `"qualitative"`, `"sequential"` or `"diverging"`.
#'
#' @return A data frame with one row per palette, containing the palette
#'   `name`, the source `album` and `year`, a short `blurb`, the number of
#'   colours defined (`n`) and the palette `type`.
#' @examples
#' head(killer_palette_info())
#' killer_palette_info(type = "diverging")
#' @export
killer_palette_info <- function(type = NULL) {
  types <- if (is.null(type)) {
    KILLER_TYPES
  } else {
    match.arg(type, KILLER_TYPES, several.ok = TRUE)
  }
  rows <- lapply(types, function(ty) {
    data.frame(
      name = killer_names(),
      album = vapply(killer_palettes, `[[`, character(1), "album"),
      year = vapply(killer_palettes, `[[`, integer(1), "year"),
      type = ty,
      n = vapply(killer_palettes, function(p) length(p[[ty]]), integer(1)),
      blurb = vapply(killer_palettes, `[[`, character(1), "blurb"),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })
  out <- do.call(rbind, rows)
  out[order(out$year, out$name, out$type), ]
}

#' Look up a palette definition
#'
#' @param palette Palette name.
#' @return The matching element of [killer_palettes].
#' @keywords internal
#' @noRd
killer_lookup <- function(palette) {
  if (!is.character(palette) || length(palette) != 1L || is.na(palette)) {
    stop("`palette` must be a single palette name.", call. = FALSE)
  }
  if (!palette %in% names(killer_palettes)) {
    # Offer the closest names, so a typo is cheap to recover from.
    near <- agrep(palette, names(killer_palettes), max.distance = 0.4, value = TRUE)
    hint <- if (length(near)) {
      paste0(" Did you mean ", paste0("\"", near, "\"", collapse = " or "), "?")
    } else {
      " See `killer_names()` for the available palettes."
    }
    stop("Unknown palette \"", palette, "\".", hint, call. = FALSE)
  }
  killer_palettes[[palette]]
}

#' Interpolate colours perceptually
#'
#' Ramps through CIELAB rather than RGB, so intermediate colours keep the
#' even lightness progression the palettes were built to have.
#'
#' @param colours Character vector of hex anchor stops.
#' @param n Number of colours to return.
#' @return A character vector of `n` hex colours.
#' @keywords internal
#' @noRd
killer_interpolate <- function(colours, n) {
  if (n == 1L) {
    # A single colour from a ramp should be the midpoint, not an endpoint.
    colours <- colours[ceiling(length(colours) / 2)]
    return(toupper(colours))
  }
  ramp <- grDevices::colorRamp(colours, space = "Lab", interpolate = "spline")
  vals <- ramp(seq(0, 1, length.out = n))
  vals[] <- pmin(pmax(vals, 0), 255)
  grDevices::rgb(vals[, 1], vals[, 2], vals[, 3], maxColorValue = 255)
}

#' Draw colours from a Queen album palette
#'
#' The workhorse behind every killerPals scale. Qualitative palettes return
#' their colours in a fixed order chosen so that consecutive colours contrast
#' strongly; sequential and diverging palettes are interpolated through CIELAB
#' to whatever length you ask for.
#'
#' @param palette Palette name, e.g. `"flash"` or `"opera_night"`. See
#'   [killer_names()].
#' @param n Number of colours to return. Defaults to every colour the palette
#'   defines. For `type = "qualitative"` this cannot exceed the number of
#'   colours available, because inventing extra categorical colours would
#'   silently break the palette's colourblind-safe separation.
#' @param type Palette type: `"qualitative"` for unordered categories,
#'   `"sequential"` for ordered low-to-high values, `"diverging"` for values
#'   spread either side of a meaningful midpoint.
#' @param direction `1` for the palette's natural order, `-1` to reverse it.
#'
#' @return A character vector of `n` hex colour strings, of class
#'   `killer_palette` so it prints as swatches.
#'
#' @examples
#' killer_pal("flash")
#' killer_pal("opera_night", n = 4)
#' killer_pal("heavenly", n = 9, type = "sequential")
#' killer_pal("innuendo", n = 5, type = "diverging", direction = -1)
#'
#' # All 48 palettes at a glance:
#' head(killer_palette_info())
#' @seealso [scale_colour_killer_d()] and friends for ggplot2 scales,
#'   [killer_check()] to audit a palette's accessibility.
#' @export
killer_pal <- function(palette = "greatest_hits",
                       n = NULL,
                       type = c("qualitative", "sequential", "diverging"),
                       direction = 1) {
  type <- match.arg(type)
  pal <- killer_lookup(palette)
  colours <- pal[[type]]

  if (!direction %in% c(-1, 1)) {
    stop("`direction` must be 1 or -1.", call. = FALSE)
  }

  if (is.null(n)) n <- length(colours)
  n <- as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }

  out <- if (type == "qualitative") {
    if (n > length(colours)) {
      stop(
        "Palette \"", palette, "\" defines ", length(colours),
        " qualitative colours; ", n, " requested.\n",
        "Use `type = \"sequential\"` for an interpolated ramp, or pick a ",
        "palette with more colours (see `killer_palette_info()`).",
        call. = FALSE
      )
    }
    colours[seq_len(n)]
  } else {
    killer_interpolate(colours, n)
  }

  if (direction == -1) out <- rev(out)
  structure(toupper(out), class = c("killer_palette", "character"),
            palette = palette, type = type)
}

#' Palette functions for programmatic use
#'
#' Returns a function of `n`, which is the shape ggplot2 and scales expect.
#' Rarely needed directly: the `scale_*_killer_*()` family calls this for you.
#'
#' @inheritParams killer_pal
#' @return A function taking a single argument `n` and returning that many hex
#'   colours.
#' @examples
#' pal <- killer_pal_fun("hot_space", type = "sequential")
#' pal(3)
#' pal(11)
#' @export
killer_pal_fun <- function(palette = "greatest_hits",
                           type = c("qualitative", "sequential", "diverging"),
                           direction = 1) {
  type <- match.arg(type)
  killer_lookup(palette)  # fail fast on a bad name, not on first use
  function(n) as.character(killer_pal(palette, n, type, direction))
}

#' @export
print.killer_palette <- function(x, ...) {
  pal <- attr(x, "palette")
  info <- killer_palettes[[pal]]
  cat("<killer_palette> ", pal, " (", attr(x, "type"), ", ", length(x), " colours)\n",
      "  ", info$album, " (", info$year, ") - ", info$blurb, "\n", sep = "")
  cat("  ", paste(unclass(x), collapse = " "), "\n", sep = "")
  invisible(x)
}

#' Plot a palette as swatches
#'
#' @param x A `killer_palette`, as returned by [killer_pal()].
#' @param ... Ignored.
#' @return `x`, invisibly. Called for its side effect of drawing a plot.
#' @examples
#' plot(killer_pal("all_that_jazz"))
#' plot(killer_pal("miracle", n = 9, type = "diverging"))
#' @export
plot.killer_palette <- function(x, ...) {
  n <- length(x)
  op <- graphics::par(mar = c(2.5, 0.5, 2.5, 0.5))
  on.exit(graphics::par(op), add = TRUE)
  graphics::plot(
    c(0, n), c(0, 1), type = "n", axes = FALSE, xlab = "", ylab = "",
    main = paste0(attr(x, "palette"), " (", attr(x, "type"), ")")
  )
  graphics::rect(seq_len(n) - 1, 0, seq_len(n), 1, col = unclass(x), border = NA)
  graphics::text(seq_len(n) - 0.5, -0.08, labels = unclass(x),
                 srt = 90, adj = 1, xpd = NA, cex = 0.65)
  invisible(x)
}
