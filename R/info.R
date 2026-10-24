#' Information about zurngtest
#'
#' Reports the package version, the vendored 'PractRand' version and the
#' test batteries zurngtest supports.
#'
#' @return A list with elements `version` (the package version, a string),
#'   `practrand` (the version of the vendored 'PractRand' library, a
#'   string) and `batteries` (a character vector of battery names).
#' @export
#' @examples
#' zurngtest_info()
zurngtest_info <- function() {
  list(
    version = unname(getNamespaceVersion("zurngtest")),
    practrand = .Call(zrt_practrand_version),
    batteries = c("core", "expanded")
  )
}
