-- Basic JOIN query structure:
-- SELECT [what you want to show — columns from any of the joined tables]
-- FROM [main table]
-- JOIN [other table] ON [shared key]
-- WHERE [optional condition to filter rows — can reference columns from any joined table]
-- Example: SELECT t.title, c.name FROM title t
--          JOIN movie_companies mc ON t.id = mc.movie_id
--          JOIN company_name c ON c.id = mc.company_id
--          WHERE c.name ILIKE '%Disney%';
-- (JOINs typically match a foreign key in one table to a primary key in another)

-- 1. List all movies and their types (e.g. movie, video game)
SELECT t.title, k.kind
FROM title t
JOIN kind_type k ON t.kind_id = k.id;

-- 2. Find all video games with a known production year, and list them in descending order by year
SELECT t.title, t.production_year
FROM title t
JOIN kind_type k ON t.kind_id = k.id
WHERE k.kind ILIKE '%video game%' AND t.production_year IS NOT NULL
ORDER BY t.production_year DESC

-- 3. Find all movies and their production companies
SELECT t.title, c.name AS company
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name c ON c.id = mc.company_id;

-- 4. List each movie and all associated keywords
SELECT t.title, k.keyword
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id;

-- 5. Find movies that are part of a series (self-join)
-- (The 'title' table contains a 'title' attribute that can represent either an episode or a series, depending on the row.
--  An episode has a value in 'episode_of_id' that points to the 'id' of its parent series.
--  This self-join matches the episode row (alias 'e') to its series row (alias 's') by joining e.episode_of_id = s.id.
--  For example, if a row for 'Episode 1' has e.episode_of_id = 100, we join to the row where s.id = 100, and retrieve s.title, which is the name of the series the episode belongs to.
--  In general, when a table includes a foreign key that references its own primary key, we can self-join the table by matching the foreign key to the primary key.
--  Note: this only works when the foreign key truly points to another row in the same table, for example, we cannot self-join title.id with kind_id, because kind_id references to the different table of kind_type)
SELECT e.title AS episode_title, s.title AS series_title
FROM title e
JOIN title s ON e.episode_of_id = s.id;

-- 6. Show all titles with their rating or runtime information
-- (If you're unsure where values like ratings or runtimes are stored, first look at the database structure or try exploring with queries like SELECT * FROM any table to investigate what each table contains)
SELECT t.title, mi.info, it.info AS info_type
FROM title t
JOIN movie_info mi ON t.id = mi.movie_id
JOIN info_type it ON mi.info_type_id = it.id
WHERE it.info ILIKE '%rating%' OR it.info ILIKE '%runtime%';
-- ('mi.info' contains the actual value, e.g. 'PG-13' for rating or '90' for runtime,
--  and 'it.info' tells us what kind of value it is either 'rating' or 'runtimes')

-- 7. List all movies and their actors
SELECT t.title, n.name 
FROM title t
JOIN cast_info ci on ci.movie_id = t.id
JOIN name n on n.id = ci.person_id
JOIN role_type rt on rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%'
ORDER BY t.title;

-- 8. List all movies where the actor is Denzel Washington along with their production year
SELECT DISTINCT t.title, t.production_year, n.name -- (Added DISTINCT after receiving multiple same rows)
FROM title t
JOIN cast_info ci on ci.movie_id = t.id
JOIN name n on n.id = ci.person_id
JOIN role_type rt on rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%' AND (n.name ILIKE '%Denzel%' AND n.name ILIKE '%Washington%')
ORDER BY t.production_year; -- (ascending order is the default for ORDER BY)

-- 9. List all actors and actresses of the movie 'Gladiator' (2000) with their characters names
SELECT DISTINCT n.name AS performer_name, cn.name AS character_name
FROM title t -- (Start from the movie, then join to cast_info, name, role_type, and char_name to build the full picture)
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN char_name cn ON cn.id = ci.person_role_id 
WHERE t.title ILIKE 'Gladiator'
  AND t.production_year = 2000
  AND (rt.role ILIKE '%actor%' OR rt.role ILIKE '%actress%')
  AND cn.name NOT ILIKE '%himself%' AND cn.name NOT ILIKE '%herself%'; -- (Try without it to get the difference)

-- 10. List all people who worked on movies with 'Matrix' in the title along with their role
SELECT DISTINCT n.name, rt.role
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN title t ON ci.movie_id = t.id
WHERE t.title ILIKE '%Matrix%'
ORDER BY rt.role;

-- 11. LEFT JOIN: Show all movies with or without a company
-- (LEFT JOIN keeps all rows from the left table — here, all movies — and shows NULL when there's no matching company.
--  The same concept applies to RIGHT JOIN — it keeps all rows from the right table and fills in NULLs on the left side when there's no match.
--  Also note that if you just write JOIN without specifying LEFT or RIGHT, it's treated as an INNER JOIN, which only returns rows where there is a match on both sides of the join condition)
SELECT t.title, cn.name AS company
FROM title t
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id;
-- ORDER BY cn.name DESC; -- (Uncomment and drop ';' from above to see titles without a company with NULL values, or run: SELECT * FROM title t WHERE t.id NOT IN (SELECT movie_id FROM movie_companies);)
-- (Try without LEFT to get the difference: titles without a company will disappear - you get less results)

-- 12. Show all actors and their roles in movies
SELECT DISTINCT t.title, n.name, rt.role
FROM title t
JOIN cast_info ci ON ci.movie_id = t.id
JOIN role_type rt ON rt.id = ci.role_id
JOIN name n ON n.id = ci.person_id
WHERE rt.role IN ('actor', 'actress'); -- (Similar to rt.role = 'actor' OR rt.role = 'actress')

-- 13. Find all Disney movies and their production year
SELECT DISTINCT t.title, cn.name, t.production_year
FROM title t
JOIN movie_companies mc ON mc.movie_id = t.id 
JOIN company_name cn ON cn.id = mc.company_id
WHERE cn.name ILIKE '%Disney%'
ORDER BY t.production_year;

-- 14. Find the movies and actors released by Disney 
SELECT DISTINCT t.title, n.name AS actors
FROM title t
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON ci.role_id = rt.id
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
WHERE rt.role ILIKE '%actor%' AND cn.name ILIKE '%Disney%';

-- 15. Find all Pixar movies after 2000 and their directors
SELECT t.title, n.name, t.production_year AS director
FROM title t
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
WHERE rt.role ILIKE '%Director%' AND cn.name ILIKE '%Pixar%' AND t.production_year > 2000
ORDER BY t.production_year;

-- 16. Find actors who worked in movies with 'Avengers' in the title
SELECT DISTINCT n.name AS actors
FROM title t  -- (Could also start with FROM name n instead, with corresponding joins —
              --  you'd join to cast_info on n.id = ci.person_id, then to title via ci.movie_id = t.id.
              --  In SQL, the order in which you join tables doesn't affect the result as long as all relationships are correctly defined)
JOIN cast_info ci ON ci.movie_id = t.id
JOIN name n ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%' AND t.title ILIKE '%Avengers%';

-- 17. Show movie titles that are tagged with 'drama' or 'comedy' keywords (film genres), along with their production company names
SELECT t.title, k.keyword AS genre, cn.name AS company
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
WHERE k.keyword ILIKE '%drama%' OR k.keyword ILIKE '%comedy%';

-- 18. Show 'comedy' movies with their actors, roles, and production company
SELECT t.title, k.keyword AS film_genres, n.name AS actor, rt.role AS role, cn.name AS production_company
FROM title t
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
JOIN cast_info ci ON ci.movie_id = t.id
JOIN role_type rt ON rt.id = ci.role_id
JOIN name n ON n.id = ci.person_id
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
WHERE k.keyword ILIKe '%comedy%' AND rt.role ILIKE '%Actor%'
ORDER BY t.title;

-- 19. Show the 5 most recent 'action' movies with their production company
SELECT t.title, t.production_year, cn.name AS production_company
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON k.id = mk.keyword_id
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
WHERE k.keyword ILIKE '%action%' AND t.production_year IS NOT NULL
ORDER BY t.production_year DESC
LIMIT 5;

-- 20. Show the most recent movie produced by each company
-- (Uses DISTINCT ON — a PostgreSQL feature — to select one row per company based on latest year)
SELECT DISTINCT ON (cn.name) cn.name AS company, t.title, t.production_year
FROM company_name cn  -- (Notice here we start from the company_name table and move toward title,
                      --  in contrast to most above queries which begin with title and move toward company or cast_info)
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
WHERE t.production_year IS NOT NULL
ORDER BY cn.name, t.production_year DESC;
