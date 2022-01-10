-- Employee

SELECT 
  *
FROM employees.employee
LIMIT 10;

SELECT 
  COUNT(*)
FROM employees.employee;


SELECT 
  DISTINCT
  COUNT(*)
FROM employees.employee;


-- Title 

SELECT 
  *
FROM employees.title
LIMIT 10;


SELECT
  employee_id,
  COUNT(*)
FROM employees.title
GROUP BY 1
ORDER BY 2 DESC;


-- Salary 

SELECT 
  *
FROM employees.salary
LIMIT 10;


SELECT 
  employee_id,
  COUNT(*)
FROM employees.salary
GROUP BY 1
ORDER BY 2 DESC;


-- Department employee 

SELECT 
  *
FROM employees.department_employee
LIMIT 10;


SELECT 
  employee_id,
  COUNT(*)
FROM employees.department_employee
GROUP BY 1
ORDER BY 2 DESC;


SELECT 
  employee_id,
  COUNT(DISTINCT department_id)
FROM employees.department_employee
WHERE employee_id = 62121
GROUP BY 1;

SELECT 
  *
FROM employees.department_employee
WHERE employee_id = 10029;


-- Department manager 

SELECT 
  *
FROM employees.department_manager
LIMIT 10;


SELECT 
  employee_id,
  COUNT(*)
FROM employees.department_manager
GROUP BY 1
ORDER BY 2 DESC;

SELECT 
  department_id,
  COUNT(*)
FROM employees.department_manager
GROUP BY 1
ORDER BY 2 DESC;

SELECT 
  *
FROM employees.department_manager
WHERE department_id = 'd009';


-- Department 

SELECT 
  *
FROM employees.department
LIMIT 10;

SELECT 
  COUNT(*)
FROM employees.department;


-- Creating Temp tables for all

-- employee
DROP TABLE IF EXISTS temp_employee;
CREATE TABLE temp_employee AS
SELECT * FROM employees.employee;

-- temp department employee
DROP TABLE IF EXISTS temp_department;
CREATE TEMP TABLE temp_department AS
SELECT * FROM employees.department;

-- temp department employee
DROP TABLE IF EXISTS temp_department_employee;
CREATE TEMP TABLE temp_department_employee AS
SELECT * FROM employees.department_employee;

-- department manager
DROP TABLE IF EXISTS temp_department_manager;
CREATE TEMP TABLE temp_department_manager AS
SELECT * FROM employees.department_manager;

-- salary
DROP TABLE IF EXISTS temp_salary;
CREATE TEMP TABLE temp_salary AS
SELECT * FROM employees.salary;

-- title
DROP TABLE IF EXISTS temp_title;
CREATE TEMP TABLE temp_title AS
SELECT * FROM employees.title;


-- Updating hire dates 

SELECT 
  *
FROM temp_employee
LIMIT 10;

SELECT 
  *
FROM temp_employee
WHERE hire_date = '99'
LIMIT 10;



-- Creating views 

DROP SCHEMA IF EXISTS v_employees CASCADE;
CREATE SCHEMA v_employees;


-- department 

DROP VIEW IF EXISTS v_employees.department;
CREATE VIEW v_employees.department AS 
SELECT 
  *
FROM employees.department;


--department employee 

select * from employees.department_employee;

DROP VIEW IF EXISTS v_employees.department_employee;
CREATE VIEW v_employees.department_employee AS 
SELECT 
  employee_id,
  department_id,
  from_date + interval '18 years' as from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date 
    END AS to_date
FROM employees.department_employee;


-- department_manager 

SELECT 
  *
FROM employees.department_manager
LIMIT 10;

DROP VIEW IF EXISTS v_employees.department_manager;
CREATE VIEW v_employees.department_manager AS 
SELECT 
  employee_id,
  department_id,
  from_date + interval '18 years' as from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date 
    END AS to_date
FROM employees.department_manager;


-- employee 

SELECT 
  *
FROM employees.employee
LIMIT 10;


SELECT 
  *
FROM employees.employee
WHERE birth_date = '9999-01-01';


DROP VIEW IF EXISTS v_employees.employee;
CREATE VIEW v_employees.employee AS 
SELECT 
  id,
  birth_date + interval '18 years' as birth_date,
  first_name,
  last_name,
  gender,
  hire_date + interval '18 years' as hire_date
FROM employees.employee;


-- salary 

SELECT 
  *
FROM employees.salary
LIMIT 10;


SELECT 
  *
FROM employees.salary
WHERE to_date = '9999-01-01'
LIMIT 10;


DROP VIEW IF EXISTS v_employees.salary;
CREATE VIEW v_employees.salary AS 
SELECT 
  employee_id,
  amount,
  from_date + interval '18 years' AS from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years' 
    ELSE to_date 
    END AS to_date
FROM employees.salary;


-- title 

SELECT 
  *
FROM employees.title
LIMIT 10;

DROP VIEW IF EXISTS v_employees.title;
CREATE VIEW v_employees.title AS 
SELECT 
  employee_id,
  title,
  from_date + interval '18 years' AS from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years' 
    ELSE to_date 
    END AS to_date
FROM employees.title;


-- Normal select

SELECT 
  *
FROM v_employees.salary
WHERE employee_id = 10001
ORDER BY from_date DESC
LIMIT 5;


-- Creating materialised views 

DROP TABLE IF EXISTS georgi_salary CASCADE;
CREATE TABLE georgi_salary AS 
SELECT 
  *
FROM employees.salary
WHERE employee_id = 10001;


DROP MATERIALIZED VIEW IF EXISTS v_employees.georgi_salary;
CREATE MATERIALIZED VIEW v_employees.georgi_salary AS 
SELECT 
  employee_id,
  amount,
  from_date + interval '18 years' AS from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years' 
    ELSE to_date 
    END AS to_date
FROM georgi_salary;


SELECT 
  *
FROM georgi_salary;


-- Update georgi's salary 

UPDATE georgi_salary
SET to_date = '2003-01-01'
WHERE to_date = '9999-01-01';


INSERT INTO georgi_salary(employee_id, amount, from_date, to_date)
VALUES(10001, 95000, '2003-01-01','9999-01-01');


SELECT
  *
FROM v_employees.georgi_salary
WHERE employee_id = 10001
ORDER BY from_date DESC
LIMIT 5;


REFRESH MATERIALIZED VIEW v_employees.georgi_salary;


SELECT
  *
FROM v_employees.georgi_salary
WHERE employee_id = 10001
ORDER BY from_date DESC
LIMIT 5;


-- Creating Materialized views 


-- Creating m_views 

DROP SCHEMA IF EXISTS mv_employees CASCADE;
CREATE SCHEMA mv_employees;


-- department 

DROP MATERIALIZED VIEW IF EXISTS mv_employees.department;
CREATE MATERIALIZED VIEW mv_employees.department AS 
SELECT 
  *
FROM employees.department;


select * from mv_employees.department limit 10;

--department employee 

select * from employees.department_employee;

DROP MATERIALIZED VIEW IF EXISTS mv_employees.department_employee;
CREATE MATERIALIZED VIEW mv_employees.department_employee AS 
SELECT 
  employee_id,
  department_id,
  (from_date + interval '18 years')::DATE as from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN (to_date + interval '18 years')::DATE
    ELSE to_date 
    END AS to_date
FROM employees.department_employee;


-- department_manager 

SELECT 
  *
FROM employees.department_manager
LIMIT 10;

DROP MATERIALIZED VIEW IF EXISTS mv_employees.department_manager;
CREATE MATERIALIZED VIEW mv_employees.department_manager AS 
SELECT 
  employee_id,
  department_id,
  (from_date + interval '18 years')::DATE as from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN (to_date + interval '18 years')::DATE
    ELSE to_date 
    END AS to_date
FROM employees.department_manager;


-- employee 

SELECT 
  *
FROM employees.employee
LIMIT 10;


SELECT 
  *
FROM employees.employee
WHERE birth_date = '9999-01-01';


DROP MATERIALIZED VIEW IF EXISTS mv_employees.employee;
CREATE MATERIALIZED VIEW mv_employees.employee AS 
SELECT 
  id,
  (birth_date + interval '18 years')::DATE as birth_date,
  first_name,
  last_name,
  gender,
  (hire_date + interval '18 years')::DATE as hire_date
FROM employees.employee;


-- salary 

SELECT 
  *
FROM employees.salary
LIMIT 10;


SELECT 
  *
FROM employees.salary
WHERE to_date = '9999-01-01'
LIMIT 10;


DROP MATERIALIZED VIEW IF EXISTS mv_employees.salary;
CREATE MATERIALIZED VIEW mv_employees.salary AS 
SELECT 
  employee_id,
  amount,
  (from_date + interval '18 years')::DATE AS from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN (to_date + interval '18 years')::DATE 
    ELSE to_date 
    END AS to_date
FROM employees.salary;


-- title 

SELECT 
  *
FROM employees.title
LIMIT 10;

DROP MATERIALIZED VIEW IF EXISTS mv_employees.title;
CREATE MATERIALIZED VIEW mv_employees.title AS 
SELECT 
  employee_id,
  title,
  (from_date + interval '18 years' )::DATE AS from_date,
  CASE 
    WHEN to_date <> '9999-01-01' THEN (to_date + interval '18 years')::DATE 
    ELSE to_date 
    END AS to_date
FROM employees.title;


-- Execution Plan 


EXPLAIN 
SELECT 
  *
FROM employees.salary;


SELECT 
  *
FROM pg_indexes 
WHERE schemaname = 'employees';



-- Creating indexes 


CREATE UNIQUE INDEX ON mv_employees.employee USING btree (id);
CREATE UNIQUE INDEX ON mv_employees.department_employee USING btree (employee_id, department_id);
CREATE INDEX        ON mv_employees.department_employee USING btree (department_id);
CREATE UNIQUE INDEX ON mv_employees.department USING btree (id);
CREATE UNIQUE INDEX ON mv_employees.department USING btree (dept_name);
CREATE UNIQUE INDEX ON mv_employees.department_manager USING btree (employee_id, department_id);
CREATE INDEX        ON mv_employees.department_manager USING btree (department_id);
CREATE UNIQUE INDEX ON mv_employees.salary USING btree (employee_id, from_date);
CREATE UNIQUE INDEX ON mv_employees.title USING btree (employee_id, title, from_date);


SELECT 
  *
FROM mv_employees.salary
WHERE employee_id = 10001
ORDER BY from_date;


SELECT 
  employee_id,
  amount,
  from_date,
  to_date,
  LAG(amount) OVER(ORDER BY from_date) as lag_amount,
  ROUND(((amount - LAG(amount) OVER(ORDER BY from_date))/amount::NUMERIC)*100,2) as precentage 
FROM mv_employees.salary
WHERE employee_id = 10001; 


-- Naive Join

DROP TABLE IF EXISTS naive_join_table;
CREATE TEMP TABLE naive_join_table AS
SELECT
  employee.id,
  employee.birth_date,
  employee.first_name,
  employee.last_name,
  employee.gender,
  employee.hire_date,
  -- we do not need title.employee_id as employee.id is already included!
  title.title,
  title.from_date AS title_from_date,
  title.to_date AS title_to_date,
  -- same goes for the title.employee_id column
  salary.amount,
  salary.from_date AS salary_from_date,
  salary.to_date AS salary_to_date,
  -- same for department_employee.employee_id
  -- shorten department_employee to dept for the aliases
  department_employee.department_id,
  department_employee.from_date AS dept_from_date,
  department_employee.to_date AS dept_to_date,
  -- we do not need department.department_id as it is already included!
  department.dept_name
FROM mv_employees.employee
INNER JOIN mv_employees.title
  ON employee.id = title.employee_id
INNER JOIN mv_employees.salary
  ON employee.id = salary.employee_id
INNER JOIN mv_employees.department_employee
  ON employee.id = department_employee.employee_id
-- NOTE: department is joined only to the department_employee table!
INNER JOIN mv_employees.department
  ON department_employee.department_id = department.id;
  

SELECT 
  COUNT(*)
FROM naive_join_table;


SELECT
  title,
  title_from_date,
  title_to_date,
  amount,
  salary_from_date,
  salary_to_date,
  dept_name,
  dept_from_date,
  dept_to_date
FROM naive_join_table
WHERE id = 11669
ORDER BY
  title_to_date DESC,
  dept_to_date DESC,
  salary_to_date DESC;
  

SELECT
      employee_id,
      to_date,
      amount,
      LAG(amount) OVER (
        PARTITION BY employee_id
        ORDER BY from_date
      ) AS amount_lag
    FROM mv_employees.salary

SELECT * FROM (
    SELECT
      employee_id,
      to_date,
      LAG(amount) OVER (
        PARTITION BY employee_id
        ORDER BY from_date
      ) AS amount
    FROM mv_employees.salary
  ) all_salaries
  -- keep only latest valid previous_salary records only
  -- must have this in subquery to account for execution order
  WHERE to_date = '9999-01-01'
;