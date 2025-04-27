-- Transactions in SQL: Ensuring Data Integrity and Consistency

-- Short Introduction:
-- A transaction is a logical unit of work that contains one or more SQL operations.
-- Transactions ensure that a series of actions either fully happen or fully don't happen — "all or nothing."
-- This protects your data from inconsistencies in case of errors, crashes, or unexpected problems.

-- Basic Transaction Commands:
-- - BEGIN or START TRANSACTION → start a new transaction
-- - COMMIT → permanently save all operations since BEGIN
-- - ROLLBACK → undo all operations since BEGIN

-- Simple Example:
-- (Insert a new movie inside a transaction, then rollback)
-- BEGIN;
-- INSERT INTO moviedb.movies (title, production_year) VALUES ('Test Movie', 2024);
-- ROLLBACK;
-- (Result: no new movie is actually inserted.)

-- 1. Start a transaction manually
BEGIN;
-- (Now, operations will not be final until COMMIT or ROLLBACK.)

-- 2. Insert a row and COMMIT
BEGIN;
INSERT INTO moviedb.movies (title, production_year, genre)
VALUES ('The Matrix Reloaded', 2003, 'Science Fiction');	-- (Suppose genre is a column of movies table.)
COMMIT;
-- (The new row is now permanently saved.)

-- 3. Insert a row and ROLLBACK
BEGIN;
INSERT INTO moviedb.movies (title, production_year, genre)
VALUES ('Failed Insert', 2024, 'Drama');
ROLLBACK;
-- (The new row is discarded — the database remains unchanged.)

-- 4. Update a movie inside a transaction
BEGIN;
UPDATE moviedb.movies
SET genre = 'Sci-Fi Action'
WHERE title = 'The Matrix Reloaded';
COMMIT;
-- (The update is saved.)

-- 5. Update and ROLLBACK
BEGIN;
UPDATE moviedb.movies
SET production_year = 2099
WHERE title = 'The Matrix Reloaded';
ROLLBACK;
-- (The update is undone — no future-dated movie!)

-- 6. Delete a movie and COMMIT
BEGIN;
DELETE FROM moviedb.movies
WHERE title = 'Fake Movie';
COMMIT;
-- (If no such title existed, no changes.)

-- 7. Using SAVEPOINTs (partial rollback)
BEGIN;
INSERT INTO moviedb.movies (title, production_year, genre)
VALUES ('Savepoint Test 1', 2024, 'Action');
SAVEPOINT after_first_insert;

INSERT INTO moviedb.movies (title, production_year, genre)
VALUES ('Savepoint Test 2', 2024, 'Action');
ROLLBACK TO after_first_insert;

COMMIT;
-- (Only 'Savepoint Test 1' is committed — 'Savepoint Test 2' was rolled back.)

-- 8. Simulating a lost update
-- (In real concurrency cases: two users update the same record unaware.)
BEGIN;
UPDATE moviedb.movies
SET production_year = 2025
WHERE title = 'The Matrix Reloaded';
-- (Suppose another transaction simultaneously updated the same row differently!)
COMMIT;	-- (The final update is the last one before COMMIT.)
-- (Lesson: careful transaction handling avoids overwriting each other’s work.)

-- 9. Viewing your transaction ID (simple consistency check)
SELECT txid_current();
-- (Shows your current session transaction ID.)

-- 10. See all in-progress transactions (PostgreSQL-specific)
SELECT * 
FROM pg_stat_activity
WHERE state = 'active';
-- (Monitor currently running transactions.)

-- 11. Best practice: Always use WHERE carefully in updates/deletes
-- (Bad: Forgetting WHERE clause)
UPDATE moviedb.movies
SET genre = 'Disaster';
-- (It updates EVERY row!)

-- (Good: safe targeted update)
UPDATE moviedb.movies
SET genre = 'Disaster'
WHERE title = 'Specific Movie';
-- (Always include WHERE unless you really mean all rows!)

-- ============================================================================
-- 🛡️ Golden Rules for Transactions:

-- - Always think: COMMIT only if all steps succeed — otherwise ROLLBACK.
-- - Use SAVEPOINT when you want to partially undo changes.
-- - Avoid long open transactions — they can block other users!
-- - Always update/delete with WHERE.
-- - Test multi-step operations inside transactions before applying in production.

-- ============================================================================
