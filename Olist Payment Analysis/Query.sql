WITH products AS(  
  SELECT
    product_id,
    string_field_1 AS product_category_name,
    product_weight_g/1000 AS product_weight_kg,
    (product_length_cm*product_height_cm*product_width_cm)/1000000 AS product_volume
  FROM
    `olist_db.olist_products_dataset` pd
  LEFT JOIN
    `olist_db.product_category_name_translation` pcn
  ON
    pd.product_category_name = pcn.string_field_0),

customer_details AS (
  SELECT
    order_id,
    ood.customer_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    customer_zip_code_prefix,
    customer_city,
    customer_state
  FROM
    `olist_db.olist_orders_dataset` ood
  LEFT JOIN
    `olist_db.olist_customesr_dataset` ocd
  ON
    ocd.customer_id = ood.customer_id
  WHERE
    order_status != 'created'
    OR
    order_status != 'approved'
),


transactions AS(
  SELECT
    oi.order_id,
    customer_unique_id,
    order_item_id,
    oi.product_id,
    product_category_name,
    oi.seller_id,
    price,
    freight_value,
    IF(price<79,freight_value,0) AS customer_shipping_fee,
    IF(price>=79,freight_value/2,5) AS seller_shipping_fee,
    IF(price>=79,freight_value/2,0) AS olist_shipping_fee,
    cd.order_status,
    cd.order_purchase_timestamp,
    cd.order_approved_at,
    ROUND(TIMESTAMP_DIFF(cd.order_approved_at, cd.order_purchase_timestamp, MINUTE)/60, 2) AS approvement_interval,
    cd.order_delivered_carrier_date,
    ROUND(TIMESTAMP_DIFF(cd.order_delivered_carrier_date, cd.order_approved_at, MINUTE)/60, 2) AS handover_interval,
    cd.order_delivered_customer_date,
    ROUND(TIMESTAMP_DIFF(cd.order_delivered_customer_date,cd.order_delivered_carrier_date, MINUTE)/60, 2) AS delivery_interval,
    cd.order_estimated_delivery_date,
    product_weight_kg,
    product_volume,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    seller_zip_code_prefix,
    seller_city,
    seller_state
  FROM
    `olist_db.olist_order_items_dataset` oi
  LEFT JOIN
    products pd
  ON
    oi.product_id = pd.product_id
  LEFT JOIN
    `olist_db.olist_orders_dataset` odd
  ON
    oi.order_id = odd.order_id
  LEFT JOIN
    customer_details cd
  ON
    cd.customer_id = odd.customer_id
  LEFT JOIN
    `olist_db.olist_sellers_dataset` osd
  ON
    osd.seller_id = oi.seller_id
  WHERE
    cd.order_status != 'created'
    OR
    cd.order_status != 'approved'
    
),


transactions_detailed AS(
SELECT
  order_id,
  customer_unique_id,
  order_item_id,
  product_id,
  product_category_name,
  seller_id,
  price,
  freight_value,
  customer_shipping_fee,
  seller_shipping_fee,
  olist_shipping_fee,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  approvement_interval,
  CASE
    WHEN TIMESTAMP_DIFF(order_approved_at,order_purchase_timestamp, DAY) = 0 THEN 'Same Day Approvement'
    WHEN TIMESTAMP_DIFF(order_approved_at,order_purchase_timestamp, DAY) = 0 THEN 'Timely Approvement'
    WHEN TIMESTAMP_DIFF(order_approved_at,order_purchase_timestamp, DAY) = 0 THEN 'Late Approvement'
    ELSE NULL END AS approvement_performance,
  order_delivered_carrier_date,
  handover_interval,
  CASE
    WHEN TIMESTAMP_DIFF(order_delivered_carrier_date,order_approved_at, DAY) = 0 THEN 'Same Day Handover'
    WHEN TIMESTAMP_DIFF(order_delivered_carrier_date,order_approved_at, DAY) <= 4 THEN 'Timely Handover'
    WHEN TIMESTAMP_DIFF(order_delivered_carrier_date,order_approved_at, DAY) > 4 THEN 'Late Handover'
    ELSE NULL END AS handover_performance,
  order_delivered_customer_date,
  delivery_interval,
  CASE
    WHEN TIMESTAMP_DIFF(order_delivered_customer_date,order_delivered_carrier_date, DAY) <= 7 THEN 'Same Week Delivery'
    WHEN TIMESTAMP_DIFF(order_delivered_customer_date,order_delivered_carrier_date, DAY) <= 18 THEN 'Timely Delivery'
    WHEN TIMESTAMP_DIFF(order_delivered_customer_date,order_delivered_carrier_date, DAY) > 18 THEN 'Late Delivery'
    ELSE NULL END AS delivery_performance,
  order_estimated_delivery_date,
  IF(TIMESTAMP_DIFF(order_delivered_customer_date,order_estimated_delivery_date, DAY)>0,1,0) delayed_delivery,
  product_weight_kg,
  product_volume,
  customer_zip_code_prefix,
  customer_city,
  customer_state,
  seller_zip_code_prefix,
  seller_city,
  seller_state
FROM
  transactions
WHERE
  order_approved_at IS NOT NULL
  AND
  (approvement_interval IS NULL OR approvement_interval >= 0)
  AND
  (handover_interval IS NULL OR handover_interval > 0)
  AND
  (delivery_interval IS NULL OR delivery_interval > 0)
)

SELECT
  *
FROM
  transactions_detailed











