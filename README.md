# IMDb SQL Practice Repository

This repository contains a series of structured SQL query files and schema references designed for practicing and mastering SQL using a relational IMDb-style movie database.  
It covers everything from basic SELECT statements to advanced PostgreSQL features such as CTEs, subqueries, window functions, and query optimization.

## Contents:

### imdb_schema.png
- An entity-relationship diagram illustrating the IMDb-style schema used in the queries.
- Serves as a reference for understanding table relationships, primary keys, foreign keys, and attributes.

### queries/
- **queries/00_database_manipulation.sql**
  - Covers schema creation, table creation, basic INSERT, UPDATE, DELETE operations, exporting results, and EXPLAIN for analyzing queries.

- **queries/01_basic_selects.sql**
  - Beginner-friendly SQL queries to retrieve rows, apply simple WHERE filters, basic projections, and view specific data.

- **queries/02_joins.sql**
  - Practical examples of INNER JOIN, LEFT JOIN, multi-table joins, with comments explaining relationships between entities.

- **queries/03_aggregations.sql**
  - Demonstrates how to use GROUP BY, COUNT, AVG, HAVING, and filtering aggregates properly.

- **queries/04_subqueries.sql**
  - Includes examples of scalar, correlated, and IN/EXISTS subqueries, progressing from basic to intermediate level.

- **queries/05_ctes.sql**
  - Introduces Common Table Expressions (CTEs) using the WITH clause for modular, cleaner queries.

- **queries/06_query_optimization_techniques.sql**
  - A complete techniques manual: tips like filter early, use EXISTS smartly, defer ORDER BY, push conditions into JOINs.

- **queries/07_query_optimization_examples.sql**
  - 20 real-world query examples: each shows the normal version first, then the optimized version, with explanation why optimization matters.
    
- **queries/08_window_functions.sql**
  - Explains window functions like ROW_NUMBER(), RANK(), LEAD(), LAG(), PERCENT_RANK(), showing how to do advanced ranking, cumulative sums, 
    and comparisons across rows.

- **queries/09_set_operations.sql**
  - Shows UNION, UNION ALL, INTERSECT, and EXCEPT set operations: when and how to merge, compare, or differentiate two result sets.

- **queries/10_indexes.sql**
  - Introduction to SQL indexing. Shows how to create indexes to speed up WHERE conditions and JOINs, and gives examples comparing execution      times before and after indexing.

- **queries/11_transactions_and_consistency.sql**
  - Covers transactions (BEGIN, COMMIT, ROLLBACK), savepoints, lost update scenarios, consistency best practices, and isolation basics in SQL.

---

Feel free to explore each query file to build confidence in SQL, from the fundamentals to advanced PostgreSQL techniques.  
If you encounter issues or have suggestions, feel free to open an issue or start a discussion!

**Note:**  
This project assumes you have access to a PostgreSQL database loaded with a compatible IMDb-like dataset.  
If you need help importing the schema or if you are interested in obtaining the database itself (since it cannot be uploaded here), feel free to contact me directly and I can share it with you privately (Google Drive, Dropbox, etc.).

---
