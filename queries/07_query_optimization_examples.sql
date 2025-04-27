-- Normal vs. Optimized queries demonstrating SQL optimization techniques using the IMDb-style database.

-- ============================================================================
-- 1. Find companies containing the word "Disney" (Basic filter optimization)
-- ============================================================================

-- (Normal version: no index optimization, case-sensitive)
SELECT name
FROM company_name
WHERE name LIKE '%Disney%';

-- (Optimized: case-insensitive ILIKE, better matching without missing results)
SELECT name
FROM company_name
WHERE name ILIKE '%Disney%';

-- ============================================================================
-- 2. Movies with missing production year
-- ============================================================================

-- (Normal version: wrong NULL comparison)
SELECT title
FROM title
WHERE production_year = NULL;

-- (Optimized: correct IS NULL)
SELECT title
FROM title
WHERE production_year IS NULL;

-- ============================================================================
-- 3. Find companies that produced at least 5 movies
-- ============================================================================

-- (Normal version: group and filter)
SELECT cn.name, COUNT(*) AS movie_count
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id	-- (Remember: no need to join title table,  because mc.movie_id column is enough!)
GROUP BY cn.name
HAVING COUNT(*) >= 5;

-- (Optimized: same but add ORDER BY to prioritize heavy hitters)
SELECT cn.name, COUNT(*) AS movie_count
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
GROUP BY cn.name
HAVING COUNT(*) >= 5
ORDER BY movie_count DESC;
-- (Notice: By adding ORDER BY movie_count DESC, we prioritize the companies producing the most movies,
--  making the results more useful and meaningful immediately, especially when combined with a LIMIT later if needed.
--  Although it doesn't speed up the query, it optimizes the relevance and usability of the output.)

-- ============================================================================
-- 4. List horror movies after 2010
-- ============================================================================

-- (Normal version: simple WHERE)
SELECT t.title
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%horror%'
  AND t.production_year > 2010;

-- (Optimized: using early CTE filtering)
WITH horror_movies AS (
    SELECT id, title
    FROM title
    WHERE production_year > 2010
)
SELECT hm.title
FROM horror_movies hm
JOIN movie_keyword mk ON hm.id = mk.movie_id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%horror%';

-- ============================================================================
-- 5. Top 5 starring actors (actors with nr_order between 1 and 4) by movie count
-- ============================================================================

-- (Normal version: simple grouping without early prefiltering)
SELECT n.name, COUNT(*) AS movie_count
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%'
  AND ci.nr_order BETWEEN 1 AND 4
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 5;

-- (Optimized: preselect actors and starring roles earlier)
WITH actor_counts AS (
    SELECT n.id, n.name, COUNT(*) AS movie_count
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%Actor%'
      AND ci.nr_order BETWEEN 1 AND 4
    GROUP BY n.id, n.name
)
SELECT name, movie_count
FROM actor_counts
ORDER BY movie_count DESC
LIMIT 5;
-- (Notice: By restricting actors to starring roles (nr_order between 1 and 4) early during filtering,
--  and grouping inside a CTE first, we keep the data smaller and focus only on top-level important appearances.)

-- ============================================================================
-- 6. Find the movies and their actors released by Disney (Better join and filtering)
-- ============================================================================

-- (Normal version: joins first, filters late)
-- EXPLAIN ANALYZE -- (Uncomment to see details of execution.)
SELECT t.title AS movie_title, n.name AS actor
FROM title t
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
JOIN cast_info ci ON ci.movie_id = t.id
JOIN role_type rt ON rt.id = ci.role_id
JOIN name n ON n.id = ci.person_id
WHERE cn.name LIKE '%Disney%' AND rt.role LIKE '%actor%';

-- (Optimized: prefilter Disney companies first, and only actor_roles, then join)
--  EXPLAIN ANALYZE -- (Uncomment to see details of execution and compare with the above results.)
WITH disney_movies AS (
    SELECT t.id, t.title
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON cn.id = mc.company_id
    WHERE cn.name ILIKE '%Disney%'
),
actor_roles AS(
	SELECT n.name, ci.movie_id
	FROM name n
	JOIN cast_info ci ON ci.person_id = n.id
	JOIN role_type rt ON rt.id = ci.role_id
	WHERE rt.role ILIKE '%actor%'
)
SELECT dm.title AS movie_title, ar.name AS actor_role
FROM disney_movies dm
JOIN actor_roles ar ON ar.movie_id = dm.id;
-- (Optimized: prefilter Disney movies and actor roles separately using CTEs before joining, drastically reducing the number of rows to be joined.
--  The join of the two pre-filtered CTEs is done by matching their common movie_id column. Notice that we should iclude movie_id as column in actor_roles cte.)

-- ============================================================================
-- 7. Find Disney movies between 2012 and 2015 having at least 2 producers. Display the movies and the number of producers
-- ============================================================================

-- (Normal version: filter late)
SELECT t.title, COUNT(*) AS producers
FROM title t
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
JOIN cast_info ci ON ci.movie_id = t.id
JOIN role_type rt ON rt.id = ci.role_id
WHERE cn.name ILIKE '%Disney%'
  AND t.production_year BETWEEN 2012 AND 2015
  AND rt.role ILIKE '%Producer%'
GROUP BY t.title
HAVING COUNT(*) >= 2;

-- (Optimized: prefilter Disney and producer roles separately)
WITH disney_titles AS (
    SELECT t.id, t.title
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON cn.id = mc.company_id
    WHERE cn.name ILIKE '%Disney%' AND t.production_year BETWEEN 2012 AND 2015
)
SELECT dt.title, COUNT(*) AS producers
FROM disney_titles dt
JOIN cast_info ci ON ci.movie_id = dt.id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%Producer%'
GROUP BY dt.title
HAVING COUNT(*) >= 2;

-- (Alternative optimized: prefilter Disney titles and movies with >=2 producers separately, then join)
WITH disney_titles AS (
	SELECT t.title, t.id	-- (Notice we need t.id as column to join with the producers_more_than_2 cte.)
	FROM title t
	JOIN movie_companies mc ON mc.movie_id = t.id
	JOIN company_name cn ON cn.id = mc.company_id
	WHERE cn.name ILIKE '%Disney%'
		AND t.production_year BETWEEN 2012 AND 2015
),
producers_more_than_2 AS (
	SELECT ci.movie_id		-- (Notice we need ci.movie_id as column to join with disney_titles cte.)
	FROM cast_info ci
	JOIN role_type rt ON rt.id = ci.role_id
	WHERE rt.role ILIKE '%producer%'
	GROUP BY ci.movie_id
	HAVING COUNT(*) >= 2
)
SELECT dt.title
FROM disney_titles dt
JOIN producers_more_than_2 pm2 ON pm2.movie_id = dt.id; 
-- (Notice: We split the Disney filtering and the producer counting into two separate CTEs, making the final join extremely lightweight.
--  However, for this specific case alternative optimized query, this approach is actually slower than the direct CTE method above,
--  but it remains a valuable strategy for other cases where datasets are bigger or differently distributed, as in Query 6.
--  Generally, the optimization techniques we apply depend on the structure and characteristics of the specific database.
--  here are no absolute rules — the best strategy often varies depending on the context.)

-- ============================================================================
-- 8. Find the latest video game title (Retrieve only needed data)
-- ============================================================================

-- (Normal version: no filtering early)
SELECT title, production_year
FROM title
WHERE kind_id = (SELECT id FROM kind_type WHERE kind ILIKE '%video game%')
	AND production_year IS NOT NULL
ORDER BY production_year DESC
LIMIT 1;

-- (Optimized: filter earlier and limit sorting)
WITH video_games AS (
    SELECT id, title, production_year
    FROM title
    WHERE kind_id = (SELECT id FROM kind_type WHERE kind ILIKE '%video game%')
		AND production_year IS NOT NULL
)
SELECT title, production_year
FROM video_games
ORDER BY production_year DESC
LIMIT 1;

-- ============================================================================
-- 9. List actors who have starred in more movies than Tom Hanks
-- ============================================================================

-- (Normal version: heavy correlated subquery)
SELECT name
FROM name n
WHERE (
    SELECT COUNT(*)
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE ci.person_id = n.id AND rt.role ILIKE '%Actor%'
) > (
    SELECT COUNT(*)
    FROM name n2
    JOIN cast_info ci2 ON ci2.person_id = n2.id
    JOIN role_type rt2 ON rt2.id = ci2.role_id
    WHERE n2.name = 'Tom Hanks' AND rt2.role ILIKE '%Actor%'
);

-- (Optimized: precompute actor movie counts)
WITH actor_counts AS (
    SELECT ci.person_id, COUNT(*) AS movie_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%Actor%'
    GROUP BY ci.person_id
),
tom_hanks_count AS (
    SELECT movie_count
    FROM actor_counts ac
    JOIN name n ON n.id = ac.person_id
    WHERE n.name = 'Tom Hanks'
)
SELECT n.name
FROM actor_counts ac
JOIN name n ON n.id = ac.person_id
WHERE ac.movie_count > (SELECT movie_count FROM tom_hanks_count);
-- (Notice: The second CTE is built upon the first CTE, allowing the query to stay modular, 
--  progressively filtering and preparing the data step-by-step in a clean and efficient way.)

-- ============================================================================
-- 10. Retrieve movies after 2010 with their production companies
-- ============================================================================

-- (Normal version: no early filtering)
SELECT t.title AS movie_title, cn.name AS company_name
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON cn.id = mc.company_id
WHERE t.production_year > 2010;

-- (Optimized: filter title first)
WITH recent_titles AS (
    SELECT id, title -- (Notice that we need to add id column to be able to make the join later.)
    FROM title
    WHERE production_year > 2010
)
SELECT rt.title AS movie_title, cn.name AS companay_name
FROM recent_titles rt
JOIN movie_companies mc ON mc.movie_id = rt.id -- (Notice that to be able to join cte with mc, we need to have the id column in rt.)
JOIN company_name cn ON cn.id = mc.company_id;

-- ============================================================================
-- 11. Retrieve actors in 'comedy' movies after 2000
-- ============================================================================

-- (Normal version: filter late)
SELECT DISTINCT n.name AS actor
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON t.id = ci.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%comedy%'
	AND rt.role ILIKE '%actor%'
	AND t.production_year > 2000;

-- (Optimized: prefilter comedies first)
WITH comedy_movies AS (
    SELECT t.id
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%comedy%' AND t.production_year > 2000
)
SELECT DISTINCT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%' AND ci.movie_id IN (SELECT id FROM comedy_movies);

-- ============================================================================
-- 12. Find the top 100 actors and their movies produced after 2010
-- ============================================================================

-- (Normal version: JOIN full data, then LIMIT after sorting)
SELECT n.name, t.title, t.production_year
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON t.id = ci.movie_id
WHERE t.production_year > 2010 AND rt.role ILIKE '%actor%'
ORDER BY n.name
LIMIT 100;

-- (Optimized version: pre-limit actors first, then join)
WITH top_actors AS (
    SELECT n.id, n.name
    FROM name n
	JOIN cast_info ci ON ci.person_id = n.id
	JOIN role_type rt ON rt.id = ci.role_id
	WHERE rt.role ILIKE '%actor%'
    ORDER BY n.name
    LIMIT 100
)
SELECT ta.name, t.title, t.production_year
FROM top_actors ta
JOIN cast_info ci ON ci.person_id = ta.id
JOIN title t ON t.id = ci.movie_id
WHERE t.production_year > 2010;
-- (Notice: By limiting actors first inside a subquery (CTE), 
--  we avoid joining millions of people unnecessarily, and we focus the join only on the top 100 actors from the beginning - great example!)

-- ============================================================================
-- 13. Actors with more than 3 different characters played
-- ============================================================================

-- (Normal version: join, count, filter roles later)
SELECT n.name, COUNT(DISTINCT cn.name) AS characters
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN char_name cn ON cn.id = ci.person_role_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role LIKE '%actor%'
GROUP BY n.name
HAVING COUNT(DISTINCT cn.name) > 3;

-- (Optimized: filter actors earlier, select only needed columns)
WITH actor_characters AS (
    SELECT ci.person_id, COUNT(DISTINCT ci.person_role_id) AS character_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY ci.person_id
)
SELECT n.name
FROM actor_characters ac
JOIN name n ON n.id = ac.person_id
WHERE ac.character_count > 3;
-- (Notice: In the optimized version, we filter actor roles early during aggregation using ILIKE for better matching flexibility, 
--  and we only bring necessary columns into the final join, making the query faster and lighter.)

-- ============================================================================
-- 14. Movies with no keywords
-- ============================================================================

-- (Normal version: NOT IN style)
SELECT title
FROM title
WHERE id NOT IN (
    SELECT DISTINCT movie_id
    FROM movie_keyword
);

-- (Optimized: NOT EXISTS style)
SELECT title
FROM title t
WHERE NOT EXISTS (
    SELECT 1
    FROM movie_keyword mk
    WHERE mk.movie_id = t.id
);
-- (Notice: This is a great example of how NOT EXISTS optimizes a query.
--  In the NOT IN version, the database must first collect all distinct movie_ids and then compare every title.id against the entire list, causing memory and scan overhead. 
--  In the NOT EXISTS version, the database checks each movie individually, exiting early as soon as a keyword match is found, making it much faster and lighter on large tables.)

-- ============================================================================
-- 15. Find actors who have acted both in movies and video games
-- ============================================================================

-- (Normal version: heavy joins and conditions)
SELECT DISTINCT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%' OR kind ILIKE '%video game%')
GROUP BY n.name
HAVING COUNT(DISTINCT t.kind_id) = 2;

-- (Optimized: use two EXISTS checks)
SELECT n.name
FROM name n
WHERE EXISTS (
    SELECT 1 FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE ci.person_id = n.id AND t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')
)
AND EXISTS (
    SELECT 1 FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE ci.person_id = n.id AND t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%video game%')
);
-- (Notice: The optimized version with EXISTS stops searching as soon as it finds a match for each condition,
--  avoiding full scans and heavy grouping, making it much faster especially on large datasets.)

-- ============================================================================
-- 16. Find actors who acted only in 'comedy' movies
-- ============================================================================

-- (Normal version: heavy HAVING with CASE)
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON t.id = ci.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
GROUP BY n.name
HAVING SUM(CASE WHEN k.keyword ILIKE '%comedy%' THEN 0 ELSE 1 END) = 0;
-- (Remimber that CASE checks each movie's keyword: if it's 'comedy' → counts 0, otherwise 1; 
--  then SUM totals the non-comedy cases — if the sum is 0, it means all movies are comedies.)

-- (Optimized: NOT EXISTS style, faster early exit)
SELECT n.name
FROM name n
WHERE NOT EXISTS (
    SELECT 1
    FROM cast_info ci
    JOIN title t ON t.id = ci.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE ci.person_id = n.id
      AND k.keyword NOT ILIKE '%comedy%'
);
-- (Notice: In the normal version, the database processes all actors and their movies, grouping everything first and then filtering. In the optimized version with NOT EXISTS,
--  the database checks each actor individually before joining all large tables exhaustively, and exits immediately if a non-comedy movie is found, 
--  keeping only the actors who satisfy the condition. This early check and exit makes the query much faster and lighter on large datasets.)

-- ============================================================================
-- 17. Companies producing both drama and comedy
-- ============================================================================

-- (Normal version: messy grouping)
SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%drama%' OR k.keyword ILIKE '%comedy%'
GROUP BY cn.name
HAVING COUNT(DISTINCT CASE WHEN k.keyword ILIKE '%drama%' THEN 1 END) > 0
   AND COUNT(DISTINCT CASE WHEN k.keyword ILIKE '%comedy%' THEN 1 END) > 0;

-- (Optimized: using two EXISTS)
SELECT DISTINCT cn.name
FROM company_name cn
WHERE EXISTS (
    SELECT 1
    FROM movie_companies mc
    JOIN title t ON t.id = mc.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE mc.company_id = cn.id
      AND k.keyword ILIKE '%drama%'
)
AND EXISTS (
    SELECT 1
    FROM movie_companies mc
    JOIN title t ON t.id = mc.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE mc.company_id = cn.id
      AND k.keyword ILIKE '%comedy%'
);

-- ============================================================================
-- 18. Actors in comedy but not horror after 2010
-- ============================================================================

-- (Normal version: heavy HAVING filtering)
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE t.production_year > 2010
GROUP BY n.name
HAVING SUM(CASE WHEN k.keyword ILIKE '%horror%' THEN 1 ELSE 0 END) = 0
   AND SUM(CASE WHEN k.keyword ILIKE '%comedy%' THEN 1 ELSE 0 END) > 0;

-- (Optimized: EXISTS filtering)
SELECT n.name
FROM name n
WHERE EXISTS (
    SELECT 1
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE ci.person_id = n.id
      AND k.keyword ILIKE '%comedy%'
      AND t.production_year > 2010
)
AND NOT EXISTS (
    SELECT 1
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE ci.person_id = n.id
      AND k.keyword ILIKE '%horror%'
      AND t.production_year > 2010
);

-- ============================================================================
-- 19. Find movie titles and their genre (using subquery instead of JOIN)
-- ============================================================================

-- (Normal version: heavy JOIN to fetch genres)
SELECT t.title, k.keyword
FROM title t
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%drama%';

-- (Optimized version: use subquery inside SELECT instead of JOINs)
SELECT t.title,
    (SELECT k.keyword
     FROM movie_keyword mk
     JOIN keyword k ON k.id = mk.keyword_id
     WHERE mk.movie_id = t.id
       AND k.keyword ILIKE '%drama%'
     LIMIT 1) AS genre	-- (LIMIT 1 ensures the subquery returns only one keyword per movie  (because movies can have multiple genres/tags), preventing multiple row errors inside SELECT.)
FROM title t
WHERE EXISTS (
    SELECT 1
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE mk.movie_id = t.id
      AND k.keyword ILIKE '%drama%'
);
-- (Notice: Instead of joining all rows (many-to-many explosion), we use a subquery to fetch only one genre per movie, avoiding huge intermediate JOIN results — lighter and faster on large datasets.)

-- ============================================================================
-- 20. Find the number of movies produced per year after 2010
-- ============================================================================
 
-- (Normal version: useless subquery wrapping simple SELECT)
SELECT *
FROM (
    SELECT production_year, COUNT(*) AS movie_count
    FROM title
    WHERE production_year > 2010
    GROUP BY production_year
) AS subquery
ORDER BY movie_count DESC;

-- (Optimized version: remove useless subquery)
SELECT production_year, COUNT(*) AS movie_count
FROM title
WHERE production_year > 2010
GROUP BY production_year
ORDER BY movie_count DESC;
-- (Notice: This example reminds us that we don't always need to wrap simple queries into unnecessary subqueries.
--  Keeping the structure clean and direct not only simplifies reading and maintenance, but also improves performance. 
--  Clean structure = faster execution = smarter optimization!)

-- ============================================================================
-- Closing Notes:
-- Good query writing saves hours of debugging and terabytes of resources!

-- 🛠️ Practical SQL Optimization Blueprint (Step-by-Step Thinking)

-- Always first look at WHERE clauses carefully:

-- - WHERE with ILIKE or LIKE on text fields (e.g., 'Drama', 'Disney', 'Titanic')
--   → First thought: "Can I prefilter using a CTE or subquery before joining?"
--   → Prefiltering specific values early (with CTE or subquery) reduces work dramatically.

-- - WHERE production_year = NULL
--   → Remember: use IS NULL instead of = NULL.

-- - WHERE with COUNT(*), SUM(), AVG(), or HAVING clauses
--   → Think: "Can I filter earlier with WHERE before grouping?"
--   → Suggestion: "Maybe create a CTE or subquery to prefilter rows before aggregating."

-- - WHERE with COUNT(*) or IN subqueries
--   → Think: "Would EXISTS be faster if I only need to check existence?"

-- - WHERE using functions on columns (e.g., LOWER(title), EXTRACT(year FROM date))
--   → Think: "Am I blocking index usage? Should I normalize or precompute the value instead?"
--   → Normalize: store already lowercased or formatted versions of values in a separate indexed column.
--   → Precompute: create a new column like 'title_lower' or 'release_year' and fill it during INSERT/UPDATE, so queries can filter directly without needing to apply functions on the fly.

-- Now check the SELECT clause:

-- - SELECT *
--   → Always avoid. Select only necessary columns to reduce memory, network usage, and disk I/O.

-- - SELECT DISTINCT
--   → Ask: "Do I really need DISTINCT? Could I use GROUP BY better, or avoid duplicates earlier?"

-- Regarding JOINs:

-- - JOINs without WHERE filters
--   → Push filters into JOINs as early as possible to minimize intermediate row counts.

-- - JOINs with text matching
--   → Prefer filtering separately using CTEs before joining.

-- Operations involving sets:

-- - UNION
--   → Prefer UNION ALL unless you must remove duplicates.

-- - ORDER BY combined with LIMIT
--   → Think: "Can I LIMIT early to avoid sorting large datasets?"
--   → If the query involves JOINs and then LIMIT, consider wrapping the most selective table in a subquery with LIMIT first, so the join happens against a much smaller result set.

-- - Complex questions (asking for two different things)
--   → Split into multiple CTEs or subqueries (e.g., Disney titles + producer count).
--   → Then JOIN or use EXISTS between them.

-- Overall mindset:

-- - Always think set-based: operate on groups of rows, not row-by-row.
-- - Keep intermediate datasets as small as possible.
-- - Defer heavy operations (ORDER BY, DISTINCT) until absolutely necessary.

-- 🛡️ Remember:
-- EXPLAIN and EXPLAIN ANALYZE are your best friends for analyzing real performance.

-- 🚀 Keep your queries simple, selective, and smart to achieve high efficiency!
-- ============================================================================

-- 🧠 Ultra-Condensed Exam Reminder (5-Second Checklist):

-- 1️. WHERE first → Prefilter as early as possible (CTE or subquery if needed)
-- 2️. SELECT clean → Only needed columns (no SELECT *)
-- 3️. JOIN smart → Filter tables before joining (smaller = faster)
-- 4️. GROUP BY smart → Filter early if possible, avoid heavy HAVING
-- 5️. ORDER BY late → LIMIT first if possible to avoid sorting millions of rows

-- Always think: Filter → Minimize → Aggregate → Order → Output

-- ✨ Smart queries not only run faster — they make you think smarter too!
-- ============================================================================
