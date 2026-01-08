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

##  Dataset
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

---

## Data insights from the Analysis.SQL file

1. Overall Trend

Revenue grows sharply from 2016 (very small amounts) to 2017 and 2018
indicating either:
The business scaled up quickly, or Data for early months is incomplete (e.g., September–December 2016 are very low, possibly partial data).
The cumulative Running_total confirms this growth trend — it rises steadily as months progress.

1.1. Rolling 3-Month Average Revenue

The Rolling_3Mths_avg_revenue smooths out month-to-month volatility.
Early months of 2017 show sharp increases:
January 2017: 138k → February 2017: 291k → March 2017: 449k.
Rolling average captures this upward momentum (~215k in Feb, ~293k in Mar).
By late 2017 and early 2018, the 3-month average stabilizes around 1M, indicating steady monthly revenue growth.

1.2. Seasonality / Monthly Patterns

There’s a noticeable dip in September 2018 (4.4k) and October 2018 (589), which is drastic compared to prior months.
Possible causes:
Most other months in 2017–2018 show high and relatively consistent revenue, especially Nov–Jan, hinting at potential peak seasons.

1.3. Rapid Revenue Increases

Biggest month-over-month jumps:
October 2016 → January 2017: huge revenue growth (from ~59k to 138k in Jan 2017, likely reflecting business growth).
Nov 2017: 1,194,882 → significant spike (highest revenue in 2017), possibly a seasonal promotion or major event.

1.4. Observations on Running Total

The Running_total consistently increases, which is expected.
It shows long-term growth trajectory:
2016 end: ~59k cumulative revenue.
2017 end: ~7.2M cumulative revenue.
2018 end (October): ~8.7M cumulative revenue.
Growth rate seems fastest in 2017, then stabilizes in 2018, indicating scaling maturity.




