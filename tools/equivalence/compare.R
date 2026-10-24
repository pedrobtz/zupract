# Compare pract_test() with PractRand's own RNG_test on the same bytes.
#
#   Rscript tools/equivalence/compare.R <path-to-RNG_test>
#
# Run from the package root with zurngtest installed. For each input below
# both tools test the same file of bytes with the core battery and standard
# folding at 64 KiB to 1 MiB; at every length the test names, the
# evaluations and the p-values (to the precision RNG_test prints) must agree.
# Exits non-zero on any difference.
args <- commandArgs(TRUE)
rng_test <- normalizePath(args[[1]])
suppressMessages(library(zurngtest))

inputs <- list(
  # Fails at once, and hard.
  pattern = rep(as.raw(0:255), length.out = 2^20),
  # Passes.
  mersenne = local({
    withr::local_seed(1, .rng_kind = "Mersenne-Twister")
    as.raw(sample.int(256L, 2^20, TRUE) - 1L)
  }),
  # 32-bit counter words: fails, on some tests only.
  counter = writeBin(seq_len(2^18) - 1L, raw(), endian = "little")
)

# RNG_test -a lines: "  Name (34 chars)  R= +1.2  p = 0.5  evaluation", or
# "pass"/"fail" in place of the p-value for pass/fail results.
row_pattern <- paste0(
  "^  (.{34})R[=<>]\\s*(\\S+)\\s+",
  "(p\\s*~?=\\s*\\S+|\"pass\"|\"fail\")",
  "\\s+(\\S.*?)\\s*$"
)

parse_rng_test <- function(lines) {
  rows <- list()
  bytes <- NA_real_
  for (line in lines) {
    if (startsWith(line, "length= ")) {
      bytes <- 2^as.numeric(sub(".*\\(2\\^([0-9.]+) bytes\\).*", "\\1", line))
      next
    }
    m <- regmatches(line, regexec(row_pattern, line))[[1]]
    if (length(m) == 5) {
      rows[[length(rows) + 1]] <- data.frame(
        bytes = bytes,
        test = trimws(m[[2]]),
        p_text = m[[4]],
        evaluation = trimws(m[[5]]),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

# p as RNG_test prints it, with the half-unit of its last printed digit:
# "8.0e-797" (0 in a double), "1-2.3e-9", "0.5", "0", and "pass" or "fail"
# for pass/fail results, whose p-value is non-zero for a pass.
parse_p <- function(text) {
  value <- sub("^p\\s*~?=\\s*", "", text)
  pass_fail <- value %in% c("\"pass\"", "\"fail\"")
  one_minus <- startsWith(value, "1-")
  num <- sub("^1-", "", value)
  mantissa <- sub("e.*", "", num)
  decimals <- ifelse(
    grepl(".", mantissa, fixed = TRUE),
    nchar(sub(".*\\.", "", mantissa)),
    0
  )
  exponent <- ifelse(grepl("e", num), suppressWarnings(as.numeric(sub(".*e", "", num))), 0)
  x <- suppressWarnings(as.numeric(num))
  data.frame(
    p = ifelse(pass_fail, as.numeric(value == "\"pass\""), ifelse(one_minus, 1 - x, x)),
    # One unit of the last digit: RNG_test truncates some mantissas.
    tol = ifelse(pass_fail, NA, 1.0001 * 10^(exponent - decimals) + 1e-12),
    pass_fail = pass_fail
  )
}

# Agreement to printed precision; values beyond what a double holds agree
# when both are at the same end.
same_p <- function(parsed, ours) {
  theirs <- parsed$p
  tiny <- theirs < 1e-290 & ours < 1e-290
  huge <- theirs > 1 - 1e-12 & ours > 1 - 1e-12
  ifelse(
    parsed$pass_fail,
    (ours > 0) == (theirs > 0),
    tiny | huge | abs(theirs - ours) <= parsed$tol
  )
}

failures <- 0
for (name in names(inputs)) {
  file <- tempfile(fileext = ".bin")
  writeBin(inputs[[name]], file)
  out <- system2(
    rng_test,
    c("stdin", "-a", "-tlmin", "64KB", "-tlmax", "1MB", "-tlmaxonly"),
    stdin = file,
    stdout = TRUE,
    stderr = TRUE
  )
  theirs <- parse_rng_test(out)
  ours <- pract_test(
    pract_raw(inputs[[name]]),
    min_bytes = 2^16,
    max_bytes = 2^20,
    stop_on_failure = FALSE
  )
  for (len in unique(theirs$bytes)) {
    t <- theirs[theirs$bytes == len, ]
    o <- ours[ours$bytes == len, ]
    problems <- character()
    if (!setequal(t$test, o$test)) {
      problems <- c(
        problems,
        paste("only in RNG_test:", paste(setdiff(t$test, o$test), collapse = ", ")),
        paste("only in pract_test:", paste(setdiff(o$test, t$test), collapse = ", "))
      )
    }
    common <- intersect(t$test, o$test)
    t <- t[match(common, t$test), ]
    o <- o[match(common, o$test), ]
    differ <- t$evaluation != o$evaluation
    if (any(differ)) {
      problems <- c(problems, sprintf(
        "evaluation of %s: RNG_test %s, pract_test %s",
        common[differ], t$evaluation[differ], o$evaluation[differ]
      ))
    }
    off <- which(!same_p(parse_p(t$p_text), o$p_value))
    if (length(off)) {
      problems <- c(problems, sprintf(
        "p-value of %s: RNG_test %s, pract_test %.3g",
        common[off], t$p_text[off], o$p_value[off]
      ))
    }
    cat(sprintf(
      "%-9s %8.0f bytes: %d results, %s\n",
      name, len, nrow(t), if (length(problems)) "DIFFERENT" else "same"
    ))
    if (length(problems)) {
      cat(paste0("  ", problems, "\n"), sep = "")
      failures <- failures + 1
    }
  }
}
if (failures > 0) {
  quit(status = 1)
}
