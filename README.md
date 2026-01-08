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
