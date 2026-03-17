# 🪑 Sofra Furniture Co. — Manufacturing Analytics (2020–2025)

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoftexcel&logoColor=white)

## 📌 Project Overview

End-to-end analytics project for a fictional Egyptian furniture manufacturer — **Sofra Furniture Co.**
Covers the full data pipeline from raw data audit to an interactive Power BI dashboard, backed by a SQL Server database.

> **Tools:** Excel · SQL Server · Power BI Desktop  
> **Data Period:** 2020 – 2025  
> **Records:** 49,000+ transactions across Sales, Production, and Purchases

---

## 🏗️ Project Architecture

```
Raw Data (Excel)
      │
      ▼
Data Audit & Cleaning
      │
      ▼
SQL Server Database (Star Schema)
      │
      ▼
Power BI Dashboard (4 Pages)
```

---

## 📊 Dashboard Pages

| Page | Description | Key KPIs |
|------|-------------|----------|
| **Sales Performance** | Revenue trends, channel & category analysis | 1.13B EGP Revenue · 160K Units · 20% Return Rate 
![Sales Performance](https://github.com/AhmedMagdyF/Sofra-Furniture-Analytics/blob/main/Screenshot%202026-03-17%20082239.png)
| **Production & Scrap** | Efficiency tracking, scrap analysis | 95.68% Efficiency · 7.51% Avg Scrap |
![Production & Scrap](screenshots/02_Production_Scrap.png)
| **Purchases & Suppliers** | Spend analysis, supplier performance | 3.66B EGP Spend · 12 Suppliers |
![Purchases & Suppliers](screenshots/03_Purchases_Suppliers.png)
| **Product Profitability** | Gross profit, margin analysis | 42.31% GP Margin · 4 Negative Margin Products |
![Product Profitability](screenshots/04_Product_Profitability.png)

---

## 🗄️ Database Schema (Star Schema)

### Dimension Tables
- `Dim_Date` — Date attributes (Year, Month, Quarter, Week)
- `Dim_Products` — 35 products with cost and pricing
- `Dim_Customers` — 150 customers (Wholesale & Retail)
- `Dim_Suppliers` — 12 suppliers with lead times
- `Dim_Materials` — 40 raw materials
- `Dim_Warehouses` — 3 warehouse locations

### Fact Tables
- `Fact_Sales` — 20,000 transactions with computed Net_Revenue
- `Fact_Production` — 15,000 orders with Efficiency% and Scrap_Category
- `Fact_Purchases` — 14,000 POs with Total_Cost

### Bridge Table
- `Map_BOM` — Bill of Materials linking products to materials

---

## 📁 Repository Structure

```
Sofra-Furniture-Analytics/
│
├── README.md
│
├── data/
│   └── Sofra_Furniture_Full_Industrial_System_v2.xlsx
│
├── sql/
│   ├── 01_DDL_CreateTables.sql       # Create all 10 tables
│   ├── 02_Import_Data.sql            # Load all data
│   └── 03_Views_and_KPIs.sql         # Views & KPI queries
│
├── powerbi/
│   └── Sofra_Dashboard.pbix          # Power BI report file
│
└── docs/
    └── Sofra_PBI_Dashboard_Blueprint.docx
```

---

## 🚀 How to Run

### 1. SQL Server Setup
```sql
-- Step 1: Create Database
CREATE DATABASE SofraFurnitureDB;

-- Step 2: Run scripts in order
-- 01_DDL_CreateTables.sql
-- 02_Import_Data.sql
-- 03_Views_and_KPIs.sql
```

### 2. Power BI Connection
1. Open `Sofra_Dashboard.pbix`
2. Go to **Transform Data** → **Data Source Settings**
3. Update Server to your local SQL Server instance
4. Use **Windows Authentication**
5. Click **Refresh**

---

## 🔍 Key Findings

- **Storage** is the top revenue category at **321M EGP**
- **Wholesale** channel drives **55.5%** of total revenue
- **4 products** have negative profit margins and need urgent pricing review
- Average scrap rate of **7.51%** with **33%** of orders classified as High Scrap
- Production efficiency is stable at **~95%** across all years

---

## ⚠️ Data Quality Notes

| Issue | Table | Count | Action Taken |
|-------|-------|-------|--------------|
| Negative Quantity | Fact_Sales | 4,000 (20%) | Tagged as Returns |
| Null Discount | Fact_Sales | 4,039 (20%) | Replaced with 0 |
| Produced > Planned | Fact_Production | 7,097 (47%) | Flagged as Over-Production |
| High Scrap > 10% | Fact_Production | 5,030 (33%) | Categorized as High |
| Negative GP Products | Dim_Products | 4 products | Highlighted in dashboard |

---

## 👤 Author

**[Ahmed Magdy Farag]**  
Data Analyst  
[LinkedIn](https://linkedin.com/in/yourprofile) · [GitHub](https://github.com/yourusername)
