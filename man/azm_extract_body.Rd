% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geocode.R
\name{azm_extract_body}
\alias{azm_extract_body}
\title{Extract Specified Data from Azure Maps API Response}
\usage{
azm_extract_body(body_json, type, direction)
}
\arguments{
\item{body_json}{JSON. The response from the Azure Maps API.}

\item{type}{A string for the nested list object field, e.g. "position", "address", or "matchConfidence".}

\item{direction}{"fwd" or "rev"}
}
\value{
List. The extracted data.
}
\description{
A function to extract specified data types from the Azure Maps API response.
}
