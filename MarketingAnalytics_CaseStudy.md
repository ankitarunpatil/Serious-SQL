# Marketing Analytics

# **Logic and Processes** for different cases

<br>

## Deciding which type of table join to use ?
1. Decide what is the purpose of joining tables.
2. Check for distribution of foreign keys within each table.
3. The number of foreign key values exists in each table.

<br>

## Asking key analytical questions
1. How many records exists per foreign key value in left and right tables?
2. How many overlapping and missing unique foreign key values are there between the two tables?

<br>

## Perform a simple count on records

```sql
SELECT 
  count(*)
FROM dvd_rentals.inventory;
```

```sql
SELECT 
  count(distinct inventory_id)
FROM dvd_rentals.rental;
```

## Perform group by on the records (Aggregate the data twice to see the results)

* We follow these 2 simple steps to summarise our dataset:
1. Perform a GROUP BY record count on the target column
2. Summarise the record count output to show the distribution of records by unique count of the target column

<br>

```sql
with cte as 
  (SELECT 
    inventory_id,
    count(*) as row_counts
  FROM dvd_rentals.rental
  GROUP BY 1)

SELECT 
  row_counts,
  count(inventory_id) as inventory_ids
FROM cte
GROUP BY 1
ORDER BY 1;
```

<br>


## Foreign key overlap analysis

1. How many overlapping and missing unique foreign key values are there between the two tables?
2. Which foreign keys only exist in the left table?
3. Which foreign keys only exist in the right table?
4. Further investigate if there are records.

<br>

```sql
-- how many foreign keys exists only in the left table and not on the right 
SELECT 
  count(DISTINCT rental.inventory_id)
FROM dvd_rentals.rental
WHERE NOT EXISTS
  (SELECT 
    inventory_id
  FROM dvd_rentals.inventory
  WHERE rental.inventory_id = inventory.inventory_id);

```

<br>

```sql

--how many foreign keys exists only in the right table and not in the left table 
SELECT 
  count(DISTINCT inventory.inventory_id)
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    rental_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);

```

<br>

#### Investigation

<br>

```sql
SELECT 
  count(DISTINCT inventory.inventory_id)
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    rental_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);


```

<br>

#### We can quickly perform a left semi join or a WHERE EXISTS to get the count of unique foreign key values that are in the intersection.

<br>

```sql

SELECT 
  count(DISTINCT rental.inventory_id)
FROM dvd_rentals.rental
WHERE EXISTS
  (SELECT 
    inventory.inventory_id
  FROM dvd_rentals.inventory
  WHERE rental.inventory_id = inventory.inventory_id);

```

<br>


### Implementing the joins 

<br>

* Use left join and also inner join to find the record counts and check if they match

<br>

```sql
DROP TABLE IF EXISTS left_rental_join;
CREATE TEMP TABLE left_rental_join AS 
SELECT 
  r.customer_id,
  r.inventory_id,
  i.film_id
FROM dvd_rentals.rental r 
LEFT JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id;

DROP TABLE IF EXISTS inner_rental_join;
CREATE TEMP TABLE inner_rental_join as 
SELECT 
  r.customer_id,
  r.inventory_id,
  i.film_id
FROM dvd_rentals.rental r 
INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id; 


-- check counts for each output 

(SELECT 
  'left join' as join_type,
  count(*) as record_count,
  count(DISTINCT inventory_id) as unique_key_values
FROM left_rental_join)

UNION 

(SELECT
  'inner join' as join_type,
  count(*) as record_count,
  count(DISTINCT inventory_id) as unique_key_values
FROM inner_rental_join);

```

<br>

#### 1. Query to find rental_counts, customer_id, category_name for customer with id= 1. <br>

```sql
SELECT 
  r.customer_id,
  c.name,
  count(*) as rental_count
FROM dvd_rentals.rental r INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id 
INNER JOIN dvd_rentals.film f 
ON i.film_id = f.film_id 
INNER JOIN dvd_rentals.film_category fc 
ON f.film_id = fc.film_id 
INNER JOIN dvd_rentals.category c 
ON fc.category_id = c.category_id
WHERE r.customer_id = 1
GROUP BY 1,2
ORDER BY 3 DESC;
```
<br>


#### 2. Query to find rental_counts, customer_id, category_name and film_names for customer with id= 1. <br>

```sql
SELECT 
  r.customer_id,
  c.name,
  f.title,
  count(*) as rental_count
FROM dvd_rentals.rental r INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id 
INNER JOIN dvd_rentals.film f 
ON i.film_id = f.film_id 
INNER JOIN dvd_rentals.film_category fc 
ON f.film_id = fc.film_id 
INNER JOIN dvd_rentals.category c 
ON fc.category_id = c.category_id
WHERE r.customer_id = 1
GROUP BY 1,2,3
ORDER BY 4 DESC;
```
<br>


#### 2. Query to find top 2 customer_id, category_name and rental count with respect to each cutomer id. <br>


```sql
select 
  a.customer_id,
  a.category_name,
  a.rental_count
  from
  (SELECT 
    customer_id,
    name as category_name,
    count(*) as rental_count,
    dense_rank() over (partition by customer_id order by count(*) desc) rents
  FROM dvd_rentals.rental r LEFT JOIN dvd_rentals.inventory i 
  ON r.inventory_id = i.inventory_id 
  INNER JOIN dvd_rentals.film f 
  ON f.film_id = i.film_id 
  INNER JOIN dvd_rentals.film_category fc 
  ON fc.film_id = f.film_id 
  INNER JOIN dvd_rentals.category c
  ON c.category_id = fc.category_id
  GROUP BY 1,2
  ORDER BY 1, 3 DESC) a 
where a.rents <3;
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
