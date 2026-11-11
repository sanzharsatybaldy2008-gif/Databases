Drop table if exists employees cascade ;
Drop table if exists departments cascade ;
Drop table if exists projects cascade ;
-- PART 1. ПОДГОТОВКА ТАБЛИЦ (пропусти, если таблицы из лабы 6 есть)
-- =====================================================================

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id  INT,
    salary   NUMERIC(10,2)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INT,
    budget       NUMERIC(12,2)
);

INSERT INTO departments VALUES
    (101, 'IT',        'Building A'),
    (102, 'HR',        'Building B'),
    (103, 'Finance',   'Building C'),
    (104, 'Marketing', 'Building D');

INSERT INTO employees VALUES
    (1, 'John Smith',     101, 50000),
    (2, 'Jane Doe',       102, 60000),
    (3, 'Mike Johnson',   101, 55000),
    (4, 'Sarah Williams', 103, 65000),
    (5, 'Tom Brown',      NULL, 45000);

INSERT INTO projects VALUES
    (201, 'Website Redesign',  101, 100000),
    (202, 'Employee Training', 102,  50000),
    (203, 'Budget Planning',   103,  75000),
    (204, 'Mobile App',        101, 150000);


-- =====================================================================
-- PART 2. СОЗДАНИЕ БАЗОВЫХ VIEWS
-- =====================================================================

-- ---------- 2.1 Простой view (INNER JOIN) ----------
CREATE VIEW employee_details AS
SELECT e.emp_name,
       e.salary,
       d.dept_name,
       d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;
-- Ответ: 4 строки. У Tom Brown dept_id = NULL, условие NULL = 101
-- даёт "неизвестно", и INNER JOIN такую строку отбрасывает.

-- ---------- 2.2 View с агрегацией ----------
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id)         AS employee_count,
       ROUND(AVG(e.salary), 2) AS avg_salary,
       MAX(e.salary)           AS max_salary,
       MIN(e.salary)           AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

-- ---------- 2.3 View с несколькими JOIN ----------
CREATE VIEW project_overview AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       COUNT(e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees   e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

SELECT * FROM project_overview;

-- ---------- 2.4 View с фильтром ----------
CREATE VIEW high_earners AS
SELECT e.emp_name,
       e.salary,
       d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;
-- Ответ: да, видны все со salary > 55000 (Jane и Sarah).


-- =====================================================================
-- PART 3. ИЗМЕНЕНИЕ И УПРАВЛЕНИЕ VIEWS
-- =====================================================================

-- ---------- 3.1 Замена view (новая колонка только В КОНЕЦ) ----------
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name,
       e.salary,
       d.dept_name,
       d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- ---------- 3.2 Переименование view ----------
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

-- ---------- 3.3 Временный view и удаление ----------
CREATE TEMP VIEW temp_view AS
SELECT emp_name, salary
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;

DROP VIEW temp_view;


-- =====================================================================
-- PART 4. ОБНОВЛЯЕМЫЕ VIEWS
-- =====================================================================

-- ---------- 4.1 Создание обновляемого view ----------
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- ---------- 4.2 UPDATE через view ----------
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';
-- Ответ: да, таблица employees обновилась (salary = 52000).

-- ---------- 4.3 INSERT через view ----------
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees WHERE emp_id = 6;
-- Ответ: вставка успешна, строка есть в employees.

-- ---------- 4.4 View с LOCAL CHECK OPTION ----------
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- ДОЛЖНО УПАСТЬ: ERROR: new row violates check option for view "it_employees"
-- Причина: dept_id = 103, а view пропускает только dept_id = 101.
-- Раскомментируй и запусти ОТДЕЛЬНО (выдели только эту команду):
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
-- VALUES (7, 'Bob Wilson', 103, 60000);


-- =====================================================================
-- PART 5. MATERIALIZED VIEWS
-- =====================================================================

-- ---------- 5.1 Создание materialized view WITH DATA ----------
-- Сначала сворачиваем employees и projects до одной строки на отдел,
-- иначе JOIN размножит строки и суммы посчитаются неверно.
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(e.total_employees, 0) AS total_employees,
       COALESCE(e.total_salaries, 0)  AS total_salaries,
       COALESCE(p.total_projects, 0)  AS total_projects,
       COALESCE(p.total_budget, 0)    AS total_project_budget
FROM departments d
LEFT JOIN (
    SELECT dept_id,
           COUNT(*)    AS total_employees,
           SUM(salary) AS total_salaries
    FROM employees
    GROUP BY dept_id
) e ON e.dept_id = d.dept_id
LEFT JOIN (
    SELECT dept_id,
           COUNT(*)    AS total_projects,
           SUM(budget) AS total_budget
    FROM projects
    GROUP BY dept_id
) p ON p.dept_id = d.dept_id
WITH DATA;

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

-- ---------- 5.2 REFRESH ----------
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- ДО refresh (старые данные: у IT 2 сотрудника)
SELECT 'ДО refresh' AS step, * FROM dept_summary_mv WHERE dept_id = 101;

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- ПОСЛЕ refresh (у IT уже 3 сотрудника)
SELECT 'ПОСЛЕ refresh' AS step, * FROM dept_summary_mv WHERE dept_id = 101;

-- ---------- 5.3 CONCURRENTLY ----------
-- Нужен UNIQUE-индекс без WHERE, и view уже должен быть заполнен.
CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id
    ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Преимущество: читатели (SELECT) не блокируются во время обновления.

-- ---------- 5.4 Materialized view WITH NO DATA ----------
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       COUNT(e.emp_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees   e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;

-- Проверка состояния: ispopulated = f (данных ещё нет)
SELECT matviewname, ispopulated FROM pg_matviews;

-- ДОЛЖНО УПАСТЬ: ERROR: materialized view "project_stats_mv" has not been populated
-- Раскомментируй и запусти ОТДЕЛЬНО:
-- SELECT * FROM project_stats_mv;

-- Исправление: загрузить данные
REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;


-- =====================================================================
-- PART 6. РОЛИ
-- =====================================================================

-- ---------- 6.1 Базовые роли ----------
DROP ROLE analyst;
CREATE ROLE analyst;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE USER report_user WITH PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- ---------- 6.2 Роли с атрибутами ----------
CREATE ROLE db_creator   WITH LOGIN CREATEDB   PASSWORD 'creator789';
CREATE ROLE user_manager WITH LOGIN CREATEROLE PASSWORD 'manager101';
CREATE ROLE admin_user   WITH LOGIN SUPERUSER  PASSWORD 'admin999';

SELECT rolname, rolcanlogin, rolcreatedb, rolcreaterole, rolsuper
FROM pg_roles
WHERE rolname IN ('db_creator', 'user_manager', 'admin_user');

-- ---------- 6.3 Выдача прав ----------
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- ---------- 6.4 Групповые роли ----------
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE ROLE hr_user1      WITH LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2      WITH LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 WITH LOGIN PASSWORD 'fin001';

GRANT hr_team      TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees       TO hr_team;
GRANT SELECT         ON dept_statistics TO finance_team;

-- Проверка членства в группах
SELECT m.rolname AS member, g.rolname AS group_role
FROM pg_auth_members am
JOIN pg_roles m ON m.oid = am.member
JOIN pg_roles g ON g.oid = am.roleid
WHERE g.rolname IN ('hr_team', 'finance_team');

-- ---------- 6.5 Отзыв прав ----------
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- ---------- 6.6 Изменение атрибутов ----------
ALTER ROLE analyst      WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst      WITH PASSWORD NULL;
ALTER ROLE data_viewer  WITH CONNECTION LIMIT 5;

SELECT rolname, rolcanlogin, rolsuper, rolconnlimit
FROM pg_roles
WHERE rolname IN ('analyst', 'user_manager', 'data_viewer');

-- Есть ли пароль у analyst (pg_authid доступна только суперпользователю)
SELECT rolname, rolpassword IS NOT NULL AS has_password
FROM pg_authid
WHERE rolname = 'analyst';


-- =====================================================================
-- PART 7. ПРОДВИНУТОЕ УПРАВЛЕНИЕ РОЛЯМИ
-- =====================================================================

-- ---------- 7.1 Иерархия ролей ----------
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst, senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- ---------- 7.2 Владение объектами ----------
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';

ALTER VIEW  dept_statistics OWNER TO project_manager;
ALTER TABLE projects        OWNER TO project_manager;

-- Права на таблицы внутри view проверяются от имени ВЛАДЕЛЬЦА view.
-- Без этой команды finance_team получит "permission denied" на dept_statistics.
GRANT SELECT ON employees, departments TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

-- Владельцы view смотрим отдельно (pg_tables их не показывает)
SELECT viewname, viewowner
FROM pg_views
WHERE schemaname = 'public';

-- ---------- 7.3 REASSIGN и удаление роли ----------
CREATE ROLE temp_owner WITH LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

-- Если твой суперпользователь называется не postgres, замени имя ниже.
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- Проверка: таблица осталась (владелец postgres), роли больше нет
SELECT tablename, tableowner FROM pg_tables WHERE tablename = 'temp_table';
SELECT rolname FROM pg_roles WHERE rolname = 'temp_owner';

-- ---------- 7.4 Ограничение доступа через views ----------
CREATE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- =====================================================================
-- PART 8. ПРАКТИЧЕСКИЕ СЦЕНАРИИ
-- =====================================================================

-- ---------- 8.1 Dashboard ----------
-- В таблице projects нет статуса, поэтому "active projects" = все проекты отдела.
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       COALESCE(e.employee_count, 0) AS employee_count,
       COALESCE(e.avg_salary, 0)     AS avg_salary,
       COALESCE(p.project_count, 0)  AS active_projects,
       COALESCE(p.total_budget, 0)   AS total_project_budget,
       COALESCE(ROUND(p.total_budget / NULLIF(e.employee_count, 0), 2), 0)
                                     AS budget_per_employee
FROM departments d
LEFT JOIN (
    SELECT dept_id,
           COUNT(*)              AS employee_count,
           ROUND(AVG(salary), 2) AS avg_salary
    FROM employees
    GROUP BY dept_id
) e ON e.dept_id = d.dept_id
LEFT JOIN (
    SELECT dept_id,
           COUNT(*)    AS project_count,
           SUM(budget) AS total_budget
    FROM projects
    GROUP BY dept_id
) p ON p.dept_id = d.dept_id;

SELECT * FROM dept_dashboard;

-- ---------- 8.2 Audit view ----------
ALTER TABLE projects
    ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;

-- ---------- 8.3 Система контроля доступа ----------
-- Level 1: Viewer
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

-- Level 2: Entry
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3: Analyst
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4: Manager
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Пользователи
CREATE ROLE alice   WITH LOGIN PASSWORD 'alice123';
CREATE ROLE bob     WITH LOGIN PASSWORD 'bob123';
CREATE ROLE charlie WITH LOGIN PASSWORD 'charlie123';

GRANT viewer_role  TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
