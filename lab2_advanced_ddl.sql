-- ============================================================
-- LABORATORY WORK #2
-- Advanced DDL Operations
-- Parts 1-4
-- PostgreSQL
-- ============================================================


-- ============================================================
-- PART 1: Multiple Database Management
-- ============================================================

-- Task 1.1.1
DROP DATABASE IF EXISTS
university_main;
CREATE DATABASE university_main
WITH
    OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8';


-- Task 1.1.2
CREATE DATABASE university_archive
WITH
    CONNECTION LIMIT = 50
    TEMPLATE = template0;


-- Task 1.1.3
CREATE DATABASE university_test
WITH
    CONNECTION LIMIT = 10
    IS_TEMPLATE = true;


-- ============================================================
-- Task 1.2: Tablespace Operations
-- ============================================================

-- Task 1.2.1
CREATE TABLESPACE student_data
LOCATION 'C:/data/students';


-- Task 1.2.2
CREATE TABLESPACE course_data
OWNER postgres
LOCATION 'C:/data/courses';


-- Task 1.2.3
CREATE DATABASE university_distributed
WITH
    TEMPLATE=template0
    TABLESPACE = student_data
    ENCODING='LATIN9';

-- ============================================================
-- IMPORTANT:
-- After Part 1, connect DataGrip to university_main
-- before executing Parts 2-4.
-- ============================================================


-- ============================================================
-- PART 2: Complex Table Creation
-- ============================================================

-- Task 2.1.1
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(3,2),
    is_active BOOLEAN,
    graduation_year SMALLINT
);


-- Task 2.1.2
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(12,2),
    is_tenured BOOLEAN,
    years_experience INTEGER
);


-- Task 2.1.3
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT,
    max_enrollment INTEGER,
    course_fee NUMERIC(10,2),
    is_online BOOLEAN,
    created_at TIMESTAMP WITHOUT TIME ZONE
);


-- ============================================================
-- Task 2.2
-- ============================================================

-- Task 2.2.1
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INTEGER,
    professor_id INTEGER,
    classroom VARCHAR(20),
    class_date DATE,
    start_time TIME WITHOUT TIME ZONE,
    end_time TIME WITHOUT TIME ZONE,
    duration INTERVAL
);


-- Task 2.2.2
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    course_id INTEGER,
    semester VARCHAR(20),
    year INTEGER,
    grade CHAR(2),
    attendance_percentage NUMERIC(4,1),
    submission_timestamp TIMESTAMP WITH TIME ZONE,
    last_updated TIMESTAMP WITH TIME ZONE
);


-- ============================================================
-- PART 3: Advanced ALTER TABLE Operations
-- ============================================================

-- ============================================================
-- Task 3.1 - students
-- ============================================================

ALTER TABLE students
ADD COLUMN middle_name VARCHAR(30);

ALTER TABLE students
ADD COLUMN student_status VARCHAR(20);

ALTER TABLE students
ALTER COLUMN phone TYPE VARCHAR(20);

ALTER TABLE students
ALTER COLUMN student_status SET DEFAULT 'ACTIVE';

ALTER TABLE students
ALTER COLUMN gpa SET DEFAULT 0.00;


-- ============================================================
-- Task 3.1 - professors
-- ============================================================

ALTER TABLE professors
ADD COLUMN department_code CHAR(5);

ALTER TABLE professors
ADD COLUMN research_area TEXT;

ALTER TABLE professors
ALTER COLUMN years_experience TYPE SMALLINT;

ALTER TABLE professors
ALTER COLUMN is_tenured SET DEFAULT false;

ALTER TABLE professors
ADD COLUMN last_promotion_date DATE;


-- ============================================================
-- Task 3.1 - courses
-- ============================================================

ALTER TABLE courses
ADD COLUMN prerequisite_course_id INTEGER;

ALTER TABLE courses
ADD COLUMN difficulty_level SMALLINT;

ALTER TABLE courses
ALTER COLUMN course_code TYPE VARCHAR(10);

ALTER TABLE courses
ALTER COLUMN credits SET DEFAULT 3;

ALTER TABLE courses
ADD COLUMN lab_required BOOLEAN DEFAULT false;


-- ============================================================
-- Task 3.2 - class_schedule
-- ============================================================

ALTER TABLE class_schedule
ADD COLUMN room_capacity INTEGER;

ALTER TABLE class_schedule
DROP COLUMN duration;

ALTER TABLE class_schedule
ADD COLUMN session_type VARCHAR(15);

ALTER TABLE class_schedule
ALTER COLUMN classroom TYPE VARCHAR(30);

ALTER TABLE class_schedule
ADD COLUMN equipment_needed TEXT;


-- ============================================================
-- Task 3.2 - student_records
-- ============================================================

ALTER TABLE student_records
ADD COLUMN extra_credit_points NUMERIC(3,1);

ALTER TABLE student_records
ALTER COLUMN grade TYPE VARCHAR(5);

ALTER TABLE student_records
ALTER COLUMN extra_credit_points SET DEFAULT 0.0;

ALTER TABLE student_records
ADD COLUMN final_exam_date DATE;

ALTER TABLE student_records
DROP COLUMN last_updated;


-- ============================================================
-- PART 4: Table Relationships and Management
-- ============================================================

-- ============================================================
-- Task 4.1.1 - departments
-- ============================================================

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(15,2),
    established_year INTEGER
);


-- ============================================================
-- Task 4.1.2 - library_books
-- ============================================================

CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),
    title VARCHAR(200),
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(10,2),
    is_available BOOLEAN,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE
);


-- ============================================================
-- Task 4.1.3 - student_book_loans
-- ============================================================

CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    book_id INTEGER,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount NUMERIC(10,2),
    loan_status VARCHAR(20)
);


-- ============================================================
-- Task 4.2.1
-- Add columns only - no foreign key relationships yet
-- ============================================================

ALTER TABLE professors
ADD COLUMN department_id INTEGER;

ALTER TABLE students
ADD COLUMN advisor_id INTEGER;

ALTER TABLE courses
ADD COLUMN department_id INTEGER;


-- ============================================================
-- Task 4.2.2 - grade_scale
-- ============================================================

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2)
);


-- ============================================================
-- Task 4.2.3 - semester_calendar
-- ============================================================

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN
);


-- PART 5
-- ============================================================

-- Task 5.1: Conditional Table Operations
-- ============================================================

-- 5.1.1
DROP TABLE IF EXISTS student_book_loans;

DROP TABLE IF EXISTS library_books;

DROP TABLE IF EXISTS grade_scale;


-- ============================================================
-- 5.1.2
-- Recreate grade_scale with additional description column
-- ============================================================

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2),
    description TEXT
);


-- ============================================================
-- 5.1.3
-- Drop semester_calendar with CASCADE
-- ============================================================

DROP TABLE IF EXISTS semester_calendar CASCADE;


-- Recreate semester_calendar with the same structure

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN
);


-- ============================================================
-- Task 5.2: Database Cleanup
-- ============================================================

-- 5.2.1
-- Drop university_test database if it exists

DROP DATABASE IF EXISTS university_test;


-- Drop university_distributed database if it exists

DROP DATABASE IF EXISTS university_distributed;


-- ============================================================
-- 5.2.2
-- Create university_backup using university_main as template
-- ============================================================

CREATE DATABASE university_backup
WITH
    TEMPLATE = university_main;
