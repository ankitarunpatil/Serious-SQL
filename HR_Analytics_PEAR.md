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

