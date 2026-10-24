#' Information about zurngtest
#'
#' Reports the package version, the vendored 'PractRand' version and the
#' test batteries available.
#'
#' @return A list with elements `version` (the package version),
#'   `practrand` (the version of the vendored 'PractRand' library) and
#'   `batteries` (the names of the test batteries).
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
