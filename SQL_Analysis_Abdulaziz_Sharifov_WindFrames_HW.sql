
--TASK 1

WITH channel_sales AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        SUM(amount_sold) AS amount_sold
    FROM sales
    WHERE calendar_year BETWEEN 1999 AND 2001
      AND country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY country_region, calendar_year, channel_desc
),
channel_share AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        ROUND(
            100.0 * amount_sold
            / SUM(amount_sold) OVER (
                PARTITION BY country_region, calendar_year
            ),
            2
        ) AS pct_by_channels
    FROM channel_sales
)
SELECT
    country_region,
    calendar_year,
    channel_desc,
    amount_sold AS amount_sold,
    pct_by_channels AS "% BY CHANNELS",
    LAG(pct_by_channels) OVER (
        PARTITION BY country_region, channel_desc
        ORDER BY calendar_year
    ) AS "% PREVIOUS PERIOD",
    ROUND(
        pct_by_channels
        - LAG(pct_by_channels) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ),
        2
    ) AS "% DIFF"
FROM channel_share
ORDER BY country_region, calendar_year, channel_desc;



--TASK 2

SELECT
    calendar_week_number,
    time_id,
    day_name,
    sales,


    SUM(sales) OVER (
        PARTITION BY calendar_week_number
        ORDER BY time_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sum,


    ROUND(
        AVG(sales) OVER (
            ORDER BY time_id
            ROWS BETWEEN
                CASE
                    WHEN day_name = 'Monday' THEN 2 PRECEDING
                    WHEN day_name = 'Friday' THEN 1 PRECEDING
                    ELSE 1 PRECEDING
                END
            AND
                CASE
                    WHEN day_name = 'Monday' THEN 1 FOLLOWING
                    WHEN day_name = 'Friday' THEN 2 FOLLOWING
                    ELSE 1 FOLLOWING
                END
        ),
        2
    ) AS centered_3_day_avg
FROM sales_daily
WHERE calendar_year = 1999
  AND calendar_week_number BETWEEN 49 AND 51
ORDER BY time_id;



--TASK 3

SELECT
    time_id,
    sales,
    AVG(sales) OVER (
        ORDER BY time_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_avg
FROM sales_daily;


SELECT
    time_id,
    sales,
    SUM(sales) OVER (
        ORDER BY time_id
        RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
    ) AS weekly_sum
FROM sales_daily;


SELECT
    channel_desc,
    calendar_year,
    SUM(amount_sold) AS yearly_sales,
    SUM(SUM(amount_sold)) OVER (
        ORDER BY calendar_year
        GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS two_year_sum
FROM sales
GROUP BY channel_desc, calendar_year;