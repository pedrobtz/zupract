# Every condition the package signals inherits `zurngtest_error`, so callers
# can catch them all; tests assert on the class, never on the message.
#
# `call` defaults to the call of the function that called zurngtest_abort(),
# so errors name the user-facing function. A wrapper around this helper must
# pass its own `call`.
zurngtest_abort <- function(message, class, ..., call = sys.call(-1)) {
  cnd <- structure(
    list(message = message, call = call, ...),
    class = c(class, "zurngtest_error", "error", "condition")
  )
  stop(cnd)
}
