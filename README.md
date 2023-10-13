
<!-- README.md is generated from README.Rmd. Please edit that file -->

# azmapr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/azmapr)](https://CRAN.R-project.org/package=azmapr)
[![R-CMD-check](https://github.com/pitt-ptrc/azmapr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pitt-ptrc/azmapr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of azmapr is to access the Azure Maps API and tidy the results.

## Installation

You can install the development version of azmapr like so:

``` r
remotes::install_github("pitt-ptrc/azmapr")
```

## Example

Given data frame with a column `address`, the main wrapper function
`azm_geocode` has sane defaults.

``` r
library(azmapr)

azm_geocode(cand)
#> # A tibble: 6 × 4
#>   id              address                                  lat   lon
#>   <chr>           <chr>                                  <dbl> <dbl>
#> 1 Conor_Lamb      P.O. Box 10381, Pittsburgh, PA 15234    40.4 -80.0
#> 2 Dave_McCormick  117 Woodland Rd., Pittsburgh, PA 15232  40.4 -79.9
#> 3 Jeff_Coleman    P.O. Box 23173, Pittsburgh, PA 15222    40.4 -80.0
#> 4 Steve_Irwin     5271 Forbes Ave., Pittsburgh, PA 15217  40.4 -79.9
#> 5 Jerry_Dickinson 1211 Milton St., Pittsburgh, PA 15218   40.4 -79.9
#> 6 Summer_Lee      7502 Roslyn St., Pittsburgh, PA 15218   40.4 -79.9
```

The Azure Maps API limits you to 100 address batches. If you pass a more
than 100, `azmapr` breaks it up into chunks and pauses briefly in
between. Azure Maps supports async geocoding for larger batches, but
`azmapr` hasn’t figured that out yet.

``` r
azm_geocode(cand, test_batch = TRUE)
#> running batch  1 
#> running batch  2 
#> running batch  3
#> # A tibble: 6 × 5
#>   id              address                                group   lat   lon
#>   <chr>           <chr>                                  <dbl> <dbl> <dbl>
#> 1 Conor_Lamb      P.O. Box 10381, Pittsburgh, PA 15234       0  40.4 -80.0
#> 2 Dave_McCormick  117 Woodland Rd., Pittsburgh, PA 15232     0  40.4 -79.9
#> 3 Jeff_Coleman    P.O. Box 23173, Pittsburgh, PA 15222       1  40.4 -80.0
#> 4 Steve_Irwin     5271 Forbes Ave., Pittsburgh, PA 15217     1  40.4 -79.9
#> 5 Jerry_Dickinson 1211 Milton St., Pittsburgh, PA 15218      2  40.4 -79.9
#> 6 Summer_Lee      7502 Roslyn St., Pittsburgh, PA 15218      2  40.4 -79.9
```

If you want to adjust settings, the functions are pipe-able.

``` r

cand |> 
  azm_fmt_batch(address, limit = 2) |> 
  azm_request_batch() |> 
  azm_extract_body(type = "viewport") |> 
  dplyr::bind_rows() |> 
  dplyr::mutate(topLeftPoint = unlist(topLeftPoint),
                btmRightPoint = unlist(btmRightPoint))
#> # A tibble: 12 × 2
#>    topLeftPoint btmRightPoint
#>           <dbl>         <dbl>
#>  1         40.4          40.4
#>  2        -80.1         -80.0
#>  3         40.4          40.4
#>  4        -79.9         -79.9
#>  5         40.5          40.4
#>  6        -80.0         -80.0
#>  7         40.4          40.4
#>  8        -79.9         -79.9
#>  9         40.4          40.4
#> 10        -79.9         -79.9
#> 11         40.4          40.4
#> 12        -79.9         -79.9
```
