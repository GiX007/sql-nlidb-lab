# IMDb SQL Practice Repository

This repository contains a series of structured SQL query files and schema references designed for practicing and mastering SQL using a relational IMDb-style movie database.  
It covers everything from basic SELECT statements to advanced PostgreSQL features such as CTEs, subqueries, window functions, and query optimization.

## Contents:

### imdb_schema.png
- An entity-relationship diagram illustrating the IMDb-style schema used in the queries.
- Serves as a reference for understanding table relationships, primary keys, foreign keys, and attributes.

### queries/
- **queries/00_database_manipulation.sql**
  - Demonstrates DDL and DML operations: creating schemas, creating tables, inserting, updating, deleting records, and exporting results with COPY.
  - Includes examples of EXPLAIN and query analysis.

- **queries/01_basic_selects.sql**
  - Includes beginner-friendly SQL queries to retrieve rows, apply filters, and use basic WHERE clauses.
  - Great for users new to SQL syntax.

- **queries/02_joins.sql**
  - Explores INNER JOINs, LEFT JOINs, self-joins, and multi-table queries to fetch related data like titles, companies, actors, and keywords.

- **queries/03_aggregations.sql**
  - Demonstrates GROUP BY, aggregate functions like COUNT(), AVG(), and conditional filtering with HAVING.
  - Covers thinking patterns for building aggregation queries efficiently.

- **queries/04_subqueries.sql**
  - Includes examples of scalar, correlated, and IN/EXISTS subqueries.
  - Progresses from basic single-layer subqueries to multi-layer optimization.

- **queries/05_ctes.sql**
  - Introduces Common Table Expressions (CTEs) using the WITH clause for cleaner, modular queries.
  - Covers multiple CTEs, chaining, and usage in JOINs and aggregations.

- **queries/06_query_optimization_techniques.sql**
  - Presents key query optimization principles with 20+ focused examples.
  - Techniques include early filtering, avoiding unnecessary DISTINCTs, EXISTS vs IN, function-avoidance on indexed columns, and more.
  - Bad vs Good query comparison style with clear explanations.

- **queries/07_query_optimization_examples.sql**
  - A set of 20 real-world examples showing side-by-side normal vs optimized queries.
  - Covers query restructuring, early limiting, CTE optimization, EXISTS usage, proper NULL handling, minimizing joins, and performance tricks.

---

Feel free to explore each query file to build confidence in SQL, from the fundamentals to advanced PostgreSQL techniques.  
If you encounter issues or have suggestions, feel free to open an issue or start a discussion!

**Note:**  
This project assumes you have access to a PostgreSQL database loaded with a compatible IMDb-like dataset.  
If you need help importing the schema or if you are interested in obtaining the database itself (since it cannot be uploaded here), feel free to contact me directly and I can share it with you privately (Google Drive, Dropbox, etc.).

---
