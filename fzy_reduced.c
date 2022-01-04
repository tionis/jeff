#include <janet.h>
#include <stdlib.h>

#include "match.h"

static Janet cfun_has_match(int32_t argc, Janet *argv) {
    janet_fixarity(argc, 2);
    const char *needle = janet_getcstring(argv, 0);
    const char *haystack = janet_getcstring(argv, 1);
    janet_wrap_boolean(has_match(needle, haystack));
}

static const JanetReg cfuns[] = {
    {"has_match", cfun_has_match, "(has-match needle haystack)\n\n"
        "Checks if needle has match in haystack. Returns boolean."},
    {NULL, NULL, NULL}
};

JANET_MODULE_ENTRY(JanetTable *env) {
    janet_cfuns(env, "fzy", cfuns);
}
