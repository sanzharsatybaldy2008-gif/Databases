-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Complete SQL Script (Parts 2 to 7 + Outputs + Answers)
-- Note: Run lab9_setup.sql first in a clean scratch database.
-- ============================================================


-- ============================================================
-- PART 2: YOUR FIRST FUNCTION
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 2.1: A function over one row
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);
SELECT rental_days(11);
SELECT rental_days(19);
SELECT rental_days(999);

/*
OUTPUT (Exercise 2.1):
- SELECT rental_days(2);   -> 5
- SELECT rental_days(11);  -> 8
- SELECT rental_days(19);  -> NULL
- SELECT rental_days(999); -> NULL

QUESTION & ANSWER (Exercise 2.1):
Q: What does your function return for rental 19, and what does it return for rental 999? Are the two NULLs produced for the same reason?
A: Для 19 и 999 функция возвращает NULL, но причины разные. Для аренды 19 строка существует, но end_date равно NULL, а арифметика с NULL (NULL - DATE) всегда даёт NULL. Для аренды 999 такой строки в rentals вообще нет, поэтому SELECT ... INTO v_days не находит ни одной строки и оставляет v_days со значением NULL.
*/


-- ------------------------------------------------------------
-- Exercise 2.2: A function over many rows
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS INT AS $$
DECLARE
    v_cnt INT;
BEGIN
    SELECT COUNT(*)
    INTO v_cnt
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_cnt;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);
SELECT member_rental_count(5);
SELECT member_rental_count(6);
SELECT member_rental_count(99);

/*
OUTPUT (Exercise 2.2):
- SELECT member_rental_count(1);  -> 5
- SELECT member_rental_count(5);  -> 4
- SELECT member_rental_count(6);  -> 0
- SELECT member_rental_count(99); -> 0

QUESTION & ANSWER (Exercise 2.2):
Q: Member 6 and member 99 both give the same answer. Explain why COUNT(*) returns 0 rather than NULL for a member who does not exist.
A: COUNT(*) — это агрегатная функция, которая при отсутствии подходящих строк всегда возвращает 0 (а не пустой набор/NULL), потому что подсчитывает количество совпавших строк (их ровно 0). В итоге SELECT COUNT(*) INTO всегда возвращает одну строку со значением 0.
*/


-- ------------------------------------------------------------
-- Exercise 2.3: Returning text
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

/*
OUTPUT (Exercise 2.3):
- SELECT station_city(30); -> 'Astana'
- SELECT station_city(77); -> NULL
*/


-- ------------------------------------------------------------
-- Exercise 2.4: Using a function inside a query
-- ------------------------------------------------------------
SELECT
    rental_id,
    member_id,
    rental_days(rental_id) AS days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY rental_days(rental_id) DESC;

/*
OUTPUT (Exercise 2.4):
rental_id | member_id | days
----------+-----------+-----
       11 |         3 |    8
        4 |         1 |    7
       15 |         5 |    7
       17 |         5 |    7
        7 |         2 |    6
       14 |         4 |    6
       20 |         4 |    6
        2 |         1 |    5
*/


-- ============================================================
-- PART 3: PARAMETER MODES
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 3.1: IN parameters
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100.0), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

/*
OUTPUT (Exercise 3.1):
- SELECT fee_with_discount(74.00, 15); -> 62.90
*/


-- ------------------------------------------------------------
-- Exercise 3.2: OUT parameters
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
)
AS $$
BEGIN
    SELECT
        COUNT(*),
        COALESCE(SUM(fee), 0),
        MAX(start_date)
    INTO
        rental_cnt,
        total_fee,
        last_start
    FROM rentals
    WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);

/*
OUTPUT (Exercise 3.2):
- SELECT member_stats(3);        -> (5,164.75,2025-06-01)  [один столбец типа record]
- SELECT * FROM member_stats(3); -> rental_cnt = 5 | total_fee = 164.75 | last_start = 2025-06-01
- SELECT * FROM member_stats(6); -> rental_cnt = 0 | total_fee = 0      | last_start = NULL

QUESTION & ANSWER (Exercise 3.2):
Q: How does the output of the two calls differ? Which form would you use inside a larger query, and why? What do you get for member 6?
A: SELECT member_stats(3) возвращает один составной кортеж (record) в одном столбце, а SELECT * FROM member_stats(3) разворачивает OUT-параметры в три отдельных именованных столбца. Внутри большого запроса удобнее SELECT * FROM member_stats(...) (или LATERAL), чтобы обращаться к полям (rental_cnt, total_fee, last_start) по именам без распаковки кортежа. Для участника 6 возвращается: rental_cnt = 0, total_fee = 0, last_start = NULL.
*/


-- ------------------------------------------------------------
-- Exercise 3.3: INOUT parameters
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := COALESCE(p_fee, 0) + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee)
FROM rentals
WHERE rental_id = 1;

/*
OUTPUT (Exercise 3.3):
- SELECT apply_late_fee(fee) FROM rentals WHERE rental_id = 1; -> 18.50

QUESTION & ANSWER (Exercise 3.3):
Q: The function has no RETURNS clause and no RETURN statement. Why does it still produce a value?
A: В PostgreSQL INOUT-параметры (как и OUT) сами задают выходную структуру функции: по завершении блока BEGIN ... END PostgreSQL автоматически возвращает текущее значение INOUT-переменной, поэтому отдельный RETURNS и RETURN не обязательны.
*/


-- ------------------------------------------------------------
-- Exercise 3.4: VARIADIC parameters
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
)
AS $$
BEGIN
    SELECT
        SUM(p_fees[i]),
        ROUND(AVG(p_fees[i]), 2),
        MAX(p_fees[i])
    INTO
        total,
        average,
        largest
    FROM generate_subscripts(p_fees, 1) AS g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
-- Expected error when called with zero arguments:
-- SELECT * FROM fee_summary();

/*
OUTPUT (Exercise 3.4):
- SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50); -> total = 98.50 | average = 24.63 | largest = 35.00
- SELECT * FROM fee_summary(); -> ERROR: function fee_summary() does not exist

QUESTION & ANSWER (Exercise 3.4):
Q: What happens if you call fee_summary() with no arguments at all? Why must a VARIADIC parameter be the last one in the list?
A: Вызов fee_summary() без аргументов вызывает ошибку (function fee_summary() does not exist), потому что VARIADIC требует хотя бы один аргумент (если не передан пустой массив VARIADIC ARRAY[]::NUMERIC[]). VARIADIC должен стоять последним, иначе при вызове было бы неоднозначно, какие аргументы относятся к вариативному массиву, а какие — к следующим параметрам.
*/


-- ------------------------------------------------------------
-- Exercise 3.5: Choosing a mode
-- ------------------------------------------------------------
/*
OUTPUT (Exercise 3.5):
Нет SQL-запроса (теоретическое задание на выбор режима параметров).

QUESTION & ANSWER (Exercise 3.5):
Q: For each of the following, state which parameter mode you would use and write one sentence of justification: (a) the id of the row to look up; (b) a running balance that the caller passes in and expects back updated; (c) a list of station ids of unknown length; (d) two statistics returned together from one pass over a table.
A:
(a) IN — передаётся только входное значение для поиска строки, и изменять его внутри функции не нужно.
(b) INOUT — вызывающий код передаёт текущий баланс и получает его обновлённое значение обратно.
(c) VARIADIC — позволяет передать произвольное число аргументов одного типа как единый массив без ручного конструирования массива вызывающим кодом.
(d) OUT — два OUT-параметра позволяют вернуть два именованных значения из одного SELECT ... INTO за один проход по таблице.
*/


-- ============================================================
-- PART 4: DEFAULT VALUES AND FUNCTION OVERLOADING
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 4.1: A function with one parameter
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1);
SELECT total_fees(6);

/*
OUTPUT (Exercise 4.1):
- SELECT total_fees(1); -> 98.50
- SELECT total_fees(6); -> 0
*/


-- ------------------------------------------------------------
-- Exercise 4.2: Overloading the name
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');
-- In psql: \df total_fees

/*
OUTPUT (Exercise 4.2):
- SELECT total_fees(1, DATE '2024-01-01'); -> 98.50
- SELECT total_fees(1, DATE '2025-01-01'); -> 50.00  (аренды 3: 18.50 и 4: 31.50; аренда 19 имеет fee = NULL)
*/


-- ------------------------------------------------------------
-- Exercise 4.3: Giving a parameter a default value
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- This call fails due to ambiguity (kept commented so script can run cleanly; uncomment to reproduce):
-- SELECT total_fees(1);

/*
OUTPUT / EXACT ERROR (Exercise 4.3):
ERROR:  function total_fees(integer) is not unique
LINE 1: SELECT total_fees(1);
               ^
HINT:  Could not choose a best candidate function. You might need to add explicit type casts.

QUESTION & ANSWER (Exercise 4.3):
Q: The last call fails. Copy the exact error message and the hint into your report, and explain in your own words why PostgreSQL cannot choose between the two functions.
A: При вызове total_fees(1) подходят сразу две функции: однопараметровая total_fees(integer) и двухпараметровая total_fees(integer, date) с дефолтным вторым аргументом. Обе имеют одинаковый приоритет для одного integer-аргумента, поэтому PostgreSQL не может выбрать «лучшую» и выдаёт ошибку неоднозначности.
*/


-- ------------------------------------------------------------
-- Exercise 4.4: Resolving the ambiguity
-- ------------------------------------------------------------
DROP FUNCTION total_fees(INTEGER);

SELECT total_fees(1);

/*
OUTPUT (Exercise 4.4):
- DROP FUNCTION total_fees(INTEGER); -> DROP FUNCTION
- SELECT total_fees(1);              -> 50.00

QUESTION & ANSWER (Exercise 4.4):
Q: Which of the two functions answers the call now, and what value does it return? Would dropping the other version have given the same answer?
A: Теперь вызывается двухпараметровая версия total_fees(integer, date) с p_from_date = DATE '2025-01-01', и она возвращает 50.00. Если бы мы удалили двухпараметровую версию и оставили однопараметровую, ответ был бы другим — 98.50 (сумма за всё время).
*/


-- ------------------------------------------------------------
-- Exercise 4.5: Overloading on type, not just on count
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    WHERE m.full_name = p_member_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);

/*
OUTPUT (Exercise 4.5):
- SELECT total_fees('Aisha Nurlanova'); -> 98.50
- SELECT total_fees(1);                 -> 50.00

QUESTION & ANSWER (Exercise 4.5):
Q: Adding this version does not reintroduce the error of Exercise 4.3 — why not? The two calls above refer to the same member but return different numbers: explain exactly which function each call reaches and what makes the results differ.
A: Ошибка из 4.3 не возвращается, потому что литерал 'Aisha Nurlanova' приводится к text/varchar, а не к integer, поэтому total_fees(varchar) не конкурирует с total_fees(integer, date). Вызов total_fees('Aisha Nurlanova') попадает в total_fees(varchar) и считает все оплаты Aisha за весь период (98.50), а вызов total_fees(1) попадает в total_fees(integer, date) с датой по умолчанию 2025-01-01 и считает оплаты только начиная с 2025-01-01 (50.00).
*/


-- ============================================================
-- PART 5: FUNCTIONS THAT RETURN A TABLE
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 5.1: Search by pattern
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id INT,
    found_model VARCHAR,
    found_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.bike_id,
        b.model,
        b.daily_rate
    FROM bikes b
    WHERE b.model ILIKE p_pattern
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');

/*
OUTPUT (Exercise 5.1):
1) SELECT * FROM find_bikes('%road%');
found_id | found_model | found_rate
---------+-------------+-----------
     105 | Road Sprint |       9.25
     108 | Road Sprint |       9.25

2) SELECT * FROM find_bikes('%Mini');
found_id | found_model  | found_rate
---------+--------------+-----------
     106 | Folding Mini |       3.75

3) SELECT find_bikes('%road%');
find_bikes
---------------------------
(105,"Road Sprint",9.25)
(108,"Road Sprint",9.25)

QUESTION & ANSWER (Exercise 5.1):
Q: Now run SELECT find_bikes('%road%'); without the FROM. How does the shape of the result change, and why?
A: Без FROM результат возвращается как один столбец с именем функции (find_bikes), где каждая строка — это составной кортеж (record) в скобках, а не отдельные столбцы таблицы. Это происходит потому, что в SELECT <expr> без FROM функция вычисляется как скалярное выражение, упаковывающее строки результата в составной тип.
*/


-- ------------------------------------------------------------
-- Exercise 5.2: A table from a join
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration_days INT,
    fee NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.rental_id,
        b.model,
        s.station_name,
        (r.end_date - r.start_date)::INT,
        r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    LEFT JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);

/*
OUTPUT (Exercise 5.2):
rental_id | bike_model  | station_name | duration_days |   fee
----------+-------------+--------------+---------------+-------
        8 | Mountain X  | Expo Gate    |             4 | 28.00
        9 | Road Sprint | Expo Gate    |             3 | 27.75
       10 | Mountain X  | Expo Gate    |             1 |  7.00
       21 | Mountain X  | Riverside    |             4 | 28.00
       11 | Road Sprint | Expo Gate    |             8 | 74.00
*/


-- ------------------------------------------------------------
-- Exercise 5.3: When the column names collide
-- ------------------------------------------------------------
-- Step A: Broken version that fails at call time
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

-- Expected error on call (uncomment to reproduce):
-- SELECT * FROM bike_list(10);

/*
EXACT ERROR ON BROKEN CALL (Exercise 5.3):
ERROR:  column reference "bike_id" is ambiguous
DETAIL:  It could refer to either a PL/pgSQL variable or a table column.
LINE 1: SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
               ^
QUERY:  SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
CONTEXT:  PL/pgSQL function bike_list(integer) line 3 at RETURN QUERY
*/

-- Drop broken version before recreating with different return column names
DROP FUNCTION bike_list(INT);

-- Fix 1: Rename output columns
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model
    FROM bikes
    WHERE station_id = p_station_id
    ORDER BY bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Drop Fix 1 before recreating with original return column names
DROP FUNCTION bike_list(INT);

-- Fix 2: Keep output column names and qualify table columns with an alias
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model
    FROM bikes AS b
    WHERE b.station_id = p_station_id
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

/*
OUTPUT AFTER FIX 1 & FIX 2 (Exercise 5.3):
bike_id | model
--------+--------------
    101 | City Cruiser
    102 | City Cruiser
    108 | Road Sprint

QUESTION & ANSWER (Exercise 5.3):
Q: The CREATE succeeds but the call fails. Why does the error appear only at call time? Fix the function in two different ways: first by renaming the output columns, then by keeping the names and qualifying the table columns with an alias in the query.
A: CREATE FUNCTION только сохраняет тело функции как строку (и делает базовый разбор), а PL/pgSQL планирует и проверяет имена внутри тела при первом выполнении функции в сессии. В этот момент имена выходных параметров bike_id и model конфликтуют со столбцами таблицы bikes, что вызывает column reference "bike_id" is ambiguous.
*/


-- ------------------------------------------------------------
-- Exercise 5.4: Casting the output
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (
    s_name VARCHAR,
    s_bikes INT,
    s_free INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.station_name,
        COUNT(b.bike_id)::INT AS s_bikes,
        (s.capacity - COUNT(b.bike_id))::INT AS s_free
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

/*
OUTPUT (Exercise 5.4):
1) SELECT * FROM station_board('Almaty');
s_name       | s_bikes | s_free
-------------+---------+-------
Central Park |       3 |      1
Riverside    |       2 |      1

2) SELECT * FROM station_board('Astana');
s_name    | s_bikes | s_free
----------+---------+-------
Expo Gate |       2 |      3
Depot     |       0 |      0

QUESTION & ANSWER (Exercise 5.4):
Q: The aggregate COUNT(*) produces a BIGINT. What happens if you declare the column as INT and do not cast it? Show the message you get.
A: Если не привести COUNT(...) к INT (::INT), при выполнении запроса возникает ошибка несоответствия типов возвращаемого столбца:
ERROR:  structure of query does not match function result type
DETAIL:  Returned type bigint does not match expected type integer in column 2.
CONTEXT:  PL/pgSQL function station_board(character varying) line 3 at RETURN QUERY
*/


-- ============================================================
-- PART 6: BLOCK STRUCTURE, DO BLOCKS AND SUBBLOCKS
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 6.1: An anonymous block
-- ------------------------------------------------------------
DO $$
<<rental_report>>
DECLARE
    v_total_rentals INT := 0;
BEGIN
    SELECT COUNT(*)
    INTO v_total_rentals
    FROM rentals;

    RAISE NOTICE 'The rentals table holds % rows.', v_total_rentals;
END rental_report $$;

/*
OUTPUT (Exercise 6.1):
NOTICE:  The rentals table holds 22 rows.

QUESTION & ANSWER (Exercise 6.1):
Q: What happens if the label after END does not match the one at the top?
A: Если метка после END не совпадает с меткой в начале блока, PostgreSQL выдаёт синтаксическую ошибку (ERROR: end label "wrong_label" does not match block label "rental_report").
*/


-- ------------------------------------------------------------
-- Exercise 6.2: A subblock and a hidden variable
-- ------------------------------------------------------------
DO $$
<<outer_block>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO fee_total
    FROM rentals;

    RAISE NOTICE '1. Outer before subblock: %', fee_total;

    <<inner_block>>
    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
        INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE '2. Subblock own fee_total: %', fee_total;
        RAISE NOTICE '3. Outer fee_total via label: %', outer_block.fee_total;
    END inner_block;

    RAISE NOTICE '4. Outer after subblock: %', fee_total;
END outer_block $$;

/*
OUTPUT (Exercise 6.2):
NOTICE:  1. Outer before subblock: 579.75
NOTICE:  2. Subblock own fee_total: 263.25
NOTICE:  3. Outer fee_total via label: 579.75
NOTICE:  4. Outer after subblock: 579.75

QUESTION & ANSWER (Exercise 6.2):
Q: Write down the four numbers your block prints. Did the assignment inside the subblock change the outer variable? What does that tell you about the scope of a declaration?
A: Выведенные значения: 579.75, 263.25, 579.75, 579.75. Присваивание внутри подблока не изменило внешнюю переменную, потому что объявление fee_total NUMERIC внутри подблока создало отдельную локальную переменную, которая перекрыла (shadowed) внешнюю в пределах области видимости подблока.
*/


-- ------------------------------------------------------------
-- Exercise 6.3: Declarations are local
-- ------------------------------------------------------------
-- Step A: Broken version reading a variable declared in the first subblock from the second subblock (uncomment to reproduce error)
/*
DO $$
BEGIN
    DECLARE
        v_local_only INT := 42;
    BEGIN
        PERFORM v_local_only;
    END;

    BEGIN
        RAISE NOTICE 'Trying to read v_local_only: %', v_local_only;
    END;
END $$;
*/

-- Step B: Fixed version with declaration moved to the outer block
DO $$
DECLARE
    v_shared INT;
BEGIN
    BEGIN
        v_shared := 42;
        RAISE NOTICE 'First subblock set v_shared to %', v_shared;
    END;

    BEGIN
        RAISE NOTICE 'Second subblock reads v_shared as %', v_shared;
    END;
END $$;

/*
OUTPUT (Exercise 6.3):
Step A Error:
ERROR:  column "v_local_only" does not exist

Step B Notices:
NOTICE:  First subblock set v_shared to 42
NOTICE:  Second subblock reads v_shared as 42
*/


-- ------------------------------------------------------------
-- Exercise 6.4: From a block to a function
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO before_total
    FROM rentals
    WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0)
    INTO after_total
    FROM rentals
    WHERE start_date >= p_from_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');

SELECT
    s.before_total,
    s.after_total,
    s.before_total + s.after_total AS combined_total,
    (SELECT SUM(fee) FROM rentals) AS full_table_total
FROM fee_split(DATE '2025-01-01') AS s;

/*
OUTPUT (Exercise 6.4):
- SELECT * FROM fee_split(DATE '2025-01-01'); -> before_total = 316.50 | after_total = 263.25
- Verification query:
before_total | after_total | combined_total | full_table_total
-------------+-------------+----------------+-----------------
      316.50 |      263.25 |         579.75 |           579.75
*/


-- ============================================================
-- PART 7: PRACTICAL SCENARIOS
-- ============================================================

-- ------------------------------------------------------------
-- Exercise 7.1: Station occupancy
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT s.capacity
    INTO v_capacity
    FROM stations s
    WHERE s.station_id = p_station_id;

    SELECT COUNT(*)
    INTO bikes_parked
    FROM bikes b
    WHERE b.station_id = p_station_id;

    IF v_capacity IS NULL OR v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND((bikes_parked::NUMERIC / v_capacity::NUMERIC) * 100, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l
ORDER BY s.station_id;

/*
OUTPUT (Exercise 7.1):
station_id | station_name | bikes_parked | capacity_pct
-----------+--------------+--------------+-------------
        10 | Central Park |            3 |         75.0
        20 | Riverside    |            2 |         66.7
        30 | Expo Gate    |            2 |         40.0
        40 | Old Town     |            1 |         50.0
        50 | Depot        |            0 |         NULL

QUESTION & ANSWER (Exercise 7.1):
Q: Station 50 has a capacity of zero, so your function must not raise a division-by-zero error — decide what it should return instead and justify the choice.
A: Для станции 50 (capacity = 0) разумно вернуть capacity_pct = NULL, потому что процент заполнения при нулевой вместимости математически не определён и не должен искажать средние показатели как «0% заполненности».
*/


-- ------------------------------------------------------------
-- Exercise 7.2: Top members, with a default
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_count BIGINT,
    total_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.full_name,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(r.fee), 0) AS total_spent
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY total_spent DESC, m.member_id
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);

/*
OUTPUT (Exercise 7.2):
1) SELECT * FROM top_members();
member_name    | rental_count | total_spent
---------------+--------------+------------
Marta Kowalski |            5 |      164.75
Chen Wei       |            4 |      139.25
Daniyar Serik  |            4 |      138.00

2) SELECT * FROM top_members(6);
member_name     | rental_count | total_spent
----------------+--------------+------------
Marta Kowalski  |            5 |      164.75
Chen Wei        |            4 |      139.25
Daniyar Serik   |            4 |      138.00
Aisha Nurlanova |            5 |       98.50
Omar Haddad     |            4 |       81.00
Elena Petrova   |            0 |        0.00

QUESTION & ANSWER (Exercise 7.2):
Q: One member has more rentals than the member ranked above them, yet is ranked lower. Which member, and why is that not a bug?
A: Aisha Nurlanova имеет 5 аренд (включая открытую аренду 19 с fee = NULL), но у неё меньше потраченных денег (98.50), чем у участников с 4 арендами (Chen Wei — 139.25, Daniyar Serik — 138.00). Это не баг, потому что сортировка задана по сумме потраченных средств (total_spent DESC), а не по количеству аренд.
*/


-- ------------------------------------------------------------
-- Exercise 7.3: An invoice for an open rental
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    member_name VARCHAR,
    bike_model VARCHAR,
    days INT,
    amount_owed NUMERIC,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.full_name,
        b.model,
        (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT AS days,
        ROUND(
            ((COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::NUMERIC * b.daily_rate),
            2
        ) AS amount_owed,
        CASE
            WHEN r.end_date IS NULL THEN 'OPEN'
            ELSE 'CLOSED'
        END::VARCHAR AS status
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);

/*
OUTPUT (Exercise 7.3):
1) SELECT * FROM rental_invoice(11);
member_name    | bike_model  | days | amount_owed | status
---------------+-------------+------+-------------+-------
Marta Kowalski | Road Sprint |    8 |       74.00 | CLOSED

2) SELECT * FROM rental_invoice(19);
member_name     | bike_model   | days                        | amount_owed   | status
----------------+--------------+-----------------------------+---------------+-------
Aisha Nurlanova | City Cruiser | (CURRENT_DATE - 2025-10-10) | (days * 4.50) | OPEN

QUESTION & ANSWER (Exercise 7.3):
Q: For rental 11 the amount you calculate should equal the fee stored in the table. Does it? For rental 19 the amount is different every day the lab is run — explain why, and say whether a function that depends on CURRENT_DATE can be called immutable.
A: Для аренды 11 сумма совпадает сохранённой в таблице (74.00). Для аренды 19 (end_date IS NULL) длительность считается до CURRENT_DATE, поэтому каждый день увеличивается на 1 день и на 4.50 (daily_rate велосипеда 101). Такую функцию нельзя помечать как IMMUTABLE — она как минимум STABLE (так как CURRENT_DATE фиксируется в рамках транзакции/запроса, но меняется между разными днями/запросами).
*/


-- ------------------------------------------------------------
-- Exercise 7.4: A report per city
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT m.member_id) AS member_count,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(r.fee), 0) AS total_revenue
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT m.member_id) AS member_count,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(r.fee), 0) AS total_revenue
    FROM members m
    LEFT JOIN rentals r
        ON r.member_id = m.member_id
       AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');

/*
OUTPUT (Exercise 7.4):
1) SELECT * FROM city_report('Almaty');
member_count | rental_count | total_revenue
-------------+--------------+--------------
           3 |            9 |        236.50

2) SELECT * FROM city_report('Almaty', DATE '2025-01-01');
member_count | rental_count | total_revenue
-------------+--------------+--------------
           3 |            4 |         63.50

QUESTION & ANSWER (Exercise 7.4):
Q: Both versions need a LEFT JOIN. In the two-parameter version, does the date condition belong in the ON clause or in the WHERE clause? Try both and report the difference in the member count for Almaty.
A: Условие даты должно быть в ON, а не в WHERE. Если перенести r.start_date >= '2025-01-01' в WHERE, отфильтрованные строки rentals дадут NULL в правой части LEFT JOIN, и WHERE отбросит участников, у которых не было аренд с 2025-01-01 (в Алматы вместо 3 участников останется только 2). При условии в ON сохраняются все 3 участника из Алматы.
*/


-- ============================================================
-- LAB QUESTIONS (1 - 10)
-- ============================================================
/*
1. Имя и сигнатура функции; зачем нужна сигнатура при DROP FUNCTION:
   Имя функции — это только её идентификатор (например, total_fees), а сигнатура включает имя вместе с типами входных параметров (например, total_fees(integer, date)). PostgreSQL разрешает перегрузку, поэтому по одному имени может существовать несколько разных функций; DROP FUNCTION требует сигнатуру, чтобы однозначно удалить нужную версию без случайного удаления другой.

2. Назначение dollar quoting ($$):
   Позволяет задавать тело функции без экранирования обычных одинарных кавычек '...' внутри SQL-строк и блоков. Например, при проверке WHERE status = 'OPEN' внутри динамического SQL или вложенных строк без $$ пришлось бы удваивать/учетверять кавычки.

3. Когда выбирать OUT-параметры вместо RETURNS TABLE и наоборот:
   Несколько OUT-параметров удобны для возврата одной строки с фиксированным набором скалярных/агрегатных метрик (например, сводка по пользователю). RETURNS TABLE лучше подходит, когда функция возвращает набор строк/таблицу (например, список записей с RETURN QUERY).

4. Почему VARIADIC должен быть последним:
   Если бы после VARIADIC шли обычные параметры, при вызове вроде fn(1, 2, 3) было бы невозможно однозначно определить, какие аргументы относятся к массиву VARIADIC, а какие предназначены для последующих параметров.

5. Разница между RETURN и RETURN QUERY:
   RETURN <выражение> возвращает одно скалярное или составное значение (или завершает функцию с OUT/INOUT/возвратом строки), тогда как RETURN QUERY <SELECT> выполняет запрос и добавляет все его строки в результирующий набор функции (RETURNS TABLE или SETOF).

6. Почему DEFAULT-параметр может сломать существующий вызов и как этого избежать:
   Добавление параметра со значением по умолчанию делает функцию «видимой» при вызовах с меньшим числом аргументов, из-за чего возникает конфликт перегрузок (not unique). В продакшене стоит избегать перегрузок с пересекающимися арностями/типами, давать функциям явные имена или предварительно проверять все вызовы.

7. Что происходит с переменной подблока после его завершения и как прочитать перекрытую переменную внешнего блока:
   После выхода из подблока его локальные переменные уничтожаются и больше недоступны. Прочитать перекрытую переменную внешнего блока можно с помощью метки внешнего блока: <<outer_lbl>> ... outer_lbl.var_name.

8. Плюс и минус переноса бизнес-логики в хранимую функцию:
   Плюс — единая точка реализации правила и меньше сетевых обращений к БД. Минус — сложнее тестировать, версионировать и масштабировать вычислительную нагрузку на сервере БД.

9. Trusted (PL/pgSQL) vs Untrusted (PL/Python):
   PL/pgSQL работает в песочнице сервера БД и не имеет прямого доступа к файловой системе и сети ОС, поэтому создавать функции на нём могут обычные пользователи (с правами на схему). PL/Python может обращаться к ОС/сети/файлам, поэтому создавать функции на нём может только суперпользователь (superuser).

10. Что происходит при CREATE OR REPLACE FUNCTION с изменением типов аргументов:
   CREATE OR REPLACE не меняет сигнатуру существующей функции — если типы аргументов изменились, создаётся новая перегруженная функция, а старая остаётся в базе. Это приводит к появлению двух версий функции и возможным ошибкам неоднозначности при вызовах.
*/


-- ============================================================
-- ADDITIONAL CHALLENGES (OPTIONAL)
-- ============================================================

-- ------------------------------------------------------------
-- Challenge 1: busiest_station
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION busiest_station(p_from_date DATE DEFAULT DATE '2024-01-01')
RETURNS TABLE (
    station_id INT,
    station_name VARCHAR,
    total_rental_days BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.station_id,
        s.station_name,
        COALESCE(SUM(r.end_date - r.start_date), 0)::BIGINT AS total_rental_days
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    LEFT JOIN rentals r
        ON r.bike_id = b.bike_id
       AND r.start_date >= p_from_date
       AND r.end_date IS NOT NULL
    GROUP BY s.station_id, s.station_name
    ORDER BY total_rental_days DESC, s.station_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM busiest_station();

/*
OUTPUT (Challenge 1):
station_id | station_name | total_rental_days
-----------+--------------+------------------
        30 | Expo Gate    |                28
*/


-- ------------------------------------------------------------
-- Challenge 2: Loop over members with RAISE NOTICE vs single SELECT
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_member_activity()
RETURNS VOID AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT
            m.full_name,
            COUNT(r.rental_id) AS cnt,
            COALESCE(SUM(r.fee), 0) AS spent
        FROM members m
        LEFT JOIN rentals r ON r.member_id = m.member_id
        GROUP BY m.member_id, m.full_name
        ORDER BY m.member_id
    LOOP
        RAISE NOTICE 'Member: %, rentals: %, total spent: %',
            rec.full_name, rec.cnt, rec.spent;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT notify_member_activity();

/*
COMPARISON (Challenge 2):
Построчный цикл с RAISE NOTICE полезен только для логов/уведомлений в рамках сессии; в продакшене для получения данных лучше обычный SELECT с LEFT JOIN и GROUP BY (он декларативен, легче оптимизируется планировщиком и возвращает набор строк клиенту).
*/


-- ------------------------------------------------------------
-- Challenge 3: RAISE EXCEPTION in rental_days()
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION rental_days_strict(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT (end_date - start_date)
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rental with id % does not exist', p_rental_id;
    END IF;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

/*
ANSWER (Challenge 3):
Внутри большого запроса по таблице rentals это обычно не улучшение, а риск: любая случайно встреченная «невалидная» или отсутствующая ссылка сразу прервёт весь запрос откатом транзакции, тогда как NULL позволяет отфильтровать или обработать такие случаи в самом SQL.
*/


-- ------------------------------------------------------------
-- Challenge 4: Overloading fee_report(INT), fee_report(VARCHAR), and fee_report(TEXT)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fee_report(p_id INT)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((SELECT SUM(fee) FROM rentals WHERE member_id = p_id), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fee_report(p_name VARCHAR)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((
        SELECT SUM(r.fee)
        FROM rentals r
        JOIN members m ON m.member_id = r.member_id
        WHERE m.full_name = p_name
    ), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fee_report(p_text TEXT)
RETURNS NUMERIC AS $$
BEGIN
    RETURN fee_report(p_text::VARCHAR);
END;
$$ LANGUAGE plpgsql;

/*
ANSWER (Challenge 4):
В PostgreSQL VARCHAR и TEXT — разные типы, поэтому fee_report(TEXT) создаётся как третья перегрузка. Однако строковые литералы в SQL по умолчанию имеют тип unknown, который при разрешении перегрузок чаще приводится к text, из-за чего вызов вроде fee_report('Aisha Nurlanova') пойдёт в fee_report(TEXT) вместо fee_report(VARCHAR).
*/


-- ------------------------------------------------------------
-- Challenge 5: CREATE PROCEDURE and CALL to close an open rental
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE close_rental(
    p_rental_id INT,
    p_end_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_daily_rate NUMERIC(8,2);
    v_fee NUMERIC(8,2);
BEGIN
    SELECT r.start_date, r.end_date, b.daily_rate
    INTO v_start_date, v_end_date, v_daily_rate
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rental % not found', p_rental_id;
    END IF;

    IF v_end_date IS NOT NULL THEN
        RAISE EXCEPTION 'Rental % is already closed', p_rental_id;
    END IF;

    v_fee := ROUND(((p_end_date - v_start_date)::NUMERIC * v_daily_rate), 2);

    UPDATE rentals
    SET end_date = p_end_date,
        fee = v_fee
    WHERE rental_id = p_rental_id;
END;
$$;

-- Example call (kept commented so database data remains unchanged unless tested):
-- CALL close_rental(19, DATE '2025-10-15');

/*
ANSWER (Challenge 5):
Что умеет процедура (CREATE PROCEDURE + CALL), чего не умеет функция:
Процедура вызывается через CALL и в PostgreSQL поддерживает управление транзакциями (COMMIT и ROLLBACK внутри процедуры), а также предназначена именно для операций с побочными эффектами (изменение данных/обслуживание) без обязательного возвращаемого значения.
*/