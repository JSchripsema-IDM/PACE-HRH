# TECHNICAL IMPLEMENTATION NOTE
#
# Global configuration refers to system-wide invariants that have to be set up
# from the start. The most important of these is the input Excel spreadsheet
# that defines experiment scenarios, baseline population data, task
# descriptions, etc.
#
# Global configuration can be set programmatically with the setGlobalConfig()
# function.
#
# The usual mechanism, however, is for the global configuration to be declared
# by the user in a file called globalconfig.json in the working directory. This
# file is read and the global configuration set with the function
# loadGlobalConfig().
#
# Completion of global configuration is signaled by setting
# GPE$globalConfigLoaded to TRUE.
#
# The InitializeXXXX() functions depend on knowing where to find the input Excel
# file, so each point to a function .checkAndLoadGlobalConfig() to confirm that
# global configuration has been set. A useful side-effect is that the
# InitializeXXXX() functions can be called in any order.

#' Load Global Configuration
#'
#' Finds and loads global configuration data from a JSON file, including
#' the location of the input Excel data file.
#'
#' @param path Location of global configuration file
#'
#' @return NULL (invisible)
#'
loadGlobalConfig <- function(path = "./globalconfig.json"){
  if (file.exists(path)){
    out <- tryCatch(
      {
        configInfo <- jsonlite::read_json(path)

        if (!is.null(configInfo$configDirectoryLocation)){
          configDirPath <- configInfo$configDirectoryLocation
        } else {
          configDirPath <- "."
        }

        if (!is.null(configInfo$inputExcelFile)){
          GPE$inputExcelFile <-
            paste(configDirPath,
                  configInfo$inputExcelFile,
                  sep = "/")
        }

        if (!is.null(configInfo$suiteRngSeed)){
          i <- as.integer(configInfo$suiteRngSeed)
          if (!is.na(i)){
            GPE$rngSeed <- i
          }
        }

        start <- GPE$startYear
        end <- GPE$endYear

        if (!is.null(configInfo$startYear)){
          i <- as.integer(configInfo$startYear)
          if (!is.na(i)){
            start <- i
          }
        }

        if (!is.null(configInfo$endYear)){
          i <- as.integer(configInfo$endYear)
          if (!is.na(i)){
            end <- i
          }
        }

        SetGlobalStartEndYears(start, end)

        traceMessage(paste0("Global configuration loaded from ", path))
      },
      warning = function(war)
      {
        traceMessage(paste("WARNING:", war))
      },
      error = function(err)
      {
        traceMessage(paste("ERROR:", err))
      },
      finally =
        {

        })
  }
  else {
    traceMessage("Could not find global configuration file - using defaults")
  }

  invisible(NULL)
}

# Note: this function does not check that the file path is valid.
# This function is intended to support unit tests to force the system to
# initialize based on a different configuration than is in globalconfig.json.
setGlobalConfig <- function(inputExcelFilePath = "./config/model_inputs.xlsx"){
  if (!is.blank(inputExcelFilePath)){
    GPE$inputExcelFile <- inputExcelFilePath
    GPE$globalConfigLoaded <- TRUE
  }
}

# Internal function used by the various InitializeXXXXX() functions to auto-
# magically load the global configuration.

# TODO: Add (...) support so the path= parameter can be passed through to allow
# for using files other than globalconfig.json

.checkAndLoadGlobalConfig <- function(){
  if (!GPE$globalConfigLoaded){
    loadGlobalConfig()
    GPE$globalConfigLoaded <- TRUE
  }
  invisible(NULL)
}

#' Set Global Start And End Year Parameters
#'
#' @param start Starting year
#' @param end Ending year (must be greater than \code{start})
#' @param shoulderYears Number of years to add to the end of a simulation time-series
#' to accomodate negative delivery offsets (default = 1)
#'
#' @return NULL (invisible)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' pacehrh::SetGlobalStartEndYears(2020, 2035)
#' }
SetGlobalStartEndYears <- function(start = 2020, end = 2040, shoulderYears = 1) {
  if (!assertthat::is.number(start)) {
    return(invisible(NULL))
  }

  if (!assertthat::is.number(end)) {
    return(invisible(NULL))
  }

  if (!assertthat::is.number(shoulderYears)) {
    return(invisible(NULL))
  }

  if (end <= start) {
    return(invisible(NULL))
  }

  if (shoulderYears < 0) {
    return(invisible(NULL))
  }

  GPE$startYear <- start
  GPE$endYear <- end
  GPE$years <-
    seq(from = GPE$startYear,
        to = GPE$endYear,
        by = 1)
  GPE$shoulderYears <- shoulderYears

  return(invisible(NULL))
}

#' Set Rounding Law
#'
#' The rounding law determines how the system handles rounding for
#' processes that in nature would always return integer counts, such as
#' births.
#'
#' For example: Take 35 age groups, each containing 100 fertile women, and
#' each with a fertility rate of 0.0564 births/woman/year. Say we want to
#' calculate the total number of births for a year.
#'
#' "early" law: N = round(100 * 0.0564) * 35 = 210
#' "late" law: N = round(100 * 0.0564 * 35) = 197
#' "none" law: N = 100 * 0.0564 * 35 = 197.4
#'
#' Rounding laws apply to several PACE-HRH calculations (e.g. population predictions).
#' In many cases there is no difference between "early" and "late" laws.
#'
#' By default the system is set up with the "early" rounding law.
#'
#' @param value Rounding law. Allowed values are "early", "late", "none" and NULL
#'
#' @return Previous rounding law value
#' @export
#'
#' @examples
#' \dontrun{
#' pacehrh::SetRoundingLaw("none")
#' }
SetRoundingLaw <- function(value = NULL){
  prevValue <- GPE$roundingLaw

  if (!is.null(value)){
    if (tolower(value) %in% .roundingLaws){
      GPE$roundingLaw <- value
    } else {
      traceMessage(paste0(value, " is not an allowed rounding law value"))
    }
  }

  return(invisible(prevValue))
}
