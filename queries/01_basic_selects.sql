-- Basic SELECT query structure:
-- SELECT [what you want to show — column(s)]
-- FROM [table to query]
-- WHERE [optional condition to filter rows based on a column in that table]
-- Example: SELECT title FROM title WHERE production_year > 2015;

-- 1. Select all columns for all movies (Simple use of * to view entire rows — good for debugging or exploration)
SELECT * FROM title;

-- 2. Retrieve all movie titles
SELECT title FROM title;

-- 3. Get all unique production years 
SELECT DISTINCT production_year FROM title; -- (DISTINCT used to avoid duplicate rows)

-- 4. List all unique info types recorded in movie_info
SELECT DISTINCT info_type_id FROM movie_info;

-- 5. List all movies released after 2015
SELECT title, production_year
FROM title
WHERE production_year > 2015;

-- 6. Find movies with a title starting with 'The'
SELECT title
FROM title
WHERE title ILIKE 'The%';

-- 7. Find all companies whose name contains the word 'Disney'
(ILIKE is case-insensitive, while LIKE is case-sensitive — e.g., 'disney' matches 'Disney' with ILIKE but not with LIKE)
SELECT name
FROM company_name
WHERE name ILIKE '%Disney%';

-- 8. Count how many movies were released each year (Notice there are many movies with an unknown-NULL production_year and COUNT(*) counts all rows, while COUNT(column) counts only rows where the column is NOT NULL)
SELECT production_year, COUNT(*) AS total_movies
FROM title
-- WHERE production_year IS NOT NULL
GROUP BY production_year
ORDER BY production_year;

-- 9. Get the top 10 most recent movies
SELECT title, production_year
FROM title
WHERE production_year IS NOT NULL
ORDER BY production_year DESC
LIMIT 10;

-- 10. Show titles with missing production year
SELECT title
FROM title
WHERE production_year IS NULL;

-- 11. Find all episodes (non-null episode_nr field)
SELECT title, episode_nr
FROM title
WHERE episode_nr IS NOT NULL;

-- 12. Get movies released between 2000 and 2010
SELECT title, production_year
FROM title
WHERE production_year BETWEEN 2000 AND 2010;

-- 13. Get the 5 oldest movies with known production year
SELECT title, production_year
FROM title
WHERE production_year IS NOT NULL
ORDER BY production_year ASC
LIMIT 5;

-- 14. Get the first 10 movie titles in alphabetical order
SELECT title
FROM title
ORDER BY title ASC
LIMIT 10;

-- 15. Count total number of movies in the database (Remember COUNT(*) is equivalent to COUNT(title) in our case as we have no NULL values in title column)
SELECT COUNT(title) AS total_movies FROM title;
