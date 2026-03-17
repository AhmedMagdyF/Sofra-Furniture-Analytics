USE SofraFurnitureDB ;
GO
--===========================================
--===========================================
--Views
--===========================================
-- ------------------------------------------
-- vw_Sales_Detail - Sales With all dimensions attributes
-- ------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Sales_Details AS
SELECT
    s.Invoice_ID,
    d.[Date] AS Invoice_Date,
    d.Year,
    d.Quarter,
    d.Month_Num,   
    d.Month_Name,
    c.Customer_ID,
    c.Customer_Name,
    c.City,
    c.Channel,
    p.Product_ID,
    p.Product_Name,
    p.Category,
    p.standard_cost,
    p.Standard_Selling_Price,
    w.[location] AS Warehouse,
    s.Quantity,
    s.Unit_Price,
    s.Discount_Pct,
    s.Transaction_Type,
    s.Net_Revenue,
    (s.Quantity * p.Standard_Cost) AS COGS,
    s.Net_Revenue - (s.Quantity * p.Standard_Cost) AS Gross_Profit
FROM dbo.Fact_Sales s
JOIN dbo.Dim_Date d ON s.Date_Key = d.Date_Key
JOIN dbo.Dim_Customers c ON s.Customer_ID = c.Customer_ID
JOIN dbo.Dim_Products p ON s.Product_ID = p.Product_ID
JOIN dbo.Dim_Warehouses w ON s.Warehouse_ID = w.Warehouse_ID
GO
-- ------------------------------------------
--vw_Production_Detail
-- ------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Production_Detail AS
SELECT
    pr.Production_Order_ID,
    d.[Date] AS Production_Date,
    d.[Year],
    d.Quarter,
    d.Month_Num,
    d.Month_Name,
    p.Product_ID,
    p.Product_Name,
    p.Category,
    pr.Quantity_Planned,
    pr.Quantity_Produced,
    pr.Scrap_Pct,
    pr.Efficiency_Pct,
    pr.Scrap_Category,
    (pr.Quantity_Produced * p.Standard_Cost) AS Production_Variance,
    (pr.Quantity_Produced * p.Standard_Cost) - (pr.Quantity_Planned * p.Standard_Cost) AS Cost_Variance
From dbo.Fact_Production pr
JOIN dbo.Dim_Date d ON pr.Date_Key = d.Date_Key
JOIN dbo.Dim_Products p ON pr.Product_ID = p.Product_ID
GO
-- ------------------------------------------
--vw_Purchases_Detail  
-- ------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Purchases_Detail AS
SELECT
    pu.PO_ID,
    d.[Date] AS Purchase_Date,
    d.[Year],
    d.Quarter,
    d.Month_Num,
    d.Month_Name,
    s.Supplier_ID,
    s.Supplier_Name,
    s.Lead_Time_Days,
    m.Material_ID,
    m.Material_Name,
    m.Unit,
    pu.Warehouse_ID,
    w.Location AS Warehouse_Location,
    w.Type AS Warehouse_Type,
    pu.Quantity,
    pu.Unit_Cost,
    pu.Total_Cost ,
    pu.Unit_Cost - m.Standard_Cost AS Cost_Variance,
    CASE 
      WHEN m.Standard_Cost > 0 
      THEN ROUND(((pu.Unit_Cost - m.Standard_Cost) / m.Standard_Cost) * 100, 2) 
      ELSE 0
    END           AS Cost_Variance_Pct
FROM dbo.Fact_Purchases pu  
    JOIN dbo.Dim_Date d ON pu.Date_Key = d.Date_Key
    JOIN dbo.Dim_Suppliers s ON pu.Supplier_ID = s.Supplier_ID
    JOIN dbo.Dim_Materials m ON pu.Material_ID = m.Material_ID
    JOIN dbo.Dim_Warehouses w ON pu.Warehouse_ID = w.Warehouse_ID
GO
-- ===========================================
-- KPI Queries - Sale Performance
-- ===========================================
-- KPI 1: Revenue Summary by Year 
SELECT 
    [Year],
    SUM(Net_Revenue) AS Total_Net_Revenue,
    SUM(COGS) AS Total_COGS,
    SUM(Gross_Profit) AS Total_Gross_Profit,
    ROUND(SUM(Gross_Profit) / NULLIF(SUM(Net_Revenue), 0) * 100, 2) AS Gross_Profit_Margin_Pct,
    COUNT(CASE WHEN TRANSACTION_TYPE = 'Sale' THEN 1 END) AS Total_Sales,
    COUNT(CASE WHEN TRANSACTION_TYPE = 'Return' THEN 1 END) AS Total_Return,
    ROUND(COUNT(CASE WHEN TRANSACTION_TYPE = 'Return' THEN 1 END) * 100.0
    / NULLIF(COUNT(CASE WHEN TRANSACTION_TYPE = 'Sale' THEN 1 END), 0), 2) AS Return_Rate_Pct
FROM dbo.vw_Sales_Details
GROUP BY [Year]
ORDER BY [Year];
GO
-- KPI 2 : Reveneu by Category 
SELECT
    Category,
    SUM(Net_Revenue) AS Net_Revenue,
    SUM(Gross_Profit) AS Total_Gross_Profit,
    ROUND(SUM(Gross_Profit) / NULLIF(SUM(Net_Revenue), 0) * 100, 2) AS Gross_Profit_Margin_Pct,
    SUM(Quantity) AS Total_Units_Sold,
    COUNT(DISTINCT Product_ID) AS Distinct_Products_Sold
FROM dbo.vw_Sales_Details  
WHERE Transaction_Type = 'Sale'
GROUP BY Category
ORDER BY Net_Revenue DESC;
GO
-- KPI 3: Revenue by Channel
SELECT
    Channel,
    SUM(Net_Revenue) AS Net_Revenue,
    COUNT(*) AS Invoice_Count,
    ROUND(AVG(Discount_Pct), 2) AS Avg_Discount_Pct
FROM dbo.vw_Sales_Details
WHERE Transaction_Type = 'Sale'
GROUP BY Channel
ORDER BY Net_Revenue DESC;
GO
-- KPI 4: Top 10 Products by Revenue
SELECT TOP 10
    Product_Name,
    Category,
    SUM(Net_Revenue) AS Net_Revenue,
    ROUND(SUM(Gross_Profit) / NULLIF(SUM(Net_Revenue), 0) * 100, 2) AS Gross_Profit_Margin_Pct,
    SUM(Quantity) AS Total_Units_Sold
FROM dbo.vw_Sales_Details 
WHERE Transaction_Type = 'Sale'
GROUP BY Product_Name, Category
ORDER BY Net_Revenue DESC;
GO
-- KPI 5: YoY Revenue Growth
SELECT
    curr.[Year],
    curr.Net_Revenue ,
    prev.Net_Revenue AS Revrnue_LY,
    ROUND(((curr.Net_Revenue - prev.Net_Revenue) / NULLIF(prev.Net_Revenue, 0)) * 100, 2) AS YoY_Growth_Pct
FROM (
    SELECT [Year], SUM(Net_Revenue) AS Net_Revenue
    FROM dbo.vw_Sales_Details
    WHERE Transaction_Type = 'Sale'
    GROUP BY [Year]
) curr
LEFT JOIN (
    SELECT [Year], SUM(Net_Revenue) AS Net_Revenue
    FROM dbo.vw_Sales_Details
    WHERE Transaction_Type = 'Sale'
    GROUP BY [Year]
) prev ON curr.[Year] = prev.[Year] + 1
ORDER BY curr.[Year];
GO
-- ===========================================
-- KPI Queries - Production Performance
-- ===========================================
-- KPI 6: Production KPIs by Year
SELECT
    [Year],
    SUM(Quantity_Planned) AS Total_Quantity_Planned,
    SUM(Quantity_Produced) AS Total_Quantity_Produced,
    ROUND(SUM(Quantity_Produced) / NULLIF(SUM(Quantity_Planned), 0) * 100, 2) AS Production_Efficiency_Pct,
    ROUND(AVG(Scrap_Pct), 2) AS Avg_Scrap_Pct,
    COUNT(CASE WHEN Scrap_Category = 'High' THEN 1 END) AS High_Scrap_Count,
    COUNT(CASE WHEN Scrap_Category = 'Medium' THEN 1 END) AS Medium_Scrap_Count,
    COUNT(CASE WHEN Scrap_Category = 'Low' THEN 1 END) AS Low_Scrap_Count
FROM dbo.vw_Production_Detail
GROUP BY [Year]
ORDER BY [Year];
GO
-- KPI 7: Scarp by Product
SELECT 
    Product_Name,
    Category,
    COUNT(*) AS Total_Production_Orders,
    ROUND(AVG(Scrap_Pct), 2) AS Avg_Scrap_Pct,
    SUM(CASE WHEN Scrap_Category = 'High' THEN 1 ELSE 0 END) AS High_Scrap_Count,
    SUM(CASE WHEN Scrap_Category = 'Medium' THEN 1 ELSE 0 END) AS Medium_Scrap_Count,
    SUM(CASE WHEN Scrap_Category = 'Low' THEN 1 ELSE 0 END) AS Low_Scrap_Count
FROM dbo.vw_Production_Detail
GROUP BY Product_Name, Category
ORDER BY Avg_Scrap_Pct DESC;
GO
-- ===========================================
-- KPI Queries - Purchasing Performance
-- ===========================================
-- KPI 8: Spend by Supplier
SELECT
    Supplier_Name,
    Lead_Time_Days,
    COUNT(*) AS Total_POs,
    SUM(Quantity) AS Total_Quantity,
    SUM(Total_Cost) AS Total_Spend,
    ROUND(AVG(Unit_Cost), 2) AS Avg_Unit_Cost
FROM dbo.vw_Purchases_Detail
GROUP BY Supplier_Name, Lead_Time_Days
ORDER BY Total_Spend DESC;
GO
-- KPI 9: Spend by Year
SELECT
    [Year],
    SUM(Total_Cost) AS Total_Spend,
    COUNT(DISTINCT Supplier_ID) AS Active_Suppliers,
    COUNT (*) AS Total_POs
FROM dbo.vw_Purchases_Detail
GROUP BY [Year]
ORDER BY [Year];
GO

-- ===========================================
-- KPI Queries - Inventory Performance
-- ===========================================
-- KPI 10: Inventory Turnover by Product
SELECT
    p.Product_Name,
    p.Category,
    SUM(s.Quantity) AS Total_Units_Sold,
    SUM(s.COGS) AS Total_COGS,
    ROUND(SUM(s.COGS) / NULLIF(SUM(s.Quantity), 0), 2) AS Avg_COGS_Per_Unit,
    ROUND(SUM(s.Quantity) / NULLIF(SUM(p.Standard_Cost * s.Quantity), 0), 2) AS Inventory_Turnover
FROM dbo.vw_Sales_Details s
JOIN dbo.Dim_Products p ON s.Product_ID = p.Product_ID
WHERE s.Transaction_Type = 'Sale'
GROUP BY p.Product_Name, p.Category
ORDER BY Inventory_Turnover DESC;
GO

------------------------------------
-- KPI 12: Material Usage Efficiency
SELECT
    m.Material_Name,
    m.Unit,
    SUM(pu.Quantity) AS Total_Quantity_Purchased,
    SUM(mr.Quantity_Required * pr.Quantity_Produced) AS Total_Quantity_Required,
    ROUND(SUM(mr.Quantity_Required * pr.Quantity_Produced) / NULLIF(SUM(pu.Quantity), 0) * 100, 2) AS Material_Usage_Efficiency_Pct
FROM dbo.Fact_Purchases pu
JOIN dbo.Map_BOM mr ON pu.Material_ID = mr.Material_ID
JOIN dbo.Fact_Production pr ON mr.Product_ID = pr.Product_ID
JOIN dbo.Dim_Materials m ON pu.Material_ID = m.Material_ID
GROUP BY m.Material_Name, m.Unit
ORDER BY Material_Usage_Efficiency_Pct DESC;
GO

-- ===========================================
-- Additional Queries - Customer Insights
-- ===========================================
-- Query 13: Customer Segmentation by Revenue
SELECT
    Customer_Name,
    City,
    Channel,
    SUM(Net_Revenue) AS Total_Revenue,
    COUNT(*) AS Total_Transactions,
    ROUND(AVG(Net_Revenue), 2) AS Avg_Revenue_Per_Transaction
FROM dbo.vw_Sales_Details
WHERE Transaction_Type = 'Sale'
GROUP BY Customer_Name, City, Channel
ORDER BY Total_Revenue DESC;
GO
-- Query 14: Customer Retention Analysis
SELECT
    Customer_ID,
    Customer_Name,
    City,
    Channel,
    COUNT(DISTINCT CASE WHEN Transaction_Type = 'Sale' THEN Invoice_ID END) AS Total_Sales,
    COUNT(DISTINCT CASE WHEN Transaction_Type = 'Return' THEN Invoice_ID END) AS Total_Returns,
    ROUND(COUNT(DISTINCT CASE WHEN Transaction_Type = 'Return' THEN Invoice_ID END) * 100.0
    / NULLIF(COUNT(DISTINCT CASE WHEN Transaction_Type = 'Sale' THEN Invoice_ID END), 0), 2) AS Return_Rate_Pct
FROM dbo.vw_Sales_Details
GROUP BY Customer_ID, Customer_Name, City, Channel
ORDER BY Total_Sales DESC;
GO

-- Query 15: Customer Lifetime Value (CLV) Estimation   
SELECT
    Customer_ID,
    Customer_Name,
    City,
    Channel,
    SUM(Net_Revenue) AS Total_Revenue,
    COUNT(DISTINCT Invoice_ID) AS Total_Transactions,
    ROUND(AVG(Net_Revenue), 2) AS Avg_Revenue_Per_Transaction,
    ROUND(SUM(Net_Revenue) * 1.2, 2) AS Estimated_CLV -- Assuming a 20% future growth rate
FROM dbo.vw_Sales_Details  
WHERE Transaction_Type = 'Sale'
GROUP BY Customer_ID, Customer_Name, City, Channel
ORDER BY Estimated_CLV DESC;
GO
-- ===========================================
-- KPI Queries - Profitability Analysis
-- ===========================================
-- KPI 16: Profitability Full Analysis 
SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,
    p.Standard_Cost,
    p.Standard_Selling_Price,
    p.Standard_Selling_Price - p.Standard_Cost          AS Standard_Margin,
    ROUND((p.Standard_Selling_Price - p.Standard_Cost)
        / NULLIF(p.Standard_Selling_Price,0)*100, 2)    AS Standard_Margin_Pct,
    ISNULL(s.Net_Revenue,0)                             AS Actual_Net_Revenue,
    ISNULL(s.Gross_Profit,0)                            AS Actual_Gross_Profit,
    ISNULL(s.GP_Margin_Pct,0)                           AS Actual_GP_Margin_Pct,
    CASE WHEN p.Standard_Cost > p.Standard_Selling_Price
         THEN '⚠️ Negative Margin' ELSE '✅ OK' END      AS Margin_Flag
FROM dbo.Dim_Products p
LEFT JOIN (
    SELECT
        Product_ID,
        SUM(Net_Revenue)                                            AS Net_Revenue,
        SUM(Gross_Profit)                                           AS Gross_Profit,
        ROUND(SUM(Gross_Profit)/NULLIF(SUM(Net_Revenue),0)*100,2)  AS GP_Margin_Pct
    FROM dbo.vw_Sales_Details
    WHERE Transaction_Type = 'Sale'
    GROUP BY Product_ID
) s ON p.Product_ID = s.Product_ID
ORDER BY Actual_GP_Margin_Pct DESC;
GO
 
PRINT '✅ All Views and KPI Queries created successfully!';
GO
   
    
    



        





