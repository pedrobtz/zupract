# Every condition the package signals inherits `zurngtest_error`, so callers
# can catch them all; tests assert on the class, never on the message.
zrt_abort <- function(message, class, ..., call = sys.call(-1)) {
  cnd <- structure(
    list(message = message, call = call, ...),
    class = c(class, "zurngtest_error", "error", "condition")
  )
  stop(cnd)
}
