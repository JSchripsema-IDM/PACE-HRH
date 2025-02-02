.allowedFPlotTypes <- c("lines", "ribbon", "boxplot")
.defaultFPlotType <- .allowedFPlotTypes[1]

.validateFPlotType <- function(type) {
  allowedTypes <-

  if (is.null(type)) {
    return(.defaultFPlotType)
  }

  if (!is.character(type)) {
    return(.defaultFPlotType)
  }

  if (type %in% .allowedFPlotTypes) {
    return(type)
  }

  return(.defaultFPlotType)
}

.combineFRatesMatrices <- function(results) {
  l <- lapply(results, function(r) {
    df <- as.data.frame(r$PopulationRates[["femaleFertility"]]$ratesMatrix)
    cols <- names(df)
    df$Label <- row.names(df)
    df <-
      tidyr::pivot_longer(
        df,
        cols = all_of(cols),
        names_to = "Year",
        values_to = "Rate"
      )
    return(df)
  })

  df <- data.table::rbindlist(l)
  df <- subset(df, !startsWith(df$Label, "NA"))
  df$LogRate <- log10(df$Rate)

  # Label                Year Rate        LogRate
  # AnnualBirthRate15_19 2020 0.075817219 -1.120232
  # AnnualBirthRate15_19 2021 0.076072137 -1.118774
  # AnnualBirthRate15_19 2022 0.073017269 -1.136574
  # AnnualBirthRate15_19 2023 0.080289581 -1.095341
  # AnnualBirthRate15_19 2024 0.070030775 -1.154711

  return(df)
}

#' Plot Fertility Rates Statistics
#'
#' @param results Results list (as returned by \code{RunExperiments()})
#' @param se Whether to show standard error or standard deviation confidence intervals.
#' Note: the \code{se} parameter does not apply to the "boxplot" type.
#' @param type Plot type (options = "lines", "ribbon", "boxplot")
#' @param log Use log scale for rates (default = TRUE). Applies only to "boxplot" type.
#'
#' @return ggplot grob
#' @export
#'
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 geom_line
#' @importFrom ggplot2 facet_wrap
#' @importFrom ggplot2 vars
#' @importFrom ggplot2 scale_x_discrete
#' @importFrom ggplot2 theme
#' @importFrom ggplot2 geom_errorbar
#' @importFrom ggplot2 geom_pointrange
#' @importFrom ggplot2 geom_ribbon
#' @importFrom ggplot2 geom_boxplot
#' @importFrom ggplot2 ylab
#' @importFrom ggplot2 xlab
#' @importFrom tidyr pivot_longer
#' @importFrom dplyr group_by
#' @importFrom dplyr summarize
#'
#' @examples
#' \dontrun{
#' library(pacehrh)
#'
#' pacehrh::InitializePopulation()
#' pacehrh::InitializeScenarios()
#' pacehrh::InitializeStochasticParameters()
#' pacehrh::InitializeSeasonality()
#'
#' scenario <- "ScenarioName"
#'
#' results <-
#'   pacehrh::RunExperiments(scenarioName = scenario,
#'                        trials = 100)
#'
#' g <- pacehrh::PlotFertilityRatesStats(results, type = "boxplot", log = FALSE)
#' print(g)
#'
#' g <- pacehrh::PlotFertilityRatesStats(results, type = "boxplot", log = TRUE)
#' print(g)
#'
#' g <- pacehrh::PlotFertilityRatesStats(results, se = FALSE, type = "lines")
#' print(g)
#'
#' g <- pacehrh::PlotFertilityRatesStats(results, se = TRUE, type = "lines")
#' print(g)
#'
#' g <- pacehrh::PlotFertilityRatesStats(results, se = FALSE, type = "ribbon")
#' print(g)
#'
#' g <- pacehrh::PlotFertilityRatesStats(results, se = TRUE, type = "ribbon")
#' print(g)
#' }
PlotFertilityRatesStats <- function(results, se = FALSE, type = "lines", log = TRUE) {
  if (is.null(results)) {
    return(NULL)
  }

  n <- length(results)

  if (n < 1) {
    return(NULL)
  }

  type <- .validateFPlotType(type)

  df <- .combineFRatesMatrices(results)

  if (type == "boxplot") {
    return(.fRatesBoxPlot(df, log))
  } else if (type == "ribbon") {
    return(.fRatesRibbonPlot(df, se, n))
  } else if (type == "lines") {
    return(.fRatesLinesPlot(df, se, n))
  } else {
    return(.fRatesLinesPlot(df, se, n))
  }
}

.fRatesBoxPlot <- function(df, log) {
  if (log){
    g <- ggplot(df, aes(
      x = Year,
      y = LogRate,
      color = Label,
      group = Year))
  } else {
    g <- ggplot(df, aes(
      x = Year,
      y = Rate,
      color = Label,
      group = Year))
  }

  g <- g + geom_boxplot()
  g <- g + scale_x_discrete(breaks = seq(2000, 2100, 5))
  g <- g + theme(legend.position = "none")

  if (log){
    g <- g + facet_wrap(vars(Label))
    g <- g + ylab("log10(Rate)") + xlab("Year")
  } else {
    g <- g + facet_wrap(vars(Label), scales = "free_y")
    g <- g + ylab("Rate") + xlab("Year")
  }

  return(g)
}

.fRatesRibbonPlot <- function(df, se, trials) {
  dff <- df %>% group_by(Label,Year) %>% summarize(m = mean(LogRate), sd = sd(LogRate))

  # Compute the 95% confidence interval
  if (se == TRUE) {
    dff$CI <- dff$sd * qt(0.975, trials - 1) / sqrt(trials)
    ylabel <- "Mean log10(Rate) (CI = 95%)"
  } else {
    dff$CI <- dff$sd * qt(0.975, trials - 1)
    ylabel <- "Variance log10(Rate) (CI = 95%)"
  }

  g <- ggplot(dff, aes(
    x = Year,
    y = m,
    color = Label,
    group = Label
  ))
  g <- g + geom_ribbon(aes(ymin = m - CI, ymax = m + CI, fill = Label), alpha = 0.5)
  g <- g + geom_line(size = .5)
  g <- g + facet_wrap(vars(Label))
  g <- g + scale_x_discrete(breaks = seq(2000, 2100, 5))
  g <- g + theme(legend.position = "none")
  g <- g + ylab(ylabel) + xlab("Year")
  g <- g + xlab("Year")

  return(g)
}

.fRatesLinesPlot <- function(df, se, trials) {
  dff <- df %>% group_by(Label,Year) %>% summarize(m = mean(LogRate), sd = sd(LogRate))

  # Compute the 95% confidence interval
  if (se == TRUE) {
    dff$CI <- dff$sd * qt(0.975, trials - 1) / sqrt(trials)
    ylabel <- "Mean log10(Rate) (CI = 95%)"
  } else {
    dff$CI <- dff$sd * qt(0.975, trials - 1)
    ylabel <- "Variance log10(Rate) (CI = 95%)"
  }

  g <- ggplot(dff, aes(
    x = Year,
    y = m,
    color = Label,
    group = Label
  ))
  g <- g + geom_pointrange(aes(ymin = m - CI, ymax = m + CI), size = 0.5)
  g <- g + facet_wrap(vars(Label))
  g <- g + scale_x_discrete(breaks = seq(2000, 2100, 5))
  g <- g + theme(legend.position = "none")
  g <- g + ylab(ylabel) + xlab("Year")
  g <- g + xlab("Year")

  return(g)
}

#' Plot Fertility Rates
#'
#' @param populationRates Population rates list, as returned by \code{RunExperiments()}
#' @param year Year
#'
#' @return ggplot grob
#' @export
#'
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 geom_point
#' @importFrom ggplot2 facet_grid
#' @importFrom ggplot2 vars
#' @importFrom ggplot2 ggtitle
#' @importFrom ggplot2 scale_color_manual
#' @importFrom tidyr pivot_longer
#'
#' @examples
#' \dontrun{
#' library(pacehrh)
#'
#' pacehrh::InitializePopulation()
#' pacehrh::InitializeScenarios()
#' pacehrh::InitializeStochasticParameters()
#' pacehrh::InitializeSeasonality()
#'
#' scenario <- "ScenarioName"
#'
#' results <-
#'   pacehrh::RunExperiments(scenarioName = scenario,
#'                        trials = 100)
#'
#' g <- pacehrh::PlotFertilityRates(results[[49]]$PopulationRates, 2030)
#' print(g)
#' }
PlotFertilityRates <- function(populationRates, year){
  rates <- .explodeRates(populationRates, year)

  df <- as.data.frame(rates)
  df$Age <- GPE$ages
  dff <-
    tidyr::pivot_longer(
      df,
      cols = c(
        "femaleFertility",
        "maleFertility",
        "femaleMortality",
        "maleMortality"
      ),
      names_to = "Sex",
      values_to = "Rate"
    )

  dff <- dff[dff$Sex %in% c("femaleFertility", "maleFertility"),]

  titleStr <- paste("Fertility Rates (", year, ")", sep = "")

  g <- ggplot(dff, aes(x = Age, y = Rate, color = Sex))
  g <- g + scale_color_manual(values = c(.colorF, .colorM))
  g <- g + theme(legend.position = "none")
  g <- g + geom_point(alpha = 0.5)
  g <- g + facet_grid(cols = vars(Sex))
  g <- g + ggtitle(titleStr) + xlab("Age") + ylab("Rate")
  return(g)
}

#' Plot A Single Pair of Fertility Rates Curves From A Results List
#'
#' @param results Results list (as returned by \code{RunExperiments()})
#' @param trial Trail number (index into the results list)
#' @param year Year in trial timeseries to plot
#'
#' @return ggplot grob, or NULL on error
#' @export
#'
#' @examples
#' \dontrun{
#' library(pacehrh)
#'
#' pacehrh::InitializePopulation()
#' pacehrh::InitializeScenarios()
#' pacehrh::InitializeStochasticParameters()
#' pacehrh::InitializeSeasonality()
#'
#' scenario <- "ScenarioName"
#'
#' results <-
#'   pacehrh::RunExperiments(scenarioName = scenario,
#'                        trials = 100)
#'
#' g <- pacehrh::PlotResultsFertilityRates(results, 49, 2030)
#' print(g)
#' }
PlotResultsFertilityRates <- function(results, trial = 1, year = 2020){
  if (!.validResultsParams(results, trial, year)) {
    return(NULL)
  }

  return(PlotFertilityRates(results[[trial]]$PopulationRates, year))
}

