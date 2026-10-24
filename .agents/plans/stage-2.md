# Stage 2 — Driver and core battery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `pract_test()` runs PractRand's core and expanded batteries at
doubling lengths over `pract_raw()` and `pract_fun()` sources and returns a
`zurngtest_result`.

**Architecture:** R drives the loop; C++ holds the test state. A driver
object (tests, known-good hc256, block buffer with the repeated prefix,
ported from `tools/TestManager.h`) lives behind a finalised external
pointer. R reads bytes from the source, hands each chunk to
`zrt_driver_feed`, and collects results at each length, so no R code runs
inside a C++ frame and interrupts are plain R. No C++ local with a
non-trivial destructor is alive in a frame that calls an R API function that
can longjmp; every `.Call` entry catches `std::exception` and signals
`zurngtest_internal_error`.

**Tech Stack:** R (>= 4.1), C++ (R's default standard), PractRand 0.96.

**Spec:** `.agents/design.md` §4, §5, §6, §8, §9; roadmap Stage 2.

## Global Constraints

- Labels and thresholds are `RNG_test`'s, unchanged (D5): score =
  (|suspicion| + log2(normalised weight)) · log10(2), floored at 0; labels
  normal, normalish (>0), unusual (>1), mildly suspicious (>2), suspicious
  (>3), very suspicious (>4), VERY SUSPICIOUS (>6), FAIL (>8.5), FAIL ! (>12),
  FAIL !! (>17), FAIL !!! (>25), FAIL !!!! (>45), FAIL !!!!! (>85),
  FAIL !!!!!! (>165), FAIL !!!!!!! (>325), FAIL !!!!!!!! (>999).
- Lengths are powers of two from `min_bytes` to `max_bytes`, both powers of
  two and at least 1024 (one PractRand block).
- `pract_raw()` has an unknown word size (RNG_test's `stdin`), so folding is
  the generic one; `pract_fun(f, bits)` folds by `bits`.
- `seed` seeds PractRand's known-good generator; `NULL` is a fixed default.
- A source that ends after at least one completed length ends the run with a
  final row set at the bytes actually tested; before `min_bytes` it is a
  `zurngtest_source_error`.
- Zero hard runtime dependencies; condition classes per design §8.

## Review Focus

- A source that returns more bytes than asked must not over-feed a length.
- A raw source or connection whose length is not a multiple of 1024: the
  tail below one block is dropped, never fed.
- Reusing one source object for two runs starts each run from the start.
- An interrupt during a length returns the lengths already completed.
- A `pract_fun()` returning `NA`, doubles or a list is a source error.

### Task 1: C++ driver and entry points (`src/driver.cpp`)

`zrt_driver_new(battery, folding, bits, seed)`, `zrt_driver_feed(driver,
data)` (raw or integer), `zrt_driver_results(driver)` (list of `test`,
`p_value`, `evaluation`), `zrt_issue_error_for_tests()`. Tests: an internal
error from PractRand reaches R as `zurngtest_internal_error`.

### Task 2: Sources (`R/sources.R`)

`pract_raw(x)` (raw vector or connection) and `pract_fun(f, bits = 32)`,
each a `zurngtest_source` whose `open()` returns a fresh reader. Tests:
argument classes, type and length errors from `f`.

### Task 3: `pract_test()` and `zurngtest_result` (`R/pract-test.R`)

Validation, the doubling loop, stop on failure, early end, interrupt,
`failed_at`, `source`, `elapsed`, `print()`. Tests per the exit criteria.

### Task 4: Close out

One battery list shared with `zurngtest_info()`, NEWS, roadmap, full local
check with CRAN flags, R-devel warning list, shuffled suite.
