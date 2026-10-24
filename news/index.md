# Changelog

## zurngtest 0.0.0.9000

- [`zurngtest_info()`](https://pedrobtz.github.io/zurngtest/reference/zurngtest_info.md)
  reports the package version and the test batteries.
- Every condition the package signals inherits `zurngtest_error`.
- Bundles PractRand 0.96, compiled without output to the console and
  without calls that end R;
  [`zurngtest_info()`](https://pedrobtz.github.io/zurngtest/reference/zurngtest_info.md)
  reports its version.
- [`pract_test()`](https://pedrobtz.github.io/zurngtest/reference/pract_test.md)
  runs PractRand’s core or expanded battery on a source at doubling
  lengths and returns a `zurngtest_result`: one row per test result per
  length, with PractRand’s evaluation, the first failing length and a
  [`print()`](https://rdrr.io/r/base/print.html) method in the style of
  `RNG_test`.
- [`pract_raw()`](https://pedrobtz.github.io/zurngtest/reference/pract_raw.md)
  and
  [`pract_fun()`](https://pedrobtz.github.io/zurngtest/reference/pract_raw.md)
  make sources from raw bytes, connections and R functions.
