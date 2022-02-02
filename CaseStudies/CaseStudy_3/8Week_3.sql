-- Plans table 

SELECT 
  *
FROM foodie_fi.plans
LIMIT 10;


-- Subscriptions Table

SELECT 
  *
FROM foodie_fi.subscriptions
LIMIT 10;


-- B. Data Analysis Questions 

-- 1. How many customers has Foodie-Fi ever had?

SELECT 
  COUNT(DISTINCT customer_id)
FROM foodie_fi.subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value


SELECT 
  DATE_TRUNC('month',s.start_date) AS MONTH,
  COUNT(*) AS total_distribution
FROM foodie_fi.subscriptions s 
INNER JOIN foodie_fi.plans p 
ON p.plan_id = s.plan_id
WHERE p.plan_name = 'trial'
GROUP BY 1
ORDER BY 1;


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT 
  p.plan_id,
  p.plan_name,
  COUNT(*) AS events 
FROM foodie_fi.subscriptions s 
INNER JOIN foodie_fi.plans p 
ON s.plan_id = p.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY 1,2
ORDER BY 1;


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
  SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) AS churn_customer,
  ROUND(100 * SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) / COUNT(DISTINCT customer_id)::NUMERIC,1) AS percentage
FROM foodie_fi.subscriptions;


--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to 1 decimal place?

WITH ranked_plans AS 
  (SELECT 
    customer_id,
    plan_id,
    start_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_rank
  FROM foodie_fi.subscriptions)

SELECT 
  SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) AS churn_customer,
  ROUND(100 * SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) / COUNT(DISTINCT customer_id)::NUMERIC,2) AS percentage
FROM ranked_plans
WHERE plan_rank = 2;


-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH cte_num AS 
  (SELECT 
    s.customer_id AS customer_id,
    s.plan_id AS plan_id,
    p.plan_name AS plan_name,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS ranks
  FROM foodie_fi.subscriptions s
  INNER JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id)
  
SELECT 
  plan_id,
  plan_name,
  COUNT(*) AS after_free_trial,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER()) AS percentage
FROM cte_num 
WHERE ranks = 2
GROUP BY 1,2
ORDER BY 1;


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH valid_subscriptions AS 
  (SELECT 
    customer_id,
    plan_id,
    start_date,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS valid_ranks
  FROM foodie_fi.subscriptions
  WHERE start_date <= '2020-12-31'),

summarised_plans AS 
  (SELECT
    plan_id,
    COUNT(customer_id) AS total_count
  FROM valid_subscriptions
  WHERE valid_ranks = 1
  GROUP BY 1)

SELECT 
  s.plan_id,
  p.plan_name,
  s.total_count,
  ROUND(100 * s.total_count / SUM(s.total_count) OVER(), 1) AS percentage
FROM summarised_plans s 
INNER JOIN foodie_fi.plans p  
ON p.plan_id = s.plan_id 
ORDER BY 1;


-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT 
  COUNT(DISTINCT customer_id) AS customers
FROM foodie_fi.subscriptions
WHERE plan_id = 3 
  AND start_date BETWEEN '2020-01-01' AND '2020-12-31';
  

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH annual_plan AS 
  (SELECT 
    customer_id,
    start_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3),

trial_plan AS 
  (SELECT 
    customer_id,
    start_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0)

SELECT 
  ROUND(AVG(DATE_PART('days',a.start_date::TIMESTAMP - t.start_date::TIMESTAMP))) AS average_days
FROM annual_plan a 
INNER JOIN trial_plan t 
ON a.customer_id = t.customer_id;


--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH annual_plan AS 
  (SELECT 
    customer_id,
    start_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3),

trial_plan AS 
  (SELECT 
    customer_id,
    start_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0),

annual_days AS 
  (SELECT 
    DATE_PART('days',a.start_date::TIMESTAMP - t.start_date::TIMESTAMP)::INTEGER AS duration
  FROM annual_plan a 
  INNER JOIN trial_plan t 
  ON a.customer_id = t.customer_id)

SELECT 
  30 * (a.duration / 10) || '-' || 60 * (a.duration / 10) || 'days' AS breakdown_days,
  COUNT(*) AS customers
FROM annual_days a 
GROUP BY 1,a.duration
ORDER BY a.duration;


--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH cte_downgrade AS 
  (SELECT
    customer_id,
    plan_id,
    start_date,
    LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS next_plan
  FROM foodie_fi.subscriptions
  WHERE DATE_PART('year',start_date) < '2021')

SELECT
  COUNT(*) AS total_count
FROM cte_downgrade
WHERE next_plan = 1 AND plan_id = 2;


-- C. Challeneg Payment option 

WITH leads AS 
  (SELECT 
    customer_id,
    plan_id,
    start_date,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS lead_start_date,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS lead_plan_id
  FROM foodie_fi.subscriptions
  WHERE DATE_PART('year',start_date) < '2021'
    AND plan_id != 0)

SELECT 
  plan_id,
  lead_plan_id,
  COUNT(lead_start_date) AS transition_count
FROM leads
GROUP BY 1,2
ORDER BY 1,2;



--case 1: non churn monthly customers
--case 2: churn customers
--case 3: customers who move from basic to pro plans
--case 4: pro monthly customers who move up to annual plans
--case 5: annual pro payments


WITH lead_plans AS 
  (SELECT 
    customer_id,
    plan_id,
    start_date,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS lead_start_date,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS lead_plan_id
  FROM foodie_fi.subscriptions
  WHERE DATE_PART('year',start_date) < '2021'
    AND plan_id != 0),

case1 AS 
(SELECT 
  customer_id,
  plan_id,
  start_date,
  DATE_PART('month',AGE('2020-12-31'::DATE, start_date))::INTEGER AS month_diff
FROM lead_plans
WHERE lead_plan_id IS NULL 
  AND plan_id NOT IN(3,4)),

case1_payments AS 
(SELECT 
  customer_id,
  plan_id,
  (start_date + GENERATE_SERIES(0,month_diff) * INTERVAL '1 month')::DATE AS start_date
FROM case1
),

case2 AS 
(SELECT 
  customer_id,
  plan_id,
  start_date,
  DATE_PART('month',AGE(lead_start_date -1, start_date))::INTEGER AS month_diff
FROM lead_plans
WHERE lead_plan_id = 4),

case2_payments AS 
(SELECT
  customer_id,
  plan_id,
  (start_date + GENERATE_SERIES(0,month_diff) * INTERVAL '1 month')::DATE AS start_date
FROM case2),

case3 AS 
(SELECT 
  customer_id,
  plan_id,
  start_date,
  DATE_PART('month',AGE(lead_start_date -1, start_date))::INTEGER AS month_diff
FROM lead_plans
WHERE plan_id = 1 AND lead_plan_id IN(2,3)),

case3_payments AS 
(SELECT
  customer_id,
  plan_id,
  (start_date + GENERATE_SERIES(0,month_diff) * INTERVAL '1 month')::DATE AS start_date
FROM case3),

case4 AS 
(SELECT
  customer_id,
  plan_id,
  start_date,
  DATE_PART('month',AGE(lead_start_date -1, start_date))::INTEGER AS month_diff
FROM lead_plans
WHERE plan_id = 2 AND lead_plan_id=3),

case4_payments AS 
(SELECT 
  customer_id,
  plan_id,
  (start_date + GENERATE_SERIES(0,month_diff) * INTERVAL '1 month')::DATE AS start_date
FROM case4),

case5 AS 
(SELECT
  customer_id,
  plan_id,
  start_date
FROM lead_plans
WHERE plan_id =3),

union_output AS
(SELECT 
  *
FROM case1_payments)

SELECT
  u.customer_id,
  p.plan_id,
  p.plan_name,
  u.start_date AS payment_date,
  CASE WHEN u.plan_id IN(2,3) AND 
    LAG(u.plan_id) OVER (PARTITION BY u.plan_id ORDER BY u.start_date) = 1
  THEN p.price - 9.90 
  ELSE p.price
  END AS amount,
  RANK() OVER (PARTITION BY u.plan_id ORDER BY u.start_date) AS payment_order
FROM union_output u 
INNER JOIN foodie_fi.plans p 
ON u.plan_id = p.plan_id;

