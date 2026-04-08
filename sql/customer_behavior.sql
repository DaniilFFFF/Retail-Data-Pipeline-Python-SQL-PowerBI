CREATE DATABASE customer_behavior;
USE customer_behavior;
-- Q1. Який загальний дохід (revenue), отриманий від чоловіків порівняно з жінками?
select gender, SUM(purchase_amount) as revenue
from customer
group by gender;


-- Q2. Які клієнти використали знижку, але все одно витратили більше, ніж середній чек?
select customer_id, purchase_amount 
from customer 
where discount_applied = 'Yes' and purchase_amount >= (select AVG(purchase_amount) from customer);


-- Q3. Які топ-5 товарів мають найвищий середній рейтинг відгуків?
select item_purchased, round(avg(review_rating),2) as "Average Product Rating"
from customer
group by item_purchased
order by avg(review_rating) desc
limit 5;

-- Q4. Порівняйте середні суми покупок для типів доставки Standard та Express. 
select shipping_type, 
ROUND(AVG(purchase_amount),2)
from customer
where shipping_type in ('Standard','Express')
group by shipping_type;

-- Q5. Чи витрачають підписані клієнти більше? Порівняйте середній чек та загальний дохід 
-- між підписниками та звичайними покупцями.
SELECT subscription_status,
       COUNT(customer_id) AS total_customers,
       ROUND(AVG(purchase_amount),2) AS avg_spend,
       ROUND(SUM(purchase_amount),2) AS total_revenue
FROM customer
GROUP BY subscription_status
ORDER BY total_revenue,avg_spend DESC;

-- Q6. Які 5 товарів мають найвищий відсоток покупок із застосуванням знижок?
SELECT item_purchased,
       ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS discount_rate
FROM customer
GROUP BY item_purchased
ORDER BY discount_rate DESC
LIMIT 5;


-- Q7. Сегментуйте клієнтів на "Нових", "Тих, що повернулися" та "Лояльних" на основі
-- кількості їхніх попередніх покупок.
with customer_type as (
SELECT customer_id, previous_purchases,
CASE 
    WHEN previous_purchases = 1 THEN 'New'
    WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
    ELSE 'Loyal'
    END AS customer_segment
FROM customer)

select customer_segment,count(*) AS "Number of Customers" 
from customer_type 
group by customer_segment;

-- Q8. Які топ-3 найбільш куповані товари в кожній категорії?
WITH item_counts AS (
    SELECT category,
           item_purchased,
           COUNT(customer_id) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY COUNT(customer_id) DESC) AS item_rank
    FROM customer
    GROUP BY category, item_purchased
)
SELECT item_rank,category, item_purchased, total_orders
FROM item_counts
WHERE item_rank <=3;
 
-- Q9. Чи схильні клієнти, які роблять багато покупок (понад 5), частіше оформлювати підписку?
SELECT subscription_status,
       COUNT(customer_id) AS repeat_buyers
FROM customer
WHERE previous_purchases > 5
GROUP BY subscription_status;

-- Q10. Який внесок у загальний дохід робить кожна вікова група?
SELECT 
    age_group,
    SUM(purchase_amount) AS total_revenue
FROM customer
GROUP BY age_group
ORDER BY total_revenue desc;

-- Q11. ABC-аналіз товарів (Категоризація за внеском у прибуток)
WITH item_revenues AS (
    SELECT item_purchased, 
           SUM(purchase_amount) as total_revenue
    FROM customer
    GROUP BY item_purchased
),
percent_calc AS (
    SELECT item_purchased, total_revenue,
           SUM(total_revenue) OVER(ORDER BY total_revenue DESC) / SUM(total_revenue) OVER() as cumulative_share
    FROM item_revenues
)
SELECT item_purchased, total_revenue,
       CASE 
           WHEN cumulative_share <= 0.8 THEN 'A (Top 80%)'
           WHEN cumulative_share <= 0.95 THEN 'B (Next 15%)'
           ELSE 'C (Bottom 5%)'
       END AS abc_class
FROM percent_calc;

-- Q12. Аналіз "Cohort-light" (Утримання клієнтів за кількістю покупок)
SELECT subscription_status,
       CASE 
           WHEN previous_purchases < 5 THEN 'Low Activity (1-5)'
           WHEN previous_purchases BETWEEN 6 AND 20 THEN 'Medium Activity (6-20)'
           ELSE 'High Activity (20+)'
       END AS loyalty_segment,
       COUNT(*) as customer_count,
       ROUND(AVG(purchase_amount), 2) as avg_check
FROM customer
GROUP BY subscription_status, loyalty_segment
ORDER BY subscription_status, avg_check DESC;