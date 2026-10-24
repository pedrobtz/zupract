test_that("an error inside PractRand reaches R as zurngtest_internal_error", {
  expect_error(
    .Call(zrt_issue_error_for_tests),
    class = "zurngtest_internal_error"
  )
})

test_that("the driver tests fed blocks and labels the results", {
  driver <- driver_new("core", folding = FALSE, bits = 0L, seed = 1)
  driver_feed(driver, as.raw(rep(0:255, 4096)))
  res <- driver_results(driver)
  expect_named(res, c("test", "p_value", "evaluation"))
  expect_gt(length(res$test), 0)
  expect_type(res$p_value, "double")
  # 1 MiB of a repeating 256-byte pattern fails at once.
  expect_true(any(startsWith(res$evaluation, "FAIL")))
})

test_that("the driver takes integer words as well as raw bytes", {
  driver <- driver_new("core", folding = TRUE, bits = 32L, seed = 1)
  driver_feed(driver, rep(c(1L, -1L), 2^17))
  expect_gt(length(driver_results(driver)$test), 0)
})

test_that("the driver rejects data that is not whole blocks", {
  driver <- driver_new("core", folding = FALSE, bits = 0L, seed = 1)
  expect_error(
    driver_feed(driver, raw(1000)),
    class = "zurngtest_internal_error"
  )
  expect_error(
    driver_feed(driver, 1.5),
    class = "zurngtest_internal_error"
  )
})
