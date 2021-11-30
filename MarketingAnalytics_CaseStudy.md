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

## Problem 

* We have been asked by the DVD Rental Co marketing team to generate analytical inputs for theoir customer marketing campaign.
* The needs to send out personalised emails.
* Main initiative - Each customer's viewing behaviour
* Key statiistics: Each customers's top 2 categories and favorite actor.
* There are also 3 personalised recommendations base off each customer's previous viewing history.


## Category Insights

* Top Category:
1. What was the top category watched by total rental count?
2. How many total films have they watched in their top category and how does it compare to the DVD Rental Co customer base?
3. How many more films has the customer watched compared to the average DVD Rental Co customer?
4. How does the customer rank in terms of the top X% compared to all other customers in this film category?
5. What are the top 3 film recommendations in the top category ranked by total customer rental count which the customer has not seen before?

* Second Category
1. What is the second ranking category by total rental count?
2. What proportion of each customer’s total films watched does this count make?
3. What are top 3 recommendations for the second category which the customer has not yet seen before?

* Actor Insights 
1. Which actor has featured in the customer’s rental history the most?
2. How many films featuring this actor has been watched by the customer?
3. What are the top 3 recommendations featuring this same actor which have not been watched by the customer?
 

## Join Column Analysis 1

1. Perform an anti join to check which column values exist in ```dvd_rentals.rental``` but not in ```dvd_rentals.inventory```

```sql
-- left table

SELECT 
  count(DISTINCT rental.inventory_id)
FROM dvd_rentals.rental
WHERE NOT EXISTS
  (SELECT
    inventory_id
  FROM dvd_rentals.inventory
  WHERE rental.inventory_id = inventory.inventory_id);
  
-- right table : count of this is 1 - hence then further investigate this count

SELECT 
  count(DISTINCT inventory.inventory_id)
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    inventory_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);
  

-- Investigation

SELECT 
  *
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    inventory_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);

```

* In the above analysis we can conclude that some inventory might just never be rented out to customers at the retail rental store.
* We have no issues with this 

* Let us confirm that both eft and inner joins do not differ

```sql
-- Checking both left and right join counts 

DROP TABLE IF EXISTS left_rental_join;
CREATE TEMP TABLE left_rental_join AS 
(SELECT 
  r.customer_id,
  r.inventory_id,
  i.film_id
FROM dvd_rentals.rental r 
LEFT JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id);


DROP TABLE IF EXISTS inner_rental_join;
CREATE TEMP TABLE inner_rental_join AS 
(SELECT 
  r.customer_id,
  r.inventory_id,
  i.film_id
FROM dvd_rentals.rental r 
INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id);


-- output

(
SELECT 
  'left join' as join_type,
  count(*) as record_count,
  count(DISTINCT inventory_id) as unique_key_values
FROM left_rental_join
)
UNION 
(
SELECT 
  'inner join' as join_type,
  count(*) as record_count,
  count(DISTINCT inventory_id) as unique_key_values
FROM inner_rental_join
);


```

* We can perform the same analysis for all of the tables and conclude the distributions of join keys are as expected and are similar to first 2 tables

## Join Column Analysis 2

* Investigating the relationship between ```actor_id``` and ```film_id columns``` within the dvd_rentals.film_actor table

1. An actor might show up in different films and a film can have multiple actors 
2. Hence, we can conclude that film and actor will have many to many relationship.

```sql

-- Join analysis 2 

WITH actor_film_counts AS 
  (SELECT 
    actor_id,
    count(DISTINCT film_id) as film_count
  FROM dvd_rentals.film_actor
  GROUP BY 1)

SELECT 
  film_count,
  count(*) as total_actors
FROM actor_film_counts
GROUP BY 1
ORDER BY 1 DESC
;

-- Also confirm there are multiple actors per film

WITH film_actor_count AS 
  (SELECT 
  film_id,
  count(DISTINCT actor_id) as actor_count
  FROM dvd_rentals.film_actor
  GROUP BY 1)
SELECT 
  actor_count,
  count(*) as total_films
FROM film_actor_count
GROUP BY 1
ORDER BY 1 DESC;

```

* In conclusion - we can see that there is indeed a many to many relationship of the ```film_id``` and the ```actor_id``` columns within the ```dvd_rentals.film_actor``` table so we must take extreme care when we are joining these 2 tables as part of our analysis

## Solution Plan

* Category Insights 

1. Create a base dataset and join all relevant tables ```complete_joint_dataset```
2. Calculate customer rental counts for each category ```category_counts```
3. Aggregate all customer total films watched ```total_counts```
4. Identify the top 2 categories for each customer ```top_categories```
5. Calculate each category’s aggregated average rental count ```average_category_count```
6. Calculate the percentile metric for each customer’s top category film count ```top_category_percentile```
7. Generate our first top category insights table using all previously generated tables ```top_category_insights```
8. Generate the 2nd category insights ```second_category_insights```


<br>

### Creating base table 

```sql
DROP TABLE IF EXISTS complete_join_dataset;
CREATE TEMP TABLE complete_join_dataset AS 
SELECT
  r.customer_id,
  i.film_id,
  f.title,
  c.name as category_name,
  r.rental_date
FROM dvd_rentals.rental r 
INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id 
INNER JOIN dvd_rentals.film f 
ON f.film_id = i.film_id 
INNER JOIN dvd_rentals.film_category fc 
ON f.film_id = fc.film_id 
INNER JOIN dvd_rentals.category c 
ON fc.category_id = c.category_id;

```

### Creating category counts 

```sql
DROP TABLE IF EXISTS category_counts;
CREATE TEMP TABLE category_counts AS 
SELECT 
  customer_id,
  category_name,
  count(*) as rental_count,
  max(rental_date) as latest_rental_date
FROM complete_join_dataset
GROUP BY 1,2;

--- Checking counts 

SELECT 
  *
FROM category_counts
WHERE customer_id = 1 
ORDER BY rental_count DESC, latest_rental_date DESC;

```

## Creating total counts 

```sql
DROP TABLE IF EXISTS total_counts;
CREATE TEMP TABLE total_counts AS 
SELECT 
  customer_id,
  sum(rental_count)
FROM category_counts
GROUP BY 1;

SELECT 
  *
FROM total_counts
LIMIT 5;

```

## Creating TOP Categories 

```sql

DROP TABLE IF EXISTS top_categories;
CREATE TEMP TABLE top_categories AS 
WITH ranked_cte AS (
  SELECT 
    customer_id,
    category_name,
    rental_count,
    DENSE_RANK() OVER (PARTITION BY customer_id
                      ORDER BY rental_count DESC,
                      latest_rental_date DESC,
                      category_name) 
                      AS category_rank
  FROM category_counts
)
SELECT 
  *
FROM ranked_cte
where category_rank <=2;

```


### Creating average category count


```sql

DROP TABLE IF EXISTS average_category_counts;
CREATE TEMP TABLE average_category_counts AS 
SELECT 
  category_name,
  FLOOR(AVG(rental_count)) as category_average
FROM category_counts
GROUP BY 1;

```


### Top Category Perentile

```sql

DROP TABLE IF EXISTS top_category_percentile;
CREATE TEMP TABLE top_category_percentile AS 
WITH calculated_cte AS(
  SELECT 
    t.customer_id,
    t.category_name as top_category_name,
    t.rental_count,
    c.category_name,
    t.category_rank,
    PERCENT_RANK() OVER(PARTITION BY c.category_name
                        ORDER BY c.rental_count DESC)
                        AS raw_percentile_value
  FROM category_counts c 
  LEFT JOIN top_categories t 
  on c.customer_id = t.customer_id 
)
SELECT 
  customer_id,
  category_name,
  rental_count,
  category_rank,
  CASE 
    WHEN ROUND(100* raw_percentile_value) = 0 THEN 1
    ELSE ROUND(100* raw_percentile_value)
  END AS percentile
FROM calculated_cte
WHERE category_rank = 1 
AND top_category_name = category_name;


```


### Category Insights 

```sql



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
