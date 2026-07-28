#' Queen album palette definitions
#'
#' The colour data behind every [killer_pal()] palette. One element per palette
#' family, named after the palette (not the album), in release order, with
#' `greatest_hits` last.
#'
#' Colours are derived from the fifteen Queen studio album covers by
#' `data-raw/build_palettes.py`: covers are quantised in CIELAB, then each
#' palette is optimised so that its worst-case pairwise
#' [CIEDE2000][killer_distance()] separation under normal, deuteranopic,
#' protanopic and tritanopic vision stays above threshold, subject to WCAG
#' contrast and lightness constraints. See `vignette("killerPals")` for the full
#' derivation and the accessibility report.
#'
#' @format A named list of 16 palette families. Each element is a list of:
#' \describe{
#'   \item{album}{Album title, as a string.}
#'   \item{year}{Release year, as an integer.}
#'   \item{blurb}{One-line description of the palette's character.}
#'   \item{qualitative}{Character vector of 8 hex colours (11 for
#'     `greatest_hits`) for unordered categories.}
#'   \item{sequential}{Character vector of 7 hex anchor stops, light to dark,
#'     strictly monotone in lightness.}
#'   \item{diverging}{Character vector of 11 hex anchor stops with a light
#'     neutral midpoint and a symmetric lightness profile.}
#' }
#'
#' @examples
#' names(killer_palettes)
#' killer_palettes$flash$qualitative
#' killer_palettes$opera_night$album
#' @seealso [killer_pal()] to draw colours from these definitions,
#'   [killer_palette_info()] for a tidy overview.
"killer_palettes"
