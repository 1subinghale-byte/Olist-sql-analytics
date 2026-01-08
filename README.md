#  Olist E-Commerce Analytics (SQL Server)

## Project Overview
This project analyzes the **Olist Brazilian E-Commerce dataset** using **SQL Server**, focusing on end-to-end data engineering and analytical SQL.

The project simulates a real-world analytics pipeline:
- Raw CSV ingestion
- Staging layer
- Dimensional modeling (Star Schema)
- Fact table enrichment
- Business-focused analytical insights

Key skills demonstrated:
- Data modeling & warehousing concepts
- Advanced SQL (window functions, CTEs, analytical KPIs)
- Data quality handling
- Performance-aware schema design

---

## 🗂 Dataset
- **Source:** Kaggle — *Brazilian E-Commerce Public Dataset by Olist*
- **Domain:** E-commerce (Customers, Orders, Sellers, Products, Payments, Reviews)

---

##  Architecture & Data Flow

```text
Raw CSV Files
     ↓
SSIS Package
     ↓
STG Database (raw, one table per CSV)
     ↓
Transformations & Cleansing
     ↓
Olist Analytics Database
     ├── Dimension Tables
     ├── Fact Tables
     └── Analysis Layer

##  Insights 

1. Overall Trend

SQL query :

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

Insight :

Over All trend 

Revenue grows sharply from 2016 (very small amounts) to 2017 and 2018
indicating either:
The business scaled up quickly, or Data for early months is incomplete 
The cumulative Running_total confirms this growth trend — it rises steadily as months progress.

Rolling 3-Month Average Revenue

The Rolling_3Mths_avg_revenue smooths out month-to-month volatility.
Early months of 2017 show sharp increases:
- January 2017: 138k → February 2017: 291k → March 2017: 449k.
- Rolling average captures this upward momentum (215k in Feb, 293k in Mar).
- By late 2017 and early 2018, the 3-month average stabilizes around 1M, indicating steady monthly revenue growth.

Seasonality / Monthly Patterns

- There’s a noticeable dip in September 2018 (4.4k) and October 2018 (589), which is drastic compared to prior months.
- Possible causes:
Most other months in 2017–2018 show high and relatively consistent revenue, especially Nov–Jan, hinting at potential peak seasons.

Rapid Revenue Increases

Biggest month-over-month jumps:
- October 2016 → January 2017: huge revenue growth (from ~59k to 138k in Jan 2017, likely reflecting business growth).
- Nov 2017: 1,194,882 → significant spike (highest revenue in 2017), possibly a seasonal promotion or major event.

Observations on Running Total

The Running_total consistently increases, which is expected.
It shows long-term growth trajectory:
- 2016 end: 59k cumulative revenue.
- 2017 end: 7.2M cumulative revenue.
- 2018 end (October): 8.7M cumulative revenue.
- Growth rate seems fastest in 2017, then stabilizes in 2018, indicating scaling maturity.

2. Repeat buyers percentage 

SQL Query : 

SELECT 
	COUNT(*) AS Total_Customers,
	COUNT(CASE WHEN TOTALORDERS > 1 THEN SKCUSTOMERID END) AS Repeat_Customers,
	CAST(
		100.0 *
	COUNT(CASE WHEN TOTALORDERS > 1 THEN SKCUSTOMERID END) / COUNT(*)
	AS decimal(5,2)
    ) AS repeat_customer_pct
FROM Dim.Customers

Insight : 

Repeat customer rate is very low

- Total customers: 96,096
- Repeat customers: 2,997
- Repeat rate: 3.12%

 This means 97% of customers purchase only once.
 
 This also shows that the business is heavily acquisition driven as revenue growth is likely coming form new customer acquisition.

 3. Average number of Days untill the second order 

 SQL Query : 

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

Insight :

Customers who do return take 2.5 months to place a second order. 

Customer retention is critically weak: only 3.12% of customers return, and those who do take an average of 80 days to place a second order. This suggests missed re-engagement opportunities in the first 30 days.


4. Top 20 Sellers 

SQL Query :

SELECT TOP 20 
	S.SKSellerId,
	S.seller_id, 
	SUM(PRICE + freight_value) AS Seller_revenue,
	COUNT(DISTINCT order_id) AS Orders_fullfilled
FROM FACT.ItemLine IL 
JOIN DIM.SELLERS S ON IL.SKSellerId=S.SKSellerId
GROUP BY S.SELLER_ID,S.SKSellerId
ORDER BY Seller_revenue DESC


Insight :

These 20 sellers each generate 83k–250k in revenue.

A relatively small group is driving a disproportionate share of revenue.
Any churn or performance drop among top sellers would materially impact total revenue. The marketplace is top-heavy, not evenly distributed.


5. Late Deliveries and Undelivered 

SQL Query : 

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


Insights : 

Seller delivery performance is highly skewed: while most sellers maintain late delivery rates below 5%, a small subset exceeds 10–30%, generating a disproportionate share of late and undelivered orders. High-volume sellers with moderate lateness contribute more operational risk than low-volume extreme outliers. Undelivered orders reveal an additional failure mode not captured by lateness metrics alone. These concentrated risks help explain low repeat purchase rates and long reorder cycles, indicating that targeted seller governance could materially improve customer retention


6. Delivery Time correlation with performance 

SQL Query : 

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


Insight :

Customer satisfaction drops sharply as soon as orders are late: average review scores fall from 4.0 for on-time deliveries to 2.0 with just a 1–5 day delay, and to 1.0 beyond 6 days. This indicates a non-linear trust collapse where any lateness causes disproportionate reputational damage, explaining low repeat purchase rates despite strong order volume

7. Top 20 Product Categories

SQL Query: 

SELECT 
p.product_category_name_en as ProductCategory,
sum(il.price) as Category_revenue,
count(distinct order_id) Orders
FROM DIM.Products P 
JOIN Fact.ItemLine il on P.SKProductId = il.SKProductId
GROUP BY p.product_category_name_en
order by Category_revenue desc


Insight :

Within the top 20 product categories, revenue is driven by a mix of high-volume essentials (health & beauty, bed & bath) and high-value discretionary items (watches, office furniture, computers). Categories with high revenue per order are particularly exposed to delivery delays, while high-volume categories exert the greatest pressure on logistics and customer experience. Category-specific fulfillment strategies would avoid over-optimizing for a single dimension

8.  Product delivery corelation to weight outcomes 

SQL Query :

WITH weight_buckets AS
(
SELECT 
	CASE 
		WHEN product_weight_g < 500 THEN 'LIGHT'
		WHEN product_weight_g >500 AND product_weight_g < 2000 THEN 'MEDIUM'
		ELSE 'HEAVY' 
		END AS 'Weight_bucket',
		O.delivery_delay_days,
		O.review_score
	
FROM DIM.Products p 
JOIN FACT.ItemLine IL ON P.SKProductId = IL.SKProductId
JOIN FACT.Orders O ON O.order_id = IL.order_id

)

SELECT weight_bucket, 
	avg(delivery_delay_days) as Avg_delivery_days,
	avg(review_score) as Avg_review_score
FROM weight_buckets
GROUP BY Weight_bucket
ORDER BY Avg_delivery_days DESC 


Insight :

Product weight does not significantly impact delivery speed, as light, medium, and heavy items are delivered 11–12 days earlier than promised on average. However, heavy products receive lower customer ratings despite early delivery, indicating that post-delivery factors such as handling quality, damage, or usability play a larger role in customer satisfaction than delivery speed alone.