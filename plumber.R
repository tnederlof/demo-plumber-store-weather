library(plumber)
library(httr)
library(tidyverse)
library(stringdist)

#* @apiTitle Starbucks Store Weather API
#* @apiDescription Returns up to date weather forecasts from the National Weather Service for any Starbucks store.

#* Return directory of stores
#* @param name Filter stores by name.
#* @param city Filter stores by city.
#* @param state Filter stores by state.
#* @get /stores
function(name = NULL, city = NULL, state = NULL) {
  starbucks_stores <- readRDS("starbucks_locations.rds")
  if (is.null(name) & is.null(city) & !is.null(state)) {
    starbucks_stores |> filter(state == !!state)
  } else if (is.null(name) & !is.null(city) & is.null(state)) {
    starbucks_stores |> filter(city == !!city)
  } else if (is.null(name) & !is.null(city) & !is.null(state)) {
    starbucks_stores |> filter(city == !!city,
                               state == !!state)
  } else if (!is.null(name) & is.null(city) & !is.null(state)) {
    starbucks_stores |> filter(state == !!state,
                               name == match_text(name, starbucks_stores$name))
  } else if (!is.null(name) & !is.null(city) & is.null(state)) {
    starbucks_stores |> filter(city == !!city,
                               name == match_text(name, starbucks_stores$name))
  } else if (!is.null(name) & !is.null(city) & !is.null(state)) {
    starbucks_stores |> filter(city == !!city,
                               state == !!state,
                               name == match_text(name, starbucks_stores$name))
  } else if (!is.null(name) & is.null(city) & is.null(state)) {
    starbucks_stores |> filter(name == match_text(name, starbucks_stores$name))
  } else {
    starbucks_stores
  }
}

#* Return the weather forecast of a store
#* @param storeid The Starbucks store ID
#* @post /weather
function(storeid) {
  # check input
  if (missing(storeid)) {
    stop("Missing required 'storeid' parameter.", call. = FALSE)
  }
  if (length(storeid) != 1) {
    stop("The length of the 'storeid' paramter must be 1.", call. = FALSE)
  }
  starbucks_stores <- readRDS("starbucks_locations.rds")
  if (!storeid %in% starbucks_stores$storenumber) {
    stop("The 'storeid' parameter was not valid, please check the input.", call. = FALSE)
  }
  
  # filter to the store requested
  store_selected <- starbucks_stores |> filter(storenumber == storeid)
  
  # retrieve forecast
  forecast_data <- get_forecast(store_selected$latitude, store_selected$longitude)
  forecast_data_final <- c("storeInfo" = purrr::transpose(store_selected),
                           forecast_data)
  return(forecast_data_final)
}



#' Retrieve weather forecast
#' 
#' @description A helper function find the correct grid cell and retrieve the
#'     forecast for that area.
#'
#' @param latitude
#' @param longitude 
#'
#' @return
get_forecast <- function(latitude, longitude) {
  # find the NWS 2.5km grid the latitude and longitude are in
  points_url <- glue("https://api.weather.gov/points/{latitude},{longitude}")
  points_result <- GET(points_url)
  if (status_code(points_result) != 200) {
    stop("An error connecting to api.weather.gov/points has occured")
  }
  points_result_json <- content(points_result, as = "parsed", type = "application/json")
  
  # retrieve weather forecast
  # try a couple of times to avoid random 500 errors
  try_var <- 3
  while (try_var >= 0) {
    forecast_result <- GET(points_result_json$properties$forecast)
    try_var <- try_var - 1
    if (status_code(forecast_result) == 200) {
      break
    }
  }
  if (status_code(forecast_result) != 200) {
    stop("An error connecting to api.weather.gov/gridpoints has occured")
  }
  forecast_result_json <- content(forecast_result, as = "parsed", type = "application/json")
  return(forecast_result_json$properties)
}

#' Fuzzy match text
#' 
#' @description A helper function to fuzzy match text based on word distances.
#'
#' @param text Text to be matched.
#' @param source Vector of strings to be searched.
#'
#' @return
match_text <- function(text, source) {
  name_search <- stringdist(text, source, method = "dl")
  name_search_min <- which.min(name_search) 
  if (name_search[name_search_min] > 4) {
    stop("The 'name' parameter was not valid, please check the input.", call. = FALSE)
  }
  source[name_search_min]
}