# RFC 0016: `zurngtest`, testing random number generators in R with PractRand

Adopted from [RFC 0016](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0016-zupract-practrand-rng-testing.md) on 2026-10-23. From here on this file is authoritative; the RFC is history.

- **Status:** Proposed. Merging this file adopts the design as the starting
  point for the package's own `.agents/design.md`; each decision in section
  13 stays the maintainer's until the package repository records it.
- **Date:** 2026-10-09.
- **Packages:** `zurngtest` (the RFC's working name was `zupract`); vendors
  PractRand; `zurand` in `Suggests` as its first test subject.
- **Source:** PractRand's documentation index at `pracrand.sourceforge.net`
  (`versions.txt`, last listed version 0.94; `Tests_usage.txt`, the library
  interface; `Tests_batteries.txt`); the package review of 2026-10-09 of
  Dirk Eddelbuettel's CRAN packages, which found `RDieHarder` (DieHarder,
  a 2000s-era suite) as the only test battery on CRAN and no binding of
  PractRand or TestU01. PractRand's licence file could not be fetched
  from this session; it is reported as public domain and Stage 0 confirms
  it before anything is vendored. Nothing was built; section 11 says what
  the first stage measures.

## 1. What zurngtest is

`zurngtest` runs PractRand, Chris Doty-Humphrey's statistical test suite
for random number generators, from R. PractRand finds flaws in
generators that DieHarder passes, and it is the de facto standard in the
current literature on generator design: it tests a stream of bits at
doubling lengths (1 KB, 2 KB, … up to terabytes) and reports the length
at which a generator first fails.

R users need it in three places:

- **Package authors of generators** (`dqrng`, `zurand`, `RcppZiggurat`,
  parallel and counter-based streams) who should publish PractRand
  results and today have to export bytes to the command-line tool.
- **Users of R's own generators** (`RNGkind()`), to see what
  Mersenne-Twister, L'Ecuyer-CMRG or a user-supplied generator survive.
- **Simulation work** that combines streams (seeding schemes, parallel
  substreams, `set.seed()` patterns), where the combination, not the
  generator, is what breaks.

The one-line statement that governs every decision below:

> **Feed PractRand the generator's own bits, as fast as C allows, and
> report the length at which it fails.**

## 2. Scope

**In v0.1.0:**

- `pract_test()` with PractRand's standard batteries (core and expanded
  folding), at doubling lengths up to `max_bytes`, stopping at the first
  failure if asked.
- Sources of bits: R's own generators by `RNGkind()` name, an R function
  returning raw or integer vectors, a file or connection of raw bytes,
  and a **C function pointer** registered by another package (§5.2), the
  fast path for generator packages.
- Results as a data frame per length: test name, p-value, PractRand's
  evaluation (normal, unusual, suspicious, failure).
- Interleaving and combining sources (two seeds of one generator,
  substreams) for seeding studies.

**Later, when asked:**

- PractRand's own generators as R generators (`sfc64`, `jsf64`, `efiix`)
  via `RNGkind("user-supplied")`.
- Multithreaded batteries (`MultithreadedTestManager`), once the
  single-threaded path is measured.
- A TestU01 binding (BigCrush) as a second opinion, possibly in a
  sibling package.

**Never:**

- Certifying cryptographic quality. Passing PractRand says nothing about
  security.

## 3. Position in the `zu*` family

| | zurngtest |
| --- | --- |
| Role | tool |
| R prefix | `pract_` |
| Info function | `zurngtest_info()` |
| Root condition class | `zurngtest_error` |
| Public C prefix | `zurngtest_` for the registered callable; internal `zrt_` |
| From C | `R_GetCCallable("zurngtest", "zurngtest_test_cfun")` |
| Hides symbols | yes, from Stage 0 (R3) |
| Vendored code | PractRand (C++) |
| `Depends: R` | 4.1 (R2) |
| Language | en-GB (R2) |

**Relationships.** `zurand` (counter-based generators) is the first
consumer: its design wants published PractRand results per stream
layout, and zurngtest makes that a test in its own repository rather than
an export to a command-line tool. Any generator package can do the same
through the registered C entry point, without a compile-time dependency.

**What exists elsewhere.**

- `RDieHarder` (CRAN; Eddelbuettel): DieHarder. Weaker and slower to
  find flaws than PractRand.
- `randtests`, `rngtest` (FIPS 140-2): small classical tests.
- No R binding of PractRand or TestU01 was found.

## 4. Architecture

```text
source of bits                         PractRand (vendored C++)
  R generator   --+                      TestManager-like driver
  R function    --+--> block filler  -->  battery tests
  raw / file    --+    (1 KiB blocks)     (core, expanded)
  C callable    --+                         |
                                            v
                                  results per doubling length
                                            |
                                            v
                                  data frame, verdict, length at failure
```

- PractRand consumes `TestBlock`s of 1 KiB; tests are fed at most half a
  gigabyte per call and keep a tail of blocks between calls
  (`get_blocks_to_repeat()`), which the driver handles, as PractRand's
  `TestManager` does.
- The driver is zurngtest's own (a port of `tools/TestManager.h` and the
  reporting logic of `tools/RNG_test.cpp`), because `TestManager` is not
  part of PractRand's library and needs its command-line context.
- **R sources run on the main thread only.** An R function is called to
  fill a buffer of blocks between battery calls; never from a worker. The
  C-callable source has no such restriction, which is why it is the fast
  path.

## 5. Public R API (complete v0.1.0 surface)

```r
pract_test(source, battery = c("core", "expanded"),
           min_bytes = 2^20, max_bytes = 2^34,
           stop_on_failure = TRUE, folding = TRUE, seed = NULL)

# sources
pract_rng(kind = "Mersenne-Twister", seed = 1)   # R's own generator
pract_fun(f, bits = 32)        # f(n) returns n 32-bit words (integer or raw)
pract_raw(x_or_connection)
pract_interleave(...)          # combine sources word by word

zurngtest_info()                 # PractRand version, batteries, limits
```

`pract_test()` returns an object of class `zurngtest_result`: a data frame
of `bytes`, `test`, `p_value`, `evaluation`, plus the attributes
`failed_at` (bytes, or `NA`), `source` (a description) and `elapsed`. Its
`print()` method reproduces `RNG_test`'s compact report.

### 5.1 R's own generators

`pract_rng()` draws from the generator R uses. Where `unif_rand()` is a
scaled 32-bit integer (Mersenne-Twister is the main case), the driver
recovers the integers exactly by inverting the scaling. For generators
whose output is not a scaled 32-bit word (Wichmann-Hill sums three
fractions; L'Ecuyer-CMRG combines two recurrences), it tests the 32 most
significant bits of each double and says so in the result's `source`.
Which kind falls in which case is verified per kind in Stage 2. The R
state is saved and restored around the run, so testing does not change
the user's stream.

### 5.2 The C entry point

```c
/* registered with R_RegisterCCallable("zurngtest", "zurngtest_test_cfun") */
typedef void (*zurngtest_fill_fn)(void *state, uint32_t *out, size_t n);
SEXP zurngtest_test_cfun(zurngtest_fill_fn fill, void *state, SEXP options);
```

A generator package calls this from its own C code (for example in a
test helper), passing a fill function and its state; zurngtest fills
blocks directly, with no R in the loop. The function returns the same
result object as `pract_test()`.

## 6. Results and evaluations

PractRand reports p-values and labels them from "normal" through
"unusual" and "suspicious" to "FAIL" with a severity count. zurngtest keeps
PractRand's labels and thresholds unchanged, documents them, and sets
`failed_at` at the first length with any "FAIL". It adds nothing of its
own on top: the number users compare across papers is PractRand's.

## 7. The vendored library, as zurngtest uses it

- PractRand's `src/` and `include/PractRand/` at the last release, with
  `tools/` used only as reference for the driver; the licence into
  `inst/COPYRIGHTS`.
- Patches: any write to stdout or stderr in library code (to be measured;
  the library is meant to be used without the command-line tools), and
  any `exit()`. Kept in `tools/patches/` with reasons.
- PractRand is dormant upstream (no release after 0.94 in its own
  version list); maintained forks exist. Stage 0 compares the
  sourceforge release with the most active fork and vendors one,
  recorded in `src/practrand/VERSION`.

## 8. Errors and limits

Every condition inherits `zurngtest_error`: `zurngtest_invalid_argument`,
`zurngtest_source_error` (an R function returned the wrong type or length;
a connection ended early, unless `max_bytes` allows a short test),
`zurngtest_internal_error`. `max_bytes` caps a run (default 16 GiB of
bits), and interrupts are checked between battery calls; an interrupt
returns the results up to the last completed length.

## 9. Memory

Block buffers are allocated once per run and owned by a finalised
external pointer; PractRand's test objects are created and destroyed by
the driver around each run. A 2^40-byte run streams; memory stays at the
buffer size plus the tests' own state (tens of megabytes).

## 10. Testing

- **Known results**: generators with published PractRand lengths
  (a weak LCG failing within kilobytes; `xorshift32` failing early;
  Mersenne-Twister failing PractRand's binary-rank tests at a long length;
  a good generator passing to `max_bytes`), each a regression with the
  length recorded.
- **Equivalence with `RNG_test`**: for fixed byte files, zurngtest's
  results equal the command-line tool's output, built from the same
  sources in CI.
- **Sources**: R's generators recover exact integers; `pract_fun()`
  checks types and lengths; interleaving is byte-exact.
- CRAN suite under 15 s (short lengths only); long runs are CI-only.

## 11. Build, portability and CRAN

- C++ (the standard PractRand needs, measured in Stage 0) for the vendored
  library; zurngtest's own glue in C++ as well, kept small.
- `src/Makevars`: hidden visibility; exports `R_init_zurngtest` only; the
  C callable is registered, not exported.
- Stage 0 measures compile time, warnings under CRAN's gcc and clang
  flags, the compiled-code NOTE, and confirms the licence.

## 12. Performance targets

`pract_test()` through the C callable at least 90% of `RNG_test`'s
throughput for the same generator; through `pract_rng()` at least 50%.

## 13. Decisions

| # | Question | Decision |
| --- | --- | --- |
| D1 | Suite | PractRand, vendored |
| D2 | Driver | zurngtest's own port of `TestManager` |
| D3 | Fast path | a registered C callable for generator packages |
| D4 | R sources | filled on the main thread only |
| D5 | Verdicts | PractRand's labels and thresholds unchanged |
| D6 | Info function | `zurngtest_info()`, the package name (R1) |
| D7 | Name | `zurngtest`, chosen 2026-10-23 over `zupract` and `zupractrand`; the R prefix stays `pract_`, internal C prefix `zrt_` |

## 14. Open questions

1. **The name.** Decided 2026-10-23: `zurngtest` (D7).
2. **Which upstream.** The sourceforge 0.94 release or a maintained fork?
   Stage 0 compares them.
3. **TestU01** in the same package or a sibling? Recommended: sibling, if
   ever; one battery per package keeps the licences and builds simple.

## 15. Roadmap

| Stage | Title | Size |
| --- | --- | --- |
| 0 | Identity; licence; vendor; measure build and NOTEs | S |
| 1 | Driver, core battery, raw and R-function sources | M |
| 2 | R's generators, interleaving, the C callable | M |
| 3 | Known-result regressions, `RNG_test` equivalence | M |
| 4 | Documentation, a `zurand` vignette, release 0.1.0 | S |

## 16. Acceptance criteria for v0.1.0

1. `R CMD check --as-cran` clean on every CI leg; only `R_init_zurngtest`
   exported.
2. Results equal `RNG_test`'s for the same input bytes.
3. Every known-result generator fails (or passes) at its recorded length.
4. `zurand` uses the C callable in a test.

## 17. What this RFC does not decide

- Whether CRAN-sized tests (megabytes) are meaningful enough to run in
  generator packages' CRAN checks. They are smoke tests; real results
  come from long CI runs.

Review prepared with assistance from generative AI.
