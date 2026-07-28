#' Queen album palette scales for ggplot2
#'
#' Drop-in `scale_*` replacements using the killerPals palettes.
#'
#' The suffix follows the ggplot2 convention:
#' \describe{
#'   \item{`_d`}{**discrete** - one colour per category, from the palette's
#'     qualitative colours.}
#'   \item{`_c`}{**continuous** - a smooth gradient, interpolated through
#'     CIELAB.}
#'   \item{`_b`}{**binned** - a continuous variable cut into bins.}
#' }
#'
#' `scale_color_*` spellings are provided as aliases for every
#' `scale_colour_*`.
#'
#' @param palette Palette name, e.g. `"flash"`. See [killer_names()].
#' @param type Palette type to draw from. Discrete scales default to
#'   `"qualitative"`; continuous and binned scales default to `"sequential"`
#'   and accept `"diverging"` for data with a meaningful midpoint.
#' @param direction `1` for the palette's natural order, `-1` to reverse it.
#' @param ... Passed on to [ggplot2::discrete_scale()],
#'   [ggplot2::continuous_scale()] or [ggplot2::binned_scale()].
#' @param aesthetics Character string or vector of aesthetics to apply the
#'   scale to. Useful for e.g. `c("colour", "fill")`.
#' @param na.value Colour for missing values.
#' @param guide Guide to use. See [ggplot2::guides()].
#'
#' @return A ggplot2 scale, to be added to a plot with `+`.
#'
#' @examplesIf requireNamespace("ggplot2", quietly = TRUE)
#' library(ggplot2)
#'
#' # Discrete / qualitative
#' ggplot(mpg, aes(displ, hwy, colour = class)) +
#'   geom_point() +
#'   scale_colour_killer_d("greatest_hits")
#'
#' # Continuous / sequential
#' ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
#'   geom_raster() +
#'   scale_fill_killer_c("heavenly")
#'
#' # Continuous / diverging, centred on zero
#' df <- data.frame(x = 1:20, y = 1:20, z = seq(-5, 5, length.out = 20))
#' ggplot(df, aes(x, y, colour = z)) +
#'   geom_point(size = 4) +
#'   scale_colour_killer_c("innuendo", type = "diverging",
#'                         limits = c(-5, 5))
#'
#' # Binned
#' ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
#'   geom_raster() +
#'   scale_fill_killer_b("flash")
#' @name scale_killer
#' @seealso [killer_pal()] for the underlying colours.
NULL

# A diverging scale is only meaningful when its midpoint sits at the centre of
# the value range, so remind the user to say where that is.
check_diverging_limits <- function(type, args) {
  if (identical(type, "diverging") && is.null(args$limits) && is.null(args$rescaler)) {
    message(
      "killerPals: diverging scales assume the palette midpoint is the centre ",
      "of the data range.\n  Set symmetric `limits`, or a `rescaler`, to pin ",
      "the midpoint where you mean it."
    )
  }
  invisible(NULL)
}

#' @rdname scale_killer
#' @export
scale_colour_killer_d <- function(palette = "greatest_hits",
                                  type = "qualitative",
                                  direction = 1,
                                  ...,
                                  aesthetics = "colour",
                                  na.value = "grey50") {
  ggplot2::discrete_scale(
    aesthetics = aesthetics,
    palette = killer_pal_fun(palette, type, direction),
    na.value = na.value,
    ...
  )
}

#' @rdname scale_killer
#' @export
scale_fill_killer_d <- function(palette = "greatest_hits",
                                type = "qualitative",
                                direction = 1,
                                ...,
                                aesthetics = "fill",
                                na.value = "grey50") {
  scale_colour_killer_d(palette, type, direction, ...,
                        aesthetics = aesthetics, na.value = na.value)
}

#' @rdname scale_killer
#' @export
scale_colour_killer_c <- function(palette = "greatest_hits",
                                  type = c("sequential", "diverging"),
                                  direction = 1,
                                  ...,
                                  aesthetics = "colour",
                                  na.value = "grey50",
                                  guide = "colourbar") {
  type <- match.arg(type)
  check_diverging_limits(type, list(...))
  colours <- as.character(killer_pal(palette, NULL, type, direction))
  ggplot2::continuous_scale(
    aesthetics = aesthetics,
    palette = scales::gradient_n_pal(colours, space = "Lab"),
    na.value = na.value,
    guide = guide,
    ...
  )
}

#' @rdname scale_killer
#' @export
scale_fill_killer_c <- function(palette = "greatest_hits",
                                type = c("sequential", "diverging"),
                                direction = 1,
                                ...,
                                aesthetics = "fill",
                                na.value = "grey50",
                                guide = "colourbar") {
  scale_colour_killer_c(palette, type, direction, ...,
                        aesthetics = aesthetics, na.value = na.value,
                        guide = guide)
}

#' @rdname scale_killer
#' @export
scale_colour_killer_b <- function(palette = "greatest_hits",
                                  type = c("sequential", "diverging"),
                                  direction = 1,
                                  ...,
                                  aesthetics = "colour",
                                  na.value = "grey50",
                                  guide = "coloursteps") {
  type <- match.arg(type)
  check_diverging_limits(type, list(...))
  colours <- as.character(killer_pal(palette, NULL, type, direction))
  ramp <- scales::gradient_n_pal(colours, space = "Lab")
  ggplot2::binned_scale(
    aesthetics = aesthetics,
    palette = function(x) ramp(x),
    na.value = na.value,
    guide = guide,
    ...
  )
}

#' @rdname scale_killer
#' @export
scale_fill_killer_b <- function(palette = "greatest_hits",
                                type = c("sequential", "diverging"),
                                direction = 1,
                                ...,
                                aesthetics = "fill",
                                na.value = "grey50",
                                guide = "coloursteps") {
  scale_colour_killer_b(palette, type, direction, ...,
                        aesthetics = aesthetics, na.value = na.value,
                        guide = guide)
}

# ------------------------------------------------------------ US spellings

#' @rdname scale_killer
#' @export
scale_color_killer_d <- scale_colour_killer_d

#' @rdname scale_killer
#' @export
scale_color_killer_c <- scale_colour_killer_c

#' @rdname scale_killer
#' @export
scale_color_killer_b <- scale_colour_killer_b
