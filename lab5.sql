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
-- Task 1.1
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
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
        )
);

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT valid_dates CHECK (check_out_date > check_in_date)
);

INSERT INTO employees VALUES (1, 'Alice', 'Smith', 30, 55000.00);
INSERT INTO employees VALUES (2, 'Bob', 'Jones', 45, 72000.50);

INSERT INTO products_catalog VALUES (101, 'Laptop', 1200.00, 999.99);
INSERT INTO products_catalog VALUES (102, 'Headphones', 150.00, 120.00);

INSERT INTO bookings VALUES (1001, '2026-07-01', '2026-07-07', 2);
INSERT INTO bookings VALUES (1002, '2026-08-10', '2026-08-15', 4);
-- 2. Failed Inserts (Commented out)
-- Violates age check (must be between 18 and 65)
-- INSERT INTO employees (first_name, last_name, age, salary) VALUES ('Charlie', 'Brown', 16, 40000.00);
-- Violation Reason: age 16 is less than the minimum allowed value of 18.

-- Violates salary check (must be > 0)
-- INSERT INTO employees (first_name, last_name, age, salary) VALUES ('Diana', 'Prince', 30, -500.00);
-- Violation Reason: salary -500.00 violates the CHECK constraint (salary > 0).

-- Violates named constraint 'valid_discount' (discount_price must be less than regular_price)
-- INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Smartphone', 500.00, 600.00);
-- Violation Reason: discount_price (600.00) is greater than regular_price (500.00), violating 'valid_discount'.

-- Violates guests check (num_guests between 1 and 10)
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2026-09-01', '2026-09-05', 12);
-- Violation Reason: num_guests 12 exceeds the maximum allowed value of 10.

-- Violates date check (check_out_date must be after check_in_date)
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2026-09-05', '2026-09-01', 2);
-- Violation Reason: check_out_date is prior to check_in_date, violating 'valid_dates'.
-- Task 2.1
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

INSERT INTO inventory VALUES (1, 'Office Chair', 50, 120.50, CURRENT_TIMESTAMP);
INSERT INTO inventory VALUES (2, 'Desk Lamp', 0, 25.00, CURRENT_TIMESTAMP);

INSERT INTO customers_part2 VALUES (4, 'sarah@example.com', NULL, '2026-04-10');
-- 2. Failed inserts with NULL in NOT NULL columns (Commented out)
-- INSERT INTO customers_part2 (customer_id, email, phone, registration_date)
-- VALUES (3, NULL, '555-9876', '2026-03-01');
-- Violation Reason: email column has a NOT NULL constraint and cannot accept NULL.

-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
-- VALUES (102, NULL, 10, 15.50, CURRENT_TIMESTAMP);
-- Violation Reason: item_name cannot be NULL.
-- Task 3.1
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
    CONSTRAINT unique_student_course_semester UNIQUE (student_id, course_code, semester)
);

INSERT INTO users VALUES (1, 'johndoe', 'john@mail.com', CURRENT_TIMESTAMP);
INSERT INTO course_enrollments VALUES (1, 101, 'CS101', 'Fall2026');
-- Task 4.1:
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (10, 'Human Resources', 'Building A');
INSERT INTO departments VALUES (20, 'Engineering', 'Building B');
INSERT INTO departments VALUES (30, 'Sales', 'Building C');
-- Duplicate Primary Key Test (Commented out)
-- INSERT INTO departments (dept_id, dept_name, location) VALUES (10, 'Sales', 'Building D');
-- Violation Reason: dept_id 10 already exists. Primary keys must be unique.

-- NULL Primary Key Test (Commented out)
-- INSERT INTO departments (dept_id, dept_name, location) VALUES (NULL, 'Finance', 'Building E');
-- Violation Reason: Primary key columns implicitly enforce NOT NULL.
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);
-- Task 5.1
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Sarah Connor', 10, '2025-05-10');
INSERT INTO employees_dept VALUES (2, 'John Connor', 20, '2025-06-15');

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
INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO authors VALUES (2, 'George Orwell', 'UK');

INSERT INTO publishers VALUES (1, 'Bloomsbury', 'London');
INSERT INTO publishers VALUES (2, 'Secker & Warburg', 'London');

INSERT INTO books VALUES (1, 'Harry Potter', 1, 1, 1997, '978-0747532699');
INSERT INTO books VALUES (2, '1984', 2, 2, 1949, '978-0451524935');

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

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO products_fk VALUES (101, 'Smartphone', 1);

INSERT INTO orders VALUES (500, '2026-10-01');
INSERT INTO order_items VALUES (1001, 500, 101, 2);

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
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE ecomm_order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES ecomm_orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecomm_products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO ecomm_customers VALUES (1, 'Alice Smith', 'alice@mail.com', '555-1111', '2026-01-01');
INSERT INTO ecomm_customers VALUES (2, 'Bob Jones', 'bob@mail.com', '555-2222', '2026-01-05');
INSERT INTO ecomm_customers VALUES (3, 'Charlie Brown', 'charlie@mail.com', NULL, '2026-02-10');
INSERT INTO ecomm_customers VALUES (4, 'Diana Prince', 'diana@mail.com', '555-4444', '2026-03-12');
INSERT INTO ecomm_customers VALUES (5, 'Ethan Hunt', 'ethan@mail.com', '555-5555', '2026-04-01');

INSERT INTO ecomm_products VALUES (1, 'Wireless Mouse', 'Ergonomic optical mouse', 25.99, 150);
INSERT INTO ecomm_products VALUES (2, 'Mechanical Keyboard', 'RGB backlit keyboard', 79.99, 80);
INSERT INTO ecomm_products VALUES (3, 'Monitor 27"', '4K UHD IPS monitor', 349.99, 30);
INSERT INTO ecomm_products VALUES (4, 'USB-C Hub', 'Multiport adapter', 45.00, 200);
INSERT INTO ecomm_products VALUES (5, 'External SSD 1TB', 'High-speed portable SSD', 119.99, 65);

INSERT INTO ecomm_orders VALUES (101, 1, '2026-05-01', 105.98, 'delivered');
INSERT INTO ecomm_orders VALUES (102, 2, '2026-06-03', 349.99, 'shipped');
INSERT INTO ecomm_orders VALUES (103, 3, '2026-07-15', 70.99, 'processing');
INSERT INTO ecomm_orders VALUES (104, 4, '2026-08-20', 119.99, 'pending');
INSERT INTO ecomm_orders VALUES (105, 5, '2026-09-10', 45.00, 'cancelled');

INSERT INTO ecomm_order_details VALUES (1, 101, 1, 1, 25.99);
INSERT INTO ecomm_order_details VALUES (2, 101, 2, 1, 79.99);
INSERT INTO ecomm_order_details VALUES (3, 102, 3, 1, 349.99);
INSERT INTO ecomm_order_details VALUES (4, 103, 1, 1, 25.99);
INSERT INTO ecomm_order_details VALUES (5, 103, 4, 1, 45.00);