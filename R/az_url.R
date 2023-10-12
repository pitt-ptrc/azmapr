#' Azure Maps API Base URL Component
#'
#' A character string storing the base URL component for the Azure Maps API.
#' @export
az_maps_base_url <- "https://atlas.microsoft.com/search/address/batch/sync/json?api-version=1.0&subscription-key="

#' Retrieve Full Azure Maps API URL
#'
#' This function retrieves and returns the full URL for the Azure Maps API,
#' ensuring the necessary API key is available in the user's environment.
#' @return A string, the complete API URL including the subscription key.
#' @examples
#' \dontrun{
#' url <- get_az_url()
#' }
#' @export
get_az_url <- function() {
  # Check for API key in environment
  api_key <- Sys.getenv('AZ_MAPS_SUBSCRIPTION_KEY')

  if (nzchar(api_key)) {
    # If key is available, concatenate to base URL and return
    return(paste0(az_maps_base_url, api_key))
  } else {
    # If not, return a message instructing user on obtaining API key
    stop("Azure Maps API Subscription Key not found in your environment variables. \n",
         "Obtain a key from https://azure.com/maps and set it using: \n",
         "Sys.setenv(AZ_MAPS_SUBSCRIPTION_KEY = 'your_key_here')")
  }
}
