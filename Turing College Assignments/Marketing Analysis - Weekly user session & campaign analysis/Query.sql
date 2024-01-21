WITH base AS(
  SELECT
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp_cvrt,
    TIMESTAMP_MICROS(user_first_touch_timestamp) AS first_visit_timestamp,
    *
  FROM
    `turing_data_analytics.raw_events`
  WHERE
    user_first_touch_timestamp IS NOT NULL),


user_activity AS (
  SELECT
    user_pseudo_id AS user_id,
    first_visit_timestamp,
    event_name,
    event_timestamp_cvrt,
    LAG(event_timestamp_cvrt)
      OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp_cvrt ASC) AS prvs_event_time,
    event_value_in_usd AS revenue,
    campaign,
    category
  FROM
    base
),

user_session AS(
  SELECT
    user_id,
    first_visit_timestamp,
    event_name,
    event_timestamp_cvrt,
    EXTRACT(DATE FROM event_timestamp_cvrt) AS event_date, 
    EXTRACT(DAYOFWEEK FROM event_timestamp_cvrt) AS event_day,
    EXTRACT(WEEK FROM event_timestamp_cvrt) AS event_week,
    prvs_event_time,
    TIMESTAMP_DIFF(event_timestamp_cvrt,prvs_event_time,SECOND) AS action_interval,
    revenue,
    campaign,
    category
  FROM
    user_activity 
  ORDER BY
    user_id ASC, event_timestamp_cvrt ASC),

User_session_ext AS (
  SELECT
    user_id,
    event_date,
    MAX(session_duration) AS total_daily_session
  FROM(
    SELECT
    *,
        SUM(action_interval)
      OVER(PARTITION BY user_id,event_date ORDER BY event_timestamp_cvrt ASC) AS session_duration
    FROM 
      (SELECT
          *
      FROM
       user_session
      WHERE
        action_interval BETWEEN 1 AND 600
      OR
        action_interval IS NULL ))
  GROUP BY 
    user_id,
    event_date
  ORDER BY
    user_id ASC,
    event_date ASC),

user_reach AS(
  SELECT
    us.user_id,
    first_visit_timestamp,
    event_name,
    event_timestamp_cvrt,
    us.event_date, 
    event_day,
    event_week,
    prvs_event_time,
    action_interval,
    usx.total_daily_session,
    r.reach_channel,
    campaign,
    revenue,
    category,
    ROW_NUMBER() OVER (PARTITION BY us.user_id,us.event_date ORDER BY us.event_timestamp_cvrt ASC) AS row_n
  FROM
    user_session us
  LEFT JOIN(
    SELECT
      user_id,
      campaign AS reach_channel 
    FROM
      user_session
    WHERE
      event_name = 'page_view'
      AND
      first_visit_timestamp = event_timestamp_cvrt) r
  ON
    us.user_id = r.user_id
  LEFT JOIN
    user_session_ext usx
  ON
    usx.user_id = us.user_id
    AND
    usx.event_date = us.event_date
  )


SELECT
  user_id,
  first_visit_timestamp,
  event_date,
  event_day,
  event_week,
  total_daily_session,
  IF(reach_channel IS NULL,'Unknown',reach_channel) AS reach_channel,
  revenue,
  category,
  row_n
FROM
  user_reach
WHERE
  row_n = 1
order by
  event_date ASC,
  user_id ASC   
