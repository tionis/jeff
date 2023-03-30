#include <janet.h>
#include <ctype.h>
#include <math.h>
#define SCORE_MAX INFINITY
#define SCORE_MIN -INFINITY
#define MATCH_MAX_LEN 1024
#define SCORE_GAP_LEADING -0.005
#define SCORE_GAP_TRAILING -0.005
#define SCORE_GAP_INNER -0.01
#define SCORE_MATCH_CONSECUTIVE 1
#define SCORE_MATCH_SLASH 0.9
#define SCORE_MATCH_WORD 0.8
#define SCORE_MATCH_CAPITAL 0.7
#define SCORE_MATCH_DOT 0.6

typedef double score_t;
const score_t bonuss_states[3][256] = {{0}, {['/'] = SCORE_MATCH_SLASH, ['-'] = SCORE_MATCH_WORD, ['_'] = SCORE_MATCH_WORD, [' '] = SCORE_MATCH_WORD, ['.'] = SCORE_MATCH_DOT}, {['/'] = SCORE_MATCH_SLASH, ['-'] = SCORE_MATCH_WORD, ['_'] = SCORE_MATCH_WORD, [' '] = SCORE_MATCH_WORD, ['.'] = SCORE_MATCH_DOT, ['a'] = SCORE_MATCH_CAPITAL, ['b'] = SCORE_MATCH_CAPITAL, ['c'] = SCORE_MATCH_CAPITAL, ['d'] = SCORE_MATCH_CAPITAL, ['e'] = SCORE_MATCH_CAPITAL, ['f'] = SCORE_MATCH_CAPITAL, ['g'] = SCORE_MATCH_CAPITAL, ['h'] = SCORE_MATCH_CAPITAL, ['i'] = SCORE_MATCH_CAPITAL, ['j'] = SCORE_MATCH_CAPITAL, ['k'] = SCORE_MATCH_CAPITAL, ['l'] = SCORE_MATCH_CAPITAL, ['m'] = SCORE_MATCH_CAPITAL, ['n'] = SCORE_MATCH_CAPITAL, ['o'] = SCORE_MATCH_CAPITAL, ['p'] = SCORE_MATCH_CAPITAL, ['q'] = SCORE_MATCH_CAPITAL, ['r'] = SCORE_MATCH_CAPITAL, ['s'] = SCORE_MATCH_CAPITAL, ['t'] = SCORE_MATCH_CAPITAL, ['u'] = SCORE_MATCH_CAPITAL, ['v'] = SCORE_MATCH_CAPITAL, ['w'] = SCORE_MATCH_CAPITAL, ['x'] = SCORE_MATCH_CAPITAL, ['y'] = SCORE_MATCH_CAPITAL, ['z'] = SCORE_MATCH_CAPITAL}};
const size_t bonuss_index[256] = {['0'] = 1, ['1'] = 1, ['2'] = 1, ['3'] = 1, ['4'] = 1, ['5'] = 1, ['6'] = 1, ['7'] = 1, ['8'] = 1, ['9'] = 1, ['A'] = 2, ['B'] = 2, ['C'] = 2, ['D'] = 2, ['E'] = 2, ['F'] = 2, ['G'] = 2, ['H'] = 2, ['I'] = 2, ['J'] = 2, ['K'] = 2, ['L'] = 2, ['M'] = 2, ['N'] = 2, ['O'] = 2, ['P'] = 2, ['Q'] = 2, ['R'] = 2, ['S'] = 2, ['T'] = 2, ['U'] = 2, ['V'] = 2, ['W'] = 2, ['X'] = 2, ['Y'] = 2, ['Z'] = 2, ['a'] = 1, ['b'] = 1, ['c'] = 1, ['d'] = 1, ['e'] = 1, ['f'] = 1, ['g'] = 1, ['h'] = 1, ['i'] = 1, ['j'] = 1, ['k'] = 1, ['l'] = 1, ['m'] = 1, ['n'] = 1, ['o'] = 1, ['p'] = 1, ['q'] = 1, ['r'] = 1, ['s'] = 1, ['t'] = 1, ['u'] = 1, ['v'] = 1, ['w'] = 1, ['x'] = 1, ['y'] = 1, ['z'] = 1};
struct match_struct {
  int needle_len;
  int haystack_len;
  uint8_t lower_needle[MATCH_MAX_LEN];
  uint8_t lower_haystack[MATCH_MAX_LEN];
  score_t match_bonus[MATCH_MAX_LEN];
} ;

static void precompute_bonus(const uint8_t *haystack, score_t *match_bonus) {
  uint8_t last_ch = '/';
  int i = 0;
  while (haystack[i])   {
    uint8_t ch = haystack[i];
    match_bonus[i] = (bonuss_states[bonuss_index[ch]])[last_ch];
    last_ch = ch;
    ++i;
  }

}

static void setup_match_struct(struct match_struct *match, const uint8_t *needle, const uint8_t *haystack) {
  match->needle_len = strlen(needle);
  match->haystack_len = strlen(haystack);
  if (!((match->haystack_len > MATCH_MAX_LEN) || (match->needle_len > match->haystack_len))) {
    {
      int i = 0;
      while (i < match->needle_len)       {
        match->lower_needle[i] = tolower(needle[i]);
        ++(i);
      }

      i = 0;
      while (i < match->haystack_len)       {
        match->lower_haystack[i] = tolower(haystack[i]);
        ++(i);
      }

      precompute_bonus(haystack, match->match_bonus);
    }
  }
}

static inline void match_row(const struct match_struct *match, int row, score_t *curr_D, score_t *curr_M, const score_t *last_D, const score_t *last_M) {
  int i = row;
  const score_t *match_bonus = match->match_bonus;
  score_t prev_score = SCORE_MIN;
  score_t gap_score;
  if (i == (match->needle_len - 1)) {
    gap_score = SCORE_GAP_TRAILING;
  } else {
    gap_score = SCORE_GAP_INNER;
  }
  int j = 0;
  while (j < match->haystack_len)   {
    if ((match->lower_needle[i]) == (match->lower_haystack[j])) {
      {
        score_t score = SCORE_MIN;
        if (!i) {
          score = (j * SCORE_GAP_LEADING) + (match_bonus[j]);
        } else if (j) {
          {
            score_t a = (last_M[j - 1]) + (match_bonus[j]);
            score_t b = (last_D[j - 1]) + SCORE_MATCH_CONSECUTIVE;
            if (a > b) {
              score = a;
            } else {
              score = b;
            }
          }
        }
        curr_D[j] = score;
        if (score > (prev_score + gap_score)) {
          prev_score = score;
        } else {
          prev_score = prev_score + gap_score;
        }
        curr_M[j] = prev_score;
      }
    } else {
      {
        curr_D[j] = SCORE_MIN;
        prev_score = prev_score + gap_score;
        curr_M[j] = prev_score;
      }
    }
    ++j;
  }

}

static inline int _has_match(const uint8_t *needle, const uint8_t *haystack) {
  while (*needle)   {
    uint8_t nch = *needle++;
    const uint8_t accept[3] = {nch, toupper(nch), 0};
    if (!(haystack = strpbrk(haystack, accept))) {
      return 0;
    }
    ++haystack;
  }

  return 1;
}

static Janet cfun_has_match(int32_t argc, Janet *argv) {
  janet_fixarity(argc, 2);
  JanetByteView bv;
  bv = janet_getbytes(argv, 0);
  const char *needle = janet_string(bv.bytes, bv.len);
  bv = janet_getbytes(argv, 1);
  const char *haystack = janet_string(bv.bytes, bv.len);
  return janet_wrap_boolean(_has_match(needle, haystack));
}

static Janet cfun_score(int32_t argc, Janet *argv) {
  janet_fixarity(argc, 2);
  JanetByteView bv;
  bv = janet_getbytes(argv, 0);
  const char *needle = janet_string(bv.bytes, bv.len);
  bv = janet_getbytes(argv, 1);
  const char *haystack = janet_string(bv.bytes, bv.len);
  if ((!*needle) || (!(_has_match(needle, haystack)))) {
    return janet_wrap_number(SCORE_MIN);
  }
  struct match_struct match;
  setup_match_struct(&match, needle, haystack);
  int n = match.needle_len;
  int m = match.haystack_len;
  if ((m > MATCH_MAX_LEN) || (n > m)) {
    return janet_wrap_number(SCORE_MIN);
  } else if (n == m) {
    return janet_wrap_number(SCORE_MAX);
  }
  score_t D[2][MATCH_MAX_LEN];
  score_t M[2][MATCH_MAX_LEN];
  score_t *last_D = D[0];
  score_t *last_M = M[0];
  score_t *curr_D = D[1];
  score_t *curr_M = M[1];
  int i = 0;
  score_t *tmp;
  while (i < n)   {
    match_row(&match, i, curr_D, curr_M, last_D, last_M);
    tmp = last_D;
    last_D = curr_D;
    curr_D = tmp;
    tmp = last_M;
    last_M = curr_M;
    curr_M = tmp;
    ++i;
  }

  return janet_wrap_number(last_M[m - 1]);
}

static Janet cfun_positions(int32_t argc, Janet *argv) {
  janet_fixarity(argc, 2);
  JanetByteView bv;
  bv = janet_getbytes(argv, 0);
  const char *needle = janet_string(bv.bytes, bv.len);
  bv = janet_getbytes(argv, 1);
  const char *haystack = janet_string(bv.bytes, bv.len);
  struct match_struct match;
  setup_match_struct(&match, needle, haystack);
  int n = match.needle_len;
  int m = match.haystack_len;
  JanetArray *array = janet_array(n);
  Janet warr = janet_wrap_array(array);
  if ((!*needle) || (!(_has_match(needle, haystack)))) {
    return warr;
  }
  if ((m > MATCH_MAX_LEN) || (n > m)) {
    return janet_wrap_array(array);
  } else if (n == m) {
    {
      int i = 0;
      while (i < n)       {
        janet_array_push(array, janet_wrap_number(i));
        ++(i);
      }

      return warr;
    }
  }
  score_t (*D)[MATCH_MAX_LEN];
  score_t (*M)[MATCH_MAX_LEN];
  M = janet_malloc((sizeof(score_t)) * MATCH_MAX_LEN * n);
  D = janet_malloc((sizeof(score_t)) * MATCH_MAX_LEN * n);
  score_t *last_D = D[0];
  score_t *last_M = M[0];
  score_t *curr_D = D[1];
  score_t *curr_M = M[1];
  int i = 0;
  while (i < n)   {
    curr_D = &((D[i])[0]);
    curr_M = &((M[i])[0]);
    match_row(&match, i, curr_D, curr_M, last_D, last_M);
    last_D = curr_D;
    last_M = curr_M;
    ++(i);
  }

  int match_required = 0;
  i = n - 1;
  int j = m - 1;
  while (i >= 0)   {
    while (j >= 0)     {
      if ((((D[i])[j]) != SCORE_MIN) && (match_required || (((D[i])[j]) == ((M[i])[j])))) {
        {
          match_required = i && j && (((M[i])[j]) == (((D[i - 1])[j - 1]) + SCORE_MATCH_CONSECUTIVE));
          janet_putindex(warr, i, janet_wrap_number(j));
          --(j);
          break;
        }
      }
      --(j);
    }

    --(i);
  }

  janet_free(D);
  janet_free(M);
  return warr;
}
JanetReg fzycfuns[] = {{"score", cfun_score, "(score needle haystack)\n\nComputes score for the needle in the haystack. Returns number."}, {"has-match", cfun_has_match, "(has-match needle haystack)\n\nChecks if needle has match in haystack. Returns boolean."}, {"positions", cfun_positions, "(positions needle haystack)\n\nComputes positions for the needle in the haystack. Returns array of positions."}, {NULL, NULL, NULL}};

 JANET_MODULE_ENTRY(JanetTable* env) {
  janet_def(env, "score-min", janet_wrap_number(SCORE_MIN), "Minimal possible score.");
  janet_def(env, "score-max", janet_wrap_number(SCORE_MAX), "Maximal possible score.");
  janet_cfuns(env, "fzy", fzycfuns);
}
