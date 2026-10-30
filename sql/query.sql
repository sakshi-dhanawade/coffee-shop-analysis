CREATE database coffee_shop;
use coffee_shop;
select count(*) as total_rows,min(date) as first_date,max(date) as last_date from coffee_sales;


DROP TABLE IF EXISTS coffee_sales;

CREATE TABLE coffee_sales (
    hour_of_day   INT,
    cash_type     VARCHAR(20),
    price         DECIMAL(6,2),
    product       VARCHAR(50),
    time_of_day   VARCHAR(20),
    weekday       VARCHAR(10),
    month         VARCHAR(10),
    weekday_num   INT,
    month_num     INT,
    date          DATE,
    time          TIME,
    day           INT,
    year          INT,
    is_weekend    VARCHAR(10)
);

SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE '"C:\Users\Sakshi Dhanawade\Documents\coffee_project\data\cleaned_coffee_sales.csv"'
INTO TABLE coffee_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


#Query 1: Total revenue, orders, average order value
select round(sum(price),2) as total_revenue,
    count(*) as total_orders,
    round(avg(price),2) as avg_order_value
    from coffee_sales;
    
#Query 2: Revenue and orders by product, ranked
select product,
      count(*) as total_orders,
      round(sum(price),2) as total_revenue,
      round(avg(price),2) as avg_price,
      rank() over (order by sum(price) desc ) as revenue_rank
      from coffee_sales
      group by product
      order by total_revenue desc;
#Query 3: Monthly revenue trend
SELECT
    year,
    month,
    month_num,
    ROUND(SUM(price), 2) AS monthly_revenue,
    COUNT(*)             AS monthly_orders
FROM coffee_sales
GROUP BY year, month, month_num
ORDER BY year, month_num;

#Query 4: Month-over-month growth %
WITH monthly AS (
    SELECT year, month, month_num,
           SUM(price) AS revenue
    FROM coffee_sales
    GROUP BY year, month, month_num
)
SELECT
    year, month,
    revenue,
    LAG(revenue) OVER (ORDER BY year, month_num) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY year, month_num))
        / LAG(revenue) OVER (ORDER BY year, month_num), 1
    ) AS mom_growth_pct
FROM monthly
ORDER BY year, month_num;

#Query 5: Best-selling product per weekday
WITH ranked AS (
    SELECT
        weekday,
        product,
        SUM(price) AS revenue,
        RANK() OVER (PARTITION BY weekday ORDER BY SUM(price) DESC) AS rnk
    FROM coffee_sales
    GROUP BY weekday, product
)
SELECT weekday, product, revenue
FROM ranked
WHERE rnk = 1;

#Query 6: Revenue by weekday × time of day (matches your Python heatmap)
SELECT
    weekday,
    time_of_day,
    ROUND(SUM(price), 2) AS revenue,
    COUNT(*)             AS orders
FROM coffee_sales
GROUP BY weekday, time_of_day
ORDER BY weekday, time_of_day;

#Query 7: Peak hours (top 5 by revenue)
SELECT
    hour_of_day,
    COUNT(*)             AS orders,
    ROUND(SUM(price), 2) AS revenue
FROM coffee_sales
GROUP BY hour_of_day
ORDER BY revenue DESC
LIMIT 5;

#Query 8: Weekend vs weekday comparison
SELECT
    is_weekend,
    COUNT(*)                AS orders,
    ROUND(SUM(price), 2)    AS revenue,
    ROUND(AVG(price), 2)    AS avg_order_value
FROM coffee_sales
GROUP BY is_weekend;

#Query 9: Running (cumulative) revenue total — useful for a Tableau line chart later
SELECT
    date,
    ROUND(SUM(price), 2) AS daily_revenue,
    ROUND(SUM(SUM(price)) OVER (ORDER BY date), 2) AS cumulative_revenue
FROM coffee_sales
GROUP BY date
ORDER BY date;

