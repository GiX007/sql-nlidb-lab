-- Indexes in SQL: Speeding Up Data Retrieval

-- Short Introduction:
-- An index is a data structure that helps the database find rows faster without scanning the entire table.
-- Think of it like the index of a book — instead of reading every page, you jump to the topic immediately.
-- Indexes improve the performance of SELECT queries (especially WHERE, JOIN, and ORDER BY).
-- However, they consume disk space and slightly slow down INSERT, UPDATE, DELETE operations because indexes must be updated.

-- Simple Example:
-- (Find movies after 2010 — faster with an index)
-- CREATE INDEX idx_production_year ON title(production_year);
-- SELECT title FROM title WHERE production_year > 2010;
-- (Notice: We still SELECT from the original table — indexes are used automatically by the database engine to speed up retrieval.)

-- 1. Create a basic index to speed up searches
CREATE INDEX idx_title_production_year
ON title(production_year);
-- (Creates an index on production_year to allow faster filtering in WHERE clauses.)

-- 2. Create a composite index (multi-column)
CREATE INDEX idx_title_year_and_kind
ON title(production_year, kind_id);
-- (Allows efficient searching when filtering by both production_year AND kind_id.)

-- 3. Create a unique index (no duplicates allowed)
CREATE UNIQUE INDEX idx_unique_company_name
ON company_name(name);
-- (Ensures that company names are unique — no two companies with the exact same name.)

-- 4. Create a partial index (only for recent movies)
CREATE INDEX idx_recent_movies
ON title(production_year)
WHERE production_year > 2000;
-- (Partial indexes cover only a subset of rows — smaller and faster for targeted queries.)

-- 5. Drop an existing index
DROP INDEX idx_recent_movies;
-- (Removes the index — always check if an index is truly needed before dropping.)

-- 6. View all indexes on a table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'title';
-- (Useful to inspect existing indexes — important for maintenance and optimization.)

-- 7. See impact of index on a JOIN operation
-- (Without index — slower)
SELECT t.title, cn.name
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
WHERE t.production_year > 2010;

-- (With index on movie_companies.movie_id — faster JOIN)
CREATE INDEX idx_mc_movie_id
ON movie_companies(movie_id);
-- (Notice: now joins between title and movie_companies are faster.)

-- 8. When indexes are not recommended
-- (On very small tables — scanning is faster than using index.)
--  Example: A table with < 100 rows may perform worse with indexes!

-- 9. Create a covering index (index all columns used in a query)
CREATE INDEX idx_title_production_year_title
ON title(production_year, title);
-- (If all selected columns are indexed, Postgres can do an "index-only scan" without touching the table.)

-- 10. Simulate disabling an index (Postgres only: using SET enable_indexscan = off)
-- (Use cautiously for testing — normally not recommended in production)
SET enable_indexscan = off;
-- (Now Postgres will avoid using index scans until SET enable_indexscan = on is called again.)

-- 11. Using EXPLAIN to verify if an index is used
EXPLAIN ANALYZE
SELECT title
FROM title
WHERE production_year > 2010;
-- (Look for "Index Scan" or "Bitmap Index Scan" in the plan to confirm that the index is actually used.)

-- ============================================================================
-- 🧠 Golden Rules About Indexes:

-- - Create indexes on columns used in WHERE, JOIN, or ORDER BY clauses frequently.
-- - Avoid too many indexes — each index slows down INSERT, UPDATE, and DELETE operations.
-- - Composite indexes are useful when multiple columns are filtered together.
-- - Use partial indexes if filtering always targets a subset of the table.
-- - Always use EXPLAIN ANALYZE to verify if your index is actually being used!

-- 🏋️‍♂️ Bonus Practice Tip:

-- A great exercise is to test queries from 02_joins.sql both with and without relevant indexes created manually.
-- Notice how joins between large tables (like title, cast_info, movie_companies) become significantly faster when appropriate indexes are available.
-- Try running the JOIN queries without indexes first, then create indexes on commonly joined columns (like movie_id, company_id, person_id) and compare execution times using EXPLAIN ANALYZE.
 
-- Example: 
--   CREATE INDEX idx_cast_info_movie_id ON cast_info(movie_id);
--   CREATE INDEX idx_movie_companies_company_id ON movie_companies(company_id);

-- Best queries from 02_joins.sql to test with and without indexes:

-- - Query 3: Find all movies and their production companies
--   (Create index on movie_companies.movie_id and company_name.id)

-- - Query 7: List all movies and their actors
--   (Create index on cast_info.movie_id and name.id)

-- - Query 11: LEFT JOIN showing all movies with or without a company
--   (Create index on movie_companies.movie_id and company_name.id)

-- Observing these performance differences in real queries is the best way to fully understand the power of indexing!
-- ============================================================================
