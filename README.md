# IMDb SQL Lab & NLIDB Exploration with Spider Dataset

A hands-on lab combining SQL query practice on an IMDb-style PostgreSQL schema and NLIDB experimentation using the Spider dataset.

## Overview

This repository contains structured SQL query files and schema references for practicing SQL using a relational IMDb-style movie database.  
It spans beginner to advanced PostgreSQL concepts such as CTEs, subqueries, window functions, indexing, and optimization.

Additionally, the lab includes a notebook for Natural Language Interface to Databases (NLIDB) tasks using the Spider dataset — a benchmark schema widely used for evaluating Text-to-SQL systems. The notebook showcases how LLMs (e.g., GPT) can translate between natural language, SQL, and tabular data.

## Contents:

  - docs/
    -  A_DBMS_Through_the_X_Rays.pdf 
        - A theoretical guide covering DBMS internals (query plans, transactions, locking, recovery, storage, indexing).

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
      - Advanced ranking and row comparisons using ROW_NUMBER(), RANK(), LEAD(), LAG(), PERCENT_RANK().
    
    - **09_set_operations.sql**
      - Set operations including UNION, UNION ALL, INTERSECT, and EXCEPT set operations for merging, comparing, and differentiating result sets.
    
    - **10_indexes.sql**
      - Introduction to SQL indexing. Shows how to create indexes to speed up WHERE conditions and JOINs, and gives examples comparing execution      times before and after indexing.
    
    - **11_transactions_and_consistency.sql**
      - Covers transactions (BEGIN, COMMIT, ROLLBACK), savepoints, lost update scenarios, consistency best practices, and isolation basics in SQL.

  - `NLIDBs_Lab_DB_Systems_2025_DSIT.ipynb`
      - Explores Text-to-SQL, SQL-to-Text, and Data-to-Text generation using LLMs and the Spider dataset, a standardized benchmark schema for evaluating NLIDB systems.

  - imdb_schema.png
    
    - An entity-relationship diagram illustrating the IMDb-style schema used in the queries.
    - Serves as a reference for understanding table relationships, primary keys, foreign keys, and attributes.

---

## DBMS Architecture & Internals Guide

This repository also includes a detailed pdf guide titled "A DBMS Through the X-Rays" located in the docs folder. It introduces the internal layers of a Database Management System:

  - Request Processing Layer — parsing, authorization, query optimization
  - Concurrent Access Layer — transactions, isolation, locking, and recovery
  - Storage Layer — files, buffer manager, indexing, and I/O cost modeling

Use this pdf to solidify your understanding of how queries are processed, optimized, and executed under the hood.

---

## Goals

By completing this lab, you will:

  - Gain practical experience with PostgreSQL on a realistic schema.
  - Understand how Large Language Models (LLMs) like GPT can translate between natural language and SQL queries, SQL back to human-readable descriptions, and even tabular data into narrative summaries.
  - Get introduced to techniques powering Natural Language Interfaces to Databases. 

Dive into the query files and the NLIDB notebook to build practical and conceptual mastery across both structured querying and natural language interfaces.  
If you encounter issues or have suggestions, feel free to open an issue or start a discussion!

**Note:**  
This project assumes you have access to a PostgreSQL database loaded with a compatible IMDb-like dataset.  
If you need help importing the schema or if you are interested in obtaining the database itself (since it cannot be uploaded here), feel free to contact me directly and I can share it with you privately (Google Drive, Dropbox, etc.).

**Final Note:**  
This lab is a foundational starting point. Real-world databases often involve significantly larger datasets, more complex schemas, and deeper performance tuning. Still, mastering the principles here prepares you well for those challenges.

---
