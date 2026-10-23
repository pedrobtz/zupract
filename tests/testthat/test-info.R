test_that("zurngtest_info() describes the package", {
  info <- zurngtest_info()
  expect_type(info, "list")
  expect_named(info, c("version", "practrand", "batteries"))
  expect_equal(info$version, unname(getNamespaceVersion("zurngtest")))
  expect_equal(info$batteries, c("core", "expanded"))
})
