# CIEDE2000 colour difference

The perceptual distance metric the palettes were optimised against. A
difference of roughly 1 is the smallest a person can notice; 10 or more
is comfortably distinguishable at a glance.

## Usage

``` r
killer_distance(a, b)
```

## Arguments

- a, b:

  Character vectors of colours. Recycled against each other.

## Value

A numeric vector of CIEDE2000 differences.

## References

Sharma, G., Wu, W., & Dalal, E. N. (2005). The CIEDE2000
color-difference formula. *Color Research & Application*, 30(1), 21-30.
[doi:10.1002/col.20070](https://doi.org/10.1002/col.20070)

## Examples

``` r
killer_distance("#FF0000", "#00FF00")
#> [1] 86.52385
killer_distance("#FF0000", "#FF0505")
#> [1] 0.4009687

# How close are the two most similar colours in a palette?
min(killer_distance_matrix(killer_pal("flash")), na.rm = TRUE)
#> [1] 19.50331
```
