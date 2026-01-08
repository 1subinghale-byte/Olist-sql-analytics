 
-- Create table

--1. Dim.Customer

DROP TABLE IF EXISTS Dim.Customers;
GO

CREATE TABLE Dim.Customers (
    SKCustomerId INT IDENTITY(1,1) PRIMARY KEY,
    Customer_unique_Id VARCHAR(50) NOT NULL,
    City VARCHAR(100),
    [State] CHAR(2),
    Zipcode INT,
    FirstOrderDate DATE,
    LastOrderDate DATE,
    TotalOrders INT,
    created_at DATETIME2 DEFAULT SYSDATETIME()
);


--2. Fact.Orders
DROP TABLE IF EXISTS Olist.Fact.Orders;
GO

CREATE TABLE Olist.Fact.Orders
(
    order_sk            BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id            VARCHAR(50) NOT NULL,
    customer_id         VARCHAR(50) NULL,      
    customer_unique_id  VARCHAR(50) NULL,     

    -- Status + timestamps
    order_status        VARCHAR(30) NULL,
    purchase_ts         DATETIME2 NULL,
    approved_ts         DATETIME2 NULL,
    delivered_carrier_ts DATETIME2 NULL,
    delivered_customer_ts DATETIME2 NULL,
    estimated_delivery_ts DATETIME2 NULL,
    purchase_date       DATE NULL,
    delivered_date      DATE NULL,

    -- Logistics metrics
    delivery_days       INT NULL,   -- delivered_customer - purchase
    delivery_delay_days INT NULL,   -- delivered_customer - estimated_delivery
    is_late_delivery    BIT NULL,
    item_count          INT NULL,
    items_value         DECIMAL(18,2) NULL,
    freight_value       DECIMAL(18,2) NULL,
    total_paid          DECIMAL(18,2) NULL,
    payment_count       INT NULL,
    max_installments    INT NULL,
    paid_credit_card    DECIMAL(18,2) NULL,
    paid_boleto         DECIMAL(18,2) NULL,
    paid_voucher        DECIMAL(18,2) NULL,
    paid_debit_card     DECIMAL(18,2) NULL,
    review_score        INT NULL,
    has_review_comment  BIT NULL,

    created_at          DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

--Indexes for the fact table 

CREATE UNIQUE INDEX UX_FactOrders_order_id
ON Olist.Fact.Orders(order_id);
GO


CREATE INDEX IX_FactOrders_customer_unique_id ON Olist.Fact.Orders(customer_unique_id);
CREATE INDEX IX_FactOrders_purchase_date ON Olist.Fact.Orders(purchase_date);
GO



--3 Customer to Order table bridge 


DROP TABLE IF EXISTS Olist.dbo.OrderCustomer;
GO

CREATE TABLE Olist.dbo.OrderCustomer
(
    order_id            VARCHAR(50) NOT NULL,
    customer_id         VARCHAR(50) NULL,
    customer_unique_id  VARCHAR(50) NULL,
    customer_sk         INT NULL,
    created_at          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_OrderCustomer PRIMARY KEY (order_id)
);
GO

CREATE INDEX IX_OrderCustomer_customer_sk ON Olist.dbo.OrderCustomer(customer_sk);
GO


--4. Dim.Seller

DROP TABLE IF EXISTS Dim.Sellers;
GO

CREATE TABLE Dim.Sellers
(
    SKSellerId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    seller_id  VARCHAR(50) NOT NULL,
    City       VARCHAR(100) NULL,
    State      CHAR(2) NULL,
    Zipcode    INT NULL,
    created_at DATETIME2(7) NULL DEFAULT SYSDATETIME()
);

CREATE UNIQUE INDEX UX_DimSellers_seller_id
ON Dim.Sellers(seller_id);
GO


--5 Dim.Products

DROP TABLE IF EXISTS Dim.Products;
GO

CREATE TABLE Dim.Products
(
    SKProductId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    product_id VARCHAR(50) NOT NULL,

    product_category_name_pt VARCHAR(100) NULL,
    product_category_name_en VARCHAR(100) NULL,

    product_name_lenght INT NULL,
    product_description_lenght INT NULL,
    product_photos_qty INT NULL,

    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL,

    created_at DATETIME2(7) NULL DEFAULT SYSDATETIME()
);
GO

CREATE UNIQUE INDEX UX_DimProducts_product_id
ON Dim.Products(product_id);
GO



--6 Fact.Itemline 
DROP TABLE IF EXISTS Fact.ItemLine;
GO

CREATE TABLE Fact.ItemLine
(
    SKItemLineId     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    order_id         VARCHAR(50) NOT NULL,
    order_item_id    INT NOT NULL,

    product_id       VARCHAR(50) NULL,
    seller_id        VARCHAR(50) NULL,

    SKProductId      INT NULL,
    SKSellerId       INT NULL,

    shipping_limit_ts DATETIME2(7) NULL,

    price            DECIMAL(18,2) NULL,
    freight_value    DECIMAL(18,2) NULL,

    created_at       DATETIME2(7) NOT NULL DEFAULT SYSDATETIME()
);
GO


CREATE UNIQUE INDEX UX_FactItemLine_order_line
ON Fact.ItemLine(order_id, order_item_id);
GO

CREATE INDEX IX_FactItemLine_order   ON Fact.ItemLine(order_id);
CREATE INDEX IX_FactItemLine_product ON Fact.ItemLine(SKProductId);
CREATE INDEX IX_FactItemLine_seller  ON Fact.ItemLine(SKSellerId);
GO



--7 dim.Dates

DROP TABLE IF EXISTS Dim.Dates;
GO

CREATE TABLE Dim.Dates
(
    DateSK       INT NOT NULL PRIMARY KEY,   -- yyyymmdd
    [Date]       DATE NOT NULL UNIQUE,

    [Year]       SMALLINT NOT NULL,
    [Quarter]    TINYINT NOT NULL,
    [Month]      TINYINT NOT NULL,
    [MonthName]  VARCHAR(15) NOT NULL,
    [DayOfMonth] TINYINT NOT NULL,
    [DayOfWeek]  TINYINT NOT NULL,           -- 1=Mon ... 7=Sun (ISO)
    [DayName]    VARCHAR(10) NOT NULL,

    [WeekOfYear] TINYINT NOT NULL,           -- ISO week
    [IsWeekend]  BIT NOT NULL,

    created_at   DATETIME2(7) NOT NULL DEFAULT SYSDATETIME()
);
GO
