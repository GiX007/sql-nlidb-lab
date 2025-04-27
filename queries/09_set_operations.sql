-- Set Operations in SQL: UNION, UNION ALL, INTERSECT, and EXCEPT

-- Short Introduction:
-- Set operations allow you to combine the results of two or more SELECT queries.
-- Useful for merging, comparing, or finding differences between datasets without writing complex JOINs.

-- Main types:
-- - UNION: Combines results and removes duplicates.
-- - UNION ALL: Combines results including duplicates.
-- - INTERSECT: Returns only rows present in both queries.
-- - EXCEPT (or MINUS in some databases): Returns rows from the first query that are not in the second.

-- Simple Example:
-- (Find all movie titles either from before 1980 or after 2010)
-- SELECT title FROM title WHERE production_year < 1980
-- UNION
-- SELECT title FROM title WHERE production_year > 2010;

-- Execution Order in Set Operations:
-- - In any UNION, UNION ALL, INTERSECT, or EXCEPT:
--   1️. First, the left-side SELECT query is fully executed.
--   2️. Then, the right-side SELECT query is fully executed.
--   3️. Finally, the Set Operation (UNION, INTERSECT, EXCEPT) is applied to combine or compare the two result sets.

-- Important:
-- - UNION requires extra time because after executing both queries, it must remove duplicates (sort or hash the full output).
-- - UNION ALL is faster because it simply appends the results (no deduplication step).
-- - INTERSECT and EXCEPT are also costly because they require full comparisons between sets.

-- Summary of relative cost (approximately): UNION ALL  <  INTERSECT ≈ EXCEPT  <  UNION (From fastest to slowest.)

-- 1. Find actors who acted in movies OR video games
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')

UNION

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%video game%');
-- (UNION merges both lists, removing duplicates automatically.)

-- 2. Find actors who acted in movies OR video games (allowing duplicates)
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')

UNION ALL

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%video game%');
-- (UNION ALL merges both lists, keeping duplicates.
--  UNION operations require extra time because the database must compare, sort, and remove duplicate rows.
--  Whenever possible, if duplicate removal is not necessary, prefer using UNION ALL instead of UNION.
--  UNION ALL simply appends the results without checking for duplicates, making it much faster and lighter, especially on large datasets.)

-- 3. Find all companies involved in either movie production OR video game production
SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')

UNION

SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%video game%');
-- (Finds companies active in either domain.)

-- 4. Find actors who acted both in movies AND in video games (using INTERSECT)
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')

INTERSECT

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%video game%');
-- (INTERSECT keeps only those actors appearing in both sets.)

-- 5. Find titles produced by two different companies (Disney and Pixar)
SELECT t.title
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
WHERE mc.company_id IN (SELECT id FROM company_name WHERE name ILIKE '%Disney%')

INTERSECT

SELECT t.title
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
WHERE mc.company_id IN (SELECT id FROM company_name WHERE name ILIKE '%Pixar%');
-- (Find movies jointly produced by Disney and Pixar.)

-- 6. Find actors who acted in movies but NOT in video games
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')

EXCEPT

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON ci.movie_id = t.id
WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%video game%');
-- (EXCEPT removes actors found in the second query.)

-- 7. Find keywords used in horror movies but not in comedies after 2000
SELECT k.keyword
FROM keyword k
JOIN movie_keyword mk ON k.id = mk.keyword_id
JOIN title t ON mk.movie_id = t.id
WHERE t.production_year > 2000 AND t.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%movie%')
  AND EXISTS (
    SELECT 1
    FROM movie_keyword mk2
    JOIN title t2 ON mk2.movie_id = t2.id
    WHERE mk2.keyword_id = k.id
      AND t2.production_year > 2000	-- (Notice that we should also use this to take horror movies after 2000.)
      AND EXISTS (
          SELECT 1
          FROM keyword k2
          WHERE k2.id = mk2.keyword_id
            AND k2.keyword ILIKE '%horror%'
      )
  )

EXCEPT

SELECT k.keyword
FROM keyword k
JOIN movie_keyword mk ON k.id = mk.keyword_id
JOIN title t ON mk.movie_id = t.id
WHERE EXISTS (
    SELECT 1
    FROM keyword k2
    WHERE k2.id = mk.keyword_id
      AND k2.keyword ILIKE '%comedy%'
);
-- (Find keywords exclusive to horror, excluding comedy.)

-- 8. Find movie titles released either before 1980 or after 2010
SELECT title
FROM title
WHERE production_year < 1980

UNION

SELECT title
FROM title
WHERE production_year > 2010;
-- (UNION cleanly combines two periods.)

-- 9. Find titles that were produced before 1950 AND after 2000 (theoretically impossible)
SELECT title
FROM title
WHERE production_year < 1950

INTERSECT

SELECT title
FROM title
WHERE production_year > 2000;
-- (Returns empty set — no movie can satisfy both.)

-- 10. Find companies that produced either comedies or horrors
SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON mc.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%comedy%'

UNION

SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON mc.movie_id = t.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%horror%';
-- (Companies producing at least one movie of either type.)

-- 11. Compare titles by Disney vs Pixar
SELECT t.title
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON cn.id = mc.company_id
WHERE cn.name ILIKE '%Disney%'

EXCEPT

SELECT t.title
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON cn.id = mc.company_id
WHERE cn.name ILIKE '%Pixar%';
-- (Find Disney titles not associated with Pixar.)

-- 12. Find all people who acted OR directed movies
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%'

UNION

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%director%';
-- (Merge actors and directors.)

-- 13. Find people who both acted AND directed
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%actor%'

INTERSECT

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN role_type rt ON rt.id = ci.role_id
WHERE rt.role ILIKE '%director%';
-- (People who acted AND directed.)

-- 14. Find companies that have produced drama but NOT horror
SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%drama%'

EXCEPT

SELECT cn.name
FROM company_name cn
JOIN movie_companies mc ON cn.id = mc.company_id
JOIN title t ON t.id = mc.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%horror%';
-- (Drama-producing companies but not horror.)

-- 15. Find actors who acted in 'comedy' movies but NOT in 'drama'
SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON t.id = ci.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%comedy%'

EXCEPT

SELECT n.name
FROM name n
JOIN cast_info ci ON n.id = ci.person_id
JOIN title t ON t.id = ci.movie_id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
WHERE k.keyword ILIKE '%drama%';
-- (Actors exclusive to comedy genre.)

-- ============================================================================
-- 🧠 Quick Exam Reminder: Set Operations Usage

-- - Use UNION when you want to merge two results and remove duplicates automatically.
-- - Use UNION ALL when you want to merge two results and keep duplicates (faster).
-- - Use INTERSECT when you want only the common rows between two queries.
-- - Use EXCEPT when you want rows from the first query that are NOT present in the second.
 
-- Tip: Always double-check column order and types must match across queries in set operations!
-- ============================================================================
