#!/bin/bash

set -e

CONTAINER_NAME="pg_unique_slug_dev"
DB_NAME="testdb"
DB_USER="postgres"

case "$1" in
  start)
    echo "Starting PostgreSQL container..."
    docker-compose up -d
    echo "Waiting for PostgreSQL to be ready..."
    sleep 3
    echo "PostgreSQL is ready!"
    ;;

  stop)
    echo "Stopping PostgreSQL container..."
    docker-compose down
    ;;

  restart)
    echo "Restarting PostgreSQL container..."
    docker-compose restart
    ;;

  build)
    echo "Building extension inside container..."
    docker exec -it $CONTAINER_NAME bash -c "cd /extension && make clean && make && make install"
    echo "Extension built successfully!"
    ;;

  install)
    echo "Installing extension in database..."
    docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "DROP EXTENSION IF EXISTS pg_unique_slug CASCADE;"
    docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION pg_unique_slug;"
    echo "Extension installed successfully!"
    ;;

  rebuild)
    echo "Rebuilding and reinstalling extension..."
    $0 build
    $0 install
    ;;

  psql)
    echo "Connecting to PostgreSQL..."
    docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME
    ;;

  logs)
    echo "Showing PostgreSQL logs..."
    docker-compose logs -f
    ;;

  test)
    echo "Running regression tests..."
    docker exec -it $CONTAINER_NAME bash -c "cd /extension && make installcheck"
    echo ""
    echo "Check test/regression.diffs for any failures (empty = all passed)"
    ;;

  quicktest)
    echo "Running quick manual test..."
    docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME << 'EOF'
-- Create test table
DROP TABLE IF EXISTS test_slugs;
CREATE TABLE test_slugs (
    id serial PRIMARY KEY,
    slug text UNIQUE
);

-- Generate some slugs
INSERT INTO test_slugs (slug)
SELECT gen_unique_slug('test_slugs', 'slug', 8)
FROM generate_series(1, 10);

-- Show results
SELECT * FROM test_slugs;

-- Verify uniqueness
SELECT COUNT(*), COUNT(DISTINCT slug) FROM test_slugs;

-- Cleanup
DROP TABLE test_slugs;

SELECT 'Quick test completed!' as result;
EOF
    ;;

  shell)
    echo "Opening shell in container..."
    docker exec -it $CONTAINER_NAME bash
    ;;

  clean)
    echo "Cleaning build artifacts..."
    rm -f *.o *.so *.bc
    echo "Clean complete!"
    ;;

  *)
    echo "pg_unique_slug Development Helper"
    echo ""
    echo "Usage: ./dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start      - Start PostgreSQL container"
    echo "  stop       - Stop PostgreSQL container"
    echo "  restart    - Restart PostgreSQL container"
    echo "  build      - Build extension inside container"
    echo "  install    - Install extension in database"
    echo "  rebuild    - Rebuild and reinstall extension"
    echo "  psql       - Connect to PostgreSQL"
    echo "  logs       - Show PostgreSQL logs"
    echo "  test       - Run regression tests (pg_regress)"
    echo "  quicktest  - Run quick manual test"
    echo "  shell      - Open bash shell in container"
    echo "  clean      - Clean build artifacts"
    echo ""
    exit 1
    ;;
esac
