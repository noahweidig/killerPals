# Simulate how a palette looks with colour vision deficiency

Simulate how a palette looks with colour vision deficiency

## Usage

``` r
killer_cvd(
  colours,
  type = c("deutan", "protan", "tritan", "normal"),
  severity = 1
)
```

## Arguments

- colours:

  A character vector of colours, or a `killer_palette`.

- type:

  Which deficiency to simulate: `"deutan"` (red-green, the most common),
  `"protan"` (red-green), `"tritan"` (blue-yellow), or `"normal"` to
  pass the colours straight through.

- severity:

  Severity of the deficiency, from `0` (normal vision) to `1`
  (dichromacy).

## Value

A character vector of hex colours the same length as `colours`.

## References

Machado, G. M., Oliveira, M. M., & Fernandes, L. A. F. (2009). A
physiologically-based model for simulation of color vision deficiency.
*IEEE Transactions on Visualization and Computer Graphics*, 15(6),
1291-1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113)

## See also

[`killer_check()`](https://noahweidig.github.io/killerpals/reference/killer_check.md)
for a numeric accessibility audit.

## Examples

``` r
pal <- killer_pal("flash")
killer_cvd(pal, "deutan")
#> [1] "#DEC61B" "#55658B" "#514818" "#DCD3AE" "#A8B9E8" "#67655D" "#84751E"
#> [8] "#96907B"
killer_cvd(pal, "tritan", severity = 0.6)
#> [1] "#FAAE7D" "#2D7280" "#7C1F22" "#DCD0BE" "#78CBDB" "#785D5D" "#6C7A55"
#> [8] "#9D8B83"

# Compare a palette across all four vision types
killer_cvd_grid("greatest_hits")
```
