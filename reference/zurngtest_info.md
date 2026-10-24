# Information about zurngtest

Reports the package version, the vendored 'PractRand' version and the
test batteries available.

## Usage

``` r
zurngtest_info()
```

## Value

A list with elements `version` (the package version), `practrand` (the
version of the vendored 'PractRand' library) and `batteries` (the names
of the test batteries).

## Examples

``` r
zurngtest_info()
#> $version
#> [1] "0.0.0.9000"
#> 
#> $practrand
#> [1] "0.96"
#> 
#> $batteries
#> [1] "core"     "expanded"
#> 
```
