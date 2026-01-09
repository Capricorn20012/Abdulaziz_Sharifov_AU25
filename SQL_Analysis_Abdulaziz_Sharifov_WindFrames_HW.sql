
-- TASK 1

WITH channel_year_agg AS (
    SELECT
        co.country_region,
        t.calendar_year,
        ch.channel_desc,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    JOIN sh.channels ch   ON ch.channel_id = s.channel_id
    JOIN sh.times t       ON t.time_id = s.time_id
    JOIN sh.customers cu  ON cu.cust_id = s.cust_id
    JOIN sh.countries co  ON co.country_id = cu.country_id
    WHERE UPPER(co.country_region) IN ('AMERICAS', 'ASIA', 'EUROPE')
    GROUP BY
        co.country_region,
        t.calendar_year,
        ch.channel_desc
),
channel_share AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        total_sales,
        CASE
            WHEN SUM(total_sales) OVER (PARTITION BY country_region, calendar_year) = 0 THEN 0
            ELSE ROUND(
                total_sales
                / SUM(total_sales) OVER (PARTITION BY country_region, calendar_year)
                * 100, 2
            )
        END AS channel_pct
    FROM channel_year_agg
),
channel_trends AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        total_sales,
        channel_pct,
        LAG(channel_pct) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ) AS prev_pct,
        ROUND(
            channel_pct
            - LAG(channel_pct) OVER (
                PARTITION BY country_region, channel_desc
                ORDER BY calendar_year
            ),
            2
        ) AS pct_delta
    FROM channel_share
)
SELECT
    country_region,
    calendar_year,
    channel_desc,
    total_sales || ' $'  AS "AMOUNT_SOLD",
    channel_pct || ' %'  AS "% BY CHANNEL",
    prev_pct || ' %'     AS "% PREVIOUS PERIOD",
    pct_delta || ' %'    AS "% DIFF"
FROM channel_trends
WHERE calendar_year BETWEEN 1999 AND 2001
ORDER BY
    country_region,
    channel_desc,
    calendar_year;


-- TASK 2

WITH daily_sales_base AS (
    SELECT
        t.calendar_week_number,
        t.time_id::date AS sales_date,
        t.day_name,
        SUM(s.amount_sold) AS daily_sales
    FROM sh.sales s
    JOIN sh.times t ON t.time_id = s.time_id
    WHERE t.calendar_year = 1999
      AND t.calendar_week_number BETWEEN 48 AND 52
    GROUP BY
        t.calendar_week_number,
        t.time_id::date,
        t.day_name
),
window_calc AS (
    SELECT
        calendar_week_number,
        sales_date,
        day_name,
        daily_sales,

        SUM(daily_sales) OVER (
            PARTITION BY calendar_week_number
            ORDER BY sales_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,

        ROUND(
            CASE
                WHEN UPPER(day_name) = 'MONDAY' THEN
                    AVG(daily_sales) OVER (
                        ORDER BY sales_date
                        ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
                    )
                WHEN UPPER(day_name) = 'FRIDAY' THEN
                    AVG(daily_sales) OVER (
                        ORDER BY sales_date
                        ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
                    )
                ELSE
                    AVG(daily_sales) OVER (
                        ORDER BY sales_date
                        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
                    )
            END,
            2
        ) AS moving_avg_3d
    FROM daily_sales_base
)
SELECT
    calendar_week_number,
    sales_date,
    day_name,
    daily_sales,
    running_total,
    moving_avg_3d
FROM window_calc
WHERE calendar_week_number IN (49, 50, 51)
ORDER BY
    calendar_week_number,
    sales_date;

-- TASK 3

SELECT
    t.calendar_month_number,
    SUM(s.amount_sold) AS month_sales,


    FIRST_VALUE(SUM(s.amount_sold)) OVER (
        ORDER BY t.calendar_month_number
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS rows_first_value,


    FIRST_VALUE(SUM(s.amount_sold)) OVER (
        ORDER BY t.calendar_month_number
        RANGE BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS range_first_value,


    FIRST_VALUE(SUM(s.amount_sold)) OVER (
        ORDER BY t.calendar_month_number
        GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS groups_first_value

FROM sh.sales s
INNER JOIN sh.channels ch 
	ON ch.channel_id =s.channel_id 
INNER JOIN sh.times t 
    ON t.time_id = s.time_id
INNER JOIN sh.customers cust
    ON cust.cust_id = s.cust_id
INNER JOIN sh.countries c 
	ON c.country_id =cust.country_id 
WHERE t.calendar_year = 1998 AND UPPER(ch.channel_desc)='TELE SALES'
GROUP BY
    t.calendar_month_number
ORDER BY
    t.calendar_month_number;
