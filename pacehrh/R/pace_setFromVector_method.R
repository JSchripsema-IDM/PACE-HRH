# #' @exportMethod setFromVector
#'
methods::setGeneric(
  name = "setFromVector",
  def = function(object, values)
  {
    standardGeneric("setFromVector")
  }
)

#' Set Pyramid Age Values
#'
#' @param object PopulationPyramid object
#' @param values Vector of values to copy into PopulationPyramid object
#'
#' @return Updated \code{PopulationPyramid} object
#'
methods::setMethod(
  f = "setFromVector",
  signature = c("PopulationPyramid", "numeric"),
  definition = function(object, values)
  {
    assertthat::assert_that(length(values) == length(GPE$ages))
    assertthat::assert_that(is.numeric(values) == TRUE)

    # Clear any names on the vector
    names(values) <- NULL

    object@values = values
    return(object)
  }
)
