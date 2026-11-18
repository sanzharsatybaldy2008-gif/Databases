-- LABORATORY WORK 8: SQL INDEXES
-- Run this script in PostgreSQL through DataGrip.

-- =========================================================
-- PART 1. Tables and sample data
-- Existing tables from previous labs will be kept.
-- =========================================================

CREATE TABLE IF NOT EXISTS departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10, 2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE IF NOT EXISTS projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12, 2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments (dept_id, dept_name, location)
VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Operations', 'Building C')
ON CONFLICT (dept_id) DO NOTHING;

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 101, 55000),
    (3, 'Mike Johnson', 102, 48000),
    (4, 'Sarah Williams', 102, 52000),
    (5, 'Tom Brown', 103, 60000)
ON CONFLICT (emp_id) DO NOTHING;

INSERT INTO projects (proj_id, proj_name, budget, dept_id)
VALUES
    (201, 'Website Redesign', 75000, 101),
    (202, 'Database Migration', 120000, 101),
    (203, 'HR System Upgrade', 50000, 102)
ON CONFLICT (proj_id) DO NOTHING;


-- =========================================================
-- PART 2. Basic indexes
-- =========================================================

-- PostgreSQL creates B-tree indexes by default.
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- Answer 2.1:
-- At this point, there are usually 3 indexes:
-- employees_pkey (created automatically), emp_salary_idx, and emp_dept_idx
-- (which is created below).

CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT *
FROM employees
WHERE dept_id = 101;

-- Answer 2.2:
-- An index on a foreign key speeds up searches for employees in a department
-- and JOIN operations on dept_id. It also helps PostgreSQL find related rows
-- when a department is updated or deleted.

SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Answer 2.3:
-- At this point, the indexes are usually departments_pkey, employees_pkey,
-- projects_pkey, emp_salary_idx, and emp_dept_idx.
-- The *_pkey indexes are created automatically for PRIMARY KEY constraints.


-- =========================================================
-- PART 3. Multicolumn indexes
-- =========================================================

CREATE INDEX emp_dept_salary_idx
ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101
  AND salary > 52000;

-- Answer 3.1:
-- The (dept_id, salary) index is best suited to searches by dept_id
-- and then by salary. It is usually less effective for a query filtering
-- only by salary because salary is not the first column in the index.

CREATE INDEX emp_salary_dept_idx
ON employees(salary, dept_id);

SELECT *
FROM employees
WHERE dept_id = 102
  AND salary > 50000;

SELECT *
FROM employees
WHERE salary > 50000
  AND dept_id = 102;

-- Answer 3.2:
-- Column order matters in a multicolumn index because the leading columns
-- determine which searches it can support efficiently. The order of
-- conditions in WHERE does not matter: these two queries are logically
-- equivalent. For equality on dept_id and a range condition on salary,
-- (dept_id, salary) is usually a good order.


-- =========================================================
-- PART 4. Unique indexes
-- =========================================================

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS email VARCHAR(100);

UPDATE employees
SET email = 'john.smith@company.com'
WHERE emp_id = 1;

UPDATE employees
SET email = 'jane.doe@company.com'
WHERE emp_id = 2;

UPDATE employees
SET email = 'mike.johnson@company.com'
WHERE emp_id = 3;

UPDATE employees
SET email = 'sarah.williams@company.com'
WHERE emp_id = 4;

UPDATE employees
SET email = 'tom.brown@company.com'
WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx
ON employees(email);

-- To test uniqueness, uncomment and run this statement separately.
-- It is expected to produce a unique-constraint error.
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- Answer 4.1:
-- PostgreSQL will report "duplicate key value violates unique constraint"
-- because this email already exists in the table.

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees'
  AND indexname LIKE '%phone%';

-- Answer 4.2:
-- Yes. PostgreSQL automatically creates a unique B-tree index for a UNIQUE
-- constraint. By default, multiple NULL values are allowed in this column.


-- =========================================================
-- PART 5. Indexes and sorting
-- =========================================================

CREATE INDEX emp_salary_desc_idx
ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- Answer 5.1:
-- A B-tree index can return rows in the requested order and may help avoid
-- a separate sort when the query planner considers it efficient.

CREATE INDEX proj_budget_nulls_first_idx
ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;


-- =========================================================
-- PART 6. Indexes on expressions
-- =========================================================

CREATE INDEX emp_name_lower_idx
ON employees(LOWER(emp_name));

SELECT *
FROM employees
WHERE LOWER(emp_name) = 'john smith';

-- Answer 6.1:
-- Without this index, PostgreSQL would scan the table and apply LOWER()
-- to each employee name. The expression in the query must match the
-- expression used in the index.

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx
ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;


-- =========================================================
-- PART 7. Managing indexes
-- =========================================================

ALTER INDEX emp_salary_idx
RENAME TO employees_salary_index;

SELECT indexname
FROM pg_indexes
WHERE tablename = 'employees';

DROP INDEX emp_salary_dept_idx;

-- Answer 7.2:
-- Drop an index if it duplicates another index or is rarely used.
-- Indexes use disk space and slow down INSERT, UPDATE, and DELETE operations.

REINDEX INDEX employees_salary_index;

-- Answer 7.3:
-- REINDEX rebuilds an index and can be useful if the index is bloated
-- or corrupted. After bulk data loads, updating statistics with ANALYZE
-- is often useful. REINDEX does not replace ANALYZE.


-- =========================================================
-- PART 8. Practical scenarios
-- =========================================================

CREATE INDEX emp_salary_filter_idx
ON employees(salary)
WHERE salary > 50000;

-- emp_dept_idx already exists for the JOIN on employees.dept_id.
-- emp_salary_desc_idx already exists for sorting by salary.
SELECT e.emp_name, e.salary, d.dept_name
FROM employees AS e
JOIN departments AS d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX proj_high_budget_idx
ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- Answer 8.2:
-- A partial index contains entries only for rows that match its condition.
-- It can use less space and require less maintenance when queries often
-- access that subset of the table.

EXPLAIN
SELECT *
FROM employees
WHERE salary > 52000;

-- Answer 8.3:
-- Index Scan means the planner chose an index.
-- Seq Scan means it chose to read the whole table. For a table with only
-- five rows, Seq Scan is often cheaper; this does not mean the index is broken.


-- =========================================================
-- PART 9. Comparing index types
-- =========================================================

CREATE INDEX dept_name_hash_idx
ON departments USING HASH(dept_name);

SELECT *
FROM departments
WHERE dept_name = 'IT';

-- Answer 9.1:
-- HASH indexes support equality comparisons. B-tree is usually more
-- versatile because it supports equality, range searches, and sorting.

CREATE INDEX proj_name_btree_idx
ON projects(proj_name);

CREATE INDEX proj_name_hash_idx
ON projects USING HASH(proj_name);

-- Equality search: both index types can support this query.
SELECT *
FROM projects
WHERE proj_name = 'Website Redesign';

-- Range search: B-tree can support this query; HASH cannot.
SELECT *
FROM projects
WHERE proj_name > 'Database';


-- =========================================================
-- PART 10. Reviewing, cleaning up, and documenting indexes
-- =========================================================

SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Answer 10.1:
-- Find the largest index in the query results above. Its size depends on
-- the data and the index definition, so it cannot be determined in advance.
-- On small tables, several indexes may have the same size.

DROP INDEX IF EXISTS proj_name_hash_idx;

CREATE OR REPLACE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT *
FROM index_documentation;


-- =========================================================
-- SUMMARY QUESTIONS
-- =========================================================

-- 1. The default PostgreSQL index type is B-tree.
--
-- 2. Indexes are useful for columns frequently used in WHERE conditions,
--    JOIN conditions, and ORDER BY clauses.
--
-- 3. An index is usually unnecessary for a very small table, a rarely used
--    column, or a column that changes often and does not help filter rows.
--
-- 4. PostgreSQL automatically maintains indexes when table data changes.
--    This speeds up reads but adds work to INSERT, UPDATE, and DELETE.
--
-- 5. Use EXPLAIN or EXPLAIN ANALYZE to inspect the query plan.
--
-- Reflection:
-- Indexes are useful for frequent queries on large tables. Choose them based
-- on WHERE, JOIN, and ORDER BY conditions, then check query plans with EXPLAIN.
-- Each index uses disk space and adds overhead to data changes, so remove
-- indexes that are unnecessary or rarely used.