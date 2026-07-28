# Plot a palette as swatches

Plot a palette as swatches

## Usage

``` r
# S3 method for class 'killer_palette'
plot(x, ...)
```

## Arguments

- x:

  A `killer_palette`, as returned by
  [`killer_pal()`](https://noahweidig.github.io/killerpals/reference/killer_pal.md).

- ...:

  Ignored.

## Value

`x`, invisibly. Called for its side effect of drawing a plot.

## Examples

``` r
plot(killer_pal("all_that_jazz"))

plot(killer_pal("miracle", n = 9, type = "diverging"))
```
