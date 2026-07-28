# Pairwise CIEDE2000 distances within a palette

Pairwise CIEDE2000 distances within a palette

## Usage

``` r
killer_distance_matrix(
  colours,
  cvd = c("normal", "deutan", "protan", "tritan")
)
```

## Arguments

- colours:

  A character vector of colours, or a `killer_palette`.

- cvd:

  Optionally simulate a colour vision deficiency first. One of
  `"normal"`, `"deutan"`, `"protan"` or `"tritan"`.

## Value

A square numeric matrix of CIEDE2000 distances, with `NA` on the
diagonal so that `min(..., na.rm = TRUE)` gives the worst-case pair.

## Examples

``` r
round(killer_distance_matrix(killer_pal("hot_space")), 1)
#>         #D98DF2 #772809 #9AC66D #6452A9 #918899 #6DDFD2 #CD396A #997C00
#> #D98DF2      NA    55.6    69.4    29.2    21.7    42.3    28.3    61.6
#> #772809    55.6      NA    63.9    40.3    38.3    70.1    28.6    34.2
#> #9AC66D    69.4    63.9      NA    59.7    41.1    23.6    68.1    27.7
#> #6452A9    29.2    40.3    59.7      NA    25.2    51.2    28.7    58.6
#> #918899    21.7    38.3    41.1    25.2      NA    38.0    25.6    36.4
#> #6DDFD2    42.3    70.1    23.6    51.2    38.0      NA    69.3    42.6
#> #CD396A    28.3    28.6    68.1    28.7    25.6    69.3      NA    49.7
#> #997C00    61.6    34.2    27.7    58.6    36.4    42.6    49.7      NA
min(killer_distance_matrix(killer_pal("hot_space"), cvd = "deutan"),
    na.rm = TRUE)
#> [1] 16.54701
```
