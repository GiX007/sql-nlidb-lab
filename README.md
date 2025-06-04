# IMDb SQL and NLIDB Lab

A hands-on lab combining SQL query practice and Natural Language Interfaces to Databases (NLIDBs) using an IMDb-style and Spider PostgreSQL schemas.

## Overview

This repository contains a series of structured SQL query files and schema references designed for practicing and mastering SQL using a relational IMDb-style movie database. It covers everything from basic SELECT statements to advanced PostgreSQL features such as CTEs, subqueries, window functions, and query optimization.

It also provides a notebook with NLIDB practice on the well-known Spider dataset, exploring tasks like Text-to-SQL, SQL-to-Text, and Data-to-Text using LLMs.

## Contents:

  - imdb_schema.png
    
    - An entity-relationship diagram illustrating the IMDb-style schema used in the queries.
    - Serves as a reference for understanding table relationships, primary keys, foreign keys, and attributes.

  - queries/
    - **00_database_manipulation.sql**
      - Covers schema creation, table creation, basic INSERT, UPDATE, DELETE operations, exporting results, and EXPLAIN for analyzing queries.
    
    - **01_basic_selects.sql**
      - Beginner-friendly SQL queries to retrieve rows, apply simple WHERE filters, basic projections, and view specific data.
    
    - **02_joins.sql**
      - Practical examples of INNER JOIN, LEFT JOIN, multi-table joins, with comments explaining relationships between entities.
    
    - **03_aggregations.sql**
      - Demonstrates how to use GROUP BY, COUNT, AVG, HAVING, and filtering aggregates properly.
    
    - **04_subqueries.sql**
      - Includes examples of scalar, correlated, and IN/EXISTS subqueries, progressing from basic to intermediate level.
    
    - **05_ctes.sql**
      - Introduces Common Table Expressions (CTEs) using the WITH clause for modular, cleaner queries.
    
    - **06_query_optimization_techniques.sql**
      - A complete techniques manual: tips like filter early, use EXISTS smartly, defer ORDER BY, push conditions into JOINs.
    
    - **07_query_optimization_examples.sql**
      - 20 real-world query examples: each shows the normal version first, then the optimized version, with explanation why optimization matters.
        
    - **08_window_functions.sql**
      - Explains window functions like ROW_NUMBER(), RANK(), LEAD(), LAG(), PERCENT_RANK(), showing how to do advanced ranking, cumulative sums, 
        and comparisons across rows.
    
    - **09_set_operations.sql**
      - Shows UNION, UNION ALL, INTERSECT, and EXCEPT set operations: when and how to merge, compare, or differentiate two result sets.
    
    - **10_indexes.sql**
      - Introduction to SQL indexing. Shows how to create indexes to speed up WHERE conditions and JOINs, and gives examples comparing execution      times before and after indexing.
    
    - **11_transactions_and_consistency.sql**
      - Covers transactions (BEGIN, COMMIT, ROLLBACK), savepoints, lost update scenarios, consistency best practices, and isolation basics in SQL.

  - `NLIDBs_Lab_DB_Systems_2025_DSIT.ipynb`
      - Explores Text-to-SQL, SQL-to-Text, and Data-to-Text generation using LLMs and an Spider database.

---

## Goals

By completing this lab, you will:

  - Gain practical experience with PostgreSQL on a realistic schema.
  - Understand how Large Language Models (LLMs) like GPT can convert text ↔ SQL, SQL ↔ text and a database table ↔ natural language.
  - Get introduced to techniques powering Natural Language Interfaces to Databases. 

Feel free to explore each query file to build confidence in SQL, from the fundamentals to advanced PostgreSQL techniques.  
If you encounter issues or have suggestions, feel free to open an issue or start a discussion!

**Note:**  
This project assumes you have access to a PostgreSQL database loaded with a compatible IMDb-like dataset.  
If you need help importing the schema or if you are interested in obtaining the database itself (since it cannot be uploaded here), feel free to contact me directly and I can share it with you privately (Google Drive, Dropbox, etc.).

**Final Note:**  
This lab provides just an introductory glimpse into SQL. In real-world applications, especially with today's cloud-based databases, professionals often manage much larger and more complex datasets where queries are longer, optimization is significantly more advanced, and performance tuning becomes critical. Nevertheless, this repository offers an excellent starting point for beginners aiming to build strong SQL fundamentals.

---
