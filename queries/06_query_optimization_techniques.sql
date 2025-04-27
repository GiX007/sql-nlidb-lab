-- Techniques and examples for improving query performance using an IMDb-style database.
-- In this file, we show 20+ progressively more advanced examples of query optimizations, from simple tricks to advanced performance techniques.

-- Short Introduction to Query Optimization:
-- Query optimization is the process of improving the performance of SQL queries by making them faster and more efficient by using less data, while still producing the same correct results.
-- Optimization is important because inefficient queries can consume more CPU, memory, and disk resources, causing slowdowns especially on large datasets.

-- Why we optimize queries:
-- - Reduce execution time (make queries faster)
-- - Reduce memory and disk usage as we use less data
-- - Improve overall database performance, especially under heavy load
-- - Make better use of indexes and database statistics

-- How we optimize queries:
-- - Write queries that filter data early (WHERE conditions)
-- - Retrieve only the necessary columns (avoid SELECT *)
-- - Limit rows if only partial data is needed (LIMIT)
-- - Avoid unnecessary operations (DISTINCT, heavy joins, complex subqueries)
-- - Use EXISTS vs IN properly
-- - Analyze execution plans (EXPLAIN, EXPLAIN ANALYZE)
-- - Let the database use indexes naturally

-- Simple example of query optimization:

-- (Bad query: selecting all columns and no filter)
-- SELECT * 
-- FROM title;

-- (Better query: selecting only needed columns with filtering)
-- SELECT title, production_year
-- FROM title
-- WHERE production_year > 2010;

-- (Explanation: By selecting only two columns instead of all (*), and adding a WHERE filter to restrict rows, the query becomes faster, lighter on memory, and allows the database to optimize better.)


-- 1. Filter Early (apply WHERE as soon as possible to reduce data scanned)

-- (Bad query: No WHERE, scans all rows)
SELECT title, production_year
FROM title;

-- (Optimized query: filter rows early)
SELECT title, production_year
FROM title
WHERE production_year > 2010;
-- (Explanation: By filtering with WHERE, the database processes fewer rows immediately, making the query faster and lighter.)


-- 2. Select Only Needed Columns (avoid SELECT *)

-- (Bad query: selects all columns unnecessarily)
SELECT *
FROM title
WHERE production_year > 2010;

-- (Optimized query: select only specific columns needed)
SELECT title, production_year
FROM title
WHERE production_year > 2010;
-- (Explanation: Selecting only the necessary columns reduces memory usage, network transfer, and processing time.)


-- 3. Limit Rows Early (use LIMIT when full results are not needed)

-- (Bad query: selects everything even if only a few rows are needed)
SELECT title, production_year
FROM title
WHERE production_year IS NOT NULL;

-- (Optimized query: limit results if only a few rows are needed)
SELECT title, production_year
FROM title
WHERE production_year IS NOT NULL
LIMIT 100;
-- (Explanation: LIMIT reduces the number of rows processed, sorted, or transferred, improving speed when only part of the results are needed.)


-- 4. Prefer EXISTS over IN (better for large subquery results)

-- (Bad query: IN with potentially large list)
SELECT name
FROM name
WHERE id IN (
    SELECT person_id
    FROM cast_info
);

-- (Optimized query: EXISTS checks existence efficiently)
SELECT n.name
FROM name n
WHERE EXISTS (
    SELECT 1
    FROM cast_info ci
    WHERE ci.person_id = n.id
);
-- (Explanation: EXISTS stops checking as soon as it finds a match, while IN must fetch and compare all values, making EXISTS often faster.)


-- 5. Avoid functions applied to indexed columns in WHERE 

-- (Bad query: applying a function disables index usage)
SELECT title
FROM title
WHERE LOWER(title) = 'inception';

-- (Optimized query: normalize search term instead)
SELECT title
FROM title
WHERE title ILIKE 'inception';
-- (Explanation: Functions like LOWER() prevent the database from using indexes.
-- Using ILIKE (case-insensitive search) or pre-normalized data keeps indexes usable, greatly improving performance.)


-- 6. Join Tables in the Right Order (small table first when possible) - very important!

-- (Bad query: big table first, slower)
SELECT t.title, n.name
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON n.id = ci.person_id
WHERE t.production_year > 2010;

-- (Optimized query: smaller table first, smarter access)
SELECT n.name, t.title
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON t.id = ci.movie_id
WHERE t.production_year > 2010;
-- (Explanation: Joining smaller tables first can help reduce intermediate result sizes, improving join performance especially on big datasets.)


-- 7. Use WHERE Conditions Before GROUP BY (filter before aggregating) - very important!

-- (Bad query: groups all rows, then filters)
SELECT production_year, COUNT(*)
FROM title
GROUP BY production_year
HAVING production_year > 2000;

-- (Optimized query: filter with WHERE first, then group)
SELECT production_year, COUNT(*)
FROM title
WHERE production_year > 2000
GROUP BY production_year;
-- (Explanation: Filtering rows before GROUP BY reduces the data to be grouped and aggregated, making the query much faster.)


-- 8. Handle NULLs Properly (use IS NULL or IS NOT NULL)

-- (Bad query: wrong NULL comparison, no results)
SELECT title
FROM title
WHERE production_year = NULL;

-- (Optimized query: correct way to check NULL)
SELECT title
FROM title
WHERE production_year IS NULL;
-- (Explanation: NULL in SQL needs IS NULL or IS NOT NULL — using = NULL does not work and causes silent errors.)


-- 9. Avoid Unnecessary DISTINCT if GROUP BY already guarantees uniqueness

-- (Bad query: redundant DISTINCT)
SELECT DISTINCT production_year
FROM (
    SELECT production_year
    FROM title
    GROUP BY production_year
) AS grouped_years;

-- (Optimized query: GROUP BY already ensures uniqueness)
SELECT production_year
FROM title
GROUP BY production_year;
-- (Explanation: GROUP BY already returns unique values per group. Adding DISTINCT is redundant and adds extra unnecessary work.)


-- 10. Avoid COUNT(*) inside correlated subqueries when simple EXISTS works - very important!

-- (Bad query: COUNT(*) correlated subquery, slower)
SELECT title
FROM title t
WHERE (
    SELECT COUNT(*)
    FROM movie_keyword mk
    WHERE mk.movie_id = t.id
) > 0;

-- (Optimized query: EXISTS is much faster)
SELECT title
FROM title t
WHERE EXISTS (
    SELECT 1
    FROM movie_keyword mk
    WHERE mk.movie_id = t.id
);
-- (Explanation: EXISTS stops at the first match; COUNT(*) scans all matching rows unnecessarily.
--  EXISTS is much more efficient when we only care about existence.)


-- 11. Move Conditions from WHERE to JOIN to optimize join performance - super important!!

-- (Bad query: applies filter after a large join, causing unnecessary cross-products and extra processing)
SELECT t.title, n.name
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON n.id = ci.person_id
WHERE t.production_year > 2000;

-- (Optimized query: move filter inside JOIN early)
SELECT t.title, n.name
FROM (
    SELECT id, title
    FROM title
    WHERE production_year > 2000
) t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON n.id = ci.person_id;
-- (Explanation: Filtering rows before joining reduces the number of rows participating in the join, making the join operation much faster.)


-- 12. Use UNION ALL instead of UNION when duplicates are acceptable

-- (Bad query: UNION removes duplicates, slower)
SELECT title FROM title WHERE production_year = 2000
UNION
SELECT title FROM title WHERE production_year = 2001;

-- (Optimized query: UNION ALL is faster)
SELECT title FROM title WHERE production_year = 2000
UNION ALL
SELECT title FROM title WHERE production_year = 2001;
-- (Explanation: UNION sorts and removes duplicates (extra work).
-- UNION ALL simply appends results without checking, much faster if duplicates are not an issue.)


-- 13. Avoid functions on columns during JOINs

-- (Bad query: applying function prevents index use)
SELECT t.title, mc.movie_id
FROM movie_companies mc
JOIN title t ON LOWER(t.id) = LOWER(mc.movie_id);

-- (Optimized query: no function applied to columns)
SELECT t.title, mc.movie_id
FROM movie_companies mc
JOIN title t ON t.id = mc.movie_id;
-- (Explanation: Applying functions to join columns disables index usage and forces full scans.
-- Always join on raw columns if possible to allow faster index lookups.)



-- 14. Defer ORDER BY until after filtering and limiting - very important!

-- (Bad query: ordering full dataset before limiting)
SELECT title
FROM title
ORDER BY production_year
LIMIT 100;

-- (Optimized query: limit first in a subquery, then order)
SELECT *
FROM (
    SELECT title, production_year
    FROM title
    LIMIT 100
) AS limited
ORDER BY production_year;
-- (Explanation: Sorting large datasets is expensive.
-- If possible, LIMIT early and then ORDER the smaller result set to save memory and CPU time.)


-- 15. Export only needed columns when using COPY

-- (Bad query: exporting entire table unnecessarily)
COPY (SELECT * FROM title)
TO '/path/to/movies_full.csv' WITH CSV HEADER;

-- (Optimized query: export only required columns)
COPY (SELECT title, production_year FROM title)
TO '/path/to/movies_short.csv' WITH CSV HEADER;
-- (Explanation: Exporting fewer columns reduces I/O, makes files smaller and faster to create, and speeds up future data loading.)


-- 16. Always ANALYZE after major data changes (INSERT, UPDATE and DELETE)

-- (Bad practice: no statistics update after big INSERT/DELETE)
-- (Nothing to show — the optimizer works with stale data.)

-- (Good practice: update statistics)
ANALYZE title;
-- (Explanation: ANALYZE refreshes table statistics (number of rows, distribution of data) so that the optimizer can create better, faster query plans.)


-- 17. Prefer covering indexes (select only indexed columns when possible)
-- (Indexes are special structures that speed up data retrieval.
--  Primary keys automatically create unique indexes, allowing faster WHERE lookups and JOINs.)

-- (Bad query: selects many columns, cannot use index alone)
SELECT title, production_year, id
FROM title
WHERE production_year > 2010;

-- (Optimized query: select only indexed columns like id)
SELECT id
FROM title
WHERE production_year > 2010;
-- (Explanation: If a query only uses columns from an index, the database can satisfy it directly from the index without accessing the full table ("index-only scan"), improving performance.)


-- 18. Avoid unnecessary subqueries when a simple JOIN can solve the problem - very important!
-- (Correlated subqueries execute once per row, which is slow on large tables.
--  JOIN retrieves all needed data at once in a set-based way, making it much faster and scalable.)

-- (Bad query: correlated subquery for name lookup)
SELECT title, (
    SELECT name
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    WHERE mc.movie_id = t.id
    LIMIT 1
) AS company
FROM title t;

-- (Optimized query: use JOIN directly)
SELECT t.title, c.name AS company
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name c ON c.id = mc.company_id;
-- (Explanation: JOINs are much faster than repeatedly running subqueries per row.
--  Always prefer JOIN when retrieving data from related tables.)


-- 19. Use EXPLAIN and EXPLAIN ANALYZE to check query cost

-- (Example: Check how a query is executed)
EXPLAIN
SELECT title, production_year
FROM title
WHERE production_year > 2015;

-- (Better: EXPLAIN ANALYZE shows actual timing)
EXPLAIN ANALYZE
SELECT title, production_year
FROM title
WHERE production_year > 2015;
-- (Explanation: Always use EXPLAIN and EXPLAIN ANALYZE to understand how your query behaves: estimated cost, row counts, index usage, sequential scans, etc.
--  It is the best tool for spotting slow parts of queries.)


-- 20. Example: Heavy Query vs Optimized Query - super important!!

-- (Bad query: joins and filters after joining)
SELECT t.title, n.name
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON n.id = ci.person_id
WHERE t.production_year > 2000
  AND n.name ILIKE '%Tom%';

-- (Optimized query: filter both tables early before joining)
WITH filtered_titles AS (
    SELECT id, title
    FROM title
    WHERE production_year > 2000
),
filtered_names AS (
    SELECT id, name
    FROM name
    WHERE name ILIKE '%Tom%'
)
SELECT ft.title, fn.name
FROM filtered_titles ft
JOIN cast_info ci ON ft.id = ci.movie_id
JOIN filtered_names fn ON fn.id = ci.person_id;
-- (Explanation: By reducing the size of both tables before joining (using CTEs to pre-filter), we drastically cut down the number of rows involved in joins, speeding up the query significantly.)


-- =========================================================================
-- Closing Notes:
-- Good query writing saves hours of debugging and terabytes of resources!

-- ⭐ Super Important Techniques to Always Remember:
-- - Apply WHERE filters as early as possible to reduce scanned rows.
-- - Prefer EXISTS instead of IN for existence checks.
-- - Move conditions from WHERE into JOINs when possible.
-- - Avoid COUNT(*) inside correlated subqueries — prefer EXISTS.
-- - Defer ORDER BY until after LIMIT when possible.

-- 🔥 Very Important Techniques:
-- - Avoid functions on indexed columns in WHERE and JOIN.
-- - Use UNION ALL instead of UNION when duplicate removal isn't needed.
-- - Use EXPLAIN and EXPLAIN ANALYZE to understand query performance.
-- - Use covering indexes (select only indexed columns when possible).
-- - ANALYZE tables after large data changes to refresh planner statistics.

-- 📚 Other Good Practices:
-- - Avoid unnecessary DISTINCT if GROUP BY is already used.
-- - Handle NULLs properly with IS NULL / IS NOT NULL.
-- - Export only the needed columns when writing results to files (COPY).
-- - Replace unnecessary subqueries with simple JOINs.
-- - Always think set-based (operate on groups of rows, not one-by-one).

-- =========================================================================
