SELECT 
  *
FROM pizza_runner.runners
LIMIT 10;


SELECT 
  *
FROM pizza_runner.customer_orders
LIMIT 10;


SELECT 
  *
FROM pizza_runner.runner_orders;


SELECT 
  *
FROM pizza_runner.pizza_names
LIMIT 10;


SELECT 
  *
FROM pizza_runner.pizza_recipes
LIMIT 10;


SELECT 
  *
FROM pizza_runner.pizza_toppings;


-- A. Pizza Metrics 

-- 1. How many pizzas were ordered?

SELECT 
  COUNT(*)
FROM pizza_runner.customer_orders;


-- 2. How many unique customer orders were made?

SELECT 
  COUNT (DISTINCT order_id)
FROM pizza_runner.customer_orders;


-- 3. How many successful orders were delivered by each runner?

SELECT * FROM pizza_runner.runner_orders;

-- Cleaning The Data 

DROP TABLE IF EXISTS runner_orders_temp;
CREATE TEMP TABLE runner_orders_temp AS 
  (SELECT 
    order_id,
    runner_id,
    CASE 
      WHEN pickup_time like 'null' or pickup_time IS NULL THEN '' ELSE pickup_time 
    END AS pickup_time,
    CASE 
      WHEN distance like 'null' or distance IS NULL THEN '' 
      WHEN distance like '%km' THEN TRIM('km' FROM distance) 
      ELSE distance
    END AS distance,
    CASE 
      WHEN duration like 'null' or duration IS NULL THEN ''  
      WHEN duration like '%mins' THEN TRIM('mins' FROM duration)
      WHEN duration like '%minute' THEN TRIM('minute' FROM duration)
      WHEN duration like '%minutes' THEN TRIM('minutes' FROM duration)
      ELSE duration
    END AS duration,
    CASE WHEN cancellation IS NULL OR cancellation= 'null' THEN '' ELSE cancellation END AS cancellation
  FROM pizza_runner.runner_orders);
  

SELECT 
  *
FROM runner_orders_temp;

SELECT 
  runner_id,
  COUNT(*) AS successful_orders
FROM runner_orders_temp
WHERE cancellation NOT IN('Restaurant Cancellation','Customer Cancellation')
GROUP BY 1
ORDER BY 2 DESC;


-- How many of each type of pizza was delivered?

SELECT 
  *
FROM pizza_runner.customer_orders;

DROP TABLE IF EXISTS customer_orders_temp;
CREATE TEMP TABLE customer_orders_temp AS 
  (SELECT 
    order_id,
    customer_id,
    pizza_id,
    CASE 
      WHEN exclusions IS NULL or exclusions like '%null' THEN ''
      ELSE exclusions
    END AS exclusions,
    CASE 
      WHEN extras IS NULL or extras like '%null' THEN ''
      ELSE extras
    END AS extras,
    order_time
  FROM pizza_runner.customer_orders);

SELECT * FROM customer_orders_temp;


SELECT 
  p.pizza_name,
  COUNT(*) as pizza_count
FROM runner_orders_temp r 
INNER JOIN customer_orders_temp c 
ON r.order_id = c.order_id 
INNER JOIN pizza_runner.pizza_names p 
ON c.pizza_id = p.pizza_id
WHERE r.cancellation NOT IN('Restaurant Cancellation','Customer Cancellation')
GROUP BY 1
ORDER BY 2 DESC;


-- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
  c.customer_id,
  p.pizza_name,
  COUNT(*) AS counts
FROM customer_orders_temp c 
INNER JOIN pizza_runner.pizza_names p 
ON c.pizza_id = p.pizza_id
GROUP BY 1,2
ORDER BY 1;


SELECT 
  c.customer_id,
  SUM(CASE WHEN p.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS Meatlovers,
  SUM(CASE WHEN p.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS Vegetarian
FROM customer_orders_temp c 
INNER JOIN pizza_runner.pizza_names p 
ON c.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 1;


-- What was the maximum number of pizzas delivered in a single order?

SELECT 
  *
FROM customer_orders_temp;

SELECT 
  *
FROM runner_orders_temp;

WITH max_cte AS 
  (SELECT 
    c.order_id,
    COUNT(*) AS pizza_count,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS ranks 
  FROM customer_orders_temp c 
  INNER JOIN runner_orders_temp r 
  ON c.order_id = r.order_id
  WHERE r.cancellation NOT IN('Restaurant Cancellation','Customer Cancellation')
  GROUP BY 1)

SELECT
  pizza_count
FROM max_cte 
WHERE ranks = 1 
; 


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?


SELECT
  c.customer_id,
  SUM(CASE WHEN c.exclusions ='' AND c.extras ='' THEN 0 ELSE 1 END) AS at_least_one_change,
  SUM(CASE WHEN c.exclusions ='' AND c.extras ='' THEN 1 ELSE 0 END) AS no_change
FROM customer_orders_temp c 
INNER JOIN runner_orders_temp r 
ON c.order_id = r.order_id
WHERE r.cancellation NOT IN('Restaurant Cancellation','Customer Cancellation')
GROUP BY 1
ORDER BY 1;


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT
  COUNT(*)
FROM customer_orders_temp 
WHERE exclusions !='' AND extras !='';


--9. What was the total volume of pizzas ordered for each hour of the day?

SELECT 
  DATE_PART('hour',order_time::TIMESTAMP) AS hour_of_the_day,
  COUNT(*) AS counts
FROM customer_orders_temp
GROUP BY 1
ORDER BY 1;


--10. What was the volume of orders for each day of the week?

SELECT 
  TO_CHAR(order_time,'DAY') AS day_of_week,
  COUNT(order_id) AS counts
FROM customer_orders_temp
GROUP BY 1,DATE_PART('dow', order_time)
ORDER BY DATE_PART('dow', order_time);


-- Part B - Runner and Customer Experience 

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)


select * from pizza_runner.runners;

SELECT 
  DATE_TRUNC('week',registration_date)::DATE+7 AS registration_week,
  COUNT(*) AS runners
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
  *
FROM runner_orders_temp;

SELECT 
  *
FROM customer_orders_temp;

WITH cte_pickup_times AS 
  (SELECT DISTINCT
    c.order_id,
    DATE_PART('minutes',AGE(r.pickup_time::TIMESTAMP,c.order_time))::INTEGER AS pickup_minutes 
  FROM customer_orders_temp c 
  INNER JOIN runner_orders_temp r 
  ON c.order_id = r.order_id 
  WHERE r.pickup_time != '')

SELECT   
  ROUND(AVG(pickup_minutes),3) AS avg_pickup
FROM cte_pickup_times
;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT 
  c.order_id,
  DATE_PART('min',AGE(r.pickup_time::TIMESTAMP,c.order_time))::INTEGER AS pickup_minutes,
  COUNT(c.pizza_id) AS pizza_count
FROM customer_orders_temp c 
INNER JOIN runner_orders_temp r 
ON c.order_id = r.order_id 
WHERE r.pickup_time != ''
GROUP BY 1,2
ORDER BY 3;


-- 4. What was the average distance travelled for each customer?

WITH cte_avg_dist AS 
  (SELECT 
    DISTINCT
    c.customer_id customer_id,
    c.order_id,
    r.distance::NUMERIC average_dist
  FROM customer_orders_temp c 
  INNER JOIN runner_orders_temp r 
  ON c.order_id = r.order_id  
  WHERE r.pickup_time != '')

SELECT 
  customer_id,
  ROUND(AVG(average_dist),1) 
FROM cte_avg_dist
GROUP BY 1
ORDER BY 1;


-- 5. What was the difference between the longest and shortest delivery times for all orders?


SELECT 
  MAX(duration::NUMERIC) - MIN(duration::NUMERIC) AS max_diff
FROM runner_orders_temp 
WHERE pickup_time != '';


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

WITH cte_avg_speed AS 
  (SELECT 
    runner_id,
    order_id,
    DATE_PART('hour',pickup_time::TIMESTAMP) AS hour_of_the_day,
    distance::NUMERIC AS distance,
    duration::NUMERIC AS duration
  FROM runner_orders_temp
  WHERE pickup_time != '')

SELECT 
  runner_id, 
  order_id,
  hour_of_the_day,
  distance,
  duration,
  ROUND((distance/duration*60),2) AS avg_speed
FROM cte_avg_speed 
;


-- 7. What is the successful delivery percentage for each runner?

SELECT 
  runner_id,
  100 * SUM(CASE WHEN pickup_time != '' THEN 1 ELSE 0 END) / COUNT(*) AS success_per
FROM runner_orders_temp 
GROUP BY 1
ORDER BY 1;


-- PART C 

--1. What are the standard ingredients for each pizza?

SELECT 
  *
FROM pizza_runner.pizza_toppings;

SELECT 
  *
FROM pizza_runner.pizza_recipes;


WITH cte_split AS 
  (SELECT
    pizza_id,
    REGEXP_SPLIT_TO_TABLE(toppings,'[,\s]+')::INTEGER AS topping_id
  FROM pizza_runner.pizza_recipes)

SELECT 
  c1.pizza_id,
  STRING_AGG(c2.topping_name::TEXT,', ') AS standard_ingredienst
FROM cte_split c1 
INNER JOIN pizza_runner.pizza_toppings c2 
ON c1.topping_id = c2.topping_id 
GROUP BY 1
ORDER BY 1;


-- 2. What was the most commonly added extra ?

SELECT 
  *
FROM customer_orders_temp;

SELECT
  *
FROM pizza_runner.pizza_toppings;


WITH cte_common_extras AS 
  (SELECT 
    REGEXP_SPLIT_TO_TABLE(extras,'[,\s]+')::INTEGER AS extras
  FROM customer_orders_temp c
  WHERE extras !='')

SELECT
  p.topping_name,
  COUNT(*) as extra_counts
FROM cte_common_extras c 
INNER JOIN pizza_runner.pizza_toppings p 
ON c.extras = p.topping_id
GROUP BY 1
ORDER BY 2 DESC;


-- 3. What was the most common exclusion ?


WITH cte_common_exclusions AS 
  (SELECT 
    REGEXP_SPLIT_TO_TABLE(exclusions,'[,\s]+')::INTEGER AS exclusions
  FROM customer_orders_temp
  WHERE exclusions != '')
  
SELECT 
  p.topping_name,
  COUNT(*) AS common_exclusions
FROM cte_common_exclusions c 
INNER JOIN pizza_runner.pizza_toppings p 
ON c.exclusions = p.topping_id
GROUP BY 1
ORDER BY 2 DESC;


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- + Meat Lovers + Meat Lovers - Exclude Beef + Meat Lovers - Extra Bacon + Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


WITH cte_cleaned_customer_orders AS 
  (SELECT 
    order_id,
    order_time,
    customer_id,
    pizza_id,
    CASE WHEN exclusions IN('') THEN NULL ELSE exclusions END AS exclusions,
    CASE WHEN extras IN('') THEN NULL ELSE extras END AS extras,
    ROW_NUMBER() OVER() AS original_row_number 
  FROM customer_orders_temp),

cte_extras_exclusions AS (
    SELECT
      order_id,
      customer_id,
      pizza_id,
      REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::INTEGER AS exclusions_topping_id,
      REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+')::INTEGER AS extras_topping_id,
      order_time,
      original_row_number
    FROM cte_cleaned_customer_orders
  UNION 
    SELECT
      order_id,
      customer_id,
      pizza_id,
      NULL AS exclusions_topping_id,
      NULL AS extras_topping_id,
      order_time,
      original_row_number
    FROM cte_cleaned_customer_orders
    WHERE exclusions IS NULL AND extras IS NULL
),
cte_complete_dataset AS (
  SELECT
    base.order_id,
    base.customer_id,
    base.pizza_id,
    names.pizza_name,
    base.order_time,
    base.original_row_number,
    STRING_AGG(exclusions.topping_name, ', ') AS exclusions,
    STRING_AGG(extras.topping_name, ', ') AS extras
  FROM cte_extras_exclusions AS base
  INNER JOIN pizza_runner.pizza_names AS names
    ON base.pizza_id = names.pizza_id
  LEFT JOIN pizza_runner.pizza_toppings AS exclusions
    ON base.exclusions_topping_id = exclusions.topping_id
  LEFT JOIN pizza_runner.pizza_toppings AS extras
    ON base.exclusions_topping_id = extras.topping_id
  GROUP BY
    base.order_id,
    base.customer_id,
    base.pizza_id,
    names.pizza_name,
    base.order_time,
    base.original_row_number
),
cte_parsed_string_outputs AS (
SELECT
  order_id,
  customer_id,
  pizza_id,
  order_time,
  original_row_number,
  pizza_name,
  CASE WHEN exclusions IS NULL THEN '' ELSE ' - Exclude ' || exclusions END AS exclusions,
  CASE WHEN extras IS NULL THEN '' ELSE ' - Extra ' || extras END AS extras
FROM cte_complete_dataset
)
,
final_output AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    order_time,
    original_row_number,
    pizza_name || exclusions || extras AS order_item
  FROM cte_parsed_string_outputs
)
SELECT
  order_id,
  customer_id,
  pizza_id,
  order_time,
  order_item
FROM final_output
ORDER BY original_row_number;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add 
-- a 2x in front of any relevant ingredients + For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH cte_cleaned_customer_orders AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE
      WHEN exclusions IN ('', 'null') THEN NULL
      ELSE exclusions
    END AS exclusions,
    CASE
      WHEN extras IN ('', 'null') THEN NULL
      ELSE extras
    END AS extras,
    order_time,
    ROW_NUMBER() OVER () AS original_row_number
  FROM pizza_runner.customer_orders
),
-- split the toppings using our previous solution
cte_regular_toppings AS (
SELECT
  pizza_id,
  REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
FROM pizza_runner.pizza_recipes
)
,
-- now we can should left join our regular toppings with all pizzas orders
cte_base_toppings AS (
  SELECT
    cte_cleaned_customer_orders.order_id,
    cte_cleaned_customer_orders.customer_id,
    cte_cleaned_customer_orders.pizza_id,
    cte_cleaned_customer_orders.order_time,
    cte_cleaned_customer_orders.original_row_number,
    cte_regular_toppings.topping_id
  FROM cte_cleaned_customer_orders
  LEFT JOIN cte_regular_toppings
    ON cte_cleaned_customer_orders.pizza_id = cte_regular_toppings.pizza_id
)
,
-- now we can generate CTEs for exclusions and extras by the original row number
cte_exclusions AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    order_time,
    original_row_number,
    REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::INTEGER AS topping_id
  FROM cte_cleaned_customer_orders
  WHERE exclusions IS NOT NULL
),

cte_extras AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    order_time,
    original_row_number,
    REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+')::INTEGER AS topping_id
  FROM cte_cleaned_customer_orders
  WHERE extras IS NOT NULL
),
-- now we can perform an except and a union all on the respective CTEs
cte_combined_orders AS (
  SELECT * FROM cte_base_toppings
  EXCEPT
  SELECT * FROM cte_exclusions
  UNION ALL
  SELECT * FROM cte_extras
),
-- aggregate the count of topping ID and join onto pizza toppings
cte_joined_toppings AS (
  SELECT
    t1.order_id,
    t1.customer_id,
    t1.pizza_id,
    t1.order_time ,
    t1.original_row_number ,
    t1.topping_id ,
    t2.pizza_name AS pizza_name,
    t3.topping_name ,
    COUNT(t1.*) AS topping_count
  FROM cte_combined_orders AS t1
  INNER JOIN pizza_runner.pizza_names AS t2
    ON t1.pizza_id = t2.pizza_id
  INNER JOIN pizza_runner.pizza_toppings AS t3
    ON t1.topping_id = t3.topping_id
  GROUP BY 1,2,3,4,5,6,7,8
),
final_output AS 
  (SELECT
    order_id,
    customer_id,
    pizza_id,
    order_time,
    original_row_number,
    -- this logic is quite intense!
    pizza_name, ': ' || STRING_AGG(
      CASE
        WHEN topping_count > 1 THEN topping_count || 'x ' || topping_name
        ELSE topping_name
        END,
      ', '
    ) AS ingredients_list
  FROM cte_joined_toppings
  GROUP BY 1,2,3,4,5,6)

SELECT 
  order_id,
  customer_id,
  pizza_id,
  order_time,
  original_row_number,
  pizza_name || ingredients_list AS ingredients_list
FROM final_output
;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


WITH cte_cleaned_customer_orders AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE
      WHEN exclusions IN ('', 'null') THEN NULL
      ELSE exclusions
    END AS exclusions,
    CASE
      WHEN extras IN ('', 'null') THEN NULL
      ELSE extras
    END AS extras,
    order_time,
    ROW_NUMBER() OVER () AS original_row_number
  FROM pizza_runner.customer_orders
),
-- split the toppings using our previous solution
cte_regular_toppings AS (
SELECT
  pizza_id,
  REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
FROM pizza_runner.pizza_recipes
),
-- now we can should left join our regular toppings with all pizzas orders
cte_base_toppings AS (
  SELECT
    cte_cleaned_customer_orders.order_id,
    cte_cleaned_customer_orders.customer_id,
    cte_cleaned_customer_orders.pizza_id,
    cte_cleaned_customer_orders.order_time,
    cte_cleaned_customer_orders.original_row_number,
    cte_regular_toppings.topping_id
  FROM cte_cleaned_customer_orders
  LEFT JOIN cte_regular_toppings
    ON cte_cleaned_customer_orders.pizza_id = cte_regular_toppings.pizza_id
),
-- now we can generate CTEs for exclusions and extras by the original row number
cte_exclusions AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    order_time,
    original_row_number,
    REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::INTEGER AS topping_id
  FROM cte_cleaned_customer_orders
  WHERE exclusions IS NOT NULL
),
-- check this one!
cte_extras AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    order_time,
    original_row_number,
    REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+')::INTEGER AS topping_id
  FROM cte_cleaned_customer_orders
  WHERE extras IS NOT NULL
),
-- now we can perform an except and a union all on the respective CTEs
-- also check this one!
cte_combined_orders AS (
  SELECT * FROM cte_base_toppings
  EXCEPT
  SELECT * FROM cte_exclusions
  UNION ALL
  SELECT * FROM cte_extras
)
-- perform aggregation on topping_id and join to get topping names
SELECT
  t2.topping_name,
  COUNT(*) AS topping_count
FROM cte_combined_orders AS t1
INNER JOIN pizza_runner.pizza_toppings AS t2
  ON t1.topping_id = t2.topping_id
GROUP BY t2.topping_name
ORDER BY topping_count DESC;



-- Part D: Price and Ratings 

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT 
  SUM(CASE WHEN pizza_id = '1' THEN 12 END) AS Meatlover,
  SUM(CASE WHEN pizza_id = '2' THEN 10 END) AS Vegetarian
FROM customer_orders_temp;


-- 2. What if there was an additional $1 charge for any pizza extras? + Add cheese is $1 extra

SELECT 
  order_id,
  customer_id,
  pizza_id,
  REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::INTEGER AS exclusions,
  order_time
FROM customer_orders_temp
;


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
-- how would you design an additional table for this new dataset - 
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

SELECT SETSEED(1);

DROP TABLE IF EXISTS pizza_runner.ratings;
CREATE TABLE pizza_runner.ratings (
  "order_id" INTEGER,
  "rating" INTEGER
);

INSERT INTO pizza_runner.ratings
SELECT
  order_id,
  FLOOR(1 + 5 * RANDOM()) AS rating
FROM pizza_runner.runner_orders
WHERE pickup_time IS NOT NULL;


-- 4. Using your newly generated table - 
-- can you join all of the information together to form a table which has the following information for successful deliveries? 
-- + customer_id + order_id + runner_id + rating + order_time + pickup_time + Time between order and pickup + Delivery duration + Average speed + Total number of pizzas

WITH cte_adjusted_runner_orders AS (
  SELECT
    t1.order_id,
    t1.runner_id,
    t2.order_time,
    t3.rating,
    t1.pickup_time::TIMESTAMP AS pickup_time,
    UNNEST(REGEXP_MATCH(duration, '(^[0-9]+)'))::NUMERIC AS duration,
    UNNEST(REGEXP_MATCH(distance, '(^[0-9,.]+)'))::NUMERIC AS distance,
    COUNT(t2.*) AS pizza_count
  FROM pizza_runner.runner_orders AS t1
  INNER JOIN pizza_runner.customer_orders AS t2
    ON t1.order_id = t2.order_id
  LEFT JOIN pizza_runner.ratings AS t3
    ON t3.order_id = t2.order_id
  -- WHERE t1.pickup_time != 'null'
  GROUP BY 1,2,3,4,5,6,7
)
SELECT
  order_id,
  runner_id,
  rating,
  order_time,
  pickup_time,
  DATE_PART('min', AGE(pickup_time::TIMESTAMP, order_time))::INTEGER AS pickup_minutes,
  ROUND((distance/duration*60),2) AS avg_speed,
  pizza_count
FROM cte_adjusted_runner_orders;


-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled -
-- how much money does Pizza Runner have left over after these deliveries?

WITH cte_adjusted_runner_orders AS (
  SELECT
    t1.order_id,
    t1.runner_id,
    t2.order_time,
    t3.rating,
    t1.pickup_time::TIMESTAMP AS pickup_time,
    UNNEST(REGEXP_MATCH(duration, '(^[0-9]+)'))::NUMERIC AS duration,
    UNNEST(REGEXP_MATCH(distance, '(^[0-9,.]+)'))::NUMERIC AS distance,
    SUM(CASE WHEN t2.pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers_count,
    SUM(CASE WHEN t2.pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian_count
  FROM pizza_runner.runner_orders AS t1
  INNER JOIN pizza_runner.customer_orders AS t2
    ON t1.order_id = t2.order_id
  LEFT JOIN pizza_runner.ratings AS t3
    ON t3.order_id = t2.order_id
  WHERE t1.pickup_time != 'null'
  GROUP BY
    t1.order_id,
    t1.runner_id,
    t3.rating,
    t2.order_time,
    t1.pickup_time,
    t1.duration,
    t1.distance
)
SELECT
  SUM(
    12 * meatlovers_count + 10 * vegetarian_count - 0.3 * distance
  ) AS leftover_revenue
FROM cte_adjusted_runner_orders;