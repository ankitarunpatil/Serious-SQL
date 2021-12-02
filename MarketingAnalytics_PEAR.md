
# Marketing Analytics - PEAR

#### PEAR
  * P - Problem
  * E - Exploration
  * A - Analysis
  * R - Result


## Problem 

* We have been asked by the DVD Rental Co marketing team to generate analytical inputs for theoir customer marketing campaign.
* The needs to send out personalised emails.
* Main initiative - Each customer's viewing behaviour
* Key statiistics: Each customers's top 2 categories and favorite actor.
* There are also 3 personalised recommendations base off each customer's previous viewing history.


<br>

## Email Tempelate for presonalised recommendations 
<br>
<p align="center">
  <img width="602" height="775" src="MarketingAnalytics/Template1.png">
</p>

<br>

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


<br>

## ER Diagram 
<br>
<p align="center">
  <img width="976" height="642" src="MarketingAnalytics/Schema.png">
</p>

<br>

## Exploration

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
```

  2. Checking the right table using the same process: ```dvd_rentals.inventory```

```sql

SELECT 
  count(DISTINCT inventory.inventory_id)
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    inventory_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);

```

  3. In the above analysis, we find that a single value is not showing up - hence, let's investigate

```sql

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
<br>

  4. Last step is to confirm both left and inner joins have the same row counts

```sql

-- Creating Left table 

DROP TABLE IF EXISTS left_rental_join;
CREATE TEMP TABLE left_rental_join AS 
(SELECT 
  r.customer_id,
  r.inventory_id,
  i.film_id
FROM dvd_rentals.rental r 
LEFT JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id);

-- Creating Right Table 

DROP TABLE IF EXISTS inner_rental_join;
CREATE TEMP TABLE inner_rental_join AS 
(SELECT 
  r.customer_id,
  r.inventory_id,
  i.film_id
FROM dvd_rentals.rental r 
INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id);

-- Checking the counts

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


  5. We also need to investigate the relationships between the ```actor_id``` and ```film_id``` columns within the ```dvd_rentals.film_actor``` table.

<br>

* An actor might show up in different films and a film can have multiple actors 
* Hence, we can conclude that film and actor will have many to many relationship.

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

<br>

* In conclusion - we can see that there is indeed a many to many relationship of the ```film_id``` and the ```actor_id``` columns within the ```dvd_rentals.film_actor``` table so we must take extreme care when we are joining these 2 tables as part of our analysis


