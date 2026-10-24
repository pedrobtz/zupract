# pract_test() for a generator in C, called by zurngtest_test_cfun()
# (src/callable.cpp) with the generator in `ptr`: the source fills each chunk
# natively. `options` is a named list of further pract_test() arguments, or
# NULL.
test_cfun <- function(ptr, options) {
  if (!is.null(options) && !(is.list(options) && !is.null(names(options)))) {
    zurngtest_abort(
      "`options` must be a named list of pract_test() arguments, or NULL.",
      "zurngtest_invalid_argument"
    )
  }
  open <- function() {
    list(
      fill = function(nbytes) .Call(zrt_cfun_fill, ptr, nbytes),
      close = function() invisible()
    )
  }
  source <- new_source(
    open,
    bits = 32L,
    description = "C function, 32-bit words"
  )
  do.call(pract_test, c(list(source), options))
}
