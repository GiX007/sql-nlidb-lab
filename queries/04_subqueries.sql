-- Basic SUBQUERY structure:
-- SELECT [columns]
-- FROM (subquery) AS alias
-- WHERE [optional conditions]
-- OR
-- HAVING [aggregate condition using subquery]
-- Example: SELECT AVG(movie_count) 
--			FROM (SELECT production_year, COUNT(*) AS movie_count 
--  			  FROM title 
--				  GROUP BY production_year) AS yearly_counts;
-- (Subqueries allow us to prepare intermediate results inside another query — for example, first grouping data, then applying calculations like AVG or SUM on the grouped output.
--  We usually use subqueries when we need to first aggregate, filter, or transform data and then apply further operations on the prepared intermediate results.
--  The typical thinking is: build the inner query (prepare data), then use it in the outer query to complete the final task)

-- 1. Find the average number of movies produced per year
-- (First, group movies by production year and count how many were made each year by using a subquery, the inner SELECT, to prepare the grouped data.
--  Then, the outer SELECT calculates the average number of movies per year)
SELECT AVG(yearly_count) AS average_movies_per_year
FROM (
    SELECT production_year, COUNT(*) AS yearly_count
    FROM title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
) AS yearly_stats;

-- 2. Show the average number of actors per movie
SELECT AVG(actor_count) AS avg_actors_per_movie
FROM (
    SELECT ci.movie_id, COUNT(*) AS actor_count
    FROM cast_info ci
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY ci.movie_id
) AS movie_actor_stats;

-- 3. Retrieve the latest title for video games. Display the title and its production year (check kind_type for video games)
-- (We use a subquery twice because we are applying the "only video games" filter in two different parts: once to select video games, and once to find the latest year among video games only)
SELECT title, production_year
FROM title
WHERE kind_id = (	-- 1st condition: find all video games
    SELECT id		-- (keep the titles that are video games)
    FROM kind_type
    WHERE kind ILIKE '%video game%'
)
AND production_year = (			 -- 2nd condition: find the latest production year only for video games
    SELECT MAX(production_year) -- (pick the latest video game based on year)
    FROM title
    WHERE kind_id = (
        SELECT id
        FROM kind_type
        WHERE kind ILIKE '%video game%'
    )
);

-- 4. List years with more than average number of movie releases
-- (First, we need to find the average, a new subquery, and then based on the results to apply the 'outer' condition)
SELECT production_year, COUNT(*) AS movie_count	-- (3. select years with released movies above avg of 2)
FROM title
WHERE production_year IS NOT NULL
GROUP BY production_year
HAVING COUNT(*) > (				
    SELECT AVG(yearly_count)	-- (2. take the avg of results of 1 which is a number)
    FROM (
        SELECT production_year, COUNT(*) AS yearly_count	-- (1. find how many movies released in each year)
        FROM title
        WHERE production_year IS NOT NULL
        GROUP BY production_year
    ) AS yearly_stats
)
ORDER BY movie_count DESC;

-- 5. Find movies with more actors than the average number of actors per movie (same as 4, but with joins)
SELECT t.title, COUNT(*) AS actor_count	-- (3. pick the movies having more actors than the avg result number of 2. Notice we need to join all 3 tables here as we need to display titles from title table)
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%'
GROUP BY t.title
HAVING COUNT(*) > (
    SELECT AVG(actor_count)		-- (2. get the avg number of actors per movie)
    FROM (
        SELECT ci2.movie_id, COUNT(*) AS actor_count	-- (1. find how many actors each movie has. Notice that no need to join title table as movie_id is enough)
        FROM cast_info ci2								-- (Notice the aliases became ci2, rt2 instead of ci, rt we have above)
        JOIN role_type rt2 ON rt2.id = ci2.role_id
        WHERE rt2.role ILIKE '%actor%'
        GROUP BY ci2.movie_id
    ) AS movie_actor_stats
)
ORDER BY actor_count DESC;
-- (Notice that when a subquery appears inside FROM, it acts like a temporary table and we can select its columns to display, e.g. actor_count.
--  But when a subquery appears inside WHERE or HAVING, it is used only for filtering or comparing values — we cannot directly select columns from it)

-- (Golden Rule: Always create new aliases inside subqueries, even if they refer to the same tables as the main query.
--  Each query block must manage its own aliases independently for clarity, correctness, and future-proofing)

-- 6. List actors who have starred (supposing 1 < nr_order < 5) in more movies than Tom Hanks
-- (First, find how many starring roles Tom Hanks has, then find all actors who have more starring roles than him)
SELECT n.name, COUNT(*) AS starring_roles  -- (2. get the number of starring roles for each actor and display the actor's name that verify the condition 1)
FROM cast_info ci
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%' AND ci.nr_order BETWEEN 1 AND 4
GROUP BY n.name
HAVING COUNT(*) > (
    SELECT COUNT(*)  -- (1. find all starring roles of Tom Hanks - returns a number)
    FROM cast_info ci2
    JOIN name n2 ON n2.id = ci2.person_id
    JOIN role_type rt2 ON rt2.id = ci2.role_id
    WHERE rt2.role ILIKE '%actor%' AND n2.name = 'Tom Hanks' AND ci2.nr_order BETWEEN 1 AND 4
)
ORDER BY starring_roles DESC;

-- 7. List actors who have appeared in movies tagged 'horror'
-- (This version uses a subquery: we first find all person_ids of actors who acted in horror movies, then retrieve their names from the 'name' table using WHERE IN.
--  Note: We could also solve this without a subquery by using direct JOINs. 
--	The result would be the same, but using JOINs may improve performance in large datasets, because SQL engines can better optimize JOIN operations with indexes compared to IN + subquery)
SELECT DISTINCT n.name
FROM name n
WHERE n.id IN (
    SELECT ci.person_id
    FROM cast_info ci
	JOIN role_type rt ON rt.id = ci.role_id
    JOIN title t ON t.id = ci.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword ILIKE '%horror%' AND rt.role ILIKE '%actor%'
);

-- 8. List companies that produced movies after 2010 (same logic like 7)
SELECT DISTINCT cn.name
FROM company_name cn
WHERE cn.id IN (
    SELECT mc.company_id
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    WHERE t.production_year > 2010
);

-- 9. Find the longest movie title (based on title string length) using a subquery
SELECT title
FROM title
WHERE LENGTH(title) = (
    SELECT MAX(LENGTH(title))
    FROM title
);

-- (Query 9 without using a subquery)
SELECT title
FROM title
ORDER BY LENGTH(title) DESC
LIMIT 1;

-- 10. List actors who have only starred in 'comedy' movies
-- (We use NOT EXISTS to check that there is no movie for an actor that is tagged with something other than 'comedy'.
--  If such a non-comedy movie exists for an actor, the actor is excluded; otherwise, the actor is included in the results)
SELECT n.name
FROM name n
WHERE NOT EXISTS (
    SELECT 1  -- (SELECT 1 is used because in EXISTS subqueries, SQL only checks for the existence of rows — the actual value returned does not matter. SELECT *, or SELECT any constant would behave the same)
    FROM cast_info ci
	JOIN role_type rt ON rt.id = ci.role_id
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE ci.person_id = n.id AND k.keyword NOT ILIKE '%comedy%' AND rt.role ILIKE '%actor%'
);

-- 11. Find all movies where their directors have directed more than 15 movies
-- (We first find all directors who have directed more than 15 movies using a subquery, then retrieve the movies they directed)
SELECT DISTINCT t.title
FROM title t
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%director%'
  AND n.id IN (
      SELECT ci2.person_id
      FROM cast_info ci2
      JOIN role_type rt2 ON rt2.id = ci2.role_id
      WHERE rt2.role ILIKE '%director%'
      GROUP BY ci2.person_id
      HAVING COUNT(*) > 15
  )
ORDER BY t.title;

-- (Query 11 with another way)
SELECT DISTINCT t.title
FROM title t
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN (
    SELECT person_id
    FROM cast_info
    JOIN role_type rt2 ON rt2.id = cast_info.role_id
    WHERE rt2.role ILIKE '%director%'
    GROUP BY person_id
    HAVING COUNT(*) > 15
) AS prolific_directors ON n.id = prolific_directors.person_id
WHERE rt.role ILIKE '%director%'
ORDER BY t.title;

-- 12. Find movies that are the only production of their company
-- (We first find companies that have produced exactly one movie — using GROUP BY company_id and HAVING COUNT(*) = 1.
--  Then we select the movie IDs linked to those companies.
--  Finally, we select titles whose ID matches those movie IDs)
SELECT t.title
FROM title t
WHERE t.id IN (
    SELECT mc.movie_id
    FROM movie_companies mc
    WHERE mc.company_id IN (
        SELECT company_id
        FROM movie_companies
        GROUP BY company_id
        HAVING COUNT(*) = 1
    )
);

-- 13. Find keywords that are used in more movies than 'action'
-- (The subquery counts how many movies are tagged with the keyword 'action'.
--  In the main query, we GROUP BY each keyword and count how many movies it appears in.
--  Then, in the HAVING clause, we compare each keyword's count to the 'action' keyword count.
--  Only keywords with a higher movie count than 'action' are included in the results.)
SELECT k.keyword
FROM keyword k
JOIN movie_keyword mk ON k.id = mk.keyword_id
GROUP BY k.keyword
HAVING COUNT(*) > (
    SELECT COUNT(*)
    FROM keyword k2
    JOIN movie_keyword mk2 ON k2.id = mk2.keyword_id
    WHERE k2.keyword ILIKE '%action%'
);

-- 14. Find actors who acted both in movies and video games
-- (An alternative structure using two EXISTS subqueries to separately check the two conditions)
SELECT n.name
FROM name n
WHERE EXISTS (
    SELECT 1
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
	JOIN role_type rt ON rt.id = ci.role_id
    WHERE ci.person_id = n.id AND kt.kind ILIKE '%movie%' AND rt.role ILIKE '%actor%'
)
AND EXISTS (
    SELECT 1
    FROM cast_info ci2		-- (Notice we use ci2, t2, rt2, kt2 to avoid any conflicts, despite SQL works with similar to the above block's aliases)
    JOIN title t2 ON ci2.movie_id = t2.id
    JOIN kind_type kt2 ON t2.kind_id = kt2.id
	JOIN role_type rt2 ON rt2.id = ci2.role_id
    WHERE ci2.person_id = n.id AND kt2.kind ILIKE '%video game%' AND rt2.role ILIKE '%actor%'
);

-- (Query 14 without subqueries. Notice the difference in execution time)
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON ci.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
WHERE (kt.kind ILIKE '%movie%' OR kt.kind ILIKE '%video game%')
	AND rt.role ILIKE '%actor%'
GROUP BY n.name
HAVING COUNT(DISTINCT kt.kind) = 2;
-- (Golden Rule: When checking if two different conditions are separately true (e.g., acted in both movies and video games),
--  using multiple EXISTS subqueries is faster and more precise than using JOINs and GROUP BY.
--  EXISTS stops as soon as it finds the first matching row (early exit),
--  while JOINs build all possible combinations between tables, creating duplicates and inflating the result set,
--  which slows down execution and explains why we get more results)

-- 15. Find companies that have produced at least one 'comedy' and one 'drama'
-- (We use two EXISTS subqueries to ensure both genres are produced by the company)
SELECT DISTINCT cn.name
FROM company_name cn
WHERE EXISTS (
    SELECT 1
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE mc.company_id = cn.id AND k.keyword ILIKE '%comedy%'
)
AND EXISTS (
    SELECT 1
    FROM movie_companies mc2
    JOIN title t2 ON mc2.movie_id = t2.id
    JOIN movie_keyword mk2 ON mk2.movie_id = t2.id
    JOIN keyword k2 ON k2.id = mk2.keyword_id
    WHERE mc2.company_id = cn.id AND k2.keyword ILIKE '%drama%'
);

-- 16. Find the average number of distinct movie types per actor
-- (Notice that the subquery is placed in FROM, so it acts like a temporary table, allowing us to select and use its calculated columns like distinct_types in the outer query)
SELECT AVG(distinct_types) AS avg_movie_types_per_actor
FROM (
    SELECT n.id, COUNT(DISTINCT kt.kind) AS distinct_types	-- (COUNT(DISTINCT kt.kind) counts how many different types of movies (e.g., movie, tv series, video game) each actor has participated in)
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
	JOIN role_type rt ON rt.id = ci.role_id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
	WHERE rt.role ILIKE '%actor%'
    GROUP BY n.id
) AS actor_type_counts;

-- 17. Find actors who have never acted in a 'drama' movie
-- (The subquery checks if the actor participated in any movie tagged as 'drama' and played an acting role of actor.
--  If no such 'drama' movie exists for the actor (NOT EXISTS), the actor is included in the final result)
SELECT n.name
FROM name n
WHERE NOT EXISTS (
    SELECT 1
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE ci.person_id = n.id
      AND rt.role ILIKE '%actor%'
      AND k.keyword ILIKE '%drama%'
);

-- (Query 17 without subquery, using GROUP BY and HAVING.
--  We join actors with their movies and keywords, group by actor and use HAVING to exclude any actor who participated in movies tagged as 'drama')
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
WHERE rt.role ILIKE '%actor%'
GROUP BY n.name
HAVING SUM(CASE WHEN k.keyword ILIKE '%drama%' THEN 1 ELSE 0 END) = 0;
-- (Notice once again: This method avoids subqueries but can be much slower on large datasets,
--  because JOINs create a very large intermediate result, especially when actors are linked to many movies and multiple keywords.
--  GROUP BY + HAVING must scan and group the entire joined data, even if only a few actors match.
--  Using EXISTS in the original query is much faster, because it stops searching as soon as a single 'drama' movie is found for an actor)

-- 18. Find the movie title and the number of actors for each movie
-- (We use a subquery inside the SELECT clause to count actors per movie)
SELECT t.title,
  (SELECT COUNT(*)
   FROM cast_info ci
   JOIN role_type rt ON rt.id = ci.role_id
   WHERE ci.movie_id = t.id AND rt.role ILIKE '%actor%') AS actor_count
FROM title t
WHERE t.production_year IS NOT NULL
ORDER BY actor_count DESC NULLS LAST;

-- 19. Find actors whose first movie was before 1980
-- (We use a correlated subquery to find each actor's earliest movie year)
SELECT n.name
FROM name n
WHERE (
    SELECT MIN(t.production_year)
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type rt ON rt.id = ci.role_id
    WHERE ci.person_id = n.id AND rt.role ILIKE '%actor%' AND t.production_year IS NOT NULL
) < 1980;

-- 20. Find the average number of distinct genres an actor has worked in
-- (We first find the number of distinct genres for each actor and then average it)
SELECT AVG(distinct_genres) AS avg_genres_per_actor
FROM (
    SELECT n.id, COUNT(DISTINCT k.keyword) AS distinct_genres
    FROM name n
    JOIN cast_info ci ON n.id = ci.person_id
    JOIN role_type rt ON rt.id = ci.role_id
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE rt.role ILIKE '%actor%'
    GROUP BY n.id
) AS actor_genre_stats;
