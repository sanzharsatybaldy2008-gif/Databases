CREATE DATABASE advanced_lab;

CREATE TABLE employees(
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE'

);
DROP TABLE departments;
CREATE TABLE departments(
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id VARCHAR(50)
);
CREATE TABLE projects(
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget INTEGER
);
---Part B
INSERT INTO employees (first_name,last_name,department)
VALUES('John','Doe','IT');

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Jane','Smith','HR',DEFAULT,DEFAULT);

INSERT INTO departments (dept_name, budget,manager_id)
VALUES('IT',150000,1),
      ('HR',80000, 2),
      ('Sales', 120000, 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Alice', 'Johnson', 'Finance', 50000 * 1.1, CURRENT_DATE);

-- 6. INSERT from SELECT (subquery)
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

--PART C
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
UPDATE departments d
SET budget = budget * 1.20
WHERE d.dept_name IN (
    SELECT department
    FROM employees
    WHERE department IS NOT NULL
    GROUP BY department
    HAVING AVG(salary) IS NOT NULL
);

-- 12. UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

--PART D
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT d.dept_id
    FROM departments d
             JOIN employees e ON d.dept_name = e.department
    WHERE e.department IS NOT NULL
);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--PART E
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Mark', 'Taylor', NULL, NULL);

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

--PART F
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Bob', 'Marley', 'IT', 75000)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--PART G
INSERT INTO employees (first_name,last_name,department,salary)
SELECT 'Zere','Brown','IT',65000
WHERE NOT EXISTS(
    SELECT 1 FROM employees
    WHERE first_name ='Zere' AND last_name ='Brown'
);

UPDATE employees e
SET salary =CASE
    WHEN (SELECT budget FROM department d WHERE d.dept_name = e.department)>100000
         THEN salary * 1.10
    else salary*1.05
END
WHERE department IS NOT NULL;

INSERT INTO employees (first_name,last_name,department,salary)
VALUES ('User1', 'Test', 'IT', 50000),
       ('User2', 'Test', 'IT', 52000),
       ('User3', 'Test', 'HR', 48000),
       ('User4', 'Test', 'Sales', 55000),
       ('User5', 'Test', 'Sales', 58000);

UPDATE employees
SET salary = salary *1.10
WHERE first_name LIKE 'User%';

CREATE  TABLE IF  NOT EXISTS employee_archive(LIKE employees INCLUDING ALL);

WITH moved_rows AS(
    DELETE FROM employees
    WHERE status ='Inactive'
    RETURNING *
)
INSERT INTO employee_archive
SELECT *FROM moved_rows;

UPDATE projects p
SET end_date =end_date +INTERVAL '30 days'
WHERE p.budget >50000
AND p.dept_id :: INTEGER IN(
    SELECT d.dept_id
    FROM departments d
    JOIN employees e on d.dept_name =e.department
    GROUP BY d.dept_id
    HAVING COUNT (e.emp_id)>3
    );