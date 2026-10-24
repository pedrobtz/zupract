# The shared library's symbol table, read with nm. CRAN machines may have no
# nm, and a Windows DLL's exports are not in its symbol table, so these run
# on the CI legs that have it.
nm_symbols <- function(args) {
  skip_on_cran()
  skip_on_os("windows")
  nm <- Sys.which("nm")
  skip_if(nm == "", "nm is not available")
  so <- getLoadedDLLs()[["zurngtest"]][["path"]]
  out <- system2(nm, c(args, shQuote(so)), stdout = TRUE)
  fields <- strsplit(trimws(out), "[[:space:]]+")
  # Linker-defined absolute symbols (`_edata`, `_end`, `__bss_start`) are not
  # the package's.
  fields <- Filter(function(x) length(x) < 3 || x[[2]] != "A", fields)
  names <- vapply(fields, function(x) x[[length(x)]], character(1))
  # Mach-O prefixes C names with "_"; ELF may suffix a symbol version.
  names <- sub("@.*$", "", names)
  if (Sys.info()[["sysname"]] == "Darwin") {
    names <- sub("^_", "", names)
  }
  names
}

test_that("the shared library exports only R_init_zurngtest", {
  args <- if (Sys.info()[["sysname"]] == "Darwin") {
    "-gU"
  } else {
    c("-D", "--defined-only")
  }
  # libstdc++ declares namespace std with default visibility, so the
  # instantiations of std::vector, std::string and the like that the library
  # uses stay exported under -fvisibility=hidden, along with the inline
  # placement operator new and delete from <new>. They are not the
  # package's symbols; every other one must be hidden. The pattern matches
  # mangled names in std or __gnu_cxx, including their typeinfo, guard
  # variables and local entities.
  std_symbol <- "^_Z((T[A-Z]|GVZ?|Z)?N?[rVKRO]*(St|9__gnu_cxx)|(nw|na|dl|da))"
  exported <- nm_symbols(args)
  expect_equal(
    grep(std_symbol, exported, value = TRUE, invert = TRUE),
    "R_init_zurngtest"
  )
})

test_that("compiled code links nothing that writes to the console or ends R", {
  # covr builds with --coverage, which links libgcov, and libgcov writes to
  # stderr and calls exit() and abort(). The package's own code is checked on
  # every other leg.
  skip_if(identical(Sys.getenv("R_COVR"), "true"), "covr links libgcov")
  banned <- c(
    "printf",
    "vprintf",
    "fprintf",
    "vfprintf",
    "puts",
    "putchar",
    "sprintf",
    "vsprintf",
    "exit",
    "_exit",
    "abort",
    "rand",
    "srand",
    "random",
    "srandom",
    "stdout",
    "stderr",
    "__stdoutp",
    "__stderrp",
    "_ZSt4cout",
    "_ZSt4cerr"
  )
  expect_equal(intersect(nm_symbols("-u"), banned), character())
})
