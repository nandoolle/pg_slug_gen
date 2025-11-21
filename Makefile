EXTENSION = pg_slug_gen
MODULE_big = pg_slug_gen
OBJS = pg_slug_gen.o

DATA = sql/pg_slug_gen--1.0.sql
DOCS = README.md

# Regression tests
REGRESS = basic
REGRESS_OPTS = --inputdir=test

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
