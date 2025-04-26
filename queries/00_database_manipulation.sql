-- Basic SQL operations for creating schemas, tables, inserting, updating, deleting records, exporting results, and analyzing queries.

-- Short Introduction:
-- A schema in SQL is a logical container for organizing database objects such as tables, views, functions, etc.
-- A schema is comprised of multiple tables, and tables are typically connected to each other through primary keys (unique identifiers) and foreign keys (references to other tables).
-- In addition to defining structure, we manipulate the data itself using three main types of operations:
-- - INSERT: add new records (rows) into a table
-- - UPDATE: modify existing records
-- - DELETE: remove records from a table
-- In this file, we also demonstrate exporting query results to files (using COPY) and analyzing query performance (using EXPLAIN)

-- 1. Create a new schema
CREATE SCHEMA IF NOT EXISTS moviedb;

-- 2. Create a new table under the new schema
CREATE TABLE moviedb.movies (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    production_year INT,
    genre VARCHAR(100)
);

-- 3. Insert a new movie into moviedb.movies
INSERT INTO moviedb.movies (title, production_year, genre)
VALUES ('Inception', 2010, 'Science Fiction');

-- 4. Insert multiple movies at once
INSERT INTO moviedb.movies (title, production_year, genre)
VALUES 
('The Dark Knight', 2008, 'Action'),
('Pulp Fiction', 1994, 'Crime'),
('Interstellar', 2014, 'Science Fiction');

-- 5. Update the title of a movie
UPDATE moviedb.movies
SET title = 'Inception (2010)'
WHERE title = 'Inception';

-- 6. Update the genre of a movie
UPDATE moviedb.movies
SET genre = 'Crime, Drama'
WHERE title = 'The Godfather';

-- 7. Delete a movie by title
DELETE FROM moviedb.movies
WHERE title = 'Pulp Fiction';

-- 8. Delete movies released before 1980
DELETE FROM moviedb.movies
WHERE production_year < 1980;

-- 9. Explain a simple query (to see the query plan)
EXPLAIN SELECT * FROM moviedb.movies WHERE production_year > 2000;

-- 10. Explain Analyze (for actual execution time)
EXPLAIN ANALYZE SELECT * FROM moviedb.movies WHERE production_year > 2000;

-- 11. Export query results to a CSV file
COPY (SELECT * FROM moviedb.movies)
TO 'C:\Users\giorg\Downloads\movies.csv' WITH CSV HEADER;
-- (Note: Make sure PostgreSQL server has write permissions!)

-- 12. Export only titles of recent movies to CSV
COPY (SELECT title FROM moviedb.movies WHERE production_year > 2010)
TO 'C:\Users\giorg\Downloads\recent_movies.csv' WITH CSV HEADER;

-- 13. Insert into movies table using SELECT from another table (hypothetical example)
INSERT INTO moviedb.movies (title, production_year, genre)
SELECT title, production_year, 'Unknown'
FROM title
WHERE production_year > 2020;

-- 14. Insert into another table from query result (hypothetical)
CREATE TABLE IF NOT EXISTS moviedb.recent_movies AS
SELECT *
FROM moviedb.movies
WHERE production_year > 2015;

-- 15. Insert a new movie and immediately retrieve its generated ID (using RETURNING)
-- (Notice: RETURNING allows us to immediately retrieve the generated ID or other fields after an INSERT without running a separate SELECT)
INSERT INTO moviedb.movies (title, production_year, genre)
VALUES ('Dune', 2021, 'Science Fiction')
RETURNING id, title;
