# **HR Analytics - PEAR**

## PEAR
  - P - Problem
  - E - Exploration
  - A - Analysis
  - R - Result

<br>

## **Problem**

* We have been asked by the HR Analytica to generate reusable datasets to power 2 HR analytics tools.
* Generate database views that HR Analytica will use for 2 key dashboards - reporting solutions and ad-hoc analytics requests. 
* Also fix the date related fields.

<br>

## Required Insights 

* The following insights must be generated for the 2 dashboards as requested by HR Analytica.

<br>

## Company Level

### Splitting by gender - current snapshot

* Total number of employees
* Average company tenure in years
* Average latest payrise percentage
* Statistical metrics for salary values including: ```MEAN```, ```MAX```, ```STDDEV```, Inter quartile range and median.


<br>

## Department Level

* Similar to company level, just at department level that includes additional department levek tenure metrics split by gender.

<br>


## Title level

* Siilar to department level but a little level of granularity.

<br>

## Deep diving on the employee relation

* Highlight recent event for every single employee form time to time.
* See all the various employment history ordered by effective date including salary, department, manager and title changes
* Calculate previous historic payrise percentages and value changes
* Calculate the previous position and department history in months with start and end dates
* Compare an employee’s current salary, total company tenure, department, position and gender to the average benchmarks for their current position

<br>

## Outputs

### Current snapshot reporting

<br>
<p align="center">
  <img width="498" height="746" src="HR_Analytics/Current_Snapshot.png">
</p>

### Historic Employee Deep Dive 

<br>
<p align="center">
  <img width="498" height="746" src="HR_Analytics/Historic_deep_dive.png">
</p>

<br>


## Exploration

### ER Diagram 

<br>
<p align="center">
  <img width="750" height="450" src="HR_Analytics/ER.png">
</p>

<br>


## Data Exploration

* Exploring the schema ```employees``` by accessing ```pg_indexes``` to get the index information.

<br>

```sql
SELECT *
FROM pg_indexes
WHERE schemaname = 'employees';

```

<br>

| schemaname	| tablename	| indexname	| indexdef  |
| :---:| :---:| :---:| :---:|
|employees|	employee|	idx_16988_primary|	CREATE UNIQUE INDEX idx_16988_primary ON employees.employee USING btree (id)|
|employees|	department_employee|	idx_16982_primary|	CREATE UNIQUE INDEX idx_16982_primary ON employees.department_employee USING btree (employee_id, department_id)|
|employees|	department_employee|	idx_16982_dept_no|	CREATE INDEX idx_16982_dept_no ON employees.department_employee USING btree (department_id)|
|employees|	department|	idx_16979_primary|	CREATE UNIQUE INDEX idx_16979_primary ON employees.department USING btree (id)|
|employees|	department|	idx_16979_dept_name|	CREATE UNIQUE INDEX idx_16979_dept_name ON employees.department USING btree (dept_name)|
|employees|	department_manager|	idx_16985_primary|	CREATE UNIQUE INDEX idx_16985_primary ON employees.department_manager USING btree (employee_id, department_id)|
|employees|	department_manager|	idx_16985_dept_no|	CREATE INDEX idx_16985_dept_no ON employees.department_manager USING btree (department_id)|
|employees|	salary|	idx_16991_primary|	CREATE UNIQUE INDEX idx_16991_primary ON employees.salary USING btree (employee_id, from_date)|
|employees|	title|	idx_16994_primary|	CREATE UNIQUE INDEX idx_16994_primary ON employees.title USING btree (employee_id, title, from_date)|

<br>

From the above table we can observe that:
1. The following tables have unique indexes on a single column:
    * ```employees.employee```
    * ```employees.department```

2. The rest of the tables have multiple records for ```employee_id``` values.
    * ```employees.department_employee```
    * ```employees.department_manager```
    * ```employee.salary```
    * ```employee.title```
 
##  Individual Table Analysis

### Employee Table

* Confirming whether there is a single record per employee.

<br>

```sql

with cte AS  
  (SELECT 
    id,
    COUNT(*) as row_count
  FROM employees.employee
  GROUP BY id)
SELECT
  row_count,
  COUNT(DISTINCT id) as employee_count
FROM cte 
GROUP BY 1
ORDER BY 1;

```

<br>

| row_count	| employee_count|
| :---:| :---:|
| 1 | 300024|

<br>

### Department Table 

* There are 9 unique departments 

<br>

```sql

SELECT 
  *
FROM employees.department;

```

| id	| dept_name|
| :---:| :---:|
|d001|	Marketing|
|d002|	Finance|
|d003|	Human Resources|
|d004|	Production|
|d005|	Development|
|d006|	Quality Management|
|d007|	Sales|
|d008|	Research|
|d009|	Customer Service|

<br>

### Department Employee table 

```sql

SELECT 
  *
FROM employees.department_employee
LIMIT 5;

```

| employee_id	| department_id| from_date	| to_date|
| :---:| :---:| :---:| :---:|
|10001|	d005|	1986-06-26|	9999-01-01|
|10002|	d007|	1996-08-03|	9999-01-01|
|10003|	d004|	1995-12-03|	9999-01-01|
|10004|	d004|	1986-12-01|	9999-01-01|
|10005|	d003|	1989-09-12|	9999-01-01|


<br>

* In the ```department_employee``` table we have a column named ```to_date = '9999-01-01'``` 
* Lets investigate the distribution of the ```to_date``` column.

<br>

```sql

SELECT 
  to_date,
  COUNT(*) as record_count
FROM employees.department_employee
GROUP BY 1
ORDER BY 1 DESC
LIMIT 5;

```

<br>

| to_date	| record_count|
| :---:| :---:|
|9999-01-01|	240124|
|2000-04-14|	48|
|2000-03-29|	46|
|2001-02-10|	46|
|1999-12-06|	45|

<br>

* We see that there are many values related to ```to_date```. We have many values for ```9999-01-01```. 
* Now let's confirm that we have a many-to-one relationship between ```department_employee``` and its ```employee_id```


```sql

with employee_id_cte AS 
  (SELECT 
    employee_id,
    COUNT(*) as row_count
  FROM employees.department_employee
  GROUP BY 1)
SELECT 
  row_count,
  COUNT(DISTINCT employee_id) as employee_count 
FROM employee_id_cte
GROUP BY 1 
ORDER BY 1 DESC;

```

* We can see that there are approximately 10% rows with 2 records. i.e. there are multiple records per ```employee_id```


### Department manager table

```sql 

SELECT 
FROM employees.department_manager
LIMIT 5;

```

<br>

| employee_id	| department_id| from_date	| to_date|
| :---:| :---:| :---:| :---:|
|110022|	d001|	1985-01-01|	1991-10-01|
|110039|	d001|	1991-10-01|	9999-01-01|
|110085|	d002|	1985-01-01|	1989-12-17|
|110114|	d002|	1989-12-17|	9999-01-01|
|110183|	d003|	1985-01-01|	1992-03-21|

<br>

* Investigating ```to_date``` column 

<br>

```sql

SELECT 
  to_date,
  COUNT(*) as record_count
FROM employees.department_manager
GROUP BY 1
ORDER BY 2 DESC;

```
<br>

| to_date	| record_count|
| :---:| :---:|
|9999-01-01|	9|
|1994-06-28|	1|
|1991-09-12|	1|
|1992-04-25|	1|
|1991-03-07|	1|
|1992-03-21|	1|
|1991-10-01|	1|
|1992-08-02|	1|
|1988-10-17|	1|
|1996-01-03|	1|
|1988-09-09|	1|
|1991-04-08|	1|
|1989-05-06|	1|
|1989-12-17|	1|
|1996-08-30|	1|
|1992-09-08|	1|

<br>

* Confirming rows per ```employee_id```

<br>

```sql

WITH employee_id_cte AS 
  (SELECT 
    employee_id,
    COUNT(*) as row_count
  FROM employees.department_manager
  GROUP BY 1)
SELECT 
  row_count,
  COUNT(DISTINCT employee_id) AS employee_count
FROM employee_id_cte 
GROUP BY 1
ORDER BY 1 DESC;

```

<br>

| to_date	| record_count|
| :---:| :---:|
| 1 | 24 |

* From the above query we can see that each ```employee_id``` that appears in ```empoyees.department_manager``` table will have only have a single record or a one-to-one relationship.

