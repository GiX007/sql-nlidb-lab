This repository contains a series of structured SQL query files and schema references designed for practicing and mastering SQL using a relational IMDb-style movie database. It covers everything from basic SELECT statements to advanced PostgreSQL features such as CTEs and window functions.

Contents:

schema/imdb_schema.png

  * An entity-relationship diagram illustrating the IMDb-style schema used in the queries.

  * Serves as a reference for understanding table relationships, foreign keys, and attributes.

queries
  * queries/01_basic_selects.sql

     * Includes beginner-friendly SQL queries to retrieve rows, apply filters, and use basic WHERE clauses.

     * Great for users new to SQL syntax.

  * queries/02_joins.sql

Explores INNER JOINs, LEFT JOINs, and multi-table queries to fetch related data like titles, companies, and production years.

  * queries/03_aggregations.sql

     * Demonstrates GROUP BY, aggregate functions like COUNT(), AVG(), and conditional filtering with HAVING.

  * queries/04_subqueries.sql

     * Contains examples of scalar, correlated, and IN/EXISTS subqueries for intermediate learners.

  * queries/05_ctes.sql

     * Introduces Common Table Expressions (CTEs) using the WITH clause for cleaner, modular queries.

  * queries/06_window_functions.sql

     * Covers powerful SQL constructs like ROW_NUMBER(), RANK(), and partitioning using OVER().

  * queries/07_advanced.sql

     * Includes complex use cases with CASE logic, set operations (UNION, INTERSECT), and performance-aware filtering.


Feel free to explore each query file to build confidence in SQL, from the fundamentals to advanced PostgreSQL techniques. If you encounter issues or have suggestions, open an issue or start a discussion. Note: This project assumes you have access to a PostgreSQL database loaded with a compatible IMDb-like dataset. If you need help importing the schema, let me know!
