# Logic for different cases


#### 1. How many unique category values are there in the film_list table?


```sql
SELECT
  COUNT(DISTINCT category) AS unique_category_count
FROM dvd_rentals.film_list;
```

#### 2. What is the frequency of values in the rating column in the film table?

Frequency with respect to each rating, frequency = count(*)


```sql
SELECT
  rating,
  COUNT(*) AS frequency
FROM dvd_rentals.film_list
GROUP BY rating
ORDER BY 2 DESC;
```

### Percentage logic - Percentage of records for each column
#### 3. Adding a percentage column<br>

If I do not specify any argument in the over clause, the partition will be applied on the entire dataset
So every adjacent row will contain the entire sum of the columns: 997<br>

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

### Detecting duplicate records logic 

1. Find total records 

```sql
SELECT COUNT(*)
FROM health.user_logs;
```

2. Find total distinct records 

```sql
select 
  count(distinct *)  -- this does not work in postgres 
from health.user_logs;
```

2.a. Using sub query

```sql
select
  count(*)
from 
  (select 
    distinct *
  from health.user_logs) as subquery;
```

2.b. Using CTE

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

