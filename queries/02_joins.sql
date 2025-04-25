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

-- 1. List all movies and their types (e.g., movie, video game)
-- SELECT t.title, k.kind
-- FROM title t
-- JOIN kind_type k ON t.kind_id = k.id;

-- 2. Find all video games with a known production year, and list them in descending order by year
-- SELECT t.title, t.production_year
-- FROM title t
-- JOIN kind_type k ON t.kind_id = k.id
-- WHERE k.kind ILIKE '%video game%' AND t.production_year IS NOT NULL
-- ORDER BY t.production_year DESC

-- 3. Find all movies and their production companies
-- SELECT t.title, c.name AS company
-- FROM title t
-- JOIN movie_companies mc ON t.id = mc.movie_id
-- JOIN company_name c ON c.id = mc.company_id;

-- 4. List each movie and all associated keywords
-- SELECT t.title, k.keyword
-- FROM title t
-- JOIN movie_keyword mk ON t.id = mk.movie_id
-- JOIN keyword k ON mk.keyword_id = k.id;

-- 5. Find movies that are part of a series (self-join)
-- (The 'title' table contains a 'title' attribute that can represent either an episode or a series, depending on the row.
--  An episode has a value in 'episode_of_id' that points to the 'id' of its parent series.
--  This self-join matches the episode row (alias 'e') to its series row (alias 's') by joining e.episode_of_id = s.id.
--  For example, if a row for 'Episode 1' has e.episode_of_id = 100, we join to the row where s.id = 100,
--  and retrieve s.title, which is the name of the series the episode belongs to.
--  In general, when a table includes a foreign key that references its own primary key,
--  we can self-join the table by matching the foreign key to the primary key.
--  Note: this only works when the foreign key truly points to another row in the same table —
--  for example, we cannot self-join title.id with kind_id, because kind_id references to the different table of kind_type)
-- SELECT e.title AS episode_title, s.title AS series_title
-- FROM title e
-- JOIN title s ON e.episode_of_id = s.id;

-- 6. Show all titles with their rating or runtime information
-- SELECT t.title, mi.info, it.info AS info_type
-- FROM title t
-- JOIN movie_info mi ON t.id = mi.movie_id
-- JOIN info_type it ON mi.info_type_id = it.id
-- WHERE it.info ILIKE '%rating%' OR it.info ILIKE '%runtime%';
-- ('mi.info' contains the actual value, e.g. 'PG-13' for rating or '90' for runtime,
--  and 'it.info' tells us what kind of value it is either 'rating' or 'runtimes')

-- 7. List all movies and their actors
-- SELECT t.title, n.name 
-- FROM title t
-- JOIN cast_info ci on ci.movie_id = t.id
-- JOIN name n on n.id = ci.person_id
-- JOIN role_type rt on rt.id = ci.role_id
-- WHERE rt.role ILIKE '%Actor%'
-- ORDER BY t.title;

-- 8. List all movies where the actor is Denzel Washington along with their production year
SELECT DISTINCT t.title, t.production_year, n.name -- (Added DISTINCT after receiving multiple same rows)
FROM title t
JOIN cast_info ci on ci.movie_id = t.id
JOIN name n on n.id = ci.person_id
JOIN role_type rt on rt.id = ci.role_id
WHERE rt.role ILIKE '%Actor%' AND (n.name ILIKE '%Denzel%' AND n.name ILIKE '%Washington%')
ORDER BY t.production_year; -- (ascending order is the default for ORDER BY)

-- 9. List all actors of the movie Gladiator

