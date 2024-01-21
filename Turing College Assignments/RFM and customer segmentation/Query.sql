WITH base AS(
  SELECT
    *
  FROM
    `tc-da-1.turing_data_analytics.rfm` 
  WHERE  
    invoicedate >= '2010-12-01'
  AND 
    invoicedate <= '2011-12-01'
  AND
    CustomerID IS NOT NULL
  AND 
    quantity > 0
  AND 
    UnitPrice > 0 
  ),
  
a1 AS(
  SELECT
    customerid,
    CAST(MAX(invoicedate) AS DATE) AS last_purchase,
    COUNT(DISTINCT invoiceno) AS frequency,
    ROUND(SUM(unitprice*quantity),2) AS monetary
  FROM
    base
  GROUP BY 
    customerid
    ),

a2 AS(
  SELECT
    *,
    DATE_DIFF('2011-12-01',CAST(last_purchase AS DATE), DAY) AS recency
  FROM
    a1
  ),

a3 AS(
  SELECT
    a.*,
    b.percentiles[OFFSET(25)] AS m25,
    b.percentiles[OFFSET(50)] AS m50,
    b.percentiles[OFFSET(75)] AS m75,
    b.percentiles[OFFSET(100)] AS m100,
    c.percentiles[OFFSET(25)] AS f25,
    c.percentiles[OFFSET(50)] AS f50,
    c.percentiles[OFFSET(75)] AS f75,
    c.percentiles[OFFSET(100)] AS f100,
    d.percentiles[OFFSET(25)] AS r25,
    d.percentiles[OFFSET(50)] AS r50,
    d.percentiles[OFFSET(75)] AS r75,
    d.percentiles[OFFSET(100)] AS r100,
  FROM
    a2 AS a,
    (SELECT
      APPROX_QUANTILES(monetary, 100) AS percentiles 
     FROM
      a2) AS b,
    (SELECT
      APPROX_QUANTILES(frequency, 100) AS percentiles
     FROM
      a2) AS c,
    (SELECT
      APPROX_QUANTILES(recency, 100) AS percentiles
    FROM
      a2) AS d
  ),

a4 AS(
  SELECT
    *,
    CASE  WHEN monetary <= m25 THEN 4
          WHEN monetary <= m50 AND monetary > m25 THEN 3
          WHEN monetary <= m75 AND monetary > m50 THEN 2
          WHEN monetary <= m100 AND monetary > m75 THEN 1
    END AS m_score,
    CASE  WHEN frequency <= f25 THEN 4
          WHEN frequency <= f50 AND frequency > f25 THEN 3
          WHEN frequency <= f75 AND frequency > f50 THEN 2
          WHEN frequency <= f100 AND frequency > f75 THEN 1
    END AS f_score,
    CASE  WHEN recency <= r25 THEN 1
          WHEN recency <= r50 AND recency > r25 THEN 2
          WHEN recency <= r75 AND recency > r50 THEN 3
          WHEN recency <= r100 AND recency > r75 THEN 4
    END AS r_score    
  FROM
    a3
),

a5 AS(
  SELECT
    Customerid,
    last_purchase,
    recency,
    frequency,
    monetary,
    (r_score || f_score || m_score) AS RFM_score,
    r_score,
    f_score,
    m_score
  FROM
    a4)


  SELECT
  *,
  CASE WHEN RFM_score IN  ('111') THEN 'Best Customers'
       WHEN rfm_score IN ('112', '113', '114', '212','214','313','314','213') THEN 'Loyal Customers'
       WHEN rfm_score IN ('211', '221', '231', '241', '121', '131','141') THEN 'Big Spenders'
       WHEN rfm_score IN ('311', '321', '331', '341','312','322','332','342','324', '334') THEN 'Almost Lost'
       WHEN rfm_score IN ('411', '412', '413', '421', '422', '423', '431', '432','433','441','442', '444',
        '434', '443','433','424') THEN 'Lost Customers'
       WHEN rfm_score IN ('243','244','144','143','242','142','344','343') THEN 'One Timers'
       WHEN rfm_score IN ('223','333','323','232','222','233','134','133','123','124','122','132','234','224') THEN 'Potential Loyalist'
  END AS segment
FROM
  a5

  
