# zurngtest 0.0.0.9000

* `zurngtest_info()` reports the package version and the test batteries.
* Every condition the package signals inherits `zurngtest_error`.
* Bundles PractRand 0.96, compiled without output to the console and without
  calls that end R; `zurngtest_info()` reports its version.
* `pract_test()` runs PractRand's core or expanded battery on a source at
  doubling lengths and returns a `zurngtest_result`: one row per test result
  per length, with PractRand's evaluation, the first failing length and a
  `print()` method in the style of `RNG_test`.
* `pract_raw()` and `pract_fun()` make sources from raw bytes, connections
  and R functions.
