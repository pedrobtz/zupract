test_that("zurngtest_abort() signals each class under zurngtest_error", {
  expect_error(
    zurngtest_abort("x", "zurngtest_invalid_argument"),
    class = "zurngtest_invalid_argument"
  )
  expect_error(
    zurngtest_abort("x", "zurngtest_source_error"),
    class = "zurngtest_source_error"
  )
  expect_error(
    zurngtest_abort("x", "zurngtest_internal_error"),
    class = "zurngtest_internal_error"
  )
  expect_error(
    zurngtest_abort("x", "zurngtest_internal_error"),
    class = "zurngtest_error"
  )
})

test_that("zurngtest_abort() orders the classes from specific to general", {
  cnd <- tryCatch(
    zurngtest_abort("x", "zurngtest_source_error"),
    error = identity
  )
  expect_equal(
    class(cnd),
    c("zurngtest_source_error", "zurngtest_error", "error", "condition")
  )
})

test_that("zurngtest_abort() reports the call of the function that called it", {
  f <- function() zurngtest_abort("x", "zurngtest_internal_error")
  cnd <- tryCatch(f(), error = identity)
  expect_equal(cnd$call, quote(f()))
})

test_that("zurngtest_abort() keeps extra fields", {
  cnd <- tryCatch(
    zurngtest_abort("x", "zurngtest_source_error", bytes = 1024),
    zurngtest_error = identity
  )
  expect_equal(cnd$bytes, 1024)
})

test_that("extra fields cannot replace the message or the call", {
  # `message` and `call` are formal arguments, so R matches them there and
  # never passes them through `...` to override the condition's own.
  f <- function() zurngtest_abort("x", "zurngtest_internal_error", call = NULL)
  cnd <- tryCatch(f(), error = identity)
  expect_equal(conditionMessage(cnd), "x")
  expect_null(cnd$call)
})

test_that("zurngtest_abort() messages name the caller", {
  f <- function() {
    zurngtest_abort("`n` must be positive.", "zurngtest_invalid_argument")
  }
  expect_snapshot(f(), error = TRUE)
})
