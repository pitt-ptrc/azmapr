#' Format a Batch of Addresses for Geocoding with Azure Maps
#'
#' @description
#' A function to format a batch of addresses for geocoding using Azure Maps API.
#'
#' @param df A data frame containing addresses.
#' @param address A column in `df` containing the addresses to geocode.
#' @param limit An integer. The maximum number of results to return.
#'
#' @return JSON. A formatted JSON string ready for use with the Azure Maps API.
#' @export
#'
#' @importFrom jsonlite toJSON
#' @importFrom dplyr mutate select
#' @importFrom rlang .data
#'
az_fmt_batch <- function(df, address, limit = 1){

  stopifnot("too many addresses in batch" = nrow(df) <= 100)

  df |>
    mutate(query = paste0("?query=", .data[[address]], "&limit=", limit)) |>
    select("query") |>
    list(batchItems = _) |>
    jsonlite::toJSON()
}

#' Geocode a Batch of Addresses with Azure Maps
#'
#' @description
#' A function to geocode a batch of addresses using Azure Maps API.
#'
#' @param batch_json A JSON. A JSON string formatted for use with the Azure Maps API.
#'
#' @return JSON. The response from the Azure Maps API.
#' @export
#'
#' @importFrom httr2 request req_headers req_body_raw req_perform resp_body_json
#'
az_geocode_batch <- function(batch_json){

  url <- get_az_url()

  url |>
    request() |>
    req_headers(`Content-Type` = "application/json") |>
    req_body_raw(batch_json) |>
    req_perform() |>
    resp_body_json()
}

#' Geocode Addresses from a JSON File with Azure Maps
#'
#' @description
#' A function to geocode addresses from a JSON file using Azure Maps API.
#'
#' @param batch_json File path. Path to the JSON file containing addresses to geocode.
#'
#' @return JSON. The response from the Azure Maps API.
#' @export
#'
#' @importFrom httr2 request req_headers req_body_file req_perform resp_body_json
#'
az_geocode_file <- function(batch_json){

  url <- get_az_url()

  url |>
    request() |>
    req_headers(`Content-Type` = "application/json") |>
    req_body_file(batch_json) |>
    req_perform() |>
    resp_body_json()
}

#' Extract Specified Data from Azure Maps API Response
#'
#' @description
#' A function to extract specified data types from the Azure Maps API response.
#'
#' @param body_json JSON. The response from the Azure Maps API.
#' @param type A string. The type of data to extract: "position", "address", or "matchConfidence".
#'
#' @return List. The extracted data.
#' @export
#'
#' @importFrom purrr pluck map
#'
az_extract_body <- function(body_json, type = "position"){

  stopifnot("not valid type" = is.element(type, c("position", "address", "matchConfidence")))

  purrr::pluck(body_json, "batchItems") |>
    purrr::map(~ purrr::pluck(.x, "response", "results", 1, type))
}
