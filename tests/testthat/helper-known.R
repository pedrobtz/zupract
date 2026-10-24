# A generator from src/test-generators.cpp, tested through the C callable.
known_generator <- function(name, ...) {
  .Call(zrt_test_generator, name, 1, list(...))
}

# Long runs take seconds to minutes; the equivalence workflow sets
# ZURNGTEST_LONG_TESTS=true to run them, and every other check skips them,
# valgrind and gctorture included.
skip_unless_long_tests <- function() {
  skip_if_not(
    identical(Sys.getenv("ZURNGTEST_LONG_TESTS"), "true"),
    "a long run: set ZURNGTEST_LONG_TESTS=true"
  )
}
