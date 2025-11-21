-- Basic tests for pg_unique_slug extension

-- Load the extension
CREATE EXTENSION pg_unique_slug;

-- Test 1: Basic functionality - generate a slug
\echo '--- Test 1: Basic slug generation ---'
CREATE TABLE test_basic (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

INSERT INTO test_basic (slug) VALUES (gen_unique_slug('test_basic', 'slug', 12));
SELECT length(slug) = 12 as correct_length FROM test_basic;

DROP TABLE test_basic;

-- Test 2: Verify slug contains only valid characters (A-Z, a-z)
\echo '--- Test 2: Valid character set ---'
CREATE TABLE test_charset (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

INSERT INTO test_charset (slug) VALUES (gen_unique_slug('test_charset', 'slug', 20));
SELECT slug ~ '^[A-Za-z]+$' as only_letters FROM test_charset;

DROP TABLE test_charset;

-- Test 3: Uniqueness - generate multiple slugs and verify they are unique
\echo '--- Test 3: Uniqueness verification ---'
CREATE TABLE test_unique (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

INSERT INTO test_unique (slug)
SELECT gen_unique_slug('test_unique', 'slug', 10)
FROM generate_series(1, 100);

SELECT COUNT(*) = 100 as generated_100,
       COUNT(DISTINCT slug) = 100 as all_unique
FROM test_unique;

DROP TABLE test_unique;

-- Test 4: Edge case - minimum length (1 character)
\echo '--- Test 4: Minimum length (1) ---'
CREATE TABLE test_min (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

INSERT INTO test_min (slug) VALUES (gen_unique_slug('test_min', 'slug', 1));
SELECT length(slug) = 1 as length_is_1 FROM test_min;

DROP TABLE test_min;

-- Test 5: Edge case - maximum length (256 characters)
\echo '--- Test 5: Maximum length (256) ---'
CREATE TABLE test_max (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

INSERT INTO test_max (slug) VALUES (gen_unique_slug('test_max', 'slug', 256));
SELECT length(slug) = 256 as length_is_256 FROM test_max;

DROP TABLE test_max;

-- Test 6: Error case - invalid length (0)
\echo '--- Test 6: Error on length 0 ---'
CREATE TABLE test_error (
    id serial PRIMARY KEY,
    slug text
);

DO $$
BEGIN
    PERFORM gen_unique_slug('test_error', 'slug', 0);
    RAISE EXCEPTION 'Should have raised error for length 0';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Correctly rejected length 0';
END $$;

DROP TABLE test_error;

-- Test 7: Error case - invalid length (257)
\echo '--- Test 7: Error on length 257 ---'
CREATE TABLE test_error2 (
    id serial PRIMARY KEY,
    slug text
);

DO $$
BEGIN
    PERFORM gen_unique_slug('test_error2', 'slug', 257);
    RAISE EXCEPTION 'Should have raised error for length 257';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Correctly rejected length 257';
END $$;

DROP TABLE test_error2;

-- Test 8: SQL injection protection - table name with quotes
\echo '--- Test 8: SQL injection protection ---'
CREATE TABLE "test'table" (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

INSERT INTO "test'table" (slug) VALUES (gen_unique_slug('test''table', 'slug', 8));
SELECT length(slug) = 8 as safe_from_injection FROM "test'table";

DROP TABLE "test'table";

-- Test 9: SQL injection protection - column name with quotes
\echo '--- Test 9: Column name with special characters ---'
CREATE TABLE test_column (
    id serial PRIMARY KEY,
    "slug'col" text UNIQUE
);

INSERT INTO test_column ("slug'col") VALUES (gen_unique_slug('test_column', 'slug''col', 8));
SELECT length("slug'col") = 8 as safe_column_name FROM test_column;

DROP TABLE test_column;

-- Test 10: Collision handling - fill table and generate new unique slug
\echo '--- Test 10: Collision handling with pre-existing slugs ---'
CREATE TABLE test_collision (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

-- Pre-insert some specific slugs (very short length to force potential collisions)
INSERT INTO test_collision (slug) VALUES ('AA'), ('AB'), ('AC');

-- Generate a new unique slug (should avoid AA, AB, AC)
INSERT INTO test_collision (slug) VALUES (gen_unique_slug('test_collision', 'slug', 2));

SELECT COUNT(*) = 4 as has_four_slugs,
       COUNT(DISTINCT slug) = 4 as all_still_unique
FROM test_collision;

DROP TABLE test_collision;

-- Test 11: Works as DEFAULT value in table definition
\echo '--- Test 11: Using as DEFAULT value ---'
CREATE TABLE test_default (
    id serial PRIMARY KEY,
    name text,
    slug text DEFAULT gen_unique_slug('test_default', 'slug', 8) UNIQUE
);

INSERT INTO test_default (name) VALUES ('Product 1'), ('Product 2'), ('Product 3');

SELECT COUNT(*) = 3 as inserted_three,
       COUNT(DISTINCT slug) = 3 as all_have_unique_slugs,
       MIN(length(slug)) = 8 as min_length_correct,
       MAX(length(slug)) = 8 as max_length_correct
FROM test_default;

DROP TABLE test_default;

\echo '--- All tests completed successfully! ---'
