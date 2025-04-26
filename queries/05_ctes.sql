-- Basic CTE (Common Table Expression) structure:
-- WITH cte_name AS (
--    SELECT ...
-- )
-- SELECT ...
-- (CTEs allow us to create temporary named result sets that can be referenced within the main query.
--  They improve readability and are especially useful for breaking down complex queries into simpler steps.
--  A CTE acts like a temporary table created by the SELECT inside it — and from that "table," we can select, join, group, or filter just like a real table and as needed in the main query.
--  Additionally, CTEs can sometimes help reduce execution time by allowing the database engine to optimize and materialize intermediate results more efficiently)
-- Example:
-- WITH movie_counts AS (
--    SELECT production_year, COUNT(*) AS total_movies
--    FROM title
--    GROUP BY production_year
-- )
-- SELECT AVG(total_movies)
-- FROM movie_counts;

-- 1. Find the total number of movies produced per year using CTE
WITH yearly_movie_counts AS (
    SELECT production_year, COUNT(*) AS movie_count
    FROM title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
)
SELECT *
FROM yearly_movie_counts
ORDER BY production_year;

-- (Alternative without CTE)
SELECT production_year, COUNT(*) AS movie_count
FROM title
WHERE production_year IS NOT NULL
GROUP BY production_year
ORDER BY production_year;
-- (Notice: Here we simply take a query, place it inside a CTE, a temporary table, and then SELECT * from it.
--  This shows the simplest functionality of a CTE: wrapping a query to improve organization and readability)

-- 2. Find the average number of movies produced per year using CTE (CTE vs comparing subquery)
WITH yearly_movie_counts AS (
    SELECT production_year, COUNT(*) AS movie_count
    FROM title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
)
SELECT AVG(movie_count) AS avg_movies_per_year
FROM yearly_movie_counts;

-- (Alternative without CTE - using subquery directly)
SELECT AVG(movie_count) AS avg_movies_per_year
FROM (
    SELECT production_year, COUNT(*) AS movie_count
    FROM title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
) AS yearly_counts;
-- (Notice: We often use CTEs instead of subqueries when we want to improve readability and sometimes performance.
--  In many cases, especially for larger datasets, the CTE version can execute faster, justs  like here, because the intermediate results can be materialized once, while a subquery might be recalculated multiple times - see next example)

-- 3. Find movies released after the average production year 
WITH avg_year AS (
    SELECT AVG(production_year) AS avg_prod_year
    FROM title
)
SELECT title
FROM title
WHERE production_year > (SELECT avg_prod_year FROM avg_year);

-- (Alternative without CTE)
SELECT title
FROM title
WHERE production_year > (
    SELECT AVG(production_year)
    FROM title
);
-- (Notice: Subqueries are "hidden" — so optimizers might (not always) re-execute them for every row.
--  CTEs are "named tables" — so optimizers usually compute them once and reuse the result, which can improve performance, especially on large datasets)

-- 4. Find the number of movies produced each year after 2000
WITH yearly_movies_after_2000 AS (
    SELECT production_year, COUNT(*) AS movie_count
    FROM title
    WHERE production_year > 2000
    GROUP BY production_year
)
SELECT *
FROM yearly_movies_after_2000
ORDER BY production_year;

-- (Alternative without CTE)
SELECT production_year, COUNT(*) AS movie_count
FROM title
WHERE production_year > 2000
GROUP BY production_year
ORDER BY production_year;
-- (Notice: A CTE helps isolate the filtering (after 2000) and aggregation (COUNT per year), keeping the main query clean, readable, and easy to reuse if needed)

-- 5. Find actors who acted in more than 10 movies (CTE vs direct query)
WITH actor_movie_counts AS (
    SELECT n.name, COUNT(*) AS movie_count
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY n.name
)
SELECT name, movie_count
FROM actor_movie_counts
WHERE movie_count > 10
ORDER BY movie_count DESC;

-- (Alternative without CTE - using GROUP BY and HAVING directly)
SELECT n.name, COUNT(*) AS movie_count
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%'
GROUP BY n.name
HAVING COUNT(*) > 10
ORDER BY movie_count DESC;

-- 6. Find the number of video games produced per year 
WITH video_game_counts AS (
    SELECT production_year, COUNT(*) AS game_count
    FROM title
    WHERE kind_id = (
        SELECT id FROM kind_type WHERE kind ILIKE '%video game%'
    )
    AND production_year IS NOT NULL
    GROUP BY production_year
)
SELECT *
FROM video_game_counts
ORDER BY production_year;

-- (Alternative without CTE - writing it directly)
SELECT production_year, COUNT(*) AS game_count
FROM title
WHERE kind_id = (
    SELECT id FROM kind_type WHERE kind ILIKE '%video game%'
)
AND production_year IS NOT NULL
GROUP BY production_year
ORDER BY production_year;

-- 7. Find the top 5 companies with the most movies produced 
WITH company_movie_counts AS (
    SELECT mc.company_id, COUNT(*) AS movie_count
    FROM movie_companies mc
    GROUP BY mc.company_id
)
SELECT cn.name, cmc.movie_count
FROM company_movie_counts cmc
JOIN company_name cn ON cn.id = cmc.company_id
ORDER BY cmc.movie_count DESC
LIMIT 5;

-- (Alternative without CTE - direct aggregation)
SELECT cn.name, COUNT(*) AS movie_count
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
GROUP BY cn.name
ORDER BY movie_count DESC
LIMIT 5;

-- 8. Find the average number of actors per movie 
WITH movie_actor_counts AS (
    SELECT ci.movie_id, COUNT(*) AS actor_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY ci.movie_id
)
SELECT AVG(actor_count) AS avg_actors_per_movie
FROM movie_actor_counts;

-- (Alternative without CTE - subquery in FROM)
SELECT AVG(actor_count) AS avg_actors_per_movie
FROM (
    SELECT ci.movie_id, COUNT(*) AS actor_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY ci.movie_id
) AS movie_actor_counts;

-- 9. Find the top 10 actors who have appeared in the most movies
WITH actor_movie_counts AS (
    SELECT n.name, COUNT(*) AS movie_count
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY n.name
)
SELECT name, movie_count
FROM actor_movie_counts
ORDER BY movie_count DESC
LIMIT 10;

-- (Alternative without CTE)
SELECT n.name, COUNT(*) AS movie_count
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%'
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 10;

-- 10. List movies with more actors than the average number of actors
WITH movie_actor_counts AS (
    SELECT ci.movie_id, COUNT(*) AS actor_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY ci.movie_id
)
, avg_actor_count AS (
    SELECT AVG(actor_count) AS avg_count
    FROM movie_actor_counts
)
SELECT t.title, mac.actor_count
FROM movie_actor_counts mac
JOIN title t ON t.id = mac.movie_id
WHERE mac.actor_count > (SELECT avg_count FROM avg_actor_count)
ORDER BY mac.actor_count DESC;

-- (Alternative without CTE. Notice the difference in execution time)
SELECT t.title, actor_counts.actor_count
FROM (
    SELECT ci.movie_id, COUNT(*) AS actor_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY ci.movie_id
) AS actor_counts
JOIN title t ON t.id = actor_counts.movie_id
WHERE actor_counts.actor_count > (
    SELECT AVG(actor_count)
    FROM (
        SELECT ci.movie_id, COUNT(*) AS actor_count
        FROM cast_info ci
        JOIN role_type rt ON rt.id = ci.role_id
        WHERE rt.role ILIKE '%actor%'
        GROUP BY ci.movie_id
    ) AS actor_counts_inner
)
ORDER BY actor_counts.actor_count DESC;

-- 11. Find the most common movie genres and their counts
WITH genre_counts AS (
    SELECT k.keyword, COUNT(*) AS genre_count
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.keyword
)
SELECT *
FROM genre_counts
ORDER BY genre_count DESC
LIMIT 10;

-- (Alternative without CTE)
SELECT k.keyword, COUNT(*) AS genre_count
FROM keyword k
JOIN movie_keyword mk ON k.id = mk.keyword_id
GROUP BY k.keyword
ORDER BY genre_count DESC
LIMIT 10;

-- 12. Find the number of movies each company has produced
WITH company_movies AS (
    SELECT cn.name AS company_name, COUNT(*) AS movie_count
    FROM company_name cn
    JOIN movie_companies mc ON cn.id = mc.company_id
    GROUP BY cn.name
)
SELECT *
FROM company_movies
ORDER BY movie_count DESC;

-- (Alternative without CTE)
SELECT cn.name AS company_name, COUNT(*) AS movie_count
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
GROUP BY cn.name
ORDER BY movie_count DESC;

-- 13. Find all movies tagged with 'drama' and their production companies
WITH drama_movies AS (
    SELECT t.id, t.title
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%drama%'
)
SELECT d.title, cn.name AS company
FROM drama_movies d
JOIN movie_companies mc ON mc.movie_id = d.id
JOIN company_name cn ON cn.id = mc.company_id;
-- (Notice: This is an excellent example where we create a CTE (drama_movies), then JOIN it with other tables (movie_companies and company_name) just like a normal table.
--  It shows how CTEs integrate smoothly into complex queries, making the logic cleaner and easier to follow)

-- (Alternative without CTE. Notice that it needs more time to be executed)
SELECT t.title, cn.name AS company
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON k.id = mk.keyword_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON cn.id = mc.company_id
WHERE k.keyword ILIKE '%drama%';

-- 14. Find actors who have played in 'comedy' movies after 2010
WITH comedy_movies AS (
    SELECT t.id
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%comedy%' AND t.production_year > 2010
)
SELECT DISTINCT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE ci.movie_id IN (SELECT id FROM comedy_movies)
AND rt.role ILIKE '%actor%';

-- (Alternative without CTE. Notice again the better execution time)
SELECT DISTINCT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE k.keyword ILIKE '%comedy%'
  AND t.production_year > 2010
  AND rt.role ILIKE '%actor%';

-- 15. Find the top 5 directors who directed the most movies
WITH director_movie_counts AS (
    SELECT n.name, COUNT(*) AS directed_movies
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%director%'
    GROUP BY n.name
)
SELECT *
FROM director_movie_counts
ORDER BY directed_movies DESC
LIMIT 5;

-- (Alternative without CTE)
SELECT n.name, COUNT(*) AS directed_movies
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%director%'
GROUP BY n.name
ORDER BY directed_movies DESC
LIMIT 5;

-- 16. Find companies that have produced both 'comedy' and 'drama' movies
WITH comedy_companies AS (
    SELECT DISTINCT mc.company_id
    FROM movie_companies mc
    JOIN title t ON t.id = mc.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%comedy%'
),
drama_companies AS (
    SELECT DISTINCT mc.company_id
    FROM movie_companies mc
    JOIN title t ON t.id = mc.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%drama%'
)
SELECT DISTINCT cn.name
FROM company_name cn
WHERE cn.id IN (SELECT company_id FROM comedy_companies)
AND cn.id IN (SELECT company_id FROM drama_companies);

-- (Alternative without CTE — longer and less clear)
SELECT DISTINCT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON mc.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%comedy%'
   OR k.keyword ILIKE '%drama%'
GROUP BY cn.name
HAVING COUNT(DISTINCT CASE WHEN k.keyword ILIKE '%comedy%' THEN 1 END) > 0
   AND COUNT(DISTINCT CASE WHEN k.keyword ILIKE '%drama%' THEN 1 END) > 0;
-- (Another great example: notice how the CTE version is much clearer and more readable compared to the direct query.
--  Also, CTEs can lead to better execution time, because we split the logic into two simple, optimized steps: finding comedy companies and drama companies separately)

-- 17. Find the number of 'horror' movies per production year
WITH horror_movies AS (
    SELECT t.production_year
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%horror%' AND t.production_year IS NOT NULL
)
SELECT production_year, COUNT(*) AS horror_movie_count
FROM horror_movies
GROUP BY production_year
ORDER BY production_year;

-- (Alternative without CTE)
SELECT t.production_year, COUNT(*) AS horror_movie_count
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%horror%' AND t.production_year IS NOT NULL
GROUP BY t.production_year
ORDER BY t.production_year;

-- 18. Find actors who acted in 'drama' but never in 'horror'
WITH drama_actors AS (
    SELECT DISTINCT ci.person_id
    FROM cast_info ci
    JOIN title t ON t.id = ci.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%drama%'
),
horror_actors AS (
    SELECT DISTINCT ci.person_id
    FROM cast_info ci
    JOIN title t ON t.id = ci.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%horror%'
)
SELECT n.name
FROM name n
WHERE n.id IN (SELECT person_id FROM drama_actors)
AND n.id NOT IN (SELECT person_id FROM horror_actors);

-- (Alternative without CTE — messy and heavy)
SELECT DISTINCT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE k.keyword ILIKE '%drama%'
  AND n.id NOT IN (
      SELECT ci2.person_id
      FROM cast_info ci2
      JOIN title t2 ON ci2.movie_id = t2.id
      JOIN movie_keyword mk2 ON mk2.movie_id = t2.id
      JOIN keyword k2 ON k2.id = mk2.keyword_id
      WHERE k2.keyword ILIKE '%horror%'
  );

-- 19. Find companies with the most video games produced
WITH video_games AS (
    SELECT t.id
    FROM title t
    WHERE kind_id = (
        SELECT id FROM kind_type WHERE kind ILIKE '%video game%'
    )
)
SELECT cn.name, COUNT(*) AS game_count
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
WHERE mc.movie_id IN (SELECT id FROM video_games) -- (Notice: Here we filter using a CTE by matching mc.movie_id with the id values from the video_games CTE, ensuring consistency with t.id in the original selection)
GROUP BY cn.name
ORDER BY game_count DESC
LIMIT 5;

-- (Alternative without CTE)
SELECT cn.name, COUNT(*) AS game_count
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
WHERE t.kind_id = (
    SELECT id FROM kind_type WHERE kind ILIKE '%video game%'
)
GROUP BY cn.name
ORDER BY game_count DESC
LIMIT 5;

-- 20. Find the year with the most movies produced
WITH yearly_movie_counts AS (
    SELECT production_year, COUNT(*) AS movie_count
    FROM title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
)
SELECT production_year, movie_count
FROM yearly_movie_counts
ORDER BY movie_count DESC
LIMIT 1;

-- (Alternative without CTE)
SELECT production_year, COUNT(*) AS movie_count
FROM title
WHERE production_year IS NOT NULL
GROUP BY production_year
ORDER BY movie_count DESC
LIMIT 1;
