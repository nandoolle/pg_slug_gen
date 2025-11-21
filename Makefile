EXTENSION = pg_unique_slug
MODULE_big = pg_unique_slug
OBJS = pg_unique_slug.o

DATA = sql/pg_unique_slug--1.0.sql
DOCS = README.md

# Regression tests
REGRESS = basic
REGRESS_OPTS = --inputdir=test

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
