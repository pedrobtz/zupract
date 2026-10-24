# Sources for the pract_test() tests.

# A source that fails at once: a 256-byte pattern, repeated.
repeating <- function(bytes) {
  pract_raw(rep(as.raw(0:255), length.out = bytes))
}

# A source that passes short runs: bytes from R's generator.
r_bytes <- function() {
  pract_fun(function(n) as.raw(sample.int(256L, n, TRUE) - 1L), bits = 8)
}

# pract_test() without the standard foldings, which triple a short run's
# cost; for tests that are not about folding.
quick_test <- function(source, ...) {
  pract_test(source, folding = FALSE, ...)
}
