## code to prepare `coords` dataset goes here

library(azmapr)
library(dplyr)

coords <- cand |>
  azm_geocode() |>
  select(lat, lon)

usethis::use_data(coords, overwrite = TRUE)
