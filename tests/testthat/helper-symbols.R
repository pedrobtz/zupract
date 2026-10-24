# Symbol tables of the package's shared library, for test-symbols.R.
#
# CRAN machines may lack the tools, and CRAN's own compiled-code check covers
# the same ground there, so the tests skip on CRAN. Everywhere else a missing
# tool is a failure, not a skip: a skip would hide the check on every leg at
# once. covr builds with --coverage, which links libgcov into the library:
# libgcov exports its own symbols and calls exit() and abort(), so under
# covr the tests skip. Every other leg checks the package's own symbols.

skip_unless_symbol_checks <- function() {
  skip_on_cran()
  skip_if(identical(Sys.getenv("R_COVR"), "true"), "covr links libgcov")
}

# Runs `tool` with `args` on the loaded library and returns its output. A
# non-zero status is a failure: an empty listing would pass every check.
read_library <- function(tool, args) {
  path <- Sys.which(tool)
  if (!nzchar(path)) {
    fail(paste(tool, "is not available, so the symbol checks cannot run"))
  }
  so <- getLoadedDLLs()[["zurngtest"]][["path"]]
  out <- suppressWarnings(system2(path, c(args, shQuote(so)), stdout = TRUE))
  expect_null(attr(out, "status"))
  out
}

# Symbols nm lists for the library, with Mach-O's leading underscore and ELF
# symbol versions removed.
nm_symbols <- function(args) {
  out <- read_library("nm", args)
  fields <- strsplit(trimws(out), "[[:space:]]+")
  # Linker-defined absolute symbols (`_edata`, `_end`, `__bss_start`) are not
  # the package's.
  fields <- Filter(function(x) length(x) < 3 || x[[2]] != "A", fields)
  names <- vapply(fields, function(x) x[[length(x)]], character(1))
  names <- sub("@.*$", "", names)
  if (Sys.info()[["sysname"]] == "Darwin") {
    names <- sub("^_", "", names)
  }
  names
}

# Names the library exports. A Windows DLL's exports are in its export table,
# which objdump prints, not in its symbol table.
exported_symbols <- function() {
  if (.Platform$OS.type == "windows") {
    out <- read_library("objdump", "-p")
    start <- grep("[Ordinal/Name Pointer] Table", out, fixed = TRUE)
    if (length(start) == 0) {
      return(character())
    }
    rows <- out[-seq_len(start[[1]])]
    rows <- rows[seq_len(match(TRUE, !nzchar(trimws(rows)), length(rows)))]
    # Rows look like "[   0] name" or, in newer binutils, "+base[   1]  0000
    # name": the name is the last field.
    rows <- rows[grepl("\\[\\s*[0-9]+\\]", rows)]
    return(sub("^.*\\s", "", trimws(rows)))
  }
  if (Sys.info()[["sysname"]] == "Darwin") {
    nm_symbols("-gU")
  } else {
    nm_symbols(c("-D", "--defined-only"))
  }
}

# Names the library uses but does not define.
undefined_symbols <- function() {
  nm_symbols("-u")
}

# Symbols R's compiled-code check reports, from R's own table: each C or C++
# name, and its macOS form without the leading underscore, which is also
# glibc's name for the fortified variants (__sprintf_chk). Added: glibc's
# assert, libstdc++'s std::cout and std::cerr, and fprintf and vfprintf,
# which the package bans too.
banned_symbols <- function() {
  table <- tools:::so_symbol_names_table
  table <- table[table[, "language"] %in% c("C", "C++"), , drop = FALSE]
  names <- c(table[, "ssname"], sub("^_", "", table[, "osname"]))
  names <- names[!grepl("::", names, fixed = TRUE)]
  unique(c(
    names,
    "__assert_fail",
    "_ZSt4cout",
    "_ZSt4cerr",
    "fprintf",
    "vfprintf"
  ))
}
