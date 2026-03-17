
-- ============================================================
-- SOFRA FURNITURE CO. — SQL Server DDL Script
-- Database: SofraFurnitureDB
-- Schema: Star Schema (6 Dims + 3 Facts + 1 Bridge)
-- ============================================================

USE SofraFurnitureDB;
GO

-- ============================================================
-- STEP 1: DROP TABLES (if re-running)
-- Order matters: Facts first, then Dims
-- ============================================================
IF OBJECT_ID('dbo.Map_BOM',        'U') IS NOT NULL DROP TABLE dbo.Map_BOM;
IF OBJECT_ID('dbo.Fact_Sales',     'U') IS NOT NULL DROP TABLE dbo.Fact_Sales;
IF OBJECT_ID('dbo.Fact_Production','U') IS NOT NULL DROP TABLE dbo.Fact_Production;
IF OBJECT_ID('dbo.Fact_Purchases', 'U') IS NOT NULL DROP TABLE dbo.Fact_Purchases;
IF OBJECT_ID('dbo.Dim_Date',       'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
IF OBJECT_ID('dbo.Dim_Products',   'U') IS NOT NULL DROP TABLE dbo.Dim_Products;
IF OBJECT_ID('dbo.Dim_Customers',  'U') IS NOT NULL DROP TABLE dbo.Dim_Customers;
IF OBJECT_ID('dbo.Dim_Suppliers',  'U') IS NOT NULL DROP TABLE dbo.Dim_Suppliers;
IF OBJECT_ID('dbo.Dim_Materials',  'U') IS NOT NULL DROP TABLE dbo.Dim_Materials;
IF OBJECT_ID('dbo.Dim_Warehouses', 'U') IS NOT NULL DROP TABLE dbo.Dim_Warehouses;
GO

-- ============================================================
-- STEP 2: DIMENSION TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Dim_Date
-- ------------------------------------------------------------
CREATE TABLE dbo.Dim_Date (
    Date_Key        INT           NOT NULL,   -- YYYYMMDD e.g. 20210401
    [Date]          DATE          NOT NULL,
    [Year]          SMALLINT      NOT NULL,
    Quarter         TINYINT       NOT NULL,   -- 1-4
    Month_Num       TINYINT       NOT NULL,   -- 1-12
    Month_Name      VARCHAR(10)   NOT NULL,
    Week_Num        TINYINT       NOT NULL,
    Day_Of_Week     TINYINT       NOT NULL,   -- 1=Sun ... 7=Sat
    Day_Name        VARCHAR(10)   NOT NULL,
    Is_Weekend      BIT           NOT NULL    DEFAULT 0,

    CONSTRAINT PK_Dim_Date PRIMARY KEY (Date_Key)
);
GO

-- ------------------------------------------------------------
-- Dim_Products
-- ------------------------------------------------------------
CREATE TABLE dbo.Dim_Products (
    Product_ID              VARCHAR(10)     NOT NULL,
    Product_Name            NVARCHAR(100)   NOT NULL,
    Category                NVARCHAR(50)    NOT NULL,
    Standard_Cost           DECIMAL(10,2)   NOT NULL,
    Standard_Selling_Price  DECIMAL(10,2)   NOT NULL,
    Launch_Year             SMALLINT        NOT NULL,
    [Status]                VARCHAR(10)     NOT NULL DEFAULT 'Active',

    CONSTRAINT PK_Dim_Products    PRIMARY KEY (Product_ID),
    CONSTRAINT CK_Products_Status CHECK ([Status] IN ('Active','Discontinued'))
);
GO

-- ------------------------------------------------------------
-- Dim_Customers
-- ------------------------------------------------------------
CREATE TABLE dbo.Dim_Customers (
    Customer_ID     VARCHAR(10)     NOT NULL,
    Customer_Name   NVARCHAR(100)   NOT NULL,
    City            NVARCHAR(50)    NOT NULL,
    Channel         VARCHAR(20)     NOT NULL,

    CONSTRAINT PK_Dim_Customers    PRIMARY KEY (Customer_ID),
    CONSTRAINT CK_Customers_Channel CHECK (Channel IN ('Wholesale','Retail'))
);
GO

-- ------------------------------------------------------------
-- Dim_Suppliers
-- ------------------------------------------------------------
CREATE TABLE dbo.Dim_Suppliers (
    Supplier_ID     VARCHAR(10)     NOT NULL,
    Supplier_Name   NVARCHAR(100)   NOT NULL,
    Lead_Time_Days  TINYINT         NOT NULL,

    CONSTRAINT PK_Dim_Suppliers PRIMARY KEY (Supplier_ID)
);
GO

-- ------------------------------------------------------------
-- Dim_Materials
-- ------------------------------------------------------------
CREATE TABLE dbo.Dim_Materials (
    Material_ID     VARCHAR(10)     NOT NULL,
    Material_Name   NVARCHAR(100)   NOT NULL,
    Unit            VARCHAR(10)     NOT NULL,
    Standard_Cost   DECIMAL(10,2)   NOT NULL,

    CONSTRAINT PK_Dim_Materials PRIMARY KEY (Material_ID)
);
GO

-- ------------------------------------------------------------
-- Dim_Warehouses
-- ------------------------------------------------------------
CREATE TABLE dbo.Dim_Warehouses (
    Warehouse_ID    VARCHAR(10)     NOT NULL,
    [Location]      NVARCHAR(100)   NOT NULL,
    [Type]          NVARCHAR(50)    NOT NULL,

    CONSTRAINT PK_Dim_Warehouses PRIMARY KEY (Warehouse_ID)
);
GO

-- ============================================================
-- STEP 3: FACT TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Fact_Sales
-- ------------------------------------------------------------
CREATE TABLE dbo.Fact_Sales (
    Invoice_ID          VARCHAR(20)     NOT NULL,
    Date_Key            INT             NOT NULL,
    Customer_ID         VARCHAR(10)     NOT NULL,
    Product_ID          VARCHAR(10)     NOT NULL,
    Warehouse_ID        VARCHAR(10)     NOT NULL,
    Quantity            INT             NOT NULL,
    Unit_Price          DECIMAL(10,2)   NOT NULL,
    Discount_Pct        DECIMAL(5,2)    NOT NULL DEFAULT 0,
    Transaction_Type    VARCHAR(10)     NOT NULL DEFAULT 'Sale',  -- Sale / Return
    Net_Revenue         AS (
                            CASE WHEN Transaction_Type = 'Sale'
                            THEN CAST(Quantity * Unit_Price * (1 - Discount_Pct/100) AS DECIMAL(14,2))
                            ELSE 0 END
                        ) PERSISTED,

    CONSTRAINT PK_Fact_Sales              PRIMARY KEY (Invoice_ID),
    CONSTRAINT FK_Sales_Date              FOREIGN KEY (Date_Key)     REFERENCES dbo.Dim_Date(Date_Key),
    CONSTRAINT FK_Sales_Product           FOREIGN KEY (Product_ID)   REFERENCES dbo.Dim_Products(Product_ID),
    CONSTRAINT FK_Sales_Customer          FOREIGN KEY (Customer_ID)  REFERENCES dbo.Dim_Customers(Customer_ID),
    CONSTRAINT FK_Sales_Warehouse         FOREIGN KEY (Warehouse_ID) REFERENCES dbo.Dim_Warehouses(Warehouse_ID),
    CONSTRAINT CK_Sales_TransactionType   CHECK (Transaction_Type IN ('Sale','Return'))
);
GO

-- ------------------------------------------------------------
-- Fact_Production
-- ------------------------------------------------------------
CREATE TABLE dbo.Fact_Production (
    Production_Order_ID VARCHAR(20)     NOT NULL,
    Date_Key            INT             NOT NULL,
    Product_ID          VARCHAR(10)     NOT NULL,
    Quantity_Planned    INT             NOT NULL,
    Quantity_Produced   INT             NOT NULL,
    Scrap_Pct           DECIMAL(6,2)    NOT NULL DEFAULT 0,
    Efficiency_Pct      AS (
                            CASE WHEN Quantity_Planned > 0
                            THEN CAST(CAST(Quantity_Produced AS DECIMAL(10,2)) / Quantity_Planned * 100 AS DECIMAL(6,2))
                            ELSE 0 END
                        ) PERSISTED,
    Scrap_Category      AS (
                            CASE
                                WHEN Scrap_Pct > 10 THEN 'High'
                                WHEN Scrap_Pct > 5  THEN 'Medium'
                                ELSE 'Low'
                            END
                        ) PERSISTED,

    CONSTRAINT PK_Fact_Production     PRIMARY KEY (Production_Order_ID),
    CONSTRAINT FK_Production_Date     FOREIGN KEY (Date_Key)   REFERENCES dbo.Dim_Date(Date_Key),
    CONSTRAINT FK_Production_Product  FOREIGN KEY (Product_ID) REFERENCES dbo.Dim_Products(Product_ID)
);
GO

-- ------------------------------------------------------------
-- Fact_Purchases
-- ------------------------------------------------------------
CREATE TABLE dbo.Fact_Purchases (
    PO_ID           VARCHAR(20)     NOT NULL,
    Date_Key        INT             NOT NULL,
    Supplier_ID     VARCHAR(10)     NOT NULL,
    Material_ID     VARCHAR(10)     NOT NULL,
    Warehouse_ID    VARCHAR(10)     NOT NULL,
    Quantity        INT             NOT NULL,
    Unit_Cost       DECIMAL(10,2)   NOT NULL,
    Total_Cost      AS (CAST(Quantity * Unit_Cost AS DECIMAL(14,2))) PERSISTED,

    CONSTRAINT PK_Fact_Purchases          PRIMARY KEY (PO_ID),
    CONSTRAINT FK_Purchases_Date          FOREIGN KEY (Date_Key)     REFERENCES dbo.Dim_Date(Date_Key),
    CONSTRAINT FK_Purchases_Supplier      FOREIGN KEY (Supplier_ID)  REFERENCES dbo.Dim_Suppliers(Supplier_ID),
    CONSTRAINT FK_Purchases_Material      FOREIGN KEY (Material_ID)  REFERENCES dbo.Dim_Materials(Material_ID),
    CONSTRAINT FK_Purchases_Warehouse     FOREIGN KEY (Warehouse_ID) REFERENCES dbo.Dim_Warehouses(Warehouse_ID)
);
GO

-- ============================================================
-- STEP 4: BRIDGE TABLE
-- ============================================================

-- ------------------------------------------------------------
-- Map_BOM (Bill of Materials)
-- ------------------------------------------------------------
CREATE TABLE dbo.Map_BOM (
    Product_ID          VARCHAR(10)     NOT NULL,
    Material_ID         VARCHAR(10)     NOT NULL,
    Quantity_Required   DECIMAL(8,2)    NOT NULL,

    CONSTRAINT PK_Map_BOM             PRIMARY KEY (Product_ID, Material_ID),
    CONSTRAINT FK_BOM_Product         FOREIGN KEY (Product_ID)  REFERENCES dbo.Dim_Products(Product_ID),
    CONSTRAINT FK_BOM_Material        FOREIGN KEY (Material_ID) REFERENCES dbo.Dim_Materials(Material_ID)
);
GO

-- ============================================================
-- STEP 5: INDEXES (Performance)
-- ============================================================

-- Fact_Sales
CREATE NONCLUSTERED INDEX IX_Sales_Date        ON dbo.Fact_Sales(Date_Key);
CREATE NONCLUSTERED INDEX IX_Sales_Product     ON dbo.Fact_Sales(Product_ID);
CREATE NONCLUSTERED INDEX IX_Sales_Customer    ON dbo.Fact_Sales(Customer_ID);
CREATE NONCLUSTERED INDEX IX_Sales_TxType      ON dbo.Fact_Sales(Transaction_Type);

-- Fact_Production
CREATE NONCLUSTERED INDEX IX_Prod_Date         ON dbo.Fact_Production(Date_Key);
CREATE NONCLUSTERED INDEX IX_Prod_Product      ON dbo.Fact_Production(Product_ID);
CREATE NONCLUSTERED INDEX IX_Prod_ScrapCat     ON dbo.Fact_Production(Scrap_Category);

-- Fact_Purchases
CREATE NONCLUSTERED INDEX IX_Purch_Date        ON dbo.Fact_Purchases(Date_Key);
CREATE NONCLUSTERED INDEX IX_Purch_Supplier    ON dbo.Fact_Purchases(Supplier_ID);
CREATE NONCLUSTERED INDEX IX_Purch_Material    ON dbo.Fact_Purchases(Material_ID);
GO

-- ============================================================
-- STEP 6: VERIFY
-- ============================================================
SELECT
    t.name          AS TableName,
    SUM(p.rows)     AS [Row Count]
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY t.name
ORDER BY t.name;
GO

PRINT '✅ SofraFurnitureDB — All tables created successfully!';
GO






