-- part1 database setup

CREATE TABLE IF NOT EXISTS employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

CREATE TABLE IF NOT EXISTS departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000)
ON CONFLICT (emp_id) DO NOTHING;

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D')
ON CONFLICT (dept_id) DO NOTHING;

INSERT INTO projects VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000)
ON CONFLICT (project_id) DO NOTHING;


-- part 2 cross join

-- 2.1
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- Answer: 5 * 4 = 20 rows.


-- 2.2 (a): Comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;


-- 2.2 (b): INNER JOIN ON TRUE
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;


-- 2.3
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p;
-- Answer 5*5=25 rows.


-- PART 3: INNER JOIN


-- 3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d
ON e.dept_id = d.dept_id;

-- Answer 4 rows.
-- Tom Brown is excluded because dept_id is NULL.


-- 3.2
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);


-- 3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;


-- 3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d
ON e.dept_id = d.dept_id
INNER JOIN projects p
ON d.dept_id = p.dept_id;



-- PART 4: LEFT JOIN


-- 4.1
SELECT e.emp_name,
       e.dept_id AS emp_dept,
       d.dept_id AS dept_dept,
       d.dept_name
FROM employees e
LEFT JOIN departments d
ON e.dept_id = d.dept_id;


-- 4.2
SELECT e.emp_name, dept_id, d.dept_name
FROM employees e
LEFT JOIN departments d
USING (dept_id);


-- 4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d
ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;


-- 4.4
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e
ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


-- PART 5: RIGHT JOIN


-- 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d
ON e.dept_id = d.dept_id;


-- 5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e
ON e.dept_id = d.dept_id;


-- 5.3
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d
ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;



-- PART 6: FULL JOIN


-- 6.1
SELECT e.emp_name,
       e.dept_id AS emp_dept,
       d.dept_id AS dept_dept,
       d.dept_name
FROM employees e
FULL OUTER JOIN departments d
ON e.dept_id = d.dept_id;


-- 6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL OUTER JOIN projects p
ON d.dept_id = p.dept_id;


-- 6.3
SELECT
    CASE
        WHEN e.emp_id IS NULL
            THEN 'Department without employees'
        WHEN d.dept_id IS NULL
            THEN 'Employee without department'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
FULL OUTER JOIN departments d
ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL
   OR d.dept_id IS NULL;



-- PART 7: ON vs WHERE


-- 7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
ON e.dept_id = d.dept_id
AND d.location = 'Building A';


-- 7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';


-- 7.3 (a): INNER JOIN with ON
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
ON e.dept_id = d.dept_id
AND d.location = 'Building A';


-- 7.3 (b): INNER JOIN with WHERE
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';



-- PART 8: COMPLEX JOINS

-- 8.1
SELECT d.dept_name,
       e.emp_name,
       e.salary,
       p.project_name,
       p.budget
FROM departments d
LEFT JOIN employees e
ON d.dept_id = e.dept_id
LEFT JOIN projects p
ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;


-- 8.2

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS manager_id INT;

UPDATE employees
SET manager_id = 3
WHERE emp_id IN (1, 2, 4, 5);

UPDATE employees
SET manager_id = NULL
WHERE emp_id = 3;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m
ON e.manager_id = m.emp_id;


-- 8.3
SELECT d.dept_name,
       AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e
ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;



-- OPTIONAL CHALLENGES


-- Challenge 1: Simulate FULL OUTER JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d
ON e.dept_id = d.dept_id

UNION ALL

SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e
ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;


-- Challenge 2: More than one project
SELECT e.emp_name, d.dept_name
FROM employees e
JOIN departments d
ON e.dept_id = d.dept_id
WHERE e.dept_id IN (
    SELECT dept_id
    FROM projects
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);


-- Challenge 3: Organizational hierarchy
WITH RECURSIVE hierarchy AS (
    SELECT emp_id, emp_name,
           manager_id, 0 AS level,
           ARRAY[emp_id] AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.emp_name,
           e.manager_id, h.level + 1,
           h.path || e.emp_id
    FROM employees e
    JOIN hierarchy h
    ON e.manager_id = h.emp_id
    WHERE e.emp_id <> ALL(h.path)
)
SELECT emp_id, emp_name, manager_id, level
FROM hierarchy
ORDER BY path;


-- Challenge 4: Employee pairs
SELECT e1.emp_name AS employee_1,
       e2.emp_name AS employee_2,
       d.dept_name
FROM employees e1
JOIN employees e2
ON e1.dept_id = e2.dept_id
AND e1.emp_id < e2.emp_id
JOIN departments d
ON d.dept_id = e1.dept_id;