#' Information about zurngtest
#'
#' Reports the package version, the vendored 'PractRand' version and the
#' test batteries available.
#'
#' @return A list with elements `version` (the package version),
#'   `practrand` (the vendored 'PractRand' version, `NA` until it is
#'   vendored) and `batteries` (the names of the test batteries).
#' @export
#' @examples
#' zurngtest_info()
zurngtest_info <- function() {
  list(
    version = unname(getNamespaceVersion("zurngtest")),
    practrand = NA_character_,
    batteries = c("core", "expanded")
  )
}
