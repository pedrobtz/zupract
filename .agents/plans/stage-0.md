# Stage 0 — Package identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** zurngtest has its real name and metadata, its condition classes and
an info stub, and CI whose quick profile finishes in under five minutes.

**Architecture:** Base R only. Conditions are built with `structure()` and
signalled with `stop()`, so no runtime dependency is added. CI callers keep
r-actions' example triggers and profile expression.

**Tech Stack:** R (>= 4.1), testthat 3e, roxygen2, pedrobtz/r-actions v1.

**Spec:** `.agents/design.md` §3, §8; `.agents/roadmap.md` Stage 0.

## Global Constraints

- Package name `zurngtest`; R prefix `pract_`; internal C prefix `zrt_` (D7).
- `Depends: R (>= 4.1)`; `Language: en-GB`; `Version: 0.0.0.9000`.
- Zero hard runtime dependencies.
- Every condition inherits `zurngtest_error`: `zurngtest_invalid_argument`,
  `zurngtest_source_error`, `zurngtest_internal_error`.
- Tests assert on condition class, never on message text.

## Review Focus

- A condition caught with `tryCatch(error = )` must still be an `error`, and
  one caught with `zurngtest_error = ` must catch all three subclasses.
- Extra fields passed to the condition constructor must be retrievable from
  the condition object (later stages attach `bytes` to source errors).
- `zurngtest_info()` must not fail before PractRand is vendored.

---

### Task 1: Identity files

**Files:**

- Modify: `DESCRIPTION`, `LICENSE`, `LICENSE.md`, `_pkgdown.yml`

- [ ] **Step 1:** `DESCRIPTION`: Title "Test Random Number Generators with
  'PractRand'"; a Description naming PractRand (Doty-Humphrey), doubling
  lengths, sources (R generators, R functions, raw bytes, a registered C
  callable); `Authors@R` with Pedro Baltazar (`aut`, `cre`, `cph`) and Chris
  Doty-Humphrey (`cph`, comment "PractRand library, src/practrand/");
  `Depends: R (>= 4.1)`; `Language: en-GB`; `URL` with the pkgdown site and
  the repository; `BugReports`.
- [ ] **Step 2:** `LICENSE` and `LICENSE.md` copyright holder Pedro Baltazar.
- [ ] **Step 3:** Verify: `Rscript -e 'desc::desc_validate()'` or
  `devtools::check(document = TRUE)` reports no DESCRIPTION issue.

### Task 2: Conditions and info stub

**Files:**

- Create: `R/conditions.R`, `R/info.R`, `tests/testthat/test-conditions.R`,
  `tests/testthat/test-info.R`
- Delete: `tests/testthat/test-zurngtest.R` (scaffold placeholder)

**Interfaces:**

- Produces: `zrt_abort(message, class, ..., call = caller_env_call)` →
  signals a condition of class
  `c(class, "zurngtest_error", "error", "condition")` with `...` as fields.
  Later stages use `class = "zurngtest_invalid_argument"` etc.
- Produces: exported `zurngtest_info()` → list with `version` (package
  version, character), `practrand` (`NA_character_` until Stage 1),
  `batteries` (`c("core", "expanded")`).

- [ ] **Step 1: Failing tests**

```r
test_that("zrt_abort() signals the class, the root class and error", {
  for (cls in c("zurngtest_invalid_argument", "zurngtest_source_error",
                "zurngtest_internal_error")) {
    expect_error(zrt_abort("boom", cls), class = cls)
    expect_error(zrt_abort("boom", cls), class = "zurngtest_error")
  }
})
test_that("zrt_abort() keeps extra fields", {
  cnd <- tryCatch(zrt_abort("x", "zurngtest_source_error", bytes = 1024),
                  zurngtest_error = identity)
  expect_equal(cnd$bytes, 1024)
})
test_that("zurngtest_info() describes the package", {
  info <- zurngtest_info()
  expect_type(info, "list")
  expect_named(info, c("version", "practrand", "batteries"))
  expect_equal(info$batteries, c("core", "expanded"))
})
```

- [ ] **Step 2:** `devtools::test()`: fails, functions not defined.
- [ ] **Step 3:** Implement both; roxygen-document `zurngtest_info()` only.
- [ ] **Step 4:** `devtools::document()`; `devtools::test(shuffle = TRUE)`
  passes; `air format .`.
- [ ] **Step 5:** Commit.

### Task 3: CI callers

**Files:**

- Modify: `.github/workflows/R-CMD-check.yaml`, `.github/workflows/coverage.yaml`

- [ ] **Step 1:** Add the default four `runners` plus
  `{"os": "windows-latest", "r": "devel"}` to the R-CMD-check caller.
- [ ] **Step 2:** Pin `coverage.yml` to `17264ce002a9359a492e0183852a555a5bb866e7`
  with `# v1.23.0`.
- [ ] **Step 3:** Commit; after the pull request runs, read check durations
  from `gh pr checks` and record them in the roadmap's Stage 0 section.

### Task 4: Close out

- [ ] `devtools::check()`: 0 errors, 0 warnings, 0 notes (bar "New
  submission").
- [ ] NEWS.md bullet; roadmap `Done` date; commit.
