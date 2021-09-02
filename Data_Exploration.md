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
  >- **Logic**
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
  
  - Using **percentie, avg and mode** functions
  >- **Logic**
  >- Calculate median by using percentile of 0.5
  >- Calculate mode using mode function
  >- Calculate the mean using the average function

```sql 
select 
  percentile_cont(0.5) within group(order by measure_value) as median_value,
  mode() within group (order by measure_value) as mode_value,
  avg(measure_value) as mean_value
from health.user_logs
where measure ='weight';
```
<br>


### Minimum, maximum, Range <br>

  - Using **min, max** functions
  >- **Logic**
  >- Calculate min and max values 
  >- Put min and max values in CTE
  >- Then using CTE calculate the **range** - (this is more efficient as range will only be calculated on the min and max values obtained from CTE)
  >- Hence, the query is optimized using CTE in this case 
<br>

```sql
with min_max_values as 
(select 
  min(measure_value) as min_value,
  max(measure_value) as max_value
from health.user_logs
where measure='weight')
select 
  min_value,
  max_value,
  max_value - min_value as range_value
from min_max_values
;
```
<br>
### Summary Statistics <br>

  - Using all the functions (min, max, avg, percentile, mode, stddev, variance)
  >- **Logic**
  >- Percentile count returns a flot that is incompatible with round, hence I will cast it to numeric
  >- Write all the functions
  >- Group by measure 
<br>

```sql
select 
  measure,
  round(min(measure_value),2) as min_value,
  round(max(measure_value),2) as max_value,
  round(avg(measure_value),2) as avg_value,
  round(cast(percentile_cont(0.5) within group (order by measure_value) as numeric),2) as median_value,
  round(mode() within group (order by measure_value),2),
  round(stddev(measure_value),2) as standard_deviation,
  round(variance(measure_value),2) as variance_value
from health.user_logs
where measure = 'weight'
group by 1;
```
<br>


### Bucket Calculations - putting all of the data in 100 buckets i.e. percentile values 
<br>

  - Using **NTILE** 
  >- **Logic**
  >- Order all the measure values from smallest to largest
  >- Put this in a CTE
  >- Calculate min and max values as floor and ceiling values 
  >- Count the number of records in each percentile
<br>

```sql
with percentile_values as 
(select 
  measure_value,
  ntile(100) over (order by measure_value) as percentile
from health.user_logs
where measure = 'weight')

select 
  percentile,
  min(measure_value) as floor_value,
  max(measure_value) as ceiling_value,
  count(*) as percentile_counts
from percentile_values
group by 1
order by 1;

```
<br>

### Checking outliers
<br>

  - Using **Ntile**
  >- Calculate all the percentiles 
  >- Put this into CTE
  >- Calculate rank, dense_rank and filter with percentile value = 1 or 100 accordingly

```sql
with percentile_values as 
(select 
  measure_value,
  ntile(100) over (order by measure_value) as percentile
from health.user_logs
where measure = 'weight')

select 
  measure_value,
  row_number() over (order by measure_value) as row_number,
  rank() over (order by measure_value) as rank_number,
  dense_rank() over (order by measure_value) as dense_number
from percentile_values
where percentile = 1
order by measure_value;
```

<br>


### Removing Outliers
<br>

  - Using **Temp Tables**
  >- **Logic**
  >- Create a temporary tables where I will remove all the outliers by applying strict inequality conditions
  >- Calulate summary statistics on the new temporary table 
  >- Check for different results 
  >- Show the cumulative distribution with treated data 
 
<br>

```sql
drop table if exists clean_weight_logs;

create temp table clean_weight_logs as 
(select *
from health.user_logs
where measure = 'weight'
and measure_value >0 
and measure_value < 201);
```

<br>

```sql
select 
  round(min(measure_value),2) as min_value,
  round(max(measure_value),2) as max_value,
  round(avg(measure_value),2) as avg_value,
  round(cast(percentile_cont(0.5) within group (order by measure_value) as numeric),2) as median_value,
  round(mode() within group (order by measure_value),2),
  round(stddev(measure_value),2) as standard_deviation,
  round(variance(measure_value),2) as variance_value
from clean_weight_logs;

```

<br>

```sql
with percentile_values as 
(select 
  measure_value,
  ntile(100) over (order by measure_value) as percentile
from clean_weight_logs
where measure = 'weight')

select 
  percentile,
  min(measure_value) as floor_value,
  max(measure_value) as ceiling_value,
  count(*) as percentile_counts
from percentile_values
group by 1
order by 1;
```

<br>
