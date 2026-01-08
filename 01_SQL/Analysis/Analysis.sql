use Olist;
go

-- Analysis

--1. monthly revenue + rolling average 



WITH Monthly_revenue AS (
SELECT 
	D.[Year],
	D.[Month],
	D.[monthname],
	SUM(TOTAL_PAID) Revenue
FROM FACT.ORDERS F WITH (NOLOCK)
INNER JOIN DIM.DATES D 
	ON D.[Date] = F.purchase_date 
GROUP BY D.[Year],D.[MonthName],D.[Month]
)
SELECT 
	[Year],[MonthName],Revenue,
	SUM(Revenue) OVER (PARTITION BY [YEAR] ORDER BY [YEAR],[MONTH]   
						ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) Running_total,
	Avg(Revenue) Over (PARTITION BY [YEAR] ORDER BY [YEAR],[MONTH]
						ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ) Rolling_3Mths_avg_revenue
FROM Monthly_revenue 

ORDER BY 
	[YEAR],[Month] 



--2 What % of Customers are repeat buyers ? 


SELECT 
	COUNT(*) AS Total_Customers,
	COUNT(CASE WHEN TOTALORDERS > 1 THEN SKCUSTOMERID END) AS Repeat_Customers,
	CAST(
		100.0 *
	COUNT(CASE WHEN TOTALORDERS > 1 THEN SKCUSTOMERID END) / COUNT(*)
	AS decimal(5,2)
    ) AS repeat_customer_pct
FROM Dim.Customers


--3 Average days between orders 

--3.1 Avg days taken to place a second order
;WITH CUS_ORDERS AS(
SELECT 
	CUSTOMER_UNIQUE_ID,
	order_id,
	purchase_date,
	ROW_NUMBER() OVER (PARTITION BY CUSTOMER_UNIQUE_ID ORDER BY PURCHASE_DATE) ORDERSEQ
FROM FACT.ORDERS)
SELECT 
	AVG(DATEDIFF(DAY,O1.purchase_date,O2.purchase_date)) AverageTimeToSecondOrder
	FROM CUS_ORDERS O1 
	JOIN CUS_ORDERS O2 ON O1.customer_unique_id = O2.customer_unique_id
	AND O1.ORDERSEQ = 1 
	AND O2.ORDERSEQ = 2

-- 3.2 Average Days between consecutive orders

WITH CustomerOrders AS (
    SELECT
        customer_unique_id,
        purchase_date,
        ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_date) AS rn
    FROM Olist.Fact.Orders
)
SELECT
    customer_unique_id,
    AVG(days_between) AS avg_days_between_orders
FROM (
    SELECT
        c.customer_unique_id,
        DATEDIFF(DAY, LAG(c.purchase_date) OVER (PARTITION BY c.customer_unique_id ORDER BY c.purchase_date), c.purchase_date) AS days_between
    FROM CustomerOrders c
) x
WHERE days_between IS NOT NULL
and customer_unique_id = '02e9109b7e0a985108b43e573b6afb23'
GROUP BY customer_unique_id

--4. Top 20 Sellers and their revenue 

SELECT TOP 20 
	S.SKSellerId,
	S.seller_id, 
	SUM(PRICE + freight_value) AS Seller_revenue,
	COUNT(DISTINCT order_id) AS Orders_fullfilled
FROM FACT.ItemLine IL 
JOIN DIM.SELLERS S ON IL.SKSellerId=S.SKSellerId
GROUP BY S.SELLER_ID,S.SKSellerId
ORDER BY Seller_revenue DESC


--5  Sellers Matrix
-- Do late deliveries correlate with poor seller performance ?
SELECT
    s.seller_id,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(
        CASE 
            WHEN o.order_status = 'DELIVERED'
             AND o.delivered_date > o.estimated_delivery_ts
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE 
                WHEN o.order_status = 'DELIVERED'
                 AND o.delivered_date > o.estimated_delivery_ts
                THEN 1 ELSE 0
            END
        )
        / NULLIF(
            COUNT(DISTINCT CASE 
                WHEN o.order_status = 'DELIVERED' THEN o.order_id 
            END),
            0
        )
        AS DECIMAL(5,2)
    ) AS late_delivery_pct,

    SUM(
        CASE 
            WHEN o.order_status <> 'DELIVERED'
              OR o.delivered_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS undelivered_orders

FROM Fact.Orders o
JOIN Fact.ItemLine il
    ON o.order_id = il.order_id
JOIN Dim.Sellers s
    ON s.SKSellerId = il.SKSellerId
GROUP BY s.seller_id

HAVING COUNT(DISTINCT o.order_id) >= 50

ORDER BY late_delivery_pct DESC;


-- 6 Late deliveries correlatation with poor seller performance 


With order_status AS 
(
SELECT 
	ORDER_ID,
	CASE 
		WHEN delivery_delay_days <= 0 THEN 'ON TIME/ EARLY'
		WHEN delivery_delay_days >= 1 AND delivery_delay_days <=5 then '1-5 Days late' 
		WHEN delivery_delay_days >= 6 AND delivery_delay_days <=15 then '6-15 Days late'
		WHEN delivery_delay_days >=15 then '15 + days late'
		END AS Delay_bucket,
	review_score
 FROM FACT.Orders
 WHERE delivered_date is not null 
 and review_score is not null

 )
 SELECT 
	Delay_bucket,
	count(*) as total_orders,
	avg(review_score) as Avg_Review_score
FROM Order_status
group by Delay_bucket
order by total_orders desc
