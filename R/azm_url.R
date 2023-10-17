#' Azure Maps API Forward Batch URL Component
#'
#' A character string storing the URL component for the Azure Maps API.
azm_fwd_batch_url <- "https://atlas.microsoft.com/search/address/batch/sync/json?api-version=1.0&subscription-key="

#' Azure Maps API Reverse Batch URL Component
#'
#' A character string storing the URL component for the Azure Maps API.
azm_rev_batch_url <- "https://atlas.microsoft.com/search/address/reverse/batch/sync/json?api-version=1.0&subscription-key="


#' Retrieve Full Azure Maps API URL
#'
#' This function retrieves and returns the full URL for the Azure Maps API,
#' ensuring the necessary API key is available in the user's environment.
#' @param direction Forward "fwd" or Reverse "rev"
#' @return A string, the complete API URL including the subscription key.
#' @examples
#' \dontrun{
#' url <- get_azm_url()
#' }
get_azm_url <- function(direction) {

  # Check for API key in environment
  api_key <- Sys.getenv('AZ_MAPS_SUBSCRIPTION_KEY')

  if (nzchar(api_key)) {
    # If key is available, concatenate to base URL and return
    switch(
      direction,
      fwd = paste0(azm_fwd_batch_url, api_key),
      rev = paste0(azm_rev_batch_url, api_key),
      stop("geocode direction must be forward or reverse")
    )
  } else {
    # If not, return a message instructing user on obtaining API key
    stop("Azure Maps API Subscription Key not found in your environment variables. \n",
         "Obtain a key from https://azure.com/maps and set it using: \n",
         "Sys.setenv(AZ_MAPS_SUBSCRIPTION_KEY = 'your_key_here')")
  }
}
