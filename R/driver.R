# The batteries pract_test() accepts, in the order the native driver numbers
# them (1 core, 2 expanded). zurngtest_info() reports the same list.
battery_names <- c("core", "expanded")

# Thin wrappers around the native driver in src/driver.cpp. `bits` is the
# source's native word size, 0 when unknown, and selects PractRand's folding.
driver_new <- function(battery, folding, bits, seed) {
  .Call(
    zrt_driver_new,
    match(battery, battery_names),
    folding,
    as.integer(bits),
    as.double(seed)
  )
}

driver_feed <- function(driver, data) {
  invisible(.Call(zrt_driver_feed, driver, data))
}

driver_results <- function(driver) {
  .Call(zrt_driver_results, driver)
}
