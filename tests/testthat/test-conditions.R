test_that("zrt_abort() signals its class, the root class and error", {
  classes <- c(
    "zurngtest_invalid_argument",
    "zurngtest_source_error",
    "zurngtest_internal_error"
  )
  for (cls in classes) {
    expect_error(zrt_abort("boom", cls), class = cls)
    expect_error(zrt_abort("boom", cls), class = "zurngtest_error")
  }
})

test_that("zrt_abort() keeps extra fields", {
  cnd <- tryCatch(
    zrt_abort("x", "zurngtest_source_error", bytes = 1024),
    zurngtest_error = identity
  )
  expect_s3_class(cnd, "error")
  expect_equal(cnd$bytes, 1024)
})
