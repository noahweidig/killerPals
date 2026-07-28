#' Colour-vision-deficiency simulation matrices
#'
#' Machado, Oliveira & Fernandes (2009), severity 1.0, applied in linear RGB.
#' The same matrices the palettes were optimised against, so [killer_check()]
#' reproduces the build-time numbers exactly.
#'
#' @keywords internal
#' @noRd
CVD_MATRICES <- list(
  protan = matrix(c(
    0.152286, 1.052583, -0.204868,
    0.114503, 0.786281, 0.099216,
    -0.003882, -0.048116, 1.051998
  ), nrow = 3, byrow = TRUE),
  deutan = matrix(c(
    0.367322, 0.860646, -0.227968,
    0.280085, 0.672501, 0.047413,
    -0.011820, 0.042940, 0.968881
  ), nrow = 3, byrow = TRUE),
  tritan = matrix(c(
    1.255528, -0.076749, -0.178779,
    -0.078411, 0.930809, 0.147602,
    0.004733, 0.691367, 0.303900
  ), nrow = 3, byrow = TRUE)
)

srgb_to_linear <- function(x) ifelse(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055)^2.4)
linear_to_srgb <- function(x) {
  x <- pmin(pmax(x, 0), 1)
  ifelse(x <= 0.0031308, x * 12.92, 1.055 * x^(1 / 2.4) - 0.055)
}

#' Simulate how a palette looks with colour vision deficiency
#'
#' @param colours A character vector of colours, or a `killer_palette`.
#' @param type Which deficiency to simulate: `"deutan"` (red-green, the most
#'   common), `"protan"` (red-green), `"tritan"` (blue-yellow), or `"normal"`
#'   to pass the colours straight through.
#' @param severity Severity of the deficiency, from `0` (normal vision) to `1`
#'   (dichromacy).
#'
#' @return A character vector of hex colours the same length as `colours`.
#'
#' @examples
#' pal <- killer_pal("flash")
#' killer_cvd(pal, "deutan")
#' killer_cvd(pal, "tritan", severity = 0.6)
#'
#' # Compare a palette across all four vision types
#' killer_cvd_grid("greatest_hits")
#' @references
#' Machado, G. M., Oliveira, M. M., & Fernandes, L. A. F. (2009). A
#' physiologically-based model for simulation of color vision deficiency.
#' *IEEE Transactions on Visualization and Computer Graphics*, 15(6), 1291-1298.
#' \doi{10.1109/TVCG.2009.113}
#' @seealso [killer_check()] for a numeric accessibility audit.
#' @export
killer_cvd <- function(colours, type = c("deutan", "protan", "tritan", "normal"),
                       severity = 1) {
  type <- match.arg(type)
  if (!is.numeric(severity) || length(severity) != 1L ||
        is.na(severity) || severity < 0 || severity > 1) {
    stop("`severity` must be a single number between 0 and 1.", call. = FALSE)
  }
  hex <- toupper(grDevices::rgb(t(grDevices::col2rgb(colours)), maxColorValue = 255))
  if (type == "normal" || severity == 0) return(hex)

  rgb01 <- t(grDevices::col2rgb(colours)) / 255
  lin <- srgb_to_linear(rgb01)
  sim <- lin %*% t(CVD_MATRICES[[type]])
  # Linear blend between normal and full dichromacy, per Machado et al.
  out <- linear_to_srgb((1 - severity) * lin + severity * sim)
  toupper(grDevices::rgb(out[, 1], out[, 2], out[, 3], maxColorValue = 1))
}

#' Plot a palette under all four vision types
#'
#' Draws one row of swatches per vision type, so a palette can be eyeballed the
#' way its readers will actually see it.
#'
#' @inheritParams killer_pal
#' @param severity Severity of the simulated deficiency, from 0 to 1.
#' @return The simulated colours, invisibly, as a character matrix with one row
#'   per vision type. Called for its side effect of drawing a plot.
#' @examples
#' killer_cvd_grid("greatest_hits")
#' killer_cvd_grid("heavenly", n = 9, type = "sequential")
#' @export
killer_cvd_grid <- function(palette = "greatest_hits", n = NULL,
                            type = c("qualitative", "sequential", "diverging"),
                            direction = 1, severity = 1) {
  type <- match.arg(type)
  cols <- as.character(killer_pal(palette, n, type, direction))
  kinds <- c("normal", "deutan", "protan", "tritan")
  sim <- t(vapply(kinds, function(k) killer_cvd(cols, k, severity),
                  character(length(cols))))

  nk <- length(kinds)
  op <- graphics::par(mar = c(0.5, 5.5, 2.5, 0.5))
  on.exit(graphics::par(op), add = TRUE)
  graphics::plot(c(0, length(cols)), c(0, nk), type = "n", axes = FALSE,
                 xlab = "", ylab = "",
                 main = paste0(palette, " (", type, ")"))
  for (i in seq_len(nk)) {
    y <- nk - i
    graphics::rect(seq_along(cols) - 1, y + 0.1, seq_along(cols), y + 0.9,
                   col = sim[i, ], border = NA)
  }
  graphics::text(rep(-0.2, nk), seq(nk - 0.5, 0.5), labels = kinds,
                 adj = 1, xpd = NA, cex = 0.85)
  invisible(sim)
}

# ------------------------------------------------------------------- metrics

rgb_to_lab_mat <- function(colours) {
  rgb01 <- t(grDevices::col2rgb(colours)) / 255
  grDevices::convertColor(rgb01, from = "sRGB", to = "Lab")
}

#' CIEDE2000 colour difference
#'
#' The perceptual distance metric the palettes were optimised against. A
#' difference of roughly 1 is the smallest a person can notice; 10 or more is
#' comfortably distinguishable at a glance.
#'
#' @param a,b Character vectors of colours. Recycled against each other.
#' @return A numeric vector of CIEDE2000 differences.
#' @examples
#' killer_distance("#FF0000", "#00FF00")
#' killer_distance("#FF0000", "#FF0505")
#'
#' # How close are the two most similar colours in a palette?
#' min(killer_distance_matrix(killer_pal("flash")), na.rm = TRUE)
#' @references
#' Sharma, G., Wu, W., & Dalal, E. N. (2005). The CIEDE2000 color-difference
#' formula. *Color Research & Application*, 30(1), 21-30.
#' \doi{10.1002/col.20070}
#' @export
killer_distance <- function(a, b) {
  la <- rgb_to_lab_mat(a)
  lb <- rgb_to_lab_mat(b)
  n <- max(nrow(la), nrow(lb))
  la <- la[rep_len(seq_len(nrow(la)), n), , drop = FALSE]
  lb <- lb[rep_len(seq_len(nrow(lb)), n), , drop = FALSE]
  ciede2000(la, lb)
}

#' CIEDE2000 implementation
#'
#' @param lab1,lab2 Numeric matrices with columns L, a, b.
#' @keywords internal
#' @noRd
ciede2000 <- function(lab1, lab2) {
  L1 <- lab1[, 1]
  a1 <- lab1[, 2]
  b1 <- lab1[, 3]
  L2 <- lab2[, 1]
  a2 <- lab2[, 2]
  b2 <- lab2[, 3]

  C1 <- sqrt(a1^2 + b1^2)
  C2 <- sqrt(a2^2 + b2^2)
  Cbar <- (C1 + C2) / 2
  G <- 0.5 * (1 - sqrt(Cbar^7 / (Cbar^7 + 25^7 + 1e-12)))
  a1p <- (1 + G) * a1
  a2p <- (1 + G) * a2
  C1p <- sqrt(a1p^2 + b1^2)
  C2p <- sqrt(a2p^2 + b2^2)

  h1p <- (atan2(b1, a1p) * 180 / pi) %% 360
  h2p <- (atan2(b2, a2p) * 180 / pi) %% 360

  dLp <- L2 - L1
  dCp <- C2p - C1p
  dhp <- h2p - h1p
  dhp <- ifelse(dhp > 180, dhp - 360, ifelse(dhp < -180, dhp + 360, dhp))
  dhp <- ifelse(C1p * C2p == 0, 0, dhp)
  dHp <- 2 * sqrt(C1p * C2p) * sin(dhp * pi / 360)

  Lbarp <- (L1 + L2) / 2
  Cbarp <- (C1p + C2p) / 2
  hsum <- h1p + h2p
  hdiff <- abs(h1p - h2p)
  hbarp <- ifelse(
    C1p * C2p == 0, hsum,
    ifelse(hdiff <= 180, hsum / 2,
           ifelse(hsum < 360, (hsum + 360) / 2, (hsum - 360) / 2))
  )

  Tt <- 1 - 0.17 * cos((hbarp - 30) * pi / 180) +
    0.24 * cos(2 * hbarp * pi / 180) +
    0.32 * cos((3 * hbarp + 6) * pi / 180) -
    0.20 * cos((4 * hbarp - 63) * pi / 180)
  dtheta <- 30 * exp(-(((hbarp - 275) / 25)^2))
  Rc <- 2 * sqrt(Cbarp^7 / (Cbarp^7 + 25^7 + 1e-12))
  Sl <- 1 + (0.015 * (Lbarp - 50)^2) / sqrt(20 + (Lbarp - 50)^2)
  Sc <- 1 + 0.045 * Cbarp
  Sh <- 1 + 0.015 * Cbarp * Tt
  Rt <- -sin(2 * dtheta * pi / 180) * Rc

  # Unname: the Lab matrices carry column names that would otherwise leak into
  # the result and surprise callers comparing against a bare numeric.
  unname(sqrt((dLp / Sl)^2 + (dCp / Sc)^2 + (dHp / Sh)^2 +
                Rt * (dCp / Sc) * (dHp / Sh)))
}

#' Pairwise CIEDE2000 distances within a palette
#'
#' @param colours A character vector of colours, or a `killer_palette`.
#' @param cvd Optionally simulate a colour vision deficiency first. One of
#'   `"normal"`, `"deutan"`, `"protan"` or `"tritan"`.
#' @return A square numeric matrix of CIEDE2000 distances, with `NA` on the
#'   diagonal so that `min(..., na.rm = TRUE)` gives the worst-case pair.
#' @examples
#' round(killer_distance_matrix(killer_pal("hot_space")), 1)
#' min(killer_distance_matrix(killer_pal("hot_space"), cvd = "deutan"),
#'     na.rm = TRUE)
#' @export
killer_distance_matrix <- function(colours,
                                   cvd = c("normal", "deutan", "protan", "tritan")) {
  cvd <- match.arg(cvd)
  cols <- killer_cvd(colours, cvd)
  n <- length(cols)
  lab <- rgb_to_lab_mat(cols)
  out <- matrix(NA_real_, n, n, dimnames = list(cols, cols))
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      if (i != j) out[i, j] <- ciede2000(lab[i, , drop = FALSE], lab[j, , drop = FALSE])
    }
  }
  out
}

#' WCAG relative luminance
#'
#' @param colours A character vector of colours.
#' @return A numeric vector of relative luminances, between 0 and 1.
#' @examples
#' killer_luminance(c("white", "black", "#FF524F"))
#' @export
killer_luminance <- function(colours) {
  lin <- srgb_to_linear(t(grDevices::col2rgb(colours)) / 255)
  as.vector(lin %*% c(0.2126, 0.7152, 0.0722))
}

#' WCAG contrast ratio
#'
#' @param a,b Character vectors of colours. Recycled against each other.
#' @return A numeric vector of contrast ratios, between 1 and 21. WCAG 2.2 asks
#'   for at least 4.5 for body text, 3 for large text and for the boundaries of
#'   graphical objects.
#' @examples
#' killer_contrast("#FF524F", "white")
#' killer_contrast(killer_pal("flash"), "black")
#' @export
killer_contrast <- function(a, b) {
  la <- killer_luminance(a)
  lb <- killer_luminance(b)
  n <- max(length(la), length(lb))
  la <- rep_len(la, n)
  lb <- rep_len(lb, n)
  (pmax(la, lb) + 0.05) / (pmin(la, lb) + 0.05)
}

#' Audit a palette's accessibility
#'
#' Reports the numbers behind the package's colourblind- and contrast-friendly
#' claims, so you can verify them rather than take them on trust.
#'
#' @inheritParams killer_pal
#' @param colours Optionally audit an arbitrary vector of colours instead of a
#'   named palette. If supplied, `palette`, `n`, `type` and `direction` are
#'   ignored.
#'
#' @return A list of class `killer_check` with components:
#'   \describe{
#'     \item{colours}{The colours audited.}
#'     \item{min_distance}{Named numeric vector: the worst-case pairwise
#'       CIEDE2000 separation under each vision type. For a qualitative palette
#'       these should all comfortably exceed 10.}
#'     \item{contrast_white,contrast_black}{Contrast ratio of each colour
#'       against a white and a black background.}
#'     \item{lightness}{CIELAB lightness of each colour.}
#'     \item{monotone_lightness}{`TRUE` if lightness increases or decreases
#'       steadily across the palette - the property that lets a sequential
#'       palette survive being printed in greyscale.}
#'   }
#'
#' @examples
#' killer_check("greatest_hits")
#' killer_check("heavenly", n = 9, type = "sequential")
#'
#' # Audit any colours at all, not just ours
#' killer_check(colours = c("red", "green", "blue"))
#' @export
killer_check <- function(palette = "greatest_hits", n = NULL,
                         type = c("qualitative", "sequential", "diverging"),
                         direction = 1, colours = NULL) {
  type <- match.arg(type)
  cols <- if (is.null(colours)) {
    as.character(killer_pal(palette, n, type, direction))
  } else {
    toupper(grDevices::rgb(t(grDevices::col2rgb(colours)), maxColorValue = 255))
  }

  kinds <- c("normal", "deutan", "protan", "tritan")
  min_d <- vapply(kinds, function(k) {
    if (length(cols) < 2L) return(NA_real_)
    min(killer_distance_matrix(cols, k), na.rm = TRUE)
  }, numeric(1))

  L <- rgb_to_lab_mat(cols)[, 1]
  dL <- diff(L)

  structure(
    list(
      palette = if (is.null(colours)) palette else NA_character_,
      type = if (is.null(colours)) type else NA_character_,
      colours = cols,
      min_distance = min_d,
      contrast_white = killer_contrast(cols, "white"),
      contrast_black = killer_contrast(cols, "black"),
      lightness = L,
      monotone_lightness = length(dL) > 0 && (all(dL > 0) || all(dL < 0))
    ),
    class = "killer_check"
  )
}

#' @export
print.killer_check <- function(x, ...) {
  what <- if (is.na(x$palette)) {
    "custom colours"
  } else {
    paste0(x$palette, " (", x$type, ")")
  }
  cat("<killer_check>", what, "\n")
  cat("  colours:", length(x$colours), "\n")
  cat("  worst-case CIEDE2000 separation by vision type:\n")
  for (k in names(x$min_distance)) {
    cat(sprintf("    %-7s %6.1f\n", k, x$min_distance[[k]]))
  }
  cat(sprintf("  contrast vs white: %.2f - %.2f\n",
              min(x$contrast_white), max(x$contrast_white)))
  cat(sprintf("  contrast vs black: %.2f - %.2f\n",
              min(x$contrast_black), max(x$contrast_black)))
  cat(sprintf("  lightness (L*):    %.1f - %.1f\n",
              min(x$lightness), max(x$lightness)))
  cat("  monotone lightness:", x$monotone_lightness, "\n")
  invisible(x)
}
