WITH cohort AS (
  SELECT
    user_pseudo_id AS id,
    DATE_TRUNC(subscription_start, ISOWEEK) AS subscription_week,
    DATE_TRUNC(subscription_end, ISOWEEK) AS churn_week
  FROM
    `turing_data_analytics.subscriptions`
),
base_count AS(
  SELECT
      COUNT(user_pseudo_id) AS Base_sub_count,
      DATE_TRUNC(subscription_start, ISOWEEK) AS subscription_week
    FROM
      `turing_data_analytics.subscriptions`
    GROUP BY
      subscription_week
)

SELECT
  *,
  CASE 
    WHEN weeks_since_subscription IS NULL THEN NULL
    ELSE ((cohort_size/base_sub_count)*100)
    END AS churn_rate,
  CASE 
    WHEN weeks_since_subscription IS NULL THEN ((cohort_size/base_sub_count)*100)
    ELSE NULL
    END AS Retention_rate
FROM(
  SELECT
    b.Base_sub_count AS Base_sub_count,
    c.subscription_week,
    COUNT(DISTINCT c.id) AS cohort_size,
    DATE_DIFF(c.churn_week, c.subscription_week, ISOWEEK) AS weeks_since_subscription,    
    COUNTIF(c.churn_week IS NOT NULL) AS churn_count
  FROM
    cohort c
  JOIN
    base_count b
  ON
    b.subscription_week = c.subscription_week
  GROUP BY
    b.Base_sub_count,
    c.subscription_week,
    weeks_since_subscription
  HAVING 
    weeks_since_subscription <= 6
    OR
    weeks_since_subscription IS NULL
  ORDER BY
    c.subscription_week, weeks_since_subscription) 
