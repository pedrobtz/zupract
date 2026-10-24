test_that("zurngtest_info() describes the package", {
  info <- zurngtest_info()
  expect_type(info, "list")
  expect_named(info, c("version", "practrand", "batteries"))
  expect_type(info$version, "character")
  expect_equal(info$version, as.character(packageVersion("zurngtest")))
  expect_equal(info$batteries, c("core", "expanded"))
})

test_that("zurngtest_info() reports the vendored PractRand version", {
  practrand <- zurngtest_info()$practrand
  expect_type(practrand, "character")
  expect_equal(practrand, "0.96")
})
