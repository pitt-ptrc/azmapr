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
#' @import rlang
#'
azm_fmt_batch <- function(df, address, limit = 1){

  stopifnot("too many locations in batch" = nrow(df) <= 100)

  df |>
    mutate(query = paste0("?query=", {{ address }}, "&limit=", limit)) |>
    select("query") |>
    list(batchItems = _) |>
    jsonlite::toJSON()
}


#' Format a Batch of Coordinates for Reverse Geocoding with Azure Maps
#'
#' @description
#' A function to format a batch of coordinates for geocoding using Azure Maps API.
#'
#' @param df A data frame containing coordinates
#' @param lat A column in `df` containing the latitude to geocode.
#' @param lon A column in `df` containing the longitude to geocode.
#' @param limit An integer. The maximum number of results to return.
#'
#' @return JSON. A formatted JSON string ready for use with the Azure Maps API.
#' @export
#'
#' @importFrom jsonlite toJSON
#' @importFrom dplyr mutate select
#' @import rlang
#'
azm_fmt_rev_batch <- function(df, lat, lon, limit = 1){

  stopifnot("too many locations in batch" = nrow(df) <= 100)

  df |>
    mutate(query = paste0("?query=", {{ lat }}, ",", {{ lon }}, "&limit=", limit)) |>
    select("query") |>
    list(batchItems = _) |>
    jsonlite::toJSON()
}

#' Conditionally Set Request Body
#'
#' This function conditionally sets the body of an HTTP request depending on
#' the type of `batch_json`. If `batch_json` is a JSON object, `req_body_raw`
#' is used; if it's a valid file path (character string), `req_body_file` is used.
#'
#' @param request A request object created by httr::request().
#' @param batch_json Either a JSON object or a character string representing
#'   a file path to a JSON file.
#'
#' @return The modified request object.
#'
#' @importFrom httr2 req_body_raw req_body_file
req_body_cond <- function(request, batch_json) {
  if (inherits(batch_json, "json")) {
    req_body_raw(request, batch_json)
  } else if (file.exists(batch_json)) {
    req_body_file(request, batch_json)
  } else {
    stop("batch_json must be either a valid file path or a JSON object.")
  }
}


#' Request a Batch of Addresses from Azure Maps
#'
#' @description
#' A function to request a batch of addresses using Azure Maps API.
#'
#' @param batch_json A JSON. A JSON string formatted for use with the Azure Maps API.
#' @param direction "fwd" or "rev"
#' @return JSON. The response from the Azure Maps API.
#' @export
#'
#' @importFrom httr2 request req_headers req_body_raw req_perform resp_body_json
#'
azm_request_batch <- function(batch_json, direction){

  url <- get_azm_url(direction = direction)

  url |>
    request() |>
    req_headers(`Content-Type` = "application/json") |>
    req_body_cond(batch_json) |>
    req_perform() |>
    resp_body_json()
}

#' Extract Specified Data from Azure Maps API Response
#'
#' @description
#' A function to extract specified data types from the Azure Maps API response.
#'
#' @param body_json JSON. The response from the Azure Maps API.
#' @param type A string for the nested list object field, e.g. "position", "address", or "matchConfidence".
#' @param direction "fwd" or "rev"
#'
#' @return List. The extracted data.
#' @export
#'
#' @importFrom purrr pluck map
#'
azm_extract_body <- function(body_json, type, direction){

  # TODO: fix this validation in testing
  # stopifnot("support only for addresses when reverse geocoding" =
  #             direction == "rev" & type != "address")

  rm_ls_elem <- function(x) {
    x$boundingBox <- NULL
    x$routeNumbers <- NULL
    x
  }

  if(direction == "fwd"){
    body_json |>
      pluck("batchItems") |>
      map(~ pluck(.x, "response", "results", 1, type))
  } else if (direction == "rev") {
    body_json |>
      pluck("batchItems") |>
      map(~ pluck(.x, "response", "addresses", 1, type)) |>
      map(rm_ls_elem)

  }


}


#' Geocode Addresses with Azure Maps
#'
#' Utilize Azure Maps services to geocode addresses, returning either positional
#' information, address details, confidence scores, or all available details.
#'
#' @param df A data frame containing the addresses to be geocoded.
#' @param address A character vector specifying the address column(s) in `df`.
#' @param type A character string indicating the type of data to return.
#'   Must be one of "position", "address", "matchConfidence", or "all".
#'   Default is "position".
#'
#' @return A data frame containing the original data along with the requested
#'   geocoding information.
#'
#' @importFrom dplyr bind_cols bind_rows
azm_geocode_batch <- function(df, address, type = "position"){

  # Request data
  resp <- df |>
    azm_fmt_batch(address) |>
    azm_request_batch(direction = "fwd")

  # Helper function to reduce repetition
  extract_and_bind <- function(type) {
    resp |>
      azm_extract_body(type = type, direction = "fwd") |>
      bind_rows()
  }

  # Response handling
  if(type != "all"){
    res <- extract_and_bind(type = type)

    bind_cols(df, res)
  } else {
    # Extract different types of info and bind to original df
    pos <- extract_and_bind("position")
    addr <- extract_and_bind("address")
    score <- extract_and_bind("matchConfidence")

    bind_cols(df, pos, addr, score)
  }
}


#' Geocode Addresses with Azure Maps
#'
#' Utilize Azure Maps services to geocode addresses, returning either positional
#' information, address details, confidence scores, or all available details.
#'
#' @param df A data frame containing the addresses to be geocoded.
#' @param lat A column in `df` containing the latitude to geocode.
#' @param lon A column in `df` containing the longitude to geocode.
#' @param type A character string indicating the type of data to return.
#'   Must be one of "position", "address", "matchConfidence", or "all".
#'   Default is "position".
#'
#' @return A data frame containing the original data along with the requested
#'   geocoding information.
#'
#' @importFrom dplyr bind_cols bind_rows
azm_geocode_rev_batch <- function(df, lat, lon, type = "address"){

  # Request data
  resp <- df |>
    azm_fmt_rev_batch(lat, lon) |>
    azm_request_batch(direction = "rev")

  # Helper function to reduce repetition
  extract_and_bind <- function(type) {
    resp |>
      azm_extract_body(type = type, direction = "rev") |>
      bind_rows()
  }

  # Response handling
  if(type != "all"){
    res <- extract_and_bind(type = type)

    bind_cols(df, res)
  } else {
    # Extract different types of info and bind to original df
    pos <- extract_and_bind("position")
    addr <- extract_and_bind("address")
    score <- extract_and_bind("matchConfidence")

    bind_cols(df, pos, addr, score)
  }
}

#' Geocode Addresses with the AZM Geocoding Service
#'
#' @description This function interacts with the AZM geocoding service to
#' geocode addresses in a data frame, handling batching and type selection.
#'
#' @param df A data frame containing the addresses to be geocoded.
#' @param address A string indicating the name of the column in `df`
#'   containing the addresses to be geocoded.
#' @param type A string indicating the type of geocoding to be performed.
#'   Must be one of "position", "address", or "matchConfidence".
#' @param .test_batch A logical. If `TRUE`, the function will run in test mode,
#'   processing only a small subset of the data.
#'
#' @return A data frame containing the original data plus geocoding results.
#' @export
#'
#' @importFrom dplyr group_by group_split bind_rows row_number
#' @importFrom purrr imap
#'
azm_geocode <- function(df, address, type = "position", .test_batch = FALSE){
  # Input checks
  stopifnot("Input df must be a data frame." = inherits(df, "data.frame"))
  stopifnot("Not a valid type" = is.element(type, c("position", "address", "matchConfidence", "all")))

  n_chunk <- ifelse(.test_batch, 2, 100)

  if (nrow(df) <= 100 & !.test_batch){
    azm_geocode_batch(df, address, type)
  } else {
    df |>
      group_by(group = (row_number() - 1) %/% n_chunk) |>
      group_split() |>
      imap(\(x, idx){
        batch <- azm_geocode_batch(x, address, type)
        cat("running batch ", idx, "\n")
        Sys.sleep(0.2)  # pause for .2 seconds
        return(batch)
      }) |>
      bind_rows()
  }
}


#' Reverse Geocode Addresses with the AZM Geocoding Service
#'
#' @description This function interacts with the AZM geocoding service to
#' reverse geocode coordinates in a data frame, handling batching and type selection.
#'
#' @param df A data frame containing the addresses to be geocoded.
#' @param lat A column in `df` containing the latitude to geocode.
#' @param lon A column in `df` containing the longitude to geocode.
#' @param type A string indicating the type of geocoding to be performed.
#'   Must be one of "position", "address", or "matchConfidence".
#' @param .test_batch A logical. If `TRUE`, the function will run in test mode,
#'   processing only a small batches of the data.
#'
#' @return A data frame containing the original data plus geocoding results.
#' @export
#'
#' @importFrom dplyr group_by group_split bind_rows row_number
#' @importFrom purrr imap
#'
#'
azm_rev_geocode <- function(df, lat, lon, type = "address", .test_batch = FALSE){
  # Input checks
  stopifnot("Input df must be a data frame." = inherits(df, "data.frame"))
  stopifnot("Not a valid type" = is.element(type, c("position", "address", "matchConfidence", "all")))

  n_chunk <- ifelse(.test_batch, 2, 100)

  if (nrow(df) <= 100 & !.test_batch){
    azm_geocode_rev_batch(df, lat, lon, type)
  } else {
    df |>
      group_by(group = (row_number() - 1) %/% n_chunk) |>
      group_split() |>
      imap(\(x, idx){
        batch <- azm_geocode_rev_batch(x, lat, lon, type)
        cat("running batch ", idx, "\n")
        Sys.sleep(0.2)  # pause for .2 seconds
        return(batch)
      }) |>
      bind_rows()
  }
}

