-- Basic AGGREGATION query structure:
-- SELECT [column(s) to group by/to present], [aggregate functions like COUNT(), AVG(), MAX(), MIN() based on the groups]
-- FROM [table or joined tables]
-- WHERE [optional filtering before aggregation — applies to individual rows]
-- GROUP BY [column(s) you want to group results by]
-- HAVING [optional filtering after aggregation — applies to the aggregated values, not to individual rows]
-- Example: SELECT production_year, COUNT(*) 
--	    FROM title
--          WHERE production_year IS NOT NULL
--          GROUP BY production_year
--          HAVING COUNT(*) > 50
--          ORDER BY production_year;
-- (Aggregation groups rows together based on one or more columns and computes summary values for each group.
--  When constructing aggregation queries, the usual thinking is:
--  first JOIN tables if needed, then GROUP BY the right columns, and finally apply aggregation functions like COUNT() or AVG() on the grouped results.
--  HAVING is used to filter based on aggregate results like COUNT(), AVG(), etc., after GROUP BY is applied)

-- 1. Count the total number of movies in the database
SELECT COUNT(*) AS total_movies FROM title;

-- 2. Count how many movies were released each year
SELECT production_year, COUNT(*) AS movie_count
FROM title
WHERE production_year IS NOT NULL
GROUP BY production_year
ORDER BY production_year DESC;

-- 3. Find the earliest and latest production year
SELECT MIN(production_year) AS earliest_year, MAX(production_year) AS latest_year
FROM title
WHERE production_year IS NOT NULL;

-- 4. Count how many titles are of each kind (movie, video game, tv series, etc...)
-- (First, we need to join the 'title' and 'kind_type' tables to bring together titles and their kinds.
--  At first, we might think about simply selecting the kind and the title, like:
--  SELECT kt.kind, t.title FROM title t JOIN kind_type kt ON kt.id = t.kind_id GROUP BY kt.kind, t.title;
--  But since we want to count how many titles are under each kind (not list them all individually), we need to group only by 'kt.kind' and apply COUNT(*) to the joined output of 'title' and 'kind_type'.
--  The COUNT aggregates the number of titles for each kind)
SELECT kt.kind, COUNT(*) AS count
FROM title t
JOIN kind_type kt ON kt.id = t.kind_id
GROUP BY kt.kind
ORDER BY count DESC;

-- 5. Count the number of actors and actresses in the database
SELECT rt.role, COUNT (*) AS count
FROM cast_info ci
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role IN ('actor', 'actress') 
GROUP BY rt.role;

-- 6. Count how many movies each actor appeared in (limit your results to 10)
SELECT n.name, COUNT (*) AS movie_count
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%'
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 10;

-- 7. Find the average runtime of movies in minutes (assuming info_type = 'runtimes')
-- (We first filter to rows where info_type is 'runtimes' — these contain movie durations as text.
--  Since the 'mi.info' column is of type text, we use CAST to convert it to INTEGER so AVG can work with it numerically.
--  We also use a regular expression filter (~ '^[0-9]+$') to make sure the info contains only digits — no text like 'N/A' or ranges like '90-120')
SELECT AVG(CAST(mi.info AS INTEGER)) AS avg_runtime
FROM movie_info mi
JOIN info_type it ON mi.info_type_id = it.id
WHERE it.info ILIKE 'runtimes'
  AND mi.info ~ '^[0-9]+$';

-- 8. Count how many different character names appear in the database
SELECT COUNT(DISTINCT name) AS unique_character_names
FROM char_name;

-- 9. Count how many movies are tagged with each keyword / Count how many movies exist per genre-like (e.g. 'horror') keyword (top 10) 
SELECT k.keyword, COUNT (*) AS movie_count
FROM keyword k
JOIN movie_keyword mk ON mk.keyword_id = k.id
-- JOIN title t ON mk.movie_id = t.id -- (Uncomment and notice the total time of execution!)
GROUP BY k.keyword
ORDER BY movie_count DESC
LIMIT 10;

-- 10. Count how many movies each company has produced
-- (Notice that we don’t need to join the 'title' table here, since we're just counting movie IDs from 'movie_companies'.
--  This also happened in some above cases - queries 7, 8, 10  — if we don’t need movie details like the title or year, we can skip joining the 'title' table, which is important for the speed of execution especially on large datasets)
SELECT cn.name, COUNT(*) AS movie_count
FROM company_name cn
JOIN movie_companies mc ON mc.company_id = cn.id
GROUP BY cn.name
ORDER BY movie_count DESC;

-- 11. Count how many movies each of top 10 actors has acted in with a known production year
SELECT n.name, COUNT (*) as appearances
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON t.id = ci.movie_id
WHERE t.production_year IS NOT NULL AND rt.role ILIKE '%actor%'
GROUP BY n.name
ORDER BY appearances DESC
LIMIT 10; 

-- 12. Find the year with the most movie releases
SELECT production_year, COUNT (*) AS count
FROM title
WHERE production_year IS NOT NULL
GROUP BY production_year
ORDER BY count DESC
LIMIT 1;

-- 13. Count how many titles have NULL as production year
SELECT COUNT (*) AS missing_production_year
FROM title
WHERE production_year IS NULL;

-- 14. Count how many drama movies each company has produced
SELECT cn.name AS company,COUNT (*) AS drama_movies
FROM company_name cn
JOIN movie_companies mc ON mc.company_id = cn.id
JOIN title t ON t.id = mc.movie_id -- (Notice that in this case, we can't avoid these joins)
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%drama%'
GROUP BY cn.name
ORDER BY drama_movies DESC;

-- 15. Count how many actors have played more than 5 movies
SELECT n.name, COUNT (*) AS total_movies
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%'
GROUP BY n.name
HAVING COUNT(*) > 5 
ORDER BY total_movies DESC;
-- (Notice: HAVING must use the real aggregate function like COUNT(*), not the alias 'total_movies', because aliases are created later in SELECT.
--  Quick reminder of clause order: WHERE filters before grouping, GROUP BY groups rows, HAVING filters groups after grouping, and SELECT runs after HAVING to apply aliases)

-- 16. Find movies released by Disney between 2012 and 2015 having at least 2 producers. Display the movies and the number of producers per movie (check kind_type and role_type tables)
SELECT t.title, COUNT (*) AS producers
FROM title t
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
JOIN kind_type kt ON kt.id = t.kind_id
JOIN cast_info ci ON ci.movie_id = t.id
JOIN role_type rt ON rt.id = ci.role_id
WHERE cn.name ILIKE '%Disney%' 
	AND t.production_year BETWEEN 2012 AND 2015 
	AND kt.kind ILIKE '%Movie%' 
	AND rt.role ILIKE '%Producer%'
GROUP BY t.title
HAVING COUNT (*) >= 2
ORDER BY producers DESC;

-- 17. List actors who have appeared first in Gladiator movie (nr_order = 1 or nr_order = 2)
SELECT DISTINCT n.name AS performer, ci.nr_order AS numeric_order_of_appearance
FROM cast_info ci 
JOIN title t ON t.id = ci.movie_id 
JOIN name n ON n.id = ci.person_id
WHERE t.title ILIKE '%gladiator%' 
	AND t.production_year = 2000 
	AND (ci.nr_order = 1 OR ci.nr_order = 2)
ORDER BY ci.nr_order;

-- 18. List years where more than 1000 movies were released and show the average title length for each year
SELECT production_year, COUNT(*) AS movie_count, AVG(LENGTH(title)) AS avg_title_length -- AVG(LENGTH(title)) averages the number of characters in movie titles
FROM title
WHERE production_year IS NOT NULL
GROUP BY production_year
HAVING COUNT(*) > 1000
ORDER BY movie_count DESC;

-- 19. Find the actor who has starred in the most action movies the last 25 years
SELECT n.name AS actor, COUNT(*) AS action_movie_count
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON t.id = ci.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE rt.role ILIKE '%actor%' 
	AND k.keyword ILIKE '%action%'
	AND t.production_year = 2000
GROUP BY n.name
ORDER BY action_movie_count DESC
LIMIT 1;

-- 20. Show the top 10 companies with the highest average number of movies produced per year
-- (COUNT(*) counts the total number of movies produced by each company.
--  COUNT(DISTINCT t.production_year) counts how many different years the company has released movies.
--  Multiplying by 1.0 ensures decimal division (otherwise SQL would do integer division and truncate the result).
--  This gives the average number of movies per year for each company)
SELECT c.name AS company, 
       ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT t.production_year), 2) AS avg_movies_per_year
FROM company_name c
JOIN movie_companies mc ON c.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY c.name
ORDER BY avg_movies_per_year DESC
LIMIT 10;
