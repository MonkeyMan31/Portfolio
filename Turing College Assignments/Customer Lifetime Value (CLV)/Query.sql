WITH base AS(
  SELECT
    CAST((LEFT(event_date,4) || '-' || RIGHT(LEFT(event_date,6),2) || '-' || RIGHT(event_date,2)) AS DATE) AS event_date,
    user_pseudo_id AS id,
    event_name,
    event_value_in_usd AS revenue
  FROM `turing_data_analytics.raw_events`
),

cohort AS(
  SELECT
    DATE_TRUNC(MIN(event_date), WEEK) AS reg_week,
    id
  FROM
    base
  GROUP BY 
    id
),

sales AS(
  SELECT
    b.id,
    c.reg_week, 
    DATE_TRUNC(event_date, WEEK) AS purchase_week,
    revenue
  FROM
    base b
  LEFT JOIN
    cohort c
  ON
    c.id = b.id 
  WHERE
    revenue IS NOT NULL
    AND
    revenue > 0
),

c1 AS (
  SELECT
    COUNT(id) AS reg_count,
    reg_week
  FROM
    cohort
  GROUP BY 
    reg_week
),

c2 AS (
  SELECT
    SUM(revenue) AS total_revenue,
    reg_week,
    DATE_DIFF(purchase_week, reg_week, WEEK) AS weeks_since_registration
  FROM
    sales
  GROUP BY
    reg_week,
    3
),

weekly_sale AS (
  SELECT
    c1.reg_week,
    c1.reg_count,
    c2.total_revenue/c1.reg_count AS avg_sale,
    c2.weeks_since_registration,
    c2.total_revenue
  FROM
    c1
  JOIN
    c2
  ON
    c1.reg_week = c2.reg_week
),

cumulative_sums AS (
  SELECT
    reg_week,
    weeks_since_registration,
    SUM(total_revenue) OVER (PARTITION BY reg_week ORDER BY weeks_since_registration) AS cumulative_revenue,
    (SUM(total_revenue) OVER (PARTITION BY reg_week ORDER BY weeks_since_registration))/reg_count AS cumulative_avg_revenue,
  FROM
    weekly_sale ws
),

cumulative_growth AS(
SELECT
  weeks_since_registration,
  (total_cumulative_avg / LAG(total_cumulative_avg, 1) OVER (ORDER BY weeks_since_registration) - 1) * 100 AS cumulative_growth,
  total_cumulative_avg
FROM(
  SELECT
    weeks_since_registration,
    AVG(cumulative_avg_revenue) AS total_cumulative_avg
  FROM
    cumulative_sums
  GROUP BY
    weeks_since_registration
    )
)


SELECT
  cs.reg_week,
  cs.weeks_since_registration,
  cg.total_cumulative_avg,
  cg.cumulative_growth
FROM
  cumulative_sums cs
JOIN
  cumulative_growth cg
ON
  cs.weeks_since_registration = cg.weeks_since_registration

