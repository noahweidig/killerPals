# Turn the generated palette definitions into data/killer_palettes.rda.
# Run via `make palettes`, after data-raw/build_palettes.py.
source(file.path("data-raw", "palettes-generated.R"))

stopifnot(
  is.list(killer_palettes),
  length(killer_palettes) == 16L,
  all(vapply(killer_palettes, function(p) {
    all(c("album", "year", "blurb", "qualitative", "sequential", "diverging") %in% names(p))
  }, logical(1)))
)

dir.create("data", showWarnings = FALSE)
save(killer_palettes, file = file.path("data", "killer_palettes.rda"),
     compress = "xz", version = 3)
cat("wrote data/killer_palettes.rda with", length(killer_palettes), "palette families\n")
