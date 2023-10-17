
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
azm_geocode(cand, .test_batch = TRUE)
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
  azm_request_batch(direction = "fwd") |> 
  azm_extract_body(type = "viewport", direction = "fwd") |> 
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

You can also reverse geocode. Again, given a dataframe with `lat` and
`lon` the main wrapper has sane defaults. Suppose you want to associate
9-digit zipcodes with coordinates.

``` r
coords |> 
  azm_rev_geocode(lat, lon) |> 
  dplyr::select(lat, lon, streetNameAndNumber, extendedPostalCode)
#> # A tibble: 6 × 4
#>     lat   lon streetNameAndNumber extendedPostalCode
#>   <dbl> <dbl> <chr>               <chr>             
#> 1  40.4 -80.0 946 Locust Avenue   15234-2112        
#> 2  40.4 -79.9 117 Woodland Road   15232-2815        
#> 3  40.4 -80.0 929 Penn Avenue     15222-3802        
#> 4  40.4 -79.9 5271 Forbes Avenue  15217-1161        
#> 5  40.4 -79.9 1211 Milton Street  15218-1232        
#> 6  40.4 -79.9 7502 Roslyn Street  15218-2519
```

But you can also pipe and adjust

``` r
coords |> 
  azm_fmt_rev_batch(lat, lon, limit = 1) |> 
  azm_request_batch(direction = "rev") |> 
  azm_extract_body(type = "address", direction = "rev") |> 
  dplyr::bind_rows()
#> # A tibble: 6 × 18
#>   buildingNumber streetNumber street  streetName streetNameAndNumber countryCode
#>   <chr>          <chr>        <chr>   <chr>      <chr>               <chr>      
#> 1 946            946          Locust… Locust Av… 946 Locust Avenue   US         
#> 2 117            117          Woodla… Woodland … 117 Woodland Road   US         
#> 3 929            929          Penn A… Penn Aven… 929 Penn Avenue     US         
#> 4 5271           5271         Forbes… Forbes Av… 5271 Forbes Avenue  US         
#> 5 1211           1211         Milton… Milton St… 1211 Milton Street  US         
#> 6 7502           7502         Roslyn… Roslyn St… 7502 Roslyn Street  US         
#> # ℹ 12 more variables: countrySubdivision <chr>,
#> #   countrySecondarySubdivision <chr>, municipality <chr>, postalCode <chr>,
#> #   country <chr>, countryCodeISO3 <chr>, freeformAddress <chr>,
#> #   extendedPostalCode <chr>, countrySubdivisionName <chr>,
#> #   countrySubdivisionCode <chr>, localName <chr>,
#> #   municipalitySubdivision <chr>
```
