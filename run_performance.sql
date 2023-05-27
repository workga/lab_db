\i ./procedures.sql
\i ./triggers.sql
\i ./fill_db.sql
\i ./selects.sql


ANALYZE VERBOSE;


\echo "TEST: CROSSTAB"
EXPLAIN ANALYZE SELECT * FROM select2;

\echo "TEST: WITH"
EXPLAIN ANALYZE SELECT * FROM select2_1;

-- \echo "TEST: FUNCTIONS"
-- EXPLAIN ANALYZE SELECT * FROM select2_2;

\echo "TEST: 2 WITH"
EXPLAIN ANALYZE SELECT * FROM select2_3;
