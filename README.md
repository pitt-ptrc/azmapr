
<!-- README.md is generated from README.Rmd. Please edit that file -->

# azmapr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/azmapr)](https://CRAN.R-project.org/package=azmapr)
<!-- badges: end -->

The goal of azmapr is to access the Azure Maps API and tidy the results.

## Installation

You can install the development version of azmapr like so:

``` r
remotes::install("pitt-ptrc/azmapr)
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(azmapr)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

path_json <- system.file("extdata", "test.json", package = "azmapr")

resp <- 
  path_json |> 
  # TODO: geocode -> addr_search
  az_geocode_file()

resp |> 
  az_extract_body(type = "position") |> 
  bind_rows()
#> # A tibble: 5 × 2
#>     lat     lon
#>   <dbl>   <dbl>
#> 1  47.6 -122.  
#> 2  47.6 -122.  
#> 3  40.7  -74.0 
#> 4  47.6 -122.  
#> 5  48.9    2.29

resp |> 
  az_extract_body(type = "address") |> 
  bind_rows() |> 
  select(1:4)
#> # A tibble: 5 × 4
#>   streetNumber streetName            municipalitySubdivision municipality
#>   <chr>        <chr>                 <chr>                   <chr>       
#> 1 400          Broad Street          Queen Anne              Seattle     
#> 2 <NA>         NE One Microsoft Way  <NA>                    Redmond     
#> 3 350          5th Avenue            Manhattan               New York    
#> 4 <NA>         Pike Place            Downtown Seattle        Seattle     
#> 5 5            Avenue Anatole France 7ème Arrondissement     Paris
```
