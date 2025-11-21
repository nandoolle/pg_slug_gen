-- pg_unique_slug extension version 1.0

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_unique_slug" to load this file. \quit

CREATE FUNCTION gen_unique_slug(
    table_name text,
    column_name text,
    slug_length int
)
RETURNS text
AS 'MODULE_PATHNAME'
LANGUAGE C
VOLATILE
STRICT;

COMMENT ON FUNCTION gen_unique_slug(text, text, int) IS
'Generate a cryptographically secure random slug with guaranteed uniqueness.
Parameters: table_name, column_name, slug_length (1-256).
Uses pg_strong_random() and checks for uniqueness in the specified table/column.';
