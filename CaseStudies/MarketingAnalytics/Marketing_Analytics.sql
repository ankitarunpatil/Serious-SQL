select * 
from dvd_rentals.rental 
limit 10;

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



-- Rental counts of customer 1

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


-- films that a customer_id = 1 watched based on each category

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


-- Exploring data 

SELECT 
  *
FROM dvd_rentals.inventory
LIMIT 10;

SELECT 
  film_id,
  store_id,
  count(*) as film_counts
FROM dvd_rentals.inventory
GROUP BY 1,2
ORDER BY 1;

SELECT 
  count(*)
FROM dvd_rentals.inventory;

SELECT 
  count(distinct inventory_id)
FROM dvd_rentals.rental;

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


SELECT 
  count(DISTINCT rental.inventory_id)
FROM dvd_rentals.rental
WHERE NOT EXISTS
  (SELECT 
    inventory_id
  FROM dvd_rentals.inventory
  WHERE rental.inventory_id = inventory.inventory_id);


SELECT 
  count(DISTINCT inventory.inventory_id)
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    rental_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);


SELECT
  *
FROM dvd_rentals.inventory
WHERE NOT EXISTS
  (SELECT 
    inventory_id
  FROM dvd_rentals.rental
  WHERE rental.inventory_id = inventory.inventory_id);
  

SELECT 
  count(DISTINCT rental.inventory_id)
FROM dvd_rentals.rental
WHERE EXISTS
  (SELECT 
    inventory.inventory_id
  FROM dvd_rentals.inventory
  WHERE rental.inventory_id = inventory.inventory_id);
  

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



SELECT 
  count(distinct film_id)
FROM dvd_rentals.inventory;

SELECT 
  count(distinct film_id)
FROM dvd_rentals.film;


-- group by 

with base_counts as 
(SELECT 
  film_id,
  count(*) as record_count
FROM dvd_rentals.inventory
GROUP BY 1)

SELECT 
  record_count,
  count(DISTINCT film_id) as unique_film_values
FROM base_counts
GROUP BY 1
ORDER BY 1;


SELECT 
  film_id,
  count(*) as record_counts
FROM dvd_rentals.film
GROUP BY 1
ORDER BY 2 desc
LIMIT 5;


-- where not exists 

SELECT 
  count(DISTINCT i.film_id)
FROM dvd_rentals.inventory i 
WHERE NOT EXISTS
  (SELECT 
    f.film_id
  FROM dvd_rentals.film f 
  WHERE i.film_id = f.film_id);
  

SELECT 
  count(DISTINCT f.film_id)
FROM dvd_rentals.film f 
WHERE NOT EXISTS 
  (SELECT 
    i.film_id
  FROM dvd_rentals.inventory i 
  WHERE i.film_id = f.film_id);
  
-- left semi join 

SELECT 
  count(DISTINCT film_id)
FROM dvd_rentals.inventory i
WHERE EXISTS
  (SELECT
    f.film_id
  FROM dvd_rentals.film f 
  WHERE f.film_id = i.film_id);
  

-- Base Table 

DROP TABLE IF EXISTS complete_joint_dataset;
CREATE TEMP TABLE complete_joint_dataset AS
SELECT
  rental.customer_id,
  inventory.film_id,
  film.title,
  rental.rental_date,
  category.name AS category_name
FROM dvd_rentals.rental
INNER JOIN dvd_rentals.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN dvd_rentals.film
  ON inventory.film_id = film.film_id
INNER JOIN dvd_rentals.film_category
  ON film.film_id = film_category.film_id
INNER JOIN dvd_rentals.category
  ON film_category.category_id = category.category_id;
  


-- bitcoin dataset 

SELECT 
  market_date,
  volume,
  close_price
FROM trading.daily_btc;


-- Complete join 

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

SELECT 
  *
FROM complete_join_dataset
LIMIT 10;


-- Categoy counts 

DROP TABLE IF EXISTS category_counts;
CREATE TEMP TABLE category_counts AS 
SELECT 
  customer_id,
  category_name,
  count(*) as rental_count,
  max(rental_date) as latest_rental_date
FROM complete_join_dataset
GROUP BY 1,2;

SELECT 
  *
FROM category_counts
WHERE customer_id = 1 
ORDER BY rental_count DESC, latest_rental_date DESC;


-- Total counts 

DROP TABLE IF EXISTS total_counts;
CREATE TEMP TABLE total_counts AS 
SELECT 
  customer_id,
  sum(rental_count) as total_count
FROM category_counts
GROUP BY 1;


SELECT 
  *
FROM total_counts
LIMIT 5;

-- TOP CATEGORIES

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


select * from complete_join_dataset;
select * from category_counts;
select * from total_counts;
select * from top_categories;


-- Average category count 

DROP TABLE IF EXISTS average_category_counts;
CREATE TEMP TABLE average_category_counts AS 
SELECT 
  category_name,
  FLOOR(AVG(rental_count)) as category_average
FROM category_counts
GROUP BY 1;


-- TOP category percentile 

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



-- Category insights 1

DROP TABLE IF EXISTS first_category_insights;
CREATE TEMP TABLE first_category_insights AS 
SELECT 
  base.customer_id,
  base.category_name,
  base.rental_count,
  base.rental_count - average.category_average as average_comparison,
  base.percentile
FROM top_category_percentile as base 
LEFT JOIN average_category_counts as average 
ON base.category_name = average.category_name;



-- Category insights 2 

DROP TABLE IF EXISTS second_category_insights;
CREATE TEMP TABLE second_category_insights AS 
SELECT 
  t.customer_id,
  t.category_name,
  t.rental_count,
  ROUND(100* t.rental_count::NUMERIC/tc.total_count) AS total_percentage
FROM top_categories t 
LEFT JOIN total_counts tc 
ON t.customer_id = tc.customer_id 
where category_rank = 2;

select * from second_category_insights;

-- Film counts 

DROP TABLE IF EXISTS film_counts;
CREATE TEMP TABLE film_counts AS 
SELECT DISTINCT
  film_id,
  title,
  category_name,
  count(*) OVER (PARTITION BY film_id) as rental_count
FROM complete_join_dataset;



-- Category film exclusion

DROP TABLE IF EXISTS category_film_exclusions;
CREATE TEMP TABLE category_film_exclusions AS 
SELECT DISTINCT
  customer_id,
  film_id
FROM complete_join_dataset;


-- Final category recommendations 

DROP TABLE IF EXISTS category_recommendations;
CREATE TEMP TABLE category_recommendations AS 
with ranked_films_cte AS( 
  SELECT 
    t.customer_id,
    t.category_name,t.category_rank,
    f.film_id,
    f.title,
    f.rental_count,
    DENSE_RANK() OVER (PARTITION BY t.customer_id, t.category_rank
                        ORDER BY f.rental_count DESC,
                        f.title) as reco_rank
  FROM top_categories t 
  INNER JOIN film_counts f 
  ON t.category_name = f.category_name
  WHERE NOT EXISTS
  (
    SELECT 1
    FROM category_film_exclusions c
    WHERE c.customer_id = t.customer_id AND 
    c.film_id = f.film_id
  )
)
SELECT 
  *
FROM ranked_films_cte
WHERE reco_rank <=3;


SELECT 
  *
FROM category_recommendations;


-- Actor Insights 

-- Creating base table for Actor Insights 

DROP TABLE IF EXISTS actor_joint_dataset;
CREATE TEMP TABLE actor_joint_dataset AS 
SELECT 
  r.customer_id,
  r.rental_id,
  r.rental_date,
  f.film_id,
  f.title,
  ac.actor_id,
  ac.first_name,
  ac.last_name
FROM dvd_rentals.rental r 
INNER JOIN dvd_rentals.inventory i 
ON r.inventory_id = i.inventory_id 
INNER JOIN dvd_rentals.film f 
ON i.film_id = f.film_id 
INNER JOIN dvd_rentals.film_actor a 
ON f.film_id = a.film_id 
INNER JOIN dvd_rentals.actor ac 
ON a.actor_id = ac.actor_id;


-- TOP Actor Counts

DROP TABLE IF EXISTS top_actor_count;
CREATE TEMP TABLE top_actor_count AS 
with actor_counts AS   
  (SELECT 
    customer_id,
    actor_id,
    first_name,
    last_name,
    COUNT(*) as rental_count,
    MAX(rental_date) as latest_rental_date
  FROM actor_joint_dataset
  GROUP BY 1,2,3,4),
ranked_actor_counts AS 
  (
  SELECT 
    actor_counts.*,
    DENSE_RANK() OVER (PARTITION BY customer_id 
                        ORDER BY rental_count DESC,
                        latest_rental_date DESC,
                        first_name,
                        last_name) as actor_rank
  FROM actor_counts
  )
SELECT 
  customer_id,
  actor_id,
  first_name,
  last_name,
  rental_count
FROM ranked_actor_counts
WHERE actor_rank = 1;


SELECT 
  *
FROM top_actor_count;


-- Actor Recommendations 


DROP TABLE IF EXISTS actor_film_counts;
CREATE TEMP TABLE actor_film_counts AS 
with film_counts AS
  (
    SELECT 
    film_id,
    COUNT(DISTINCT rental_id) AS rental_count
    FROM actor_joint_dataset
    GROUP BY 1
  )
SELECT DISTINCT 
  a.film_id,
  a.actor_id,
  a.title,
  film_counts.rental_count
FROM actor_joint_dataset a 
LEFT JOIN film_counts 
ON a.film_id = film_counts.film_id;


SELECT
  *
FROM actor_film_counts;


-- ACTOR Film Exclusions 

DROP TABLE IF EXISTS actor_film_exclusions;
CREATE TEMP TABLE actor_film_exclusions AS 
(
  SELECT 
    customer_id,
    film_id
  FROM complete_join_dataset
)
UNION 
(
  SELECT 
    customer_id,
    film_id
  FROM category_recommendations
);



SELECT 
  *
FROM actor_film_exclusions
LIMIT 10;


-- Final actor recommendations 


DROP TABLE IF EXISTS actor_recommendations;
CREATE TEMP TABLE actor_recommendations AS 
with ranked_actor_films_cte AS 
  (SELECT 
    t.customer_id,
    t.first_name,
    t.last_name,
    t.rental_count,
    a.title,
    a.film_id,
    a.actor_id,
    DENSE_RANK() OVER (PARTITION BY t.customer_id 
                        ORDER BY a.rental_count DESC,
                        a.title) as reco_rank
  FROM top_actor_count t 
  INNER JOIN actor_film_counts a 
  ON t.actor_id = a.actor_id 
  WHERE NOT EXISTS(
                    SELECT 1
                    FROM actor_film_exclusions af 
                    WHERE af.customer_id = t.customer_id 
                    AND af.film_id =  a.film_id
                    
                  )
  )
SELECT 
  *
FROM ranked_actor_films_cte
WHERE reco_rank <=3;


SELECT 
  *
FROM actor_recommendations;



-- Final Transformation


DROP TABLE IF EXISTS final_data_asset;
CREATE TEMP TABLE final_data_asset AS 
with first_category AS
(
  SELECT 
    customer_id,
    category_name,
    CONCAT
    (
      'You''ve watched ', rental_count, ' ',category_name,
      'films, that''s ', average_comparison,
      ' more than the DVD REntal Co average and puts you in the top ',
      percentile, '% of', category_name, ' gurus!'
    ) AS insight
  FROM first_category_insights
),
second_category AS 
(
  SELECT
    customer_id,
    category_name,
    CONCAT
    (
      'You''ve watched ', rental_count, ' ',category_name,
      ' films making up', total_percentage,
      '% of your entire viewing history!'
    ) AS insight
  FROM second_category_insights
),
top_actor AS 
(
  SELECT 
    customer_id,
    CONCAT(INITCAP(first_name), ' ', INITCAP(last_name)) AS actor_name,
    CONCAT
    (
      'You''ve watched ', rental_count, ' films featuring',
      INITCAP(first_name), ' ', INITCAP(last_name),
      '! Here are some other films ', INITCAP(first_name),
      ' stars in that might interest you!'
    ) AS insight
  FROM top_actor_count
),
adjusted_title_case_category_recommendations AS 
(
  SELECT 
    customer_id,
    INITCAP(title) as title,
    category_rank,
    reco_rank
  FROM category_recommendations
),
wide_category_recommendations AS 
(
  SELECT 
    customer_id,
    MAX(CASE WHEN category_rank = 1 and reco_rank = 1 THEN title END) AS cat1_reco1,
    MAX(CASE WHEN category_rank = 1 and reco_rank = 2 THEN title END) AS cat1_reco2,
    MAX(CASE WHEN category_rank = 1 and reco_rank = 3 THEN title END) AS cat1_reco3,
    MAX(CASE WHEN category_rank = 2 and reco_rank = 1 THEN title END) AS cat2_reco1,
    MAX(CASE WHEN category_rank = 2 and reco_rank = 2 THEN title END) AS cat2_reco2,
    MAX(CASE WHEN category_rank = 2 and reco_rank = 2 THEN title END) AS cat2_reco3
  FROM adjusted_title_case_category_recommendations
  GROUP BY customer_id
),
adjusted_title_case_actor_recommendations AS 
(
  SELECT 
    customer_id,
    INITCAP(title) as title,
    reco_rank
  FROM actor_recommendations
),
wide_actor_recommendations AS 
(
  SELECT 
    customer_id,
    MAX(CASE WHEN reco_rank = 1 THEN title END) AS actor_reco1,
    MAX(CASE WHEN reco_rank = 2 THEN title END) AS actor_reco2,
    MAX(CASE WHEN reco_rank = 2 THEN title END) AS actor_reco3
  FROM adjusted_title_case_actor_recommendations
  GROUP BY 1
),
final_output AS 
(
  SELECT 
    t1.customer_id,
    t1.category_name AS cat_1,
    t4.cat1_reco1,
    t4.cat1_reco2,
    t4.cat1_reco3,
    t2.category_name AS cat2,
    t4.cat2_reco1,
    t4.cat2_reco2,
    t4.cat2_reco3,
    t3.actor_name as actor,
    t5.actor_reco1,
    t5.actor_reco2,
    t5.actor_reco3,
    t1.insight AS insight_cat1,
    t2.insight AS insight_cat2,
    t3.insight AS insight_actor
  FROM first_category as t1 
  INNER JOIN second_category as t2 
  ON t1.customer_id = t2.customer_id
  INNER JOIN top_actor t3 
  ON t1.customer_id = t3.customer_id 
  INNER JOIN wide_category_recommendations t4 
  ON t1.customer_id = t4.customer_id 
  INNER JOIN wide_actor_recommendations t5 
  ON t1.customer_id = t5.customer_id 
)
SELECT 
  * 
FROM final_output; 




SELECT 
  *
FROM final_data_asset
LIMIT 5;




-- Practice again 

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



-- Practice end  