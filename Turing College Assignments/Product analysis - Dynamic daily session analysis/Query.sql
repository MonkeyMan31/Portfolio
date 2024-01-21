WITH BASE AS(
  SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp_cvrt,
    TIMESTAMP_MICROS(user_first_touch_timestamp) AS first_visit_stamp,
    *
  FROM
    `turing_data_analytics.raw_events`),

same_day_events AS(
  SELECT
    user_pseudo_id AS user_id,
    EXTRACT(DATE FROM first_visit_stamp) AS first_visit_date,
    CAST(first_visit_stamp AS TIME) AS first_visit_time,
    CASE
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 1 THEN 'Sunday'
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 2 THEN 'Monday'
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 3 THEN 'Tuesday'
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 4 THEN 'Wednesday'
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 5 THEN 'Thursday'
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 6 THEN 'Friday'
      WHEN EXTRACT(DAYOFWEEK FROM first_visit_stamp) = 7 THEN 'Saturday'
      END AS first_visit_day,
    event_name,
    CAST(event_timestamp_cvrt AS DATETIME) AS event_time,
    event_value_in_usd AS revenue,
    refund_value_in_usd AS refund,
    category,
    mobile_brand_name,
    operating_system,
    browser,
    country
  FROM
    base
  WHERE
    DATETIME_DIFF(first_visit_stamp,event_timestamp_cvrt,DAY) = 0
),

same_day_sales AS(
  SELECT
    sd.user_id,
    sd.first_visit_date,
    sd.first_visit_time,
    TIME_TRUNC(sd.first_visit_time,HOUR) AS first_visit_hour,
    sd.first_visit_day,
    event_time,
    event_name,
    CAST(b.item_select AS TIME) AS item_select_time,
    TIME_TRUNC(CAST(b.item_select AS TIME), HOUR) AS item_select_hour,
    TIME_DIFF(CAST(b.item_select AS TIME),sd.first_visit_time, MINUTE) AS selection_interval, 
    CAST(a.first_purchase_time AS TIME) AS first_purchase_time,
    TIME_TRUNC(CAST(a.first_purchase_time AS TIME), HOUR) AS first_purchase_hour,
    TIME_DIFF(CAST(a.first_purchase_time AS TIME),CAST(b.item_select AS TIME), MINUTE) AS checkout_interval,
    TIME_DIFF(CAST(a.first_purchase_time AS TIME),sd.first_visit_time,MINUTE) AS purchase_interval,
    a.purchase_count,
    revenue,
    category,
    mobile_brand_name,
    operating_system,
    browser,
    country
  FROM
    same_day_events sd
  LEFT JOIN
    (
      SELECT
        user_id,
        COUNT(event_name) AS purchase_count,
        MIN(event_time) AS first_purchase_time
      FROM
        same_day_events
      WHERE
        event_name = 'purchase'
        AND
        revenue > 0
        AND 
        refund IS NULL
        AND 
        TIME_DIFF(CAST(event_time AS TIME),first_visit_time, MINUTE) > 0
      GROUP BY
        user_id
    ) AS a
  ON
    a.user_id = sd.user_id
  LEFT JOIN
    (
      SELECT
        user_id,
        MIN(event_time) AS item_select
      FROM
        same_day_events
      WHERE
        event_name = 'add_to_cart'
        AND
        DATE_DIFF(first_visit_date,CAST(event_time AS DATE), DAY) = 0
      GROUP BY
        user_id
    ) b
  ON
    b.user_id = sd.user_id
  WHERE
    purchase_count > 0
    AND
    DATE_DIFF(first_visit_date,CAST(first_purchase_time AS DATE), DAY) = 0
  ORDER BY 
    user_id ASC, event_time ASC

),


c1 AS(
  SELECT
    user_id,
    event_name,
    MIN(event_time),
  FROM
    same_day_sales 
  WHERE
    event_name IN ('add_to_cart','purchase')
  GROUP BY
    user_id,
    event_name
),

cohort AS(
  SELECT
    c1.user_id,
    sds.first_visit_date,
    sds.first_visit_time,
    sds.first_visit_hour,
    sds.first_visit_day,
    sds.item_select_time,
    sds.item_select_hour,
    sds.selection_interval,
    sds.first_purchase_time,
    sds.first_purchase_hour,
    sds.checkout_interval,
    sds.purchase_interval,
    sds.purchase_count,
    sds.revenue,
    sds.category,
    sds.mobile_brand_name,
    sds.operating_system,
    sds.browser,
    sds.country
  FROM 
    c1
  LEFT JOIN
    same_day_sales sds
  ON
    c1.user_id = sds.user_id
)

cohortasqaa AS (
  SELECT
    *,
    IF(first_visit_date = purchase_date, TIME_DIFF(CAST(purchase_time AS TIME),first_visit_time,MINUTE), NULL) AS purchase_interval,
    ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY purchase_time ASC) AS row_no
    /*Used row number in order to remove the second or third purchase of customers*/ 
  FROM
    same_day_sales
),

purchases AS(
  SELECT
    user_id,
    COUNT(event_name) AS purchase_count,
    SUM(revenue) AS total_spent,
    SUM(purchase_interval)-((COUNT(purchase_interval)-1)*MIN(purchase_interval)) AS total_interval
  FROM
    cohort
  WHERE
    purchase_interval IS NOT NULL
  GROUP BY
    user_id
)

SELECT
  c.*,
  p.total_interval,
  p.purchase_count,
  p.total_spent
FROM
  cohort c
LEFT JOIN
  purchases p
ON
  p.user_id = c.user_id
WHERE
    c.purchase_interval IS NOT NULL
    AND
    c.purchase_interval > 0
    /*one entry with negative purchase interval*/
order by user_id 



