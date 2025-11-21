# pg_unique_slug

PostgreSQL extension for generating cryptographically secure unique random slugs.

## Features

- **Cryptographically Secure**: Uses `pg_strong_random()` for generating random slugs
- **Guaranteed Uniqueness**: Checks existing values in your table to ensure no collisions
- **Configurable Length**: Generate slugs from 1 to 256 characters
- **Character Set**: Uses A-Z and a-z (52 possible characters per position)
- **SQL Injection Safe**: Properly quotes identifiers and values

## Installation

### From Source

#### Requirements

- PostgreSQL 12 or higher
- PostgreSQL development headers (`postgresql-server-dev`)
- C compiler (gcc or clang)
- make

#### Build and Install

```bash
make
make install
```

#### Enable Extension

```sql
CREATE EXTENSION pg_unique_slug;
```

### Using Docker (Development)

```bash
docker-compose up -d
docker exec -it pg_unique_slug_dev psql -U postgres -d testdb
```

```sql
CREATE EXTENSION pg_unique_slug;
```

## Usage

### Function Signature

```sql
gen_unique_slug(table_name text, column_name text, slug_length int) RETURNS text
```

### Parameters

- `table_name`: Name of the table to check for uniqueness
- `column_name`: Name of the column containing slug values
- `slug_length`: Length of the slug to generate (1-256)

### Examples

#### Basic Usage

```sql
-- Generate a 12-character unique slug for products table
SELECT gen_unique_slug('products', 'slug', 12);
-- Result: 'aBcDeFgHiJkL'
```

#### As Column Default

```sql
CREATE TABLE products (
    id serial PRIMARY KEY,
    name text NOT NULL,
    slug text DEFAULT gen_unique_slug('products', 'slug', 12) UNIQUE
);

INSERT INTO products (name) VALUES ('My Product');
-- slug is automatically generated
```

#### In INSERT Statement

```sql
INSERT INTO products (name, slug)
VALUES ('Another Product', gen_unique_slug('products', 'slug', 8));
```

#### Generate Multiple Slugs

```sql
SELECT gen_unique_slug('users', 'code', 10) FROM generate_series(1, 5);
```

## How It Works

1. Generates a random slug using `pg_strong_random()`
2. Checks if the slug exists in the specified table/column
3. If it exists, generates a new one and checks again
4. Returns the first unique slug found

## Collision Probability

The probability of collision depends on the slug length and number of existing slugs:

- **8 characters**: 52^8 = ~53 trillion possibilities
- **12 characters**: 52^12 = ~390 quadrillion possibilities
- **16 characters**: 52^16 = ~2.8 × 10^27 possibilities

For most applications, a 12-character slug provides excellent uniqueness guarantees.

## Performance Considerations

- **First Insert**: Very fast (single random generation)
- **High Collision Rate**: If your table has many slugs with the same length, generation might retry multiple times
- **Recommendation**: Use longer slugs if you expect millions of records

## Security

- Uses `pg_strong_random()` which is cryptographically secure
- All table and column names are properly quoted to prevent SQL injection
- All values are properly escaped

## Development

### Project Structure

```
pg_unique_slug/
├── pg_unique_slug.c           # Main C source code
├── pg_unique_slug.control     # Extension metadata
├── sql/
│   └── pg_unique_slug--1.0.sql # SQL installation script
├── test/
│   ├── sql/
│   │   └── basic.sql          # Regression test SQL
│   └── expected/
│       └── basic.out          # Expected test output
├── Makefile                   # Build configuration
├── META.json                  # PGXN metadata
├── Dockerfile                 # Development environment
├── docker-compose.yml         # Docker setup
├── dev.sh                     # Development helper script
└── README.md                  # This file
```

### Building with Docker

```bash
docker-compose build
docker-compose up -d
docker exec -it pg_unique_slug_dev bash
```

### Running Tests

The extension includes comprehensive regression tests using PostgreSQL's `pg_regress` framework.

#### Quick Test with Helper Script

```bash
./dev.sh test
```

#### Manual Test Execution

```bash
# Build and install the extension
make clean
make
make install

# Run regression tests
make installcheck
```

#### What the Tests Cover

- Basic slug generation
- Character set validation (A-Z, a-z only)
- Uniqueness verification (100 concurrent slugs)
- Edge cases (minimum length 1, maximum length 256)
- Error handling (invalid lengths)
- SQL injection protection (quoted table/column names)
- Collision handling with pre-existing data
- DEFAULT value usage in table definitions

#### Test Results

After running `make installcheck`, check:
- `test/regression.diffs` - Shows any differences (empty = all passed)
- `test/results/` - Contains actual test output

#### Using Docker

```bash
# Start container
./dev.sh start

# Build and install
./dev.sh rebuild

# Run tests
docker exec -it pg_unique_slug_dev bash -c "cd /extension && make installcheck"

# Or use the helper
./dev.sh test
```

## Publishing to PGXN

1. Create account at https://manager.pgxn.org
2. Package the extension:
   ```bash
   git archive --format zip --prefix=pg_unique_slug-1.0.0/ --output pg_unique_slug-1.0.0.zip HEAD
   ```
3. Upload to PGXN Manager

## License

MIT License - see LICENSE file for details

## Author

Fernando Olle

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Support

- GitHub Issues: https://github.com/fernandoolle/pg_unique_slug/issues
- PGXN: https://pgxn.org/dist/pg_unique_slug/
