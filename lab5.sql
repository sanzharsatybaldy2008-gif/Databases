-- ============================================================
-- Database Constraints - Laboratory Work 5

DROP TABLE IF EXISTS ecomm_order_details CASCADE;
DROP TABLE IF EXISTS ecomm_orders CASCADE;
DROP TABLE IF EXISTS ecomm_products CASCADE;
DROP TABLE IF EXISTS ecomm_customers CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS employees_dept CASCADE;
DROP TABLE IF EXISTS student_courses CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS course_enrollments CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS customers_part2 CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS products_catalog CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

-- ============================================================
-- PART 1: CHECK constraints
-- Task 1.1: Create tables with CHECK constraints.
-- ============================================================

CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT valid_dates CHECK (check_out_date > check_in_date)
);

-- Valid test data: at least two valid rows per CHECK table.
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (1, 'Alice', 'Smith', 30, 55000.00);
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (2, 'Bob', 'Jones', 45, 72000.50);

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (101, 'Laptop', 1200.00, 999.99);
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (102, 'Headphones', 150.00, 120.00);

INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (1001, '2026-07-01', '2026-07-07', 2);
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (1002, '2026-08-10', '2026-08-15', 4);

-- Failed CHECK tests (intentionally commented out).
-- Expected failure: age must be between 18 and 65.
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary)
-- VALUES (3, 'Charlie', 'Brown', 16, 40000.00);

-- Expected failure: salary must be greater than zero.
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary)
-- VALUES (4, 'Diana', 'Prince', 30, -500.00);

-- Expected failure: discount_price must be lower than regular_price.
-- INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
-- VALUES (103, 'Smartphone', 500.00, 600.00);

-- Expected failure: number of guests must be between 1 and 10.
-- INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
-- VALUES (1003, '2026-09-01', '2026-09-05', 12);

-- Expected failure: check-out date must be later than check-in date.
-- INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
-- VALUES (1004, '2026-09-05', '2026-09-01', 2);

-- ============================================================
-- PART 2: NOT NULL constraints
-- Task 2.1: Require values in specified columns.
-- ============================================================

CREATE TABLE customers_part2 (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO customers_part2 (customer_id, email, phone, registration_date)
VALUES (1, 'john@example.com', '555-0100', '2026-01-15');
INSERT INTO customers_part2 (customer_id, email, phone, registration_date)
VALUES (2, 'jane@example.com', NULL, '2026-02-20');
INSERT INTO customers_part2 (customer_id, email, phone, registration_date)
VALUES (4, 'sarah@example.com', NULL, '2026-04-10');

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (1, 'Office Chair', 50, 120.50, CURRENT_TIMESTAMP);
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (2, 'Desk Lamp', 0, 25.00, CURRENT_TIMESTAMP);

-- Failed NOT NULL tests (intentionally commented out).
-- Expected failure: email cannot be NULL.
-- INSERT INTO customers_part2 (customer_id, email, phone, registration_date)
-- VALUES (3, NULL, '555-9876', '2026-03-01');

-- Expected failure: item_name cannot be NULL.
-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
-- VALUES (3, NULL, 10, 15.50, CURRENT_TIMESTAMP);

-- Expected failure: last_updated cannot be NULL.
-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
-- VALUES (4, 'Keyboard', 10, 30.00, NULL);

-- ============================================================
-- PART 3: UNIQUE constraints
-- Task 3.1: Single-column and composite UNIQUE constraints.
-- ============================================================

CREATE TABLE users (
    user_id INTEGER,
    username TEXT CONSTRAINT unique_username UNIQUE,
    email TEXT CONSTRAINT unique_email UNIQUE,
    created_at TIMESTAMP
);

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_student_course_semester
        UNIQUE (student_id, course_code, semester)
);

INSERT INTO users (user_id, username, email, created_at)
VALUES (1, 'johndoe', 'john@mail.com', CURRENT_TIMESTAMP);
INSERT INTO users (user_id, username, email, created_at)
VALUES (2, 'janedoe', 'jane@mail.com', CURRENT_TIMESTAMP);

INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester)
VALUES (1, 101, 'CS101', 'Fall2026');
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester)
VALUES (2, 101, 'CS102', 'Fall2026');
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester)
VALUES (3, 102, 'CS101', 'Fall2026');

-- Failed UNIQUE tests (intentionally commented out).
-- Expected failure: username already exists.
-- INSERT INTO users (user_id, username, email, created_at)
-- VALUES (3, 'johndoe', 'another@mail.com', CURRENT_TIMESTAMP);

-- Expected failure: email already exists.
-- INSERT INTO users (user_id, username, email, created_at)
-- VALUES (4, 'otheruser', 'john@mail.com', CURRENT_TIMESTAMP);

-- Expected failure: this student/course/semester combination already exists.
-- INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester)
-- VALUES (4, 101, 'CS101', 'Fall2026');

-- ============================================================
-- PART 4: PRIMARY KEY constraints
-- Task 4.1: Single-column and composite primary keys.
-- ============================================================

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments (dept_id, dept_name, location)
VALUES (10, 'Human Resources', 'Building A');
INSERT INTO departments (dept_id, dept_name, location)
VALUES (20, 'Engineering', 'Building B');
INSERT INTO departments (dept_id, dept_name, location)
VALUES (30, 'Sales', 'Building C');

-- Failed PRIMARY KEY tests (intentionally commented out).
-- Expected failure: dept_id 10 already exists.
-- INSERT INTO departments (dept_id, dept_name, location)
-- VALUES (10, 'Sales Duplicate', 'Building D');

-- Expected failure: a PRIMARY KEY cannot be NULL.
-- INSERT INTO departments (dept_id, dept_name, location)
-- VALUES (NULL, 'Finance', 'Building E');

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses (student_id, course_id, enrollment_date, grade)
VALUES (101, 1, '2026-09-01', 'A');
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade)
VALUES (101, 2, '2026-09-02', 'B');
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade)
VALUES (102, 1, '2026-09-03', 'A');

-- Expected failure: the composite primary-key pair already exists.
-- INSERT INTO student_courses (student_id, course_id, enrollment_date, grade)
-- VALUES (101, 1, '2026-09-10', 'C');

-- ============================================================
-- PART 5: FOREIGN KEY constraints and ON DELETE behavior
-- Task 5.1: Foreign keys, RESTRICT, and CASCADE.
-- ============================================================

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (1, 'Sarah Connor', 10, '2025-05-10');
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (2, 'John Connor', 20, '2025-06-15');

-- Expected failure: department 999 does not exist.
-- INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
-- VALUES (3, 'Invalid Department Employee', 999, '2025-07-01');

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors (author_id, author_name, country)
VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO authors (author_id, author_name, country)
VALUES (2, 'George Orwell', 'UK');

INSERT INTO publishers (publisher_id, publisher_name, city)
VALUES (1, 'Bloomsbury', 'London');
INSERT INTO publishers (publisher_id, publisher_name, city)
VALUES (2, 'Secker & Warburg', 'London');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn)
VALUES (1, 'Harry Potter', 1, 1, 1997, '978-0747532699');
INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn)
VALUES (2, '1984', 2, 2, 1949, '978-0451524935');

-- Expected failure: author_id 999 does not exist.
-- INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn)
-- VALUES (3, 'Unknown Author Book', 999, 1, 2026, '978-0000000000');

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories (category_id, category_name)
VALUES (1, 'Electronics');
INSERT INTO products_fk (product_id, product_name, category_id)
VALUES (101, 'Smartphone', 1);

INSERT INTO orders (order_id, order_date)
VALUES (500, '2026-10-01');
INSERT INTO order_items (item_id, order_id, product_id, quantity)
VALUES (1001, 500, 101, 2);

-- Expected failure: category 1 is referenced by product 101 (RESTRICT).
-- DELETE FROM categories WHERE category_id = 1;

-- Demonstration of CASCADE, intentionally commented out because it deletes data.
-- If executed, this removes order 500 and its related order_items row(s).
-- DELETE FROM orders WHERE order_id = 500;

-- ============================================================
-- PART 6: Complete e-commerce schema
-- Task 6.1: Combine primary keys, foreign keys, NOT NULL, UNIQUE,
-- CHECK constraints, and ON DELETE actions.
-- ============================================================

CREATE TABLE ecomm_customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE ecomm_products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE ecomm_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES ecomm_customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (
        status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
    )
);

CREATE TABLE ecomm_order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES ecomm_orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecomm_products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Sample e-commerce customers.
INSERT INTO ecomm_customers (customer_id, name, email, phone, registration_date)
VALUES (1, 'Alice Smith', 'alice@mail.com', '555-1111', '2026-01-01');
INSERT INTO ecomm_customers (customer_id, name, email, phone, registration_date)
VALUES (2, 'Bob Jones', 'bob@mail.com', '555-2222', '2026-01-05');
INSERT INTO ecomm_customers (customer_id, name, email, phone, registration_date)
VALUES (3, 'Charlie Brown', 'charlie@mail.com', NULL, '2026-02-10');
INSERT INTO ecomm_customers (customer_id, name, email, phone, registration_date)
VALUES (4, 'Diana Prince', 'diana@mail.com', '555-4444', '2026-03-12');
INSERT INTO ecomm_customers (customer_id, name, email, phone, registration_date)
VALUES (5, 'Ethan Hunt', 'ethan@mail.com', '555-5555', '2026-04-01');

-- Sample e-commerce products.
INSERT INTO ecomm_products (product_id, name, description, price, stock_quantity)
VALUES (1, 'Wireless Mouse', 'Ergonomic optical mouse', 25.99, 150);
INSERT INTO ecomm_products (product_id, name, description, price, stock_quantity)
VALUES (2, 'Mechanical Keyboard', 'RGB backlit keyboard', 79.99, 80);
INSERT INTO ecomm_products (product_id, name, description, price, stock_quantity)
VALUES (3, 'Monitor 27 inch', '4K UHD IPS monitor', 349.99, 30);
INSERT INTO ecomm_products (product_id, name, description, price, stock_quantity)
VALUES (4, 'USB-C Hub', 'Multiport adapter', 45.00, 200);
INSERT INTO ecomm_products (product_id, name, description, price, stock_quantity)
VALUES (5, 'External SSD 1TB', 'High-speed portable SSD', 119.99, 65);

-- Sample orders. Each customer_id must exist in ecomm_customers.
INSERT INTO ecomm_orders (order_id, customer_id, order_date, total_amount, status)
VALUES (101, 1, '2026-05-01', 105.98, 'delivered');
INSERT INTO ecomm_orders (order_id, customer_id, order_date, total_amount, status)
VALUES (102, 2, '2026-06-03', 349.99, 'shipped');
INSERT INTO ecomm_orders (order_id, customer_id, order_date, total_amount, status)
VALUES (103, 3, '2026-07-15', 70.99, 'processing');
INSERT INTO ecomm_orders (order_id, customer_id, order_date, total_amount, status)
VALUES (104, 4, '2026-08-20', 119.99, 'pending');
INSERT INTO ecomm_orders (order_id, customer_id, order_date, total_amount, status)
VALUES (105, 5, '2026-09-10', 45.00, 'cancelled');

-- Sample order details. Order and product IDs must exist.
INSERT INTO ecomm_order_details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (1, 101, 1, 1, 25.99);
INSERT INTO ecomm_order_details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (2, 101, 2, 1, 79.99);
INSERT INTO ecomm_order_details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (3, 102, 3, 1, 349.99);
INSERT INTO ecomm_order_details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (4, 103, 1, 1, 25.99);
INSERT INTO ecomm_order_details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (5, 103, 4, 1, 45.00);

-- Failed e-commerce constraint tests (intentionally commented out).
-- Expected failure: duplicate email violates UNIQUE.
-- INSERT INTO ecomm_customers (customer_id, name, email, phone, registration_date)
-- VALUES (6, 'Another Alice', 'alice@mail.com', NULL, '2026-10-01');

-- Expected failure: negative product price violates CHECK (price >= 0).
-- INSERT INTO ecomm_products (product_id, name, description, price, stock_quantity)
-- VALUES (6, 'Invalid Product', 'Test', -1.00, 10);

-- Expected failure: invalid status is not in the allowed list.
-- INSERT INTO ecomm_orders (order_id, customer_id, order_date, total_amount, status)
-- VALUES (106, 1, '2026-10-02', 10.00, 'unknown');

-- Expected failure: quantity must be greater than zero.
-- INSERT INTO ecomm_order_details (order_detail_id, order_id, product_id, quantity, unit_price)
-- VALUES (6, 101, 1, 0, 25.99);

-- Expected failure: product cannot be deleted while order details reference it (RESTRICT).
-- DELETE FROM ecomm_products WHERE product_id = 1;

-- ============================================================
-- FINAL VERIFICATION: these SELECT statements should execute.
-- They show sample rows from each part of the lab.
-- ============================================================

SELECT * FROM employees ORDER BY employee_id;
SELECT * FROM products_catalog ORDER BY product_id;
SELECT * FROM bookings ORDER BY booking_id;
SELECT * FROM customers_part2 ORDER BY customer_id;
SELECT * FROM inventory ORDER BY item_id;
SELECT * FROM users ORDER BY user_id;
SELECT * FROM course_enrollments ORDER BY enrollment_id;
SELECT * FROM departments ORDER BY dept_id;
SELECT * FROM student_courses ORDER BY student_id, course_id;
SELECT * FROM employees_dept ORDER BY emp_id;
SELECT * FROM books ORDER BY book_id;
SELECT * FROM order_items ORDER BY item_id;
SELECT * FROM ecomm_customers ORDER BY customer_id;
SELECT * FROM ecomm_products ORDER BY product_id;
SELECT * FROM ecomm_orders ORDER BY order_id;
SELECT * FROM ecomm_order_details ORDER BY order_detail_id;


