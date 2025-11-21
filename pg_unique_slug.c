/*
 * pg_unique_slug.c - PostgreSQL extension for generating unique random slugs
 *
 * Generates cryptographically secure random slugs with guaranteed uniqueness.
 */

#include "postgres.h"
#include "fmgr.h"
#include "executor/spi.h"
#include "utils/builtins.h"
#include "common/pg_prng.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(gen_unique_slug);

static const char charset[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz";

#define CHARSET_LEN (sizeof(charset) - 1)
#define MAX_SLUG_LENGTH 256

/*
 * Generate a random slug using pg_strong_random
 */
static void
generate_random_slug(char *slug, int len)
{
    for (int i = 0; i < len; i++) {
        unsigned char rnd;

        if (!pg_strong_random(&rnd, 1)) {
            ereport(ERROR, (errmsg("pg_strong_random failed")));
        }

        slug[i] = charset[rnd % CHARSET_LEN];
    }
    slug[len] = '\0';
}

/*
 * Check if slug already exists in the specified table/column
 */
static bool
slug_exists(const char *table_quoted, const char *column_quoted,
            const char *slug, StringInfoData *query)
{
    char *slug_quoted;
    int   ret;

    slug_quoted = TextDatumGetCString(
        DirectFunctionCall1(quote_literal_cstr, CStringGetDatum(slug))
    );

    resetStringInfo(query);
    appendStringInfo(query,
                     "SELECT 1 FROM %s WHERE %s = %s LIMIT 1",
                     table_quoted, column_quoted, slug_quoted);

    ret = SPI_execute(query->data, true, 1);

    if (ret < 0) {
        ereport(ERROR,
                (errmsg("SPI_execute failed: error code %d", ret)));
    }

    return (SPI_processed > 0);
}

Datum
gen_unique_slug(PG_FUNCTION_ARGS)
{
    text       *tbl = PG_GETARG_TEXT_PP(0);
    text       *col = PG_GETARG_TEXT_PP(1);
    int32       len = PG_GETARG_INT32(2);
    char       *table_quoted;
    char       *column_quoted;
    char        slug[MAX_SLUG_LENGTH + 1];
    StringInfoData query;

    if (len < 1 || len > MAX_SLUG_LENGTH) {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                 errmsg("slug_length must be between 1 and %d", MAX_SLUG_LENGTH)));
    }

    /* Quote identifiers to prevent SQL injection */
    table_quoted = TextDatumGetCString(
        DirectFunctionCall1(quote_ident, PointerGetDatum(tbl))
    );
    column_quoted = TextDatumGetCString(
        DirectFunctionCall1(quote_ident, PointerGetDatum(col))
    );

    if (SPI_connect() != SPI_OK_CONNECT) {
        ereport(ERROR, (errmsg("SPI_connect failed")));
    }

    initStringInfo(&query);

    /* Generate slugs until we find a unique one */
    while (true) {
        generate_random_slug(slug, len);

        if (!slug_exists(table_quoted, column_quoted, slug, &query)) {
            break;
        }
    }

    SPI_finish();
    pfree(query.data);

    PG_RETURN_TEXT_P(cstring_to_text(slug));
}
