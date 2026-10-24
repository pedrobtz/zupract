test_that("pract_rng() gives Mersenne-Twister's own 32-bit words", {
  reader <- pract_rng("Mersenne-Twister", seed = 3)$open()
  words <- reader$fill(16)
  reader$close()
  withr::local_seed(3, .rng_kind = "Mersenne-Twister")
  expected <- runif(4) * 2^32
  got <- as.double(words) + ifelse(is.na(words) | words < 0, 2^32, 0)
  got[is.na(words)] <- 2^31
  expect_equal(got, expected)
})

test_that("pract_rng() packs Knuth-TAOCP's 30-bit values without losing a bit", {
  reader <- pract_rng("Knuth-TAOCP-2002", seed = 5)$open()
  bytes <- reader$fill(30)
  reader$close()
  withr::local_seed(5, .rng_kind = "Knuth-TAOCP-2002")
  values <- round(runif(8) * 2^30)
  bits <- unlist(lapply(values, function(v) {
    rev(as.integer(intToBits(v))[1:30])
  }))
  packed <- unlist(lapply(as.integer(bytes), function(b) {
    rev(as.integer(intToBits(b))[1:8])
  }))
  expect_equal(packed, bits)
})

test_that("pract_rng() leaves the user's stream as it was", {
  withr::local_seed(11, .rng_kind = "Mersenne-Twister")
  before <- .Random.seed
  res <- pract_test(
    pract_rng("Wichmann-Hill", seed = 1),
    min_bytes = 2^16,
    max_bytes = 2^16,
    folding = FALSE
  )
  expect_equal(.Random.seed, before)
  expect_equal(RNGkind()[[1]], "Mersenne-Twister")
})

test_that("pract_rng() leaves the session's generator alone between draws", {
  withr::local_seed(11, .rng_kind = "Mersenne-Twister")
  before <- .Random.seed
  reader <- pract_rng("Super-Duper", seed = 1)$open()
  expect_equal(.Random.seed, before)
  reader$fill(8)
  expect_equal(.Random.seed, before)
  expect_equal(RNGkind()[[1]], "Mersenne-Twister")
  reader$close()
  expect_equal(.Random.seed, before)
  # A run that fails at the source still closes it.
  expect_error(
    pract_test(pract_rng("Mersenne-Twister"), min_bytes = 2^16, battery = "x"),
    class = "zurngtest_invalid_argument"
  )
  expect_equal(.Random.seed, before)
})

test_that("pract_rng() removes a .Random.seed it created", {
  withr::local_seed(1, .rng_kind = "Mersenne-Twister")
  rm(".Random.seed", envir = globalenv())
  reader <- pract_rng("Super-Duper")$open()
  reader$fill(8)
  reader$close()
  # R seeds its current kind on the next draw, so it must be the session's.
  expect_equal(RNGkind()[[1]], "Mersenne-Twister")
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
})

test_that("pract_rng() checks the kind and the seed", {
  expect_error(pract_rng("Unknown"), class = "zurngtest_invalid_argument")
  expect_error(pract_rng(seed = "a"), class = "zurngtest_invalid_argument")
  expect_error(pract_rng(seed = NA), class = "zurngtest_invalid_argument")
})

test_that("pract_rng() describes how each kind's bits are taken", {
  expect_match(pract_rng()$description, "Mersenne-Twister.*32-bit integers")
  expect_match(
    pract_rng("Wichmann-Hill")$description,
    "32 most significant bits"
  )
  expect_match(pract_rng("Knuth-TAOCP")$description, "30-bit")
})

test_that("Mersenne-Twister passes a short run", {
  res <- pract_test(pract_rng(), min_bytes = 2^18, max_bytes = 2^18)
  expect_true(is.na(attr(res, "failed_at")))
})
