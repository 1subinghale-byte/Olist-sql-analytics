

-- Create customer unique id index 

CREATE UNIQUE INDEX UX_DimCustomers_Customer_Unique_Id
ON Olist.Dim.Customers (Customer_Unique_id);


-- 1. Insert Customer Data 
-- Additional deduped + add customer metrics 
WITH CleanCustomers AS (
    SELECT
        customer_id_clean        = LTRIM(RTRIM(REPLACE(customer_id, '"',''))),
        customer_unique_id_clean = LTRIM(RTRIM(REPLACE(customer_unique_id, '"',''))),
        city_clean               = UPPER(LTRIM(RTRIM(REPLACE(customer_city, '"','')))),
        state_clean              = LTRIM(RTRIM(REPLACE(customer_state, '"',''))),
        zip_clean                = TRY_CAST(REPLACE(customer_zip_code_prefix, '"','') AS INT)
    FROM STG.dbo.Customer
),
CleanOrders AS (
    SELECT
        order_id_clean   = LTRIM(RTRIM(REPLACE(order_id, '"',''))),
        customer_id_clean= LTRIM(RTRIM(REPLACE(customer_id, '"',''))),
        purchase_ts      = TRY_CAST(REPLACE(order_purchase_timestamp, '"','') AS DATETIME2)
    FROM STG.dbo.Orders
)
INSERT INTO Olist.Dim.Customers
    (Customer_unique_Id, City, [State], Zipcode, FirstOrderDate, LastOrderDate, TotalOrders, created_at)
SELECT
    c.customer_unique_id_clean AS Customer_unique_Id,
    MAX(c.city_clean)          AS City,
    MAX(c.state_clean)         AS [State],
    MAX(c.zip_clean)           AS Zipcode,
    CAST(MIN(o.purchase_ts) AS DATE) AS FirstOrderDate,
    CAST(MAX(o.purchase_ts) AS DATE) AS LastOrderDate,
    COUNT(DISTINCT o.order_id_clean)  AS TotalOrders,
    SYSDATETIME() AS created_at
FROM CleanCustomers c
LEFT JOIN CleanOrders o
    ON o.customer_id_clean = c.customer_id_clean
GROUP BY
    c.customer_unique_id_clean;





--- INSERT INTO Olist.Bridge.OrderCustomer (order_id, customer_id, customer_unique_id, customer_sk)
INSERT INTO Olist.dbo.OrderCustomer (order_id, customer_id, customer_unique_id, customer_sk)
SELECT
    f.order_id,
    f.customer_id,
    f.customer_unique_id,
    d.skcustomerid
FROM Olist.Fact.Orders f
LEFT JOIN Olist.Dim.Customers d
    ON d.Customer_unique_Id = f.customer_unique_id;


