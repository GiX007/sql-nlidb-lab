-- Window Functions in SQL — Full Tutorial with Examples

-- Short Introduction:
-- Window functions perform calculations across sets of rows that are somehow related to the current row.
-- Unlike regular aggregates (COUNT, SUM, AVG), window functions do not collapse results — they keep row-by-row details.
-- Window functions are extremely powerful for analytics, ranking, cumulative totals, moving averages, etc.

-- Why use Window Functions?
-- - Rank rows (ROW_NUMBER, RANK, DENSE_RANK)
-- - Calculate cumulative totals (SUM() OVER)
-- - Look ahead / behind (LEAD, LAG)
-- - Partition and order data for advanced reporting

-- Basic Syntax Example:
-- SELECT title, production_year, ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS movie_rank
-- FROM title;
-- (This gives each movie a rank within its production year!)

-- 1. Assign row numbers to movies ordered by production year
SELECT title, production_year,
       ROW_NUMBER() OVER (ORDER BY production_year) AS row_num
FROM title;
-- (ROW_NUMBER() assigns a unique number to each row based on the production year ordering.
--  This is useful for tasks like pagination, selecting top-N per group, or uniquely ordering results for reporting.)

-- 2. Rank actors by number of movies
SELECT n.name, COUNT(*) AS movie_count,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS actor_rank
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
GROUP BY n.name;
-- (RANK() assigns the same rank to actors with identical movie counts — gaps appear if ties exist. For example: 
--  If two actors each have 50 movies, they both get rank 1, and the next actor gets rank 3, not 2. Use DENSE_RANK() if you want no gaps instead.)

-- 3. Find the earliest movie per company
SELECT cn.name AS company_name, t.title, t.production_year,
       ROW_NUMBER() OVER (PARTITION BY cn.name ORDER BY t.production_year ASC) AS movie_order
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id;
-- (PARTITION BY company splits the dataset into separate groups for each company name, then ROW_NUMBER() assigns unique numbers ordered by production year inside each group.
--  Unlike Query 1 where numbering was global, here numbering resets per company after each partition.
--  This helps us easily find the earliest (or second, third, etc.) movie produced by each company separately.)

-- 4. Show next movie title for each actor (LEAD)
SELECT n.name AS actor,
       t.title AS current_movie,
       t.production_year,
       LEAD(t.title) OVER (PARTITION BY n.name ORDER BY t.production_year) AS next_movie
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id;
-- (LEAD() looks at the next movie title for each actor based on the chronological order of their movies.
--  Partitioning by actor name groups all their movies together, and ordering by production year ensures we move to the next movie in time for that actor individually.
--  This helps identify an actor's upcoming projects relative to each movie.
--  If there is no next movie for an actor (at the latest one), LEAD() returns NULL.)

-- 5. Show previous movie title for each actor (LAG)
SELECT n.name AS actor,
       t.title AS current_movie,
       t.production_year,
       LAG(t.title) OVER (PARTITION BY n.name ORDER BY t.production_year) AS previous_movie
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id;

-- (LAG() fetches the previous movie title for each actor based on the chronological order of their movies.
--  Partitioning by actor name groups all their movies together, and ordering by production year ensures we move to the previous movie in time for that actor individually.
--  This helps identify an actor's prior project relative to each movie.
--  If there is no previous movie for an actor (at their first movie), LAG() returns NULL.)

-- 6. Calculate cumulative number of movies per company
SELECT cn.name, t.production_year,
       COUNT(*) OVER (PARTITION BY cn.name ORDER BY t.production_year) AS cumulative_movies
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id;
-- (Running total of movies produced per company over the years.)

-- 7. Calculate cumulative actors count by production year
SELECT t.production_year, n.name,
       COUNT(*) OVER (PARTITION BY t.production_year) AS actors_in_year
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN name n ON n.id = ci.person_id;
-- (How many actors participated each production year - this takes a while.)

-- 8. Percent rank of movies based on production year
SELECT title, production_year,
       PERCENT_RANK() OVER (ORDER BY production_year) AS perc_rank
FROM title;
-- (PERCENT_RANK() shows the relative position of each row within the result set as a percentage between 0 and 1.
--  It tells us the proportion of rows ranked below the current row.
--  Formula: (rank of current row - 1) / (total rows - 1).
--  The first row always has 0, the last row has 1, and intermediate rows get fractional values based on their order.
--  We use PERCENT_RANK() when we want to compare a row's standing relative to the entire dataset — 
--  for example, to find the top 10% newest movies, the bottom 20% oldest movies, or to normalize rankings across datasets of different sizes.)

-- 9. Assign movies into 4 groups (quartiles) by production year
SELECT title, production_year,
       NTILE(4) OVER (ORDER BY production_year) AS quartile
FROM title;
-- (NTILE(4) splits the dataset into 4 approximately equal parts.)

-- 10. Get the maximum production year across all movies
SELECT title, production_year,
       MAX(production_year) OVER () AS latest_year
FROM title;
-- (MAX() OVER () calculates the maximum production year across the entire title table, but keeps the original movie rows visible without collapsing them.
--  Every row gets the same latest production year as a reference. This allows us to easily compare each movie's production year against the latest movie, 
--  for tasks like calculating movie age, filtering movies released close to the newest ones, or building dynamic relative queries without using subqueries.)

-- 11. Show cumulative count of movies produced after 2000
SELECT title, production_year,
       COUNT(*) OVER (ORDER BY production_year) AS running_movie_count
FROM title
WHERE production_year > 2000;
-- (Running count of how many movies after 2000.)

-- 12. Find difference in production year between each movie and the previous one per company
SELECT cn.name AS company_name,
       t.title AS current_movie,
       t.production_year,
       t.production_year - LAG(t.production_year) OVER (PARTITION BY cn.name ORDER BY t.production_year) AS year_difference
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id;
-- (Shows how many years passed between two consecutive movie productions for each company. For the first company's movie the difference is null.
--  Partitioning by company ensures that year differences are calculated only within the same company, helping us analyze how frequently each company releases movies over time.
--  Without partitioning, we would just compare random movies across all companies, which is not meaningful.)

-- 13. Rank companies by number of movies produced each year
SELECT cn.name, t.production_year,
       COUNT(*) AS movie_count,
       RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(*) DESC) AS rank_in_year
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
GROUP BY cn.name, t.production_year;
-- (RANK() OVER (PARTITION BY production_year ORDER BY movie count DESC): assigns a ranking to companies within each production year, based on how many movies they produced.
--  Companies that tie on movie count receive the same rank, and gaps appear in numbering.
--  Example from results:
--   - In 1894, "Edison Manufacturing Company" produced 174 movies (rank 1).
--   - "Ralf & Gammon Company" produced 10 movies (rank 2).
--   - "Kino Video" produced 5 movies (rank 3).
--  Why are interested in using this to see which companies were the top producers each year or to analyze dominance, historical trends, and industry leaders across years.)

-- 14. Find actor's movie gaps (year difference between consecutive movies)
SELECT n.name, t.title, t.production_year,
       production_year - LAG(production_year) OVER (PARTITION BY n.name ORDER BY production_year) AS gap_years
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id;
-- (Useful to find long breaks in actors' careers!)

-- 15. Find top 3 newest movies per company
SELECT cn.name AS company_name, ranked_movies.title, ranked_movies.production_year
FROM (
    SELECT t.id, t.title, t.production_year, mc.company_id,
           ROW_NUMBER() OVER (PARTITION BY mc.company_id ORDER BY t.production_year DESC) AS rn
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
) ranked_movies
JOIN company_name cn ON cn.id = ranked_movies.company_id
WHERE rn <= 3;
-- (This query first ranks movies per company based on production year in descending order, so the newest movies get lower ranks.
--  ROW_NUMBER() assigns 1 to the newest movie, 2 to the second newest, etc.
--  Then we filter (WHERE rn <= 3) to keep only the top 3 most recent movies for each company.
--  Why we may want do this:
--  - Useful to analyze recent productions of each company.
--  - Helps highlight the latest trends or focus periods for studios without manually grouping and filtering.
--  - Instead of complex GROUP BY + subqueries, ROW_NUMBER() simplifies the logic to one clean pass!)

-- ============================================================================
-- 🚀 Window Functions = advanced analytics without losing row-by-row visibility!

-- 🛡️ Remember:
--  - Aggregate normally collapses rows.
--  - Window functions keep the rows and add calculations!

-- 🧠 Ultra-Condensed Window Functions Checklist:

-- 1️. If you want aggregation without collapsing rows → Use Window Functions (SUM() OVER, COUNT() OVER).
-- 2️. If you want ranking → Use ROW_NUMBER(), RANK(), DENSE_RANK().
-- 3️. If you need running totals, moving averages → Use cumulative functions with OVER(ORDER BY ...).
-- 4️. If you want previous or next row → Use LAG() and LEAD().
-- 5️. Always use PARTITION BY when you need results split per group.

-- Always think: "Do I need per-row calculations across a group?" → Then Window Functions are your tool!
-- ============================================================================
