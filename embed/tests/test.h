#include <stdio.h>
#include <assert.h>

#define STR_OK          "[\x1b[1;32m OK \x1b[0m]"
#define STR_FAIL        "[\x1b[1;31mFAIL\x1b[0m]"

#define passert(c) \
    do { \
        int r = (c); \
        if (r) \
            fprintf(stderr, " " STR_OK "  %s %s():%d  %s\n", __FILE__, __func__, __LINE__, #c); \
        else \
            fprintf(stderr, " " STR_FAIL "  %s %s():%d  %s\n", __FILE__, __func__, __LINE__, #c); \
        assert(r); \
    } while(0)

#define ptest() \
    fprintf(stderr, "\nStarting test %s():%d\n", __func__, __LINE__)

