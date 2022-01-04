#include <janet.h>
#include <stdlib.h>

#include "match.h"

const char *janet_bytes_to_cstring(JanetByteView bv) {
    return janet_string(bv.bytes, bv.len);
}

static Janet cfun_has_match(int32_t argc, Janet *argv) {
    janet_fixarity(argc, 2);
    const char *needle = janet_bytes_to_cstring(janet_getbytes(argv, 0));
    const char *haystack = janet_bytes_to_cstring(janet_getbytes(argv, 1));
    return janet_wrap_boolean(has_match(needle, haystack));
}

static Janet cfun_score(int32_t argc, Janet *argv) {
    janet_fixarity(argc, 2);
    const char *needle = janet_bytes_to_cstring(janet_getbytes(argv, 0));
    const char *haystack = janet_bytes_to_cstring(janet_getbytes(argv, 1));
    return janet_wrap_number(match(needle, haystack));
}

static Janet cfun_positions(int32_t argc, Janet *argv) {
    janet_fixarity(argc, 2);
    const char *needle = janet_bytes_to_cstring(janet_getbytes(argv, 0));
    const char *haystack = janet_bytes_to_cstring(janet_getbytes(argv, 1));
    int n = strlen(needle);
    size_t positions[MATCH_MAX_LEN];
    for (int i = 0; i < n + 1 && i < MATCH_MAX_LEN; i++)
        positions[i] = -1;
    match_positions(needle, haystack, &positions[0]);
    JanetArray *array = janet_array(0);
    int i = 0;
    while (positions[i] != -1) {
        janet_array_push(array, janet_wrap_number(positions[i]));
        i++;
    }
    return janet_wrap_array(array);
}

static const JanetReg cfuns[] = {
    {   "has-match", cfun_has_match, "(has-match needle haystack)\n\n"
        "Checks if needle has match in haystack. Returns boolean."
    },
    {   "score", cfun_score, "(score needle haystack)\n\n"
        "Computes score for the needle in the haystack. Returns number."
    },
    {   "positions", cfun_positions, "(positions needle haystack)\n\n"
        "Computes positions for the needle in the haystack. "
        "Returns array of positions."
    },
    {NULL, NULL, NULL}
};

JANET_MODULE_ENTRY(JanetTable *env) {
    janet_cfuns(env, "fzy", cfuns);
}
