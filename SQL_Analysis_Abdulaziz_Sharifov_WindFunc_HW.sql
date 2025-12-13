
--TASK 1

WITH customer_channel_sales AS (

    SELECT
        ch.channel_desc,
        c.cust_last_name,
        c.cust_first_name,
        SUM(s.amount_sold) AS amount_sold
    FROM sales s
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN channels ch ON s.channel_id = ch.channel_id
    GROUP BY
        ch.channel_desc,
        c.cust_last_name,
        c.cust_first_name
),
ranked_customers AS (

    SELECT
        channel_desc,
        cust_last_name,
        cust_first_name,
        amount_sold,
        DENSE_RANK() OVER (
            PARTITION BY channel_desc
            ORDER BY amount_sold DESC
        ) AS rnk,

        SUM(amount_sold) OVER (
            PARTITION BY channel_desc
        ) AS channel_total
    FROM customer_channel_sales
)
SELECT
    channel_desc,
    cust_last_name,
    cust_first_name,
    TO_CHAR(amount_sold, 'FM999999999.00') AS amount_sold,
    TO_CHAR(
        (amount_sold / channel_total) * 100,
        'FM9999990.0000'
    ) || ' %' AS sales_percentage
FROM ranked_customers
WHERE rnk <= 5
ORDER BY
    channel_desc,
    amount_sold DESC;


        
--TASK 2

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    product_name,
    TO_CHAR(q1, 'FM9999999.00') AS q1,
    TO_CHAR(q2, 'FM9999999.00') AS q2,
    TO_CHAR(q3, 'FM9999999.00') AS q3,
    TO_CHAR(q4, 'FM9999999.00') AS q4,
    TO_CHAR(q1 + q2 + q3 + q4, 'FM9999999.00') AS year_sum
FROM crosstab(
    $$
    SELECT
        p.prod_name,
        t.calendar_quarter_desc,
        SUM(s.amount_sold)
    FROM sales s
    JOIN products p   ON s.prod_id = p.prod_id
    JOIN times t      ON s.time_id = t.time_id
    JOIN customers c  ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    WHERE p.prod_category = 'Photo'
      AND co.region = 'Asia'
      AND t.calendar_year = 2000
    GROUP BY
        p.prod_name,
        t.calendar_quarter_desc
    ORDER BY 1, 2
    $$,
    $$ VALUES ('Q1'), ('Q2'), ('Q3'), ('Q4') $$
) AS ct (
    product_name TEXT,
    q1 NUMERIC,
    q2 NUMERIC,
    q3 NUMERIC,
    q4 NUMERIC
)
ORDER BY year_sum DESC;



--TASK 3

WITH yearly_sales AS (

    SELECT
        s.cust_id,
        ch.channel_desc,
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales
    FROM sales s
    JOIN times t    ON s.time_id = t.time_id
    JOIN channels ch ON s.channel_id = ch.channel_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY
        s.cust_id,
        ch.channel_desc,
        t.calendar_year
),
ranked_customers AS (

    SELECT
        cust_id,
        channel_desc,
        calendar_year,
        total_sales,
        DENSE_RANK() OVER (
            PARTITION BY calendar_year
            ORDER BY total_sales DESC
        ) AS rnk
    FROM yearly_sales
)
SELECT
    rc.channel_desc,
    rc.calendar_year,
    c.cust_last_name,
    c.cust_first_name,
    TO_CHAR(rc.total_sales, 'FM999999999.00') AS total_sales
FROM ranked_customers rc
JOIN customers c ON rc.cust_id = c.cust_id
WHERE rc.rnk <= 300
ORDER BY
    rc.calendar_year,
    rc.channel_desc,
    rc.total_sales DESC;


    
--TASK 4

SELECT
    t.calendar_month_desc,
    p.prod_category,
    TO_CHAR(
        SUM(CASE WHEN co.region = 'Americas' THEN s.amount_sold END),
        'FM999999999'
    ) AS "Americas SALES",
    TO_CHAR(
        SUM(CASE WHEN co.region = 'Europe' THEN s.amount_sold END),
        'FM999999999'
    ) AS "Europe SALES"
FROM sales s
JOIN times t      ON s.time_id = t.time_id
JOIN products p   ON s.prod_id = p.prod_id
JOIN customers c  ON s.cust_id = c.cust_id
JOIN countries co ON c.country_id = co.country_id
WHERE t.calendar_year = 2000
  AND t.calendar_month_number IN (1, 2, 3)
GROUP BY
    t.calendar_month_desc,
    p.prod_category
ORDER BY
    t.calendar_month_desc,
    p.prod_category;