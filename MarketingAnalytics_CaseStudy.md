# Marketing Analytics

# **Logic and Processes** for different cases


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
