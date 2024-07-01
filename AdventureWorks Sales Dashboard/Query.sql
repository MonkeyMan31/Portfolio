WITH salesdetails AS(
  SELECT
    salesorderid,
    orderqty,
    productid,
    SpecialOfferID,
    unitprice,
    UnitPriceDiscount,
    linetotal
  FROM
    `tc-da-1.adwentureworks_db.salesorderdetail`),


specialoffer AS(
  SELECT
    SpecialOfferID,
    description,
    DiscountPct,
    type
  FROM
    `tc-da-1.adwentureworks_db.specialoffer`),


products AS(
  SELECT
    ProductID,
    name,
    color,
    standardcost,
    listprice
  FROM
    `tc-da-1.adwentureworks_db.product`),


salesorder AS (
  SELECT
    salesorderid,
    OrderDate,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    ShipToAddressID,
    ShipMethodID,
    SubTotal,
    TaxAmt,
    Freight,
    TotalDue
  FROM
    `tc-da-1.adwentureworks_db.salesorderheader` ),
  

salesterritory AS(
  SELECT
    TerritoryID,
    name,
    CountryRegionCode,
  FROM
    `tc-da-1.adwentureworks_db.salesterritory`
)


SELECT
  salesorderid,
  orderdate, 
  orderqty,
  productid,
  a.name,
  color,
  unitprice,
  description,
  DiscountPct,
  type,
  linetotal,
  ROUND((discountpct*linetotal),4) AS TotalDiscount,
  st.name AS TerritoryName,
  CountryRegionCode,
  CASE
    WHEN CountryRegionCode = 'CA' OR CountryRegionCode = 'US' THEN 'North America'
    WHEN CountryRegionCode = 'AU' THEN 'Pacific'
    ELSE 'Europe' END AS RegionGroup
FROM(
  SELECT
    sd.salesorderid,
    EXTRACT(DATE FROM orderdate) AS orderdate, 
    orderqty,
    sd.productid,
    name,
    color,
    unitprice,
    sd.SpecialOfferID,
    description,
    DiscountPct,
    type,
    linetotal,
    ROUND((discountpct*linetotal),4) AS TotalDiscount,
    territoryid,
  FROM
    salesdetails sd
  LEFT JOIN
    salesorder so
  ON
    sd.salesorderid = so.salesorderid
  LEFT JOIN
    products p
  ON
    sd.productid = p.productid
  LEFT JOIN
    specialoffer sf
  ON
    sd.specialofferid = sf.specialofferid
  ORDER BY 
    orderdate ASC, salesorderid ASC ) a
LEFT JOIN
  salesterritory st
ON
  a.territoryid = st.territoryid
