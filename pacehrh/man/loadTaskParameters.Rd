% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pace_task_config.R
\name{loadTaskParameters}
\alias{loadTaskParameters}
\title{Load Healthcare Task Information}
\usage{
loadTaskParameters(sheetName = "TaskValues")
}
\arguments{
\item{sheetName}{Sheet name from the model input Excel file}
}
\value{
Data frame of healthcare task parameters
}
\description{
Read the healthcare task information from the model inputs Excel file. The
name and location of the model inputs Excel file is loaded from the global
configuration JSON file.
}
