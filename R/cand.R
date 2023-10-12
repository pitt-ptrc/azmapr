#' Candidate Addresses
#'
#' A dataset containing IDs and addresses of certain candidates.
#'
#' @format A data frame with 6 rows and 2 variables:
#' \describe{
#'   \item{\code{id}}{A character vector of candidate identifiers.}
#'   \item{\code{address}}{A character vector of candidate addresses.}
#' }
#' @source \url{[URL where the data was taken from, if applicable]}
#' @examples
#' data(cand)
#' head(cand)

cand <-
  structure(
    list(
      id = c(
        "Conor_Lamb",
        "Dave_McCormick",
        "Jeff_Coleman",
        "Steve_Irwin",
        "Jerry_Dickinson",
        "Summer_Lee"
      ),
      address = c(
        "P.O. Box 10381, Pittsburgh, PA 15234",
        "117 Woodland Rd., Pittsburgh, PA 15232",
        "P.O. Box 23173, Pittsburgh, PA 15222",
        "5271 Forbes Ave., Pittsburgh, PA 15217",
        "1211 Milton St., Pittsburgh, PA 15218",
        "7502 Roslyn St., Pittsburgh, PA 15218"
      )
    ),
    row.names = c(NA,-6L),
    class = c("tbl_df", "tbl", "data.frame")
  )
