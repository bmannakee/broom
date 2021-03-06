#' Tidy estimated marginal means (least-squares means) objects from the emmeans and lsmeans packages
#'
#' Tidiers for estimated marginal means objects, which report the predicted
#' means for factors or factor combinations in a linear model. This
#' covers three classes:
#' \code{emmGrid}, \code{lsmobj}, and \code{ref.grid}. (The first class is from the \code{emmeans}
#' package, and is the successor to the latter two classes, which have slightly different
#' purposes within the \code{lsmeans} package but have similar output).
#'
#' @param x "emmGrid", lsmobj", or "ref.grid" object
#' @param conf.level Level of confidence interval, used only for
#' \code{emmGrid} and \code{lsmobj} objects
#' @param ... Extra arguments, passed on to
#' \link[emmeans]{summary.emmGrid} or \link[lsmeans]{summary.ref.grid}
#'
#' @return A data frame with one observation for each estimated
#' mean, and one column for each combination of factors, along with
#' the following variables:
#'   \item{estimate}{Estimated least-squares mean}
#'   \item{std.error}{Standard error of estimate}
#'   \item{df}{Degrees of freedom}
#'   \item{conf.low}{Lower bound of confidence interval}
#'   \item{conf.high}{Upper bound of confidence interval}
#'
#' When the input is a contrast, each row will contain one estimated
#' contrast, along with some of the following columns:
#'   \item{level1}{One level of the factor being contrasted}
#'   \item{level2}{Second level}
#'   \item{contrast}{In cases where the contrast is not made up of
#'   two levels, describes each}
#'   \item{statistic}{T-ratio statistic}
#'   \item{p.value}{P-value}
#'
#' @details There are a large number of arguments that can be
#' passed on to \link[emmeans]{summary.emmGrid} or \link[lsmeans]{summary.ref.grid}.
#' By broom convention, we use \code{conf.level} to pass the \code{level} argument.
#'
#' @examples
#'
#' if (require("emmeans", quietly = TRUE)) {
#'   # linear model for sales of oranges per day
#'   oranges_lm1 <- lm(sales1 ~ price1 + price2 + day + store, data = oranges)
#'
#'   # reference grid; see vignette("basics", package = "emmeans")
#'   oranges_rg1 <- ref_grid(oranges_lm1)
#'   td <- tidy(oranges_rg1)
#'   head(td)
#'
#'   # marginal averages
#'   marginal <- emmeans(oranges_rg1, "day")
#'   tidy(marginal)
#'
#'   # contrasts
#'   tidy(contrast(marginal))
#'   tidy(contrast(marginal, method = "pairwise"))
#'
#'   # plot confidence intervals
#'   library(ggplot2)
#'   ggplot(tidy(marginal), aes(day, estimate)) +
#'     geom_point() +
#'     geom_errorbar(aes(ymin = conf.low, ymax = conf.high))
#'
#'   # by multiple prices
#'   by_price <- emmeans(oranges_lm1, "day", by = "price2",
#'                       at = list(price1 = 50, price2 = c(40, 60, 80),
#'                       day = c("2", "3", "4")) )
#'   by_price
#'   tidy(by_price)
#'
#'   ggplot(tidy(by_price), aes(price2, estimate, color = day)) +
#'     geom_line() +
#'     geom_errorbar(aes(ymin = conf.low, ymax = conf.high))
#' }
#'
#' @name emmeans_tidiers
#' @export
tidy.lsmobj <- function(x, conf.level = .95, ...) {
  tidy_emmeans(x, level = conf.level, ...)
}


#' @rdname emmeans_tidiers
#' @export
tidy.ref.grid <- function(x, ...) {
  tidy_emmeans(x, ...)
}


#' @rdname emmeans_tidiers
#' @export
tidy.emmGrid <- function(x, ...) {
  tidy_emmeans(x, ...)
}


#' Tidy one of several object from the emmeans or lsmeans packages, which have
#' a similar structure
#'
#' @noRd
tidy_emmeans <- function(x, ...) {
  s <- summary(x, ...)
  ret <- as.data.frame(s)
  repl <- c(
    lsmean = "estimate",
    emmean = "estimate",
    pmmean = "estimate",
    prediction = "estimate",
    SE = "std.error",
    lower.CL = "conf.low",
    upper.CL = "conf.high",
    t.ratio = "statistic"
  )

  if ("contrast" %in% colnames(ret) &&
    all(stringr::str_detect(ret$contrast, " - "))) {
    ret <- tidyr::separate_(ret, "contrast",
      c("level1", "level2"),
      sep = " - "
    )
  }

  colnames(ret) <- plyr::revalue(colnames(ret), repl, warn_missing = FALSE)
  tibble::as_tibble(ret)
}
