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

  stopifnot("too many addresses in batch" = nrow(df) <= 100)

  df |>
    mutate(query = paste0("?query=", {{ address }}, "&limit=", limit)) |>
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
#'
#' @return JSON. The response from the Azure Maps API.
#' @export
#'
#' @importFrom httr2 request req_headers req_body_raw req_perform resp_body_json
#'
azm_request_batch <- function(batch_json){

  url <- get_azm_url()

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
#'
#' @return List. The extracted data.
#' @export
#'
#' @importFrom purrr pluck map
#'
azm_extract_body <- function(body_json, type = "position"){

  purrr::pluck(body_json, "batchItems") |>
    purrr::map(~ purrr::pluck(.x, "response", "results", 1, type))
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
    azm_request_batch()

  # Helper function to reduce repetition
  extract_and_bind <- function(type) {
    resp |>
      azm_extract_body(type = type) |>
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
#' @param test_batch A logical. If `TRUE`, the function will run in test mode,
#'   processing only a small subset of the data.
#'
#' @return A data frame containing the original data plus geocoding results.
#' @export
#'
#' @importFrom dplyr group_by group_split bind_rows row_number
#' @importFrom purrr imap
#'
#' @examples
#' \dontrun{
#' azm_geocode(my_data, "street_address_column")
#' }
#'
azm_geocode <- function(df, address, type = "position", test_batch = FALSE){
  # Input checks
  stopifnot("Input df must be a data frame." = inherits(df, "data.frame"))
  stopifnot("Not a valid type" = is.element(type, c("position", "address", "matchConfidence")))

  n_chunk <- ifelse(test_batch, 2, 100)

  if (nrow(df) <= 100 & !test_batch){
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

