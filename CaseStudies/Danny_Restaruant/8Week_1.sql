-- Danny's Diner
-- 1. Visiting paterns 
-- 2. Money spent 
-- 3. Fav menu items 


SELECT 
  *
FROM dannys_diner.sales;


SELECT 
  *
FROM dannys_diner.members;


SELECT 
  *
FROM dannys_diner.menu;


-- What is the total amount each customer spent at the restaurant?

SELECT
  s.customer_id,
  SUM(m.price) AS total_spent
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.menu m 
on s.product_id = m.product_id
GROUP BY 1;


-- How many days has each customer visited the restaurant?

SELECT 
  customer_id,
  COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY 1;


-- What was the first item from the menu purchased by each customer?


WITH order_sales AS 
  (SELECT 
    s.customer_id AS customer_id,
    s.order_date AS order_date,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranks,
    m.product_id AS product_id,
    m.product_name AS product_name
  FROM dannys_diner.sales s 
  INNER JOIN dannys_diner.menu m 
  ON s.product_id = m. product_id) 
  
SELECT 
  DISTINCT customer_id,
  order_date,
  product_name
FROM order_sales
WHERE ranks = 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
  m.product_name,
  COUNT(*)
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.menu m 
ON s.product_id = m.product_id
GROUP BY 1
LIMIT 1;


-- Which item was the most popular for each customer?

WITH popular AS 
  (SELECT 
    s.customer_id,
    m.product_name,
    COUNT(*),
    RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) ranks
  FROM dannys_diner.sales s 
  INNER JOIN dannys_diner.menu m 
  ON s.product_id = m.product_id
  GROUP BY 1,2)

SELECT 
  *
FROM popular
WHERE ranks = 1
;


-- Which item was purchased first by the customer after they became a member?

WITH first_purchase AS 
  (SELECT 
    s.customer_id AS customer_id,
    s.order_date AS order_date,
    s.product_id,
    me.product_name AS product_name,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) ranks
  FROM dannys_diner.sales s 
  INNER JOIN dannys_diner.members m 
  ON s.customer_id = m.customer_id 
  INNER JOIN dannys_diner.menu me 
  ON me.product_id = s.product_id
  WHERE m.join_date <= s.order_date)

SELECT 
  customer_id,
  order_date,
  product_name
FROM first_purchase 
WHERE ranks = 1
;



-- Which item was purchased just before the customer became a member?



WITH first_purchase AS 
  (SELECT 
    s.customer_id AS customer_id,
    s.order_date AS order_date,
    s.product_id,
    me.product_name AS product_name,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) ranks
  FROM dannys_diner.sales s 
  INNER JOIN dannys_diner.members m 
  ON s.customer_id = m.customer_id 
  INNER JOIN dannys_diner.menu me 
  ON me.product_id = s.product_id
  WHERE m.join_date > s.order_date)

SELECT 
  customer_id,
  order_date,
  product_name
FROM first_purchase 
WHERE ranks = 1
;


-- What is the total items and amount spent for each member before they became a member?

SELECT 
  m.customer_id,
  COUNT(DISTINCT s.product_id),
  SUM(me.price)
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.members m 
ON s.customer_id = m.customer_id 
INNER JOIN dannys_diner.menu me 
ON me.product_id = s.product_id 
WHERE m.join_date > s.order_date
GROUP BY 1;


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
  s.customer_id,
  SUM(CASE WHEN m.product_name = 'sushi' THEN 2*10*m.price 
      ELSE 10 * m.price END) AS points
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.menu m 
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1; 


-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
  s.customer_id,
  SUM(
      CASE 
          WHEN m.product_name = 'sushi' THEN 2*10*m.price 
           WHEN s.order_date BETWEEN me.join_date::DATE AND (me.join_date::DATE+6) THEN 2 * 10 * m.price
           ELSE 10* m.price
      END
      ) AS points
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.menu m 
ON s.product_id = m.product_id 
INNER JOIN dannys_diner.members me 
ON me.customer_id = s.customer_id 
WHERE s.order_date <= '2021-01-31'::DATE
GROUP BY 1
ORDER BY 2;


-- Bonus Questions 



