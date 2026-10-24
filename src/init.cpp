// R entry points. R's headers come after the C++ ones, with R_NO_REMAP, so
// R's macros cannot rename anything in the standard library or PractRand.
#include "PractRand.h"

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

extern "C" {

// The PractRand version compiled in, for zurngtest_info().
SEXP zrt_practrand_version(void) {
  return Rf_mkString(PractRand::version_str);
}

static const R_CallMethodDef call_methods[] = {
    {"zrt_practrand_version", (DL_FUNC)&zrt_practrand_version, 0},
    {NULL, NULL, 0}};

void attribute_visible R_init_zurngtest(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}

} // extern "C"
