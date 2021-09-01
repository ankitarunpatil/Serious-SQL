# Logic for different cases


#### 1. How many unique category values are there in the film_list table? <br>


```sql
SELECT
  COUNT(DISTINCT category) AS unique_category_count
FROM dvd_rentals.film_list;
```
<br>

#### 2. What is the frequency of values in the rating column in the film table? <br>

* Frequency with **respect to each rating**, frequency = count(*) <br>


```sql
SELECT
  rating,
  COUNT(*) AS frequency
FROM dvd_rentals.film_list
GROUP BY rating
ORDER BY 2 DESC;
```
<br>

### Percentage logic - Percentage of records for each column
#### 3. Adding a percentage column<br>

* If I do not specify any argument in the **over** clause, the partition will be applied on the entire dataset
* So every adjacent row will contain the entire sum of the columns: 997<br>
<br>

```sql
select 
  rating,
  count(*) as frequency,
  sum(count(*)) over() as sum_of_all,
  round(100 * count(*) :: numeric / sum(count(*)) over(),2) as percentage
from dvd_rentals.film_list
group by 1
order by 2 desc;
```
<br>

### Detecting duplicate records logic 

1. Find total records <br>

```sql
SELECT COUNT(*)
FROM health.user_logs;
```
<br>

2. Find total distinct records <br>

```sql
select 
  count(distinct *)  -- this does not work in postgres 
from health.user_logs;
```
<br>

  - Using **sub query** <br>
  >- **Logic**:
  >- Retrieve all the distinct records first
  >- Then count those records <br>

```sql
select
  count(*)
from 
  (select 
    distinct *
  from health.user_logs) as subquery;
```
<br>

  - Using CTE <br>
  >- **Logic**:
  >- Write a CTE that selects all the distinct records
  >- Use the count function to count the records in CTE <br>

```sql 
with cte as 
(select 
  distinct *
from health.user_logs
)
select 
  count(*)
from cte; 
```
<br>

### Identifying the duplicate records <br>
  
  - Using **Group BY**:
  >- Use count to calculate the frequency
  >- Retrive all the columns 
  >- Group by all the columns <br>

```sql
select 
  id, 
  log_date,
  measure,
  measure_value,
  systolic,
  diastolic,
  count(*) as frequency
from health.user_logs
group by 1,2,3,4,5,6
order by 7 desc;
```
<br>

### Mean, median, mode logic <br>

```sql 
select 
  id, 
  log_date,
  measure,
  measure_value,
  systolic,
  diastolic,
  count(*) as frequency
from health.user_logs
group by 1,2,3,4,5,6
order by 7 desc;
```
<br>
