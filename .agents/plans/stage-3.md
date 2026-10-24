# Stage 3 — R generators, interleaving and the C callable Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `pract_rng()`, `pract_interleave()` and the registered C callable
`zurngtest_test_cfun`, each a source `pract_test()` runs.

**Architecture:** All three are `zurngtest_source`s, so `pract_test()`'s
loop is unchanged. `pract_rng()` recovers each kind's own integers from
`runif()` (table below) and restores the user's `.Random.seed` and
`RNGkind()` when the run closes it. `pract_interleave()` buffers whole
rounds of one word from each source. The C callable wraps the caller's fill
function in an external pointer and calls `pract_test()` through an R
function whose source fills each chunk natively (`zrt_cfun_fill`): R only
orchestrates lengths, one call per chunk of up to 16 MiB.

**Spec:** `.agents/design.md` §5.1, §5.2, §4 (D3, D4); roadmap Stage 3.

## Global Constraints

- Per kind, from R's `src/main/RNG.c`, verified empirically on 1e5 draws:
  Mersenne-Twister `u * 2^32`; Marsaglia-Multicarry and Super-Duper
  `u * (2^32 - 1)`; L'Ecuyer-CMRG `u * 4294967088` (values 1..m1); all exact
  32-bit words. Knuth-TAOCP and Knuth-TAOCP-2002 `u * 2^30`, exact 30-bit
  values, packed into a bit stream (4 values, 15 bytes). Wichmann-Hill and
  user-supplied: the 32 most significant bits, `floor(u * 2^32)`.
- The user's `.Random.seed` (or its absence) and `RNGkind()` are restored
  when the run ends, however it ends.
- `zurngtest_fill_fn` is `void (*)(void *state, uint32_t *out, size_t n)`;
  `inst/include/zurngtest.h` compiles standalone as C99 and as C++.
- `R_init_zurngtest` stays the only exported symbol.

## Review Focus

- A run that errors or is interrupted still restores the user's stream.
- Interleaving sources whose fills end at different points ends cleanly.
- Packed Knuth output keeps every bit of every value, in order.
- The C callable is reached through `R_GetCCallable()`, not by symbol.

### Task 1: `pract_rng()` (`R/rng.R`) — tests for exact recovery per kind,
restore after success, error and interrupt, Knuth packing.

### Task 2: `pract_interleave()` (`R/interleave.R`) — byte-exact word
interleaving, mismatched word sizes rejected, early end.

### Task 3: C callable (`src/callable.cpp`, `inst/include/zurngtest.h`) —
registered, equal results to `pract_test()` on the same words, header
compiles as C99.

### Task 4: Close out — NEWS, roadmap per-kind record, docs, checks.
