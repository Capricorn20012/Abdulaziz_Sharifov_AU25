
--TASK 1

WITH customer_channel_sales AS (
    SELECT
        ch.channel_desc,
        c.cust_id,
        c.cust_first_name,
        c.cust_last_name,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    JOIN sh.customers c ON s.cust_id = c.cust_id
    JOIN sh.channels ch ON s.channel_id = ch.channel_id
    GROUP BY
        ch.channel_desc,
        c.cust_id,
        c.cust_first_name,
        c.cust_last_name
),
ranked_customers AS (
    SELECT
        channel_desc,
        cust_id,
        cust_first_name,
        cust_last_name,
        amount_sold,
        ROW_NUMBER() OVER (
            PARTITION BY channel_desc
            ORDER BY amount_sold DESC
        ) AS rn,
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
WHERE rn <= 5
ORDER BY
    channel_desc,
    amount_sold DESC;


        
--TASK 2

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT
    product_name,
    TO_CHAR(COALESCE(q1, 0), 'FM9999999.00') AS q1,
    TO_CHAR(COALESCE(q2, 0), 'FM9999999.00') AS q2,
    TO_CHAR(COALESCE(q3, 0), 'FM9999999.00') AS q3,
    TO_CHAR(COALESCE(q4, 0), 'FM9999999.00') AS q4,
    TO_CHAR(
        COALESCE(q1,0) + COALESCE(q2,0) +
        COALESCE(q3,0) + COALESCE(q4,0),
        'FM9999999.00'
    ) AS year_sum
FROM crosstab(
    $$
    SELECT
        p.prod_name,
        t.calendar_quarter_desc,
        SUM(s.amount_sold)
    FROM sh.sales s
    JOIN sh.products p   ON s.prod_id = p.prod_id
    JOIN sh.times t      ON s.time_id = t.time_id
    JOIN sh.customers c  ON s.cust_id = c.cust_id
    JOIN sh.countries co ON c.country_id = co.country_id
    WHERE UPPER(p.prod_category) = 'PHOTO'
      AND UPPER(co.country_region) = 'ASIA'
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
        t.calendar_year,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY
        s.cust_id,
        t.calendar_year
),
ranked AS (
    SELECT
        cust_id,
        calendar_year,
        total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY calendar_year
            ORDER BY total_sales DESC
        ) AS rn
    FROM yearly_sales
),
top_customers AS (
    SELECT cust_id
    FROM ranked
    WHERE rn <= 300
    GROUP BY cust_id
    HAVING COUNT(DISTINCT calendar_year) = 3
)
SELECT
    ch.channel_desc,
    t.calendar_year,
    c.cust_last_name,
    c.cust_first_name,
    TO_CHAR(SUM(s.amount_sold), 'FM999999999.00') AS total_sales
FROM sh.sales s
JOIN sh.times t      ON s.time_id = t.time_id
JOIN sh.channels ch  ON s.channel_id = ch.channel_id
JOIN sh.customers c  ON s.cust_id = c.cust_id
JOIN top_customers tc ON s.cust_id = tc.cust_id
WHERE t.calendar_year IN (1998, 1999, 2001)
GROUP BY
    ch.channel_desc,
    t.calendar_year,
    c.cust_last_name,
    c.cust_first_name
ORDER BY
    t.calendar_year,
    ch.channel_desc,
    total_sales DESC;


    
--TASK 4

SELECT DISTINCT
    t.calendar_month_desc,
    p.prod_category,
    TO_CHAR(
        SUM(CASE WHEN UPPER(co.country_region) = 'AMERICAS'
                 THEN s.amount_sold END)
        OVER (PARTITION BY t.calendar_month_desc, p.prod_category),
        'FM999999999'
    ) AS "Americas SALES",
    TO_CHAR(
        SUM(CASE WHEN UPPER(co.country_region) = 'EUROPE'
                 THEN s.amount_sold END)
        OVER (PARTITION BY t.calendar_month_desc, p.prod_category),
        'FM999999999'
    ) AS "Europe SALES"
FROM sh.sales s
JOIN sh.times t      ON s.time_id = t.time_id
JOIN sh.products p   ON s.prod_id = p.prod_id
JOIN sh.customers c  ON s.cust_id = c.cust_id
JOIN sh.countries co ON c.country_id = co.country_id
WHERE t.calendar_year = 2000
  AND t.calendar_month_number IN (1, 2, 3)
ORDER BY
    t.calendar_month_desc,
    p.prod_category;