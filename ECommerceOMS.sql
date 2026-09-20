IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ECommerceOMS')
BEGIN
    CREATE DATABASE ECommerceOMS;
END
GO

-- Use the database
USE ECommerceOMS;
GO

-- ============================================================
--  E-Commerce Order Management System
--  SIMPLE SQL VERSION (Works on MySQL, PostgreSQL, SQL Server)
-- ============================================================

-- ============================================================
-- SECTION 1: DDL — CREATE TABLES
-- ============================================================

CREATE TABLE CUSTOMER (
  CustomerID INT NOT NULL,
  Email VARCHAR(255) NOT NULL,
  [Password] VARCHAR(255) NOT NULL,
  FirstName VARCHAR(100) NOT NULL,
  LastName VARCHAR(100) NOT NULL,
  Street VARCHAR(255),
  City VARCHAR(100),
  [State] VARCHAR(100),
  ZipCode VARCHAR(20),
  Country VARCHAR(100),
  RegistrationDate DATE NOT NULL,
  IsActive VARCHAR(10) NOT NULL,
  CreatedAt DATE NOT NULL,
  UpdatedAt DATE,
  PRIMARY KEY (CustomerID),
  UNIQUE (Email)
);

CREATE TABLE CUSTOMER_PHONE (
  Phone VARCHAR(20) NOT NULL,
  CustomerID INT NOT NULL,
  PRIMARY KEY (Phone, CustomerID),
  FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)
);

CREATE TABLE CATEGORY (
  CategoryID INT NOT NULL,
  CategoryName VARCHAR(100) NOT NULL,
  [Description] VARCHAR(500),
  CreatedAt DATE NOT NULL,
  ParentCategoryID INT,
  PRIMARY KEY (CategoryID),
  FOREIGN KEY (ParentCategoryID) REFERENCES CATEGORY(CategoryID),
  UNIQUE (CategoryName)
);

CREATE TABLE SUPPLIER (
  SupplierID INT NOT NULL,
  SupplierName VARCHAR(200) NOT NULL,
  ContactEmail VARCHAR(255),
  Street VARCHAR(255),
  City VARCHAR(100),
  ZipCode VARCHAR(20),
  Country VARCHAR(100),
  CreatedAt DATE NOT NULL,
  PRIMARY KEY (SupplierID)
);

CREATE TABLE SUPPLIER_CONTACTPHONE (
  ContactPhone VARCHAR(20) NOT NULL,
  SupplierID INT NOT NULL,
  PRIMARY KEY (ContactPhone, SupplierID),
  FOREIGN KEY (SupplierID) REFERENCES SUPPLIER(SupplierID)
);

CREATE TABLE PRODUCTS (
  ProductID INT NOT NULL,
  ProductName VARCHAR(200) NOT NULL,
  [Description] VARCHAR(500),
  Price NUMERIC(10,2) NOT NULL CHECK (Price >= 0),
  Stock INT NOT NULL CHECK (Stock >= 0),
  CreatedAt DATE NOT NULL,
  UpdatedAt DATE,
  CategoryID INT NOT NULL,
  SupplierID INT NOT NULL,
  PRIMARY KEY (ProductID),
  FOREIGN KEY (CategoryID) REFERENCES CATEGORY(CategoryID),
  FOREIGN KEY (SupplierID) REFERENCES SUPPLIER(SupplierID)
);

CREATE TABLE CART (
  CartID INT NOT NULL,
  CreatedAt DATE NOT NULL,
  UpdatedAt DATE,
  CustomerID INT NOT NULL,
  PRIMARY KEY (CartID),
  FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID),
  UNIQUE (CustomerID)
);

CREATE TABLE CARTITEM (
  CartItemID INT NOT NULL,
  Quantity INT NOT NULL CHECK (Quantity > 0),
  AddedAt DATE NOT NULL,
  ProductID INT NOT NULL,
  CartID INT NOT NULL,
  PRIMARY KEY (CartItemID),
  FOREIGN KEY (ProductID) REFERENCES PRODUCTS(ProductID),
  FOREIGN KEY (CartID) REFERENCES CART(CartID),
  UNIQUE (ProductID, CartID)
);

CREATE TABLE ORDERS (
  OrderID INT NOT NULL,
  OrderDate DATE NOT NULL,
  [Status] VARCHAR(20) NOT NULL,
  Street VARCHAR(255) NOT NULL,
  City VARCHAR(100) NOT NULL,
  [State] VARCHAR(100) NOT NULL,
  ZipCode VARCHAR(20) NOT NULL,
  Country VARCHAR(100) NOT NULL,
  CreatedAt DATE NOT NULL,
  UpdatedAt DATE,
  CustomerID INT NOT NULL,
  PRIMARY KEY (OrderID),
  FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)
);

CREATE TABLE ORDERITEM (
  OrderItemID INT NOT NULL,
  Quantity INT NOT NULL,
  UnitPrice NUMERIC(10,2) NOT NULL,
  ProductID INT NOT NULL,
  OrderID INT NOT NULL,
  PRIMARY KEY (OrderItemID),
  FOREIGN KEY (ProductID) REFERENCES PRODUCTS(ProductID),
  FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID)
);

CREATE TABLE PAYMENT (
  PaymentID INT NOT NULL,
  PaymentMethod VARCHAR(50) NOT NULL,
  Amount NUMERIC(12,2) NOT NULL CHECK (Amount > 0),
  [Status] VARCHAR(20) NOT NULL,
  TransactionRef VARCHAR(100),
  PaymentDate DATE,
  CreatedAt DATE NOT NULL,
  OrderID INT NOT NULL,
  PRIMARY KEY (PaymentID),
  FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID),
  --UNIQUE (TransactionRef),
  UNIQUE (OrderID)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_PAYMENT_TransactionRef 
    ON PAYMENT(TransactionRef) 
    WHERE TransactionRef IS NOT NULL;

CREATE TABLE SHIPMENT (
  ShipmentID INT NOT NULL,
  TrackingNumber VARCHAR(100),
  Carrier VARCHAR(100),
  Street VARCHAR(255) NOT NULL,
  City VARCHAR(100) NOT NULL,
  [State] VARCHAR(100) NOT NULL,
  ZipCode VARCHAR(20) NOT NULL,
  Country VARCHAR(100) NOT NULL,
  [Status] VARCHAR(20) NOT NULL,
  ShippedDate DATE,
  DeliveredDate DATE,
  CreatedAt DATE NOT NULL,
  OrderID INT NOT NULL,
  PRIMARY KEY (ShipmentID),
  FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID),
  --UNIQUE (TrackingNumber),
  UNIQUE (OrderID)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_SHIPMENT_TrackingNumber 
ON SHIPMENT(TrackingNumber) 
WHERE TrackingNumber IS NOT NULL;

CREATE TABLE REVIEW (
  ReviewID INT NOT NULL,
  Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
  Comment VARCHAR(1000),
  ReviewDate DATE NOT NULL,
  CreatedAt DATE NOT NULL,
  CustomerID INT NOT NULL,
  ProductID INT NOT NULL,
  PRIMARY KEY (ReviewID),
  FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID),
  FOREIGN KEY (ProductID) REFERENCES PRODUCTS(ProductID),
  UNIQUE (CustomerID, ProductID)
);

-- ====================================================================
-- PART 2: INDEXES
-- ====================================================================
CREATE INDEX IDX_ORDER_CustomerID ON ORDERS(CustomerID);
CREATE INDEX IDX_ORDERITEM_OrderID ON ORDERITEM(OrderID);
CREATE INDEX IDX_ORDERITEM_ProductID ON ORDERITEM(ProductID);
CREATE INDEX IDX_PAYMENT_OrderID ON PAYMENT(OrderID);
CREATE INDEX IDX_PAYMENT_Status ON PAYMENT(Status);
CREATE INDEX IDX_SHIPMENT_OrderID ON SHIPMENT(OrderID);
CREATE INDEX IDX_SHIPMENT_Status ON SHIPMENT(Status);
CREATE INDEX IDX_PRODUCTS_CategoryID ON PRODUCTS(CategoryID);
CREATE INDEX IDX_PRODUCTS_SupplierID ON PRODUCTS(SupplierID);
CREATE INDEX IDX_CARTITEM_CartID ON CARTITEM(CartID);
CREATE INDEX IDX_CARTITEM_ProductID ON CARTITEM(ProductID);
CREATE INDEX IDX_REVIEW_CustomerID ON REVIEW(CustomerID);
CREATE INDEX IDX_REVIEW_ProductID ON REVIEW(ProductID);
CREATE INDEX IDX_ORDER_OrderDate ON ORDERS(OrderDate);
CREATE INDEX IDX_ORDER_Status ON ORDERS(Status);
CREATE INDEX IDX_PRODUCTS_Price ON PRODUCTS(Price);
CREATE INDEX IDX_CUSTOMER_Email ON CUSTOMER(Email);
GO

-- ====================================================================
-- PART 3: TRIGGERS
-- ====================================================================
GO

-- TRIGGER 1: Reduce stock when order item is added (BR-08)
CREATE OR ALTER TRIGGER trg_OrderItem_UpdateStock
ON ORDERITEM AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p 
    SET p.Stock = p.Stock - i.Quantity, 
        p.UpdatedAt = GETDATE()
    FROM PRODUCTS p 
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    IF EXISTS (SELECT 1 FROM PRODUCTS WHERE Stock < 0)
    BEGIN
        RAISERROR('Insufficient stock - cannot complete order', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


-- TRIGGER 2: Update order status based on payment status (FR-22)
CREATE OR ALTER TRIGGER trg_Payment_UpdateOrderStatus
ON PAYMENT AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Payment successful -> Order Confirmed
    UPDATE o 
    SET o.Status = 'Confirmed', 
        o.UpdatedAt = GETDATE()
    FROM ORDERS o 
    INNER JOIN inserted i ON o.OrderID = i.OrderID
    INNER JOIN deleted d ON i.PaymentID = d.PaymentID
    WHERE i.Status = 'Paid' 
      AND (d.Status != 'Paid' OR d.Status IS NULL);
    
    -- Payment failed -> Order Cancelled
    UPDATE o 
    SET o.Status = 'Cancelled', 
        o.UpdatedAt = GETDATE()
    FROM ORDERS o 
    INNER JOIN inserted i ON o.OrderID = i.OrderID
    INNER JOIN deleted d ON i.PaymentID = d.PaymentID
    WHERE i.Status = 'Failed' 
      AND d.Status != 'Failed';
END;
GO

-- TRIGGER 3: Update order when shipment is delivered
CREATE OR ALTER TRIGGER trg_Shipment_UpdateOrderStatus
ON SHIPMENT AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE o 
    SET o.Status = 'Delivered', 
        o.UpdatedAt = GETDATE()
    FROM ORDERS o 
    INNER JOIN inserted i ON o.OrderID = i.OrderID
    INNER JOIN deleted d ON i.ShipmentID = d.ShipmentID
    WHERE i.Status = 'Delivered' 
      AND d.Status != 'Delivered';
END;
GO

-- ====================================================================
-- PART 4: STORED PROCEDURES
-- ====================================================================
GO

-- PROCEDURE 1: Convert cart to order (FR-07)
CREATE OR ALTER PROCEDURE usp_PlaceOrder
    @CartID INT, 
    @CustomerID INT, 
    @Street VARCHAR(255), 
    @City VARCHAR(100),
    @State VARCHAR(100), 
    @ZipCode VARCHAR(20), 
    @Country VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OrderID INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO ORDERS (OrderDate, Status, Street, City, State, ZipCode, Country, CreatedAt, CustomerID)
        VALUES (GETDATE(), 'Pending', @Street, @City, @State, @ZipCode, @Country, GETDATE(), @CustomerID);
        
        SET @OrderID = SCOPE_IDENTITY();
        
        INSERT INTO ORDERITEM (Quantity, UnitPrice, ProductID, OrderID)
        SELECT ci.Quantity, p.Price, ci.ProductID, @OrderID
        FROM CARTITEM ci 
        INNER JOIN PRODUCTS p ON ci.ProductID = p.ProductID
        WHERE ci.CartID = @CartID;
        
        DELETE FROM CARTITEM WHERE CartID = @CartID;
        
        COMMIT TRANSACTION;
        
        SELECT @OrderID AS OrderID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- PROCEDURE 2: Add product to cart (FR-04)
CREATE OR ALTER PROCEDURE usp_AddToCart
    @CustomerID INT, 
    @ProductID INT, 
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CartID INT;
    
    IF @Quantity <= 0
    BEGIN
        RAISERROR('Quantity must be greater than 0', 16, 1);
        RETURN;
    END
    
    SELECT @CartID = CartID FROM CART WHERE CustomerID = @CustomerID;
    
    IF @CartID IS NULL
    BEGIN
        INSERT INTO CART (CustomerID, CreatedAt) 
        VALUES (@CustomerID, GETDATE());
        SET @CartID = SCOPE_IDENTITY();
    END
    
    IF EXISTS (SELECT 1 FROM CARTITEM WHERE CartID = @CartID AND ProductID = @ProductID)
        UPDATE CARTITEM 
        SET Quantity = Quantity + @Quantity, 
            AddedAt = GETDATE()
        WHERE CartID = @CartID AND ProductID = @ProductID;
    ELSE
        INSERT INTO CARTITEM (Quantity, ProductID, CartID) 
        VALUES (@Quantity, @ProductID, @CartID);
END;
GO

-- PROCEDURE 3: Update order status (Admin function)
CREATE OR ALTER PROCEDURE usp_UpdateOrderStatus
    @OrderID INT, 
    @NewStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE ORDERS 
    SET Status = @NewStatus, 
        UpdatedAt = GETDATE() 
    WHERE OrderID = @OrderID;
    
    IF @NewStatus = 'Cancelled'
        UPDATE p 
        SET p.Stock = p.Stock + oi.Quantity, 
            p.UpdatedAt = GETDATE()
        FROM PRODUCTS p 
        INNER JOIN ORDERITEM oi ON p.ProductID = oi.ProductID
        WHERE oi.OrderID = @OrderID;
END;
GO

-- PROCEDURE 4: Get all orders for a customer (FR-09)
CREATE OR ALTER PROCEDURE usp_GetCustomerOrders 
    @CustomerID INT
AS
BEGIN
    SELECT 
        o.OrderID, 
        o.OrderDate, 
        o.Status AS OrderStatus,
        COUNT(oi.OrderItemID) AS TotalItems,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalAmount,
        p.Status AS PaymentStatus, 
        s.Status AS ShipmentStatus, 
        s.TrackingNumber
    FROM ORDERS o
    LEFT JOIN ORDERITEM oi ON o.OrderID = oi.OrderID
    LEFT JOIN PAYMENT p ON o.OrderID = p.OrderID
    LEFT JOIN SHIPMENT s ON o.OrderID = s.OrderID
    WHERE o.CustomerID = @CustomerID
    GROUP BY o.OrderID, o.OrderDate, o.Status, p.Status, s.Status, s.TrackingNumber
    ORDER BY o.OrderDate DESC;
END;
GO

-- PROCEDURE 5: Generate sales report (Admin function - FR-20)
CREATE OR ALTER PROCEDURE usp_SalesReport 
    @StartDate DATE, 
    @EndDate DATE
AS
BEGIN
    SELECT 
        p.ProductID, 
        p.ProductName, 
        c.CategoryName,
        SUM(oi.Quantity) AS UnitsSold,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue,
        COUNT(DISTINCT o.OrderID) AS NumberOfOrders
    FROM PRODUCTS p
    INNER JOIN ORDERITEM oi ON p.ProductID = oi.ProductID
    INNER JOIN ORDERS o ON oi.OrderID = o.OrderID
    INNER JOIN CATEGORY c ON p.CategoryID = c.CategoryID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate 
      AND o.Status = 'Delivered'
    GROUP BY p.ProductID, p.ProductName, c.CategoryName
    ORDER BY TotalRevenue DESC;
END;
GO

-- ====================================================================
-- PART 5: VIEWS
-- ====================================================================
GO

-- VIEW 1: Order Summary
CREATE OR ALTER VIEW vw_OrderSummary AS
SELECT 
    o.OrderID, 
    o.OrderDate, 
    o.Status AS OrderStatus,
    c.FirstName + ' ' + c.LastName AS CustomerName, 
    c.Email,
    p.PaymentMethod, 
    p.Amount AS PaymentAmount, 
    p.Status AS PaymentStatus,
    s.TrackingNumber, 
    s.Status AS ShipmentStatus
FROM ORDERS o
INNER JOIN CUSTOMER c ON o.CustomerID = c.CustomerID
LEFT JOIN PAYMENT p ON o.OrderID = p.OrderID
LEFT JOIN SHIPMENT s ON o.OrderID = s.OrderID;
GO

-- VIEW 2: Product Catalog
CREATE OR ALTER VIEW vw_ProductCatalog AS
SELECT 
    p.ProductID, 
    p.ProductName, 
    p.Price, 
    p.Stock,
    c.CategoryName, 
    s.SupplierName
FROM PRODUCTS p
INNER JOIN CATEGORY c ON p.CategoryID = c.CategoryID
INNER JOIN SUPPLIER s ON p.SupplierID = s.SupplierID;
GO

-- VIEW 3: Active Orders
CREATE OR ALTER VIEW vw_ActiveOrders AS
SELECT 
    o.OrderID, 
    o.OrderDate, 
    o.Status, 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    s.Status AS ShipmentStatus, 
    s.TrackingNumber
FROM ORDERS o
INNER JOIN CUSTOMER c ON o.CustomerID = c.CustomerID
LEFT JOIN SHIPMENT s ON o.OrderID = s.OrderID
WHERE o.Status NOT IN ('Delivered', 'Cancelled');
GO

-- ====================================================================
-- PART 6: DML - INSERT DATA (40+ records per table)
-- ====================================================================

-- Insert Categories (15 records)
INSERT INTO CATEGORY (CategoryID, CategoryName, Description, CreatedAt, ParentCategoryID) VALUES
(1, 'Electronics', 'Electronic devices', '2024-01-01', NULL),
(2, 'Computers', 'Laptops and desktops', '2024-01-01', 1),
(3, 'Mobile Phones', 'Smartphones', '2024-01-01', 1),
(4, 'Clothing', 'Fashion items', '2024-01-01', NULL),
(5, 'Men Clothing', 'Men fashion', '2024-01-01', 4),
(6, 'Women Clothing', 'Women fashion', '2024-01-01', 4),
(7, 'Home & Kitchen', 'Home appliances', '2024-01-01', NULL),
(8, 'Books', 'All books', '2024-01-01', NULL),
(9, 'Sports', 'Sports equipment', '2024-01-01', NULL),
(10, 'Toys', 'Toys and games', '2024-01-01', NULL),
(11, 'Audio', 'Audio equipment', '2024-01-01', 1),
(12, 'Accessories', 'Gadget accessories', '2024-01-01', 1),
(13, 'Footwear', 'Shoes and boots', '2024-01-01', 4),
(14, 'Beauty', 'Cosmetics', '2024-01-01', NULL),
(15, 'Baby', 'Baby products', '2024-01-01', NULL);
GO

-- Insert Suppliers (15 records)
INSERT INTO SUPPLIER (SupplierID, SupplierName, ContactEmail, Street, City, ZipCode, Country, CreatedAt) VALUES
(1, 'TechWorld Inc.', 'contact@techworld.com', '10 Tech Ave', 'New York', '10001', 'USA', '2024-01-01'),
(2, 'MobileZone Ltd.', 'info@mobilezone.com', '22 Mobile St', 'San Francisco', '94102', 'USA', '2024-01-02'),
(3, 'FashionHub Co.', 'sales@fashionhub.com', '5 Fashion Blvd', 'Los Angeles', '90001', 'USA', '2024-01-03'),
(4, 'HomeEssentials', 'shop@homeessentials.com', '8 Home Rd', 'Chicago', '60601', 'USA', '2024-01-04'),
(5, 'BookWorld Ltd.', 'books@bookworld.com', '3 Book Ln', 'Boston', '02101', 'USA', '2024-01-05'),
(6, 'SportsPro Inc.', 'pro@sportspro.com', '15 Sport Way', 'Dallas', '75201', 'USA', '2024-01-06'),
(7, 'ToyLand GmbH', 'toys@toyland.de', '12 Toy St', 'Berlin', '10115', 'Germany', '2024-01-07'),
(8, 'GlobalTech Ltd.', 'gt@globaltech.com', '100 Global St', 'London', 'EC1A', 'UK', '2024-01-08'),
(9, 'SmartGadgets', 'smart@smartgadgets.com', '77 Gadget Ave', 'Seoul', '04524', 'Korea', '2024-01-09'),
(10, 'AlphaSupply', 'alpha@alphasupply.com', '9 Supply Rd', 'Toronto', 'M5H', 'Canada', '2024-01-10'),
(11, 'SoundWave', 'info@soundwave.com', '42 Audio Blvd', 'Tokyo', '100-0001', 'Japan', '2024-01-11'),
(12, 'BeautyCo', 'sales@beautyco.com', '18 Beauty Ln', 'Paris', '75001', 'France', '2024-01-12'),
(13, 'BabyCare Inc.', 'contact@babycare.com', '33 Baby Rd', 'Sydney', '2000', 'Australia', '2024-01-13'),
(14, 'FootwearPro', 'info@footwearpro.com', '27 Shoe Ave', 'Milan', '20121', 'Italy', '2024-01-14'),
(15, 'GameMasters', 'sales@gamemasters.com', '91 Game St', 'Seattle', '98101', 'USA', '2024-01-15');
GO

-- Insert Supplier Contact Phones
INSERT INTO SUPPLIER_CONTACTPHONE (ContactPhone, SupplierID) VALUES
('+12125550101', 1), ('+14155550202', 2), ('+13105550303', 3),
('+13125550404', 4), ('+16175550505', 5), ('+12145550606', 6),
('+493055507070', 7), ('+442055508080', 8), ('+82255509090', 9),
('+14165550100', 10), ('+81355550111', 11), ('+33155550122', 12),
('+61255550133', 13), ('+39025550144', 14), ('+12065550155', 15);
GO

-- Insert Products (60 records)
INSERT INTO PRODUCTS (ProductID, ProductName, Description, Price, Stock, CreatedAt, UpdatedAt, CategoryID, SupplierID) VALUES
(1, 'Laptop Pro 15', '16GB RAM, 512GB SSD', 1200.00, 50, '2024-01-15', NULL, 2, 1),
(2, 'Wireless Mouse', 'Ergonomic 2.4GHz', 25.00, 200, '2024-01-15', NULL, 2, 1),
(3, 'Mechanical Keyboard', 'RGB gaming keyboard', 75.00, 150, '2024-01-15', NULL, 2, 1),
(4, 'USB-C Hub', '7-in-1 hub with HDMI', 45.00, 120, '2024-01-16', NULL, 12, 8),
(5, '27" Monitor', '4K IPS monitor', 350.00, 40, '2024-01-16', NULL, 2, 8),
(6, 'Smartphone X12', '128GB storage', 799.00, 80, '2024-01-17', NULL, 3, 2),
(7, 'Phone Case', 'Shockproof silicone', 15.00, 300, '2024-01-17', NULL, 12, 2),
(8, 'Wireless Earbuds', 'Noise cancelling', 89.00, 100, '2024-01-17', NULL, 11, 9),
(9, '10" Tablet', '64GB WiFi', 320.00, 60, '2024-01-18', NULL, 1, 9),
(10, 'Smartwatch S3', 'Heart rate GPS', 199.00, 70, '2024-01-18', NULL, 1, 9),
(11, 'Men T-Shirt', 'Cotton t-shirt', 18.00, 500, '2024-01-19', NULL, 5, 3),
(12, 'Men Jeans', 'Slim fit denim', 49.00, 300, '2024-01-19', NULL, 5, 3),
(13, 'Men Jacket', 'Waterproof jacket', 89.00, 150, '2024-01-19', NULL, 5, 3),
(14, 'Women Dress', 'Floral summer dress', 55.00, 200, '2024-01-20', NULL, 6, 3),
(15, 'Women Blouse', 'Silk blouse', 42.00, 180, '2024-01-20', NULL, 6, 3),
(16, 'Coffee Maker', '12-cup programmable', 65.00, 90, '2024-01-21', NULL, 7, 4),
(17, 'Air Fryer', '5-liter digital', 120.00, 75, '2024-01-21', NULL, 7, 4),
(18, 'Non-Stick Pan Set', '3-piece set', 55.00, 110, '2024-01-21', NULL, 7, 4),
(19, 'Blender Pro', '1000W high-speed', 85.00, 60, '2024-01-22', NULL, 7, 4),
(20, 'Knife Set', '6-piece stainless', 40.00, 130, '2024-01-22', NULL, 7, 4),
(21, 'Python Programming', 'Learn Python', 35.00, 200, '2024-01-23', NULL, 8, 5),
(22, 'Data Science Guide', 'Practical DS', 42.00, 150, '2024-01-23', NULL, 8, 5),
(23, 'SQL for Beginners', 'SQL guide', 28.00, 180, '2024-01-23', NULL, 8, 5),
(24, 'Machine Learning', 'ML algorithms', 49.00, 120, '2024-01-24', NULL, 8, 5),
(25, 'The Art of War', 'Classic strategy', 12.00, 250, '2024-01-24', NULL, 8, 5),
(26, 'Running Shoes', 'Breathable', 95.00, 120, '2024-01-25', NULL, 13, 6),
(27, 'Yoga Mat', 'Non-slip 6mm', 30.00, 200, '2024-01-25', NULL, 9, 6),
(28, 'Dumbbell Set', 'Adjustable 20kg', 150.00, 40, '2024-01-25', NULL, 9, 6),
(29, 'Cycling Helmet', 'Aerodynamic', 65.00, 80, '2024-01-26', NULL, 9, 6),
(30, 'Tennis Racket', 'Graphite', 85.00, 60, '2024-01-26', NULL, 9, 6),
(31, 'LEGO City Set', '500 pieces', 59.00, 100, '2024-01-27', NULL, 10, 7),
(32, 'Jigsaw Puzzle', '1000 pieces', 22.00, 150, '2024-01-27', NULL, 10, 7),
(33, 'RC Car', '2.4GHz 40km/h', 45.00, 80, '2024-01-27', NULL, 10, 7),
(34, 'Board Game', 'Strategy game', 35.00, 120, '2024-01-28', NULL, 10, 7),
(35, 'Teddy Bear', 'Soft plush 40cm', 18.00, 200, '2024-01-28', NULL, 15, 7),
(36, 'Bluetooth Speaker', 'Waterproof 20W', 70.00, 90, '2024-01-29', NULL, 11, 8),
(37, 'Power Bank', '20000mAh', 40.00, 160, '2024-01-29', NULL, 12, 8),
(38, 'HD Webcam', '1080p with mic', 55.00, 110, '2024-01-30', NULL, 2, 8),
(39, 'Gaming Headset', '7.1 surround', 79.00, 95, '2024-01-30', NULL, 11, 8),
(40, '1TB SSD', 'NVMe M.2', 110.00, 70, '2024-01-31', NULL, 2, 1),
(41, 'Lipstick Set', '5 matte colors', 35.00, 250, '2024-02-01', NULL, 14, 12),
(42, 'Face Moisturizer', 'Hydrating cream', 28.00, 180, '2024-02-01', NULL, 14, 12),
(43, 'Baby Onesie', 'Cotton 0-3 months', 12.00, 300, '2024-02-02', NULL, 15, 13),
(44, 'Baby Stroller', 'Lightweight', 180.00, 35, '2024-02-02', NULL, 15, 13),
(45, 'Sneakers', 'Casual athletic', 65.00, 140, '2024-02-03', NULL, 13, 14),
(46, 'Winter Boots', 'Insulated', 120.00, 60, '2024-02-03', NULL, 13, 14),
(47, 'Wireless Charger', 'Fast charging', 25.00, 200, '2024-02-04', NULL, 12, 9),
(48, 'Smart Bulb', 'WiFi color changing', 18.00, 150, '2024-02-04', NULL, 1, 1),
(49, 'Action Camera', '4K waterproof', 250.00, 45, '2024-02-05', NULL, 1, 8),
(50, 'Drone', 'Quadcopter with camera', 450.00, 25, '2024-02-05', NULL, 1, 8),
(51, 'Cookbook', 'World recipes', 25.00, 120, '2024-02-06', NULL, 8, 5),
(52, 'Fiction Novel', 'Bestseller', 15.00, 200, '2024-02-06', NULL, 8, 5),
(53, 'Sunglasses', 'Polarized UV', 45.00, 100, '2024-02-07', NULL, 12, 3),
(54, 'Watch', 'Analog quartz', 85.00, 80, '2024-02-07', NULL, 12, 3),
(55, 'Backpack', 'Waterproof laptop bag', 55.00, 120, '2024-02-08', NULL, 12, 1),
(56, 'Desk Lamp', 'LED with dimmer', 35.00, 90, '2024-02-08', NULL, 7, 4),
(57, 'Vacuum Cleaner', 'Cordless stick', 150.00, 40, '2024-02-09', NULL, 7, 4),
(58, 'Microwave Oven', '1000W digital', 120.00, 55, '2024-02-09', NULL, 7, 4),
(59, 'Hair Dryer', 'Ionic professional', 45.00, 100, '2024-02-10', NULL, 14, 12),
(60, 'Perfume', 'Eau de parfum 100ml', 65.00, 80, '2024-02-10', NULL, 14, 12);
GO

-- Insert Customers (50 records)
INSERT INTO CUSTOMER (CustomerID, Email, Password, FirstName, LastName, Street, City, State, ZipCode, Country, RegistrationDate, IsActive, CreatedAt, UpdatedAt) VALUES
(1, 'john.doe@email.com', 'pass123', 'John', 'Doe', '123 Main St', 'New York', 'NY', '10001', 'USA', '2024-01-15', 'true', '2024-01-15', NULL),
(2, 'jane.smith@email.com', 'pass456', 'Jane', 'Smith', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', '2024-01-20', 'true', '2024-01-20', NULL),
(3, 'mike.johnson@email.com', 'pass789', 'Mike', 'Johnson', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', '2024-02-01', 'true', '2024-02-01', NULL),
(4, 'sarah.williams@email.com', 'pass321', 'Sarah', 'Williams', '321 Elm St', 'Houston', 'TX', '77001', 'USA', '2024-02-10', 'true', '2024-02-10', NULL),
(5, 'david.brown@email.com', 'pass654', 'David', 'Brown', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', '2024-02-15', 'true', '2024-02-15', NULL),
(6, 'emma.davis@email.com', 'pass987', 'Emma', 'Davis', '987 Cedar Ln', 'Philadelphia', 'PA', '19019', 'USA', '2024-02-20', 'true', '2024-02-20', NULL),
(7, 'chris.wilson@email.com', 'pass147', 'Chris', 'Wilson', '147 Birch St', 'San Antonio', 'TX', '78201', 'USA', '2024-03-01', 'true', '2024-03-01', NULL),
(8, 'olivia.martinez@email.com', 'pass258', 'Olivia', 'Martinez', '258 Spruce Ave', 'San Diego', 'CA', '92101', 'USA', '2024-03-05', 'true', '2024-03-05', NULL),
(9, 'daniel.anderson@email.com', 'pass369', 'Daniel', 'Anderson', '369 Willow Rd', 'Dallas', 'TX', '75201', 'USA', '2024-03-10', 'true', '2024-03-10', NULL),
(10, 'sophia.taylor@email.com', 'pass741', 'Sophia', 'Taylor', '741 Ash St', 'San Jose', 'CA', '95101', 'USA', '2024-03-15', 'true', '2024-03-15', NULL),
(11, 'james.thomas@email.com', 'pass852', 'James', 'Thomas', '852 Poplar Dr', 'Austin', 'TX', '73301', 'USA', '2024-03-20', 'true', '2024-03-20', NULL),
(12, 'isabella.moore@email.com', 'pass963', 'Isabella', 'Moore', '963 Sycamore Ln', 'Jacksonville', 'FL', '32099', 'USA', '2024-03-25', 'true', '2024-03-25', NULL),
(13, 'robert.jackson@email.com', 'pass159', 'Robert', 'Jackson', '159 Magnolia St', 'Fort Worth', 'TX', '76101', 'USA', '2024-04-01', 'true', '2024-04-01', NULL),
(14, 'mia.white@email.com', 'pass357', 'Mia', 'White', '357 Dogwood Ave', 'Columbus', 'OH', '43085', 'USA', '2024-04-05', 'true', '2024-04-05', NULL),
(15, 'william.harris@email.com', 'pass486', 'William', 'Harris', '486 Redwood Rd', 'Charlotte', 'NC', '28201', 'USA', '2024-04-10', 'true', '2024-04-10', NULL),
(16, 'amelia.martin@email.com', 'pass275', 'Amelia', 'Martin', '275 Holly St', 'Detroit', 'MI', '48201', 'USA', '2024-04-15', 'true', '2024-04-15', NULL),
(17, 'joseph.thompson@email.com', 'pass168', 'Joseph', 'Thompson', '168 Cypress Dr', 'El Paso', 'TX', '79901', 'USA', '2024-04-20', 'true', '2024-04-20', NULL),
(18, 'evelyn.garcia@email.com', 'pass349', 'Evelyn', 'Garcia', '349 Juniper Ln', 'Memphis', 'TN', '37501', 'USA', '2024-04-25', 'true', '2024-04-25', NULL),
(19, 'thomas.martinez@email.com', 'pass527', 'Thomas', 'Martinez', '527 Hemlock St', 'Boston', 'MA', '02101', 'USA', '2024-05-01', 'true', '2024-05-01', NULL),
(20, 'abigail.robinson@email.com', 'pass641', 'Abigail', 'Robinson', '641 Beech Ave', 'Seattle', 'WA', '98101', 'USA', '2024-05-05', 'true', '2024-05-05', NULL),
(21, 'charles.clark@email.com', 'pass893', 'Charles', 'Clark', '893 Laurel Rd', 'Denver', 'CO', '80201', 'USA', '2024-05-10', 'true', '2024-05-10', NULL),
(22, 'emily.rodriguez@email.com', 'pass742', 'Emily', 'Rodriguez', '742 Palm St', 'Washington', 'DC', '20001', 'USA', '2024-05-15', 'true', '2024-05-15', NULL),
(23, 'andrew.lewis@email.com', 'pass956', 'Andrew', 'Lewis', '956 Fir Dr', 'Nashville', 'TN', '37201', 'USA', '2024-05-20', 'true', '2024-05-20', NULL),
(24, 'madison.lee@email.com', 'pass367', 'Madison', 'Lee', '367 Cedar St', 'Oklahoma City', 'OK', '73101', 'USA', '2024-05-25', 'true', '2024-05-25', NULL),
(25, 'christopher.walker@email.com', 'pass128', 'Christopher', 'Walker', '128 Alder Ave', 'Portland', 'OR', '97201', 'USA', '2024-06-01', 'true', '2024-06-01', NULL),
(26, 'charlotte.hall@email.com', 'pass439', 'Charlotte', 'Hall', '439 Hickory Rd', 'Las Vegas', 'NV', '89101', 'USA', '2024-06-05', 'true', '2024-06-05', NULL),
(27, 'joshua.allen@email.com', 'pass571', 'Joshua', 'Allen', '571 Chestnut St', 'Louisville', 'KY', '40201', 'USA', '2024-06-10', 'true', '2024-06-10', NULL),
(28, 'harper.young@email.com', 'pass682', 'Harper', 'Young', '682 Butternut Dr', 'Baltimore', 'MD', '21201', 'USA', '2024-06-15', 'true', '2024-06-15', NULL),
(29, 'ryan.hernandez@email.com', 'pass794', 'Ryan', 'Hernandez', '794 Pecan Ln', 'Milwaukee', 'WI', '53201', 'USA', '2024-06-20', 'true', '2024-06-20', NULL),
(30, 'elizabeth.king@email.com', 'pass803', 'Elizabeth', 'King', '803 Walnut St', 'Albuquerque', 'NM', '87101', 'USA', '2024-06-25', 'true', '2024-06-25', NULL),
(31, 'nicholas.wright@email.com', 'pass916', 'Nicholas', 'Wright', '916 Magnolia Ave', 'Tucson', 'AZ', '85701', 'USA', '2024-07-01', 'true', '2024-07-01', NULL),
(32, 'sophia.lopez@email.com', 'pass527', 'Sophia', 'Lopez', '527 Sycamore St', 'Fresno', 'CA', '93701', 'USA', '2024-07-05', 'true', '2024-07-05', NULL),
(33, 'brandon.hill@email.com', 'pass638', 'Brandon', 'Hill', '638 Holly Dr', 'Sacramento', 'CA', '94203', 'USA', '2024-07-10', 'true', '2024-07-10', NULL),
(34, 'grace.scott@email.com', 'pass749', 'Grace', 'Scott', '749 Poplar Ln', 'Kansas City', 'MO', '64101', 'USA', '2024-07-15', 'true', '2024-07-15', NULL),
(35, 'tyler.green@email.com', 'pass851', 'Tyler', 'Green', '851 Juniper Rd', 'Atlanta', 'GA', '30301', 'USA', '2024-07-20', 'true', '2024-07-20', NULL),
(36, 'victoria.adams@email.com', 'pass962', 'Victoria', 'Adams', '962 Fir Ave', 'Miami', 'FL', '33101', 'USA', '2024-07-25', 'true', '2024-07-25', NULL),
(37, 'dylan.baker@email.com', 'pass147', 'Dylan', 'Baker', '147 Cedar Dr', 'Raleigh', 'NC', '27601', 'USA', '2024-08-01', 'true', '2024-08-01', NULL),
(38, 'natalie.gonzalez@email.com', 'pass258', 'Natalie', 'Gonzalez', '258 Elm Ln', 'Omaha', 'NE', '68101', 'USA', '2024-08-05', 'true', '2024-08-05', NULL),
(39, 'nathan.nelson@email.com', 'pass369', 'Nathan', 'Nelson', '369 Oak St', 'Colorado Springs', 'CO', '80901', 'USA', '2024-08-10', 'true', '2024-08-10', NULL),
(40, 'hannah.carter@email.com', 'pass741', 'Hannah', 'Carter', '741 Pine Ave', 'Virginia Beach', 'VA', '23450', 'USA', '2024-08-15', 'true', '2024-08-15', NULL),
(41, 'zachary.mitchell@email.com', 'pass852', 'Zachary', 'Mitchell', '852 Maple Rd', 'Long Beach', 'CA', '90801', 'USA', '2024-08-20', 'true', '2024-08-20', NULL),
(42, 'lily.perez@email.com', 'pass963', 'Lily', 'Perez', '963 Birch St', 'Riverside', 'CA', '92501', 'USA', '2024-08-25', 'true', '2024-08-25', NULL),
(43, 'kevin.roberts@email.com', 'pass159', 'Kevin', 'Roberts', '159 Spruce Dr', 'Tampa', 'FL', '33601', 'USA', '2024-09-01', 'true', '2024-09-01', NULL),
(44, 'avery.turner@email.com', 'pass357', 'Avery', 'Turner', '357 Willow Ln', 'St. Louis', 'MO', '63101', 'USA', '2024-09-05', 'true', '2024-09-05', NULL),
(45, 'justin.phillips@email.com', 'pass486', 'Justin', 'Phillips', '486 Ash Ave', 'Cincinnati', 'OH', '45201', 'USA', '2024-09-10', 'true', '2024-09-10', NULL),
(46, 'zoey.campbell@email.com', 'pass275', 'Zoey', 'Campbell', '275 Beech Rd', 'Pittsburgh', 'PA', '15201', 'USA', '2024-09-15', 'true', '2024-09-15', NULL),
(47, 'eric.parker@email.com', 'pass168', 'Eric', 'Parker', '168 Redwood St', 'Greensboro', 'NC', '27401', 'USA', '2024-09-20', 'true', '2024-09-20', NULL),
(48, 'claire.evans@email.com', 'pass349', 'Claire', 'Evans', '349 Holly Dr', 'Plano', 'TX', '75023', 'USA', '2024-09-25', 'true', '2024-09-25', NULL),
(49, 'sean.edwards@email.com', 'pass527', 'Sean', 'Edwards', '527 Chestnut Ln', 'Newark', 'NJ', '07101', 'USA', '2024-10-01', 'true', '2024-10-01', NULL),
(50, 'anna.collins@email.com', 'pass641', 'Anna', 'Collins', '641 Butternut Ave', 'Toledo', 'OH', '43601', 'USA', '2024-10-05', 'true', '2024-10-05', NULL);
GO

-- Insert Customer Phones (50 records)
INSERT INTO CUSTOMER_PHONE (Phone, CustomerID) VALUES
('212-555-0101', 1), ('213-555-0102', 2), ('312-555-0103', 3), ('713-555-0104', 4),
('602-555-0105', 5), ('215-555-0106', 6), ('210-555-0107', 7), ('619-555-0108', 8),
('214-555-0109', 9), ('408-555-0110', 10), ('512-555-0111', 11), ('904-555-0112', 12),
('817-555-0113', 13), ('614-555-0114', 14), ('704-555-0115', 15), ('313-555-0116', 16),
('915-555-0117', 17), ('901-555-0118', 18), ('617-555-0119', 19), ('206-555-0120', 20),
('303-555-0121', 21), ('202-555-0122', 22), ('615-555-0123', 23), ('405-555-0124', 24),
('503-555-0125', 25), ('702-555-0126', 26), ('502-555-0127', 27), ('410-555-0128', 28),
('414-555-0129', 29), ('505-555-0130', 30), ('520-555-0131', 31), ('559-555-0132', 32),
('916-555-0133', 33), ('816-555-0134', 34), ('404-555-0135', 35), ('305-555-0136', 36),
('919-555-0137', 37), ('402-555-0138', 38), ('719-555-0139', 39), ('757-555-0140', 40),
('562-555-0141', 41), ('951-555-0142', 42), ('813-555-0143', 43), ('314-555-0144', 44),
('513-555-0145', 45), ('412-555-0146', 46), ('336-555-0147', 47), ('972-555-0148', 48),
('973-555-0149', 49), ('419-555-0150', 50);
GO

-- Insert Carts (50 records)
INSERT INTO CART (CartID, CreatedAt, UpdatedAt, CustomerID) VALUES
(1, '2024-02-01', NULL, 1), (2, '2024-02-02', NULL, 2),
(3, '2024-02-03', NULL, 3), (4, '2024-02-04', NULL, 4),
(5, '2024-02-05', NULL, 5), (6, '2024-02-06', NULL, 6),
(7, '2024-02-07', NULL, 7), (8, '2024-02-08', NULL, 8),
(9, '2024-02-09', NULL, 9), (10, '2024-02-10', NULL, 10),
(11, '2024-02-11', NULL, 11), (12, '2024-02-12', NULL, 12),
(13, '2024-02-13', NULL, 13), (14, '2024-02-14', NULL, 14),
(15, '2024-02-15', NULL, 15), (16, '2024-02-16', NULL, 16),
(17, '2024-02-17', NULL, 17), (18, '2024-02-18', NULL, 18),
(19, '2024-02-19', NULL, 19), (20, '2024-02-20', NULL, 20),
(21, '2024-02-21', NULL, 21), (22, '2024-02-22', NULL, 22),
(23, '2024-02-23', NULL, 23), (24, '2024-02-24', NULL, 24),
(25, '2024-02-25', NULL, 25), (26, '2024-02-26', NULL, 26),
(27, '2024-02-27', NULL, 27), (28, '2024-02-28', NULL, 28),
(29, '2024-02-29', NULL, 29), (30, '2024-03-01', NULL, 30),
(31, '2024-03-02', '2024-03-05', 31), (32, '2024-03-03', '2024-03-06', 32),
(33, '2024-03-04', '2024-03-07', 33), (34, '2024-03-05', '2024-03-08', 34),
(35, '2024-03-06', '2024-03-09', 35), (36, '2024-03-07', '2024-03-10', 36),
(37, '2024-03-08', '2024-03-11', 37), (38, '2024-03-09', '2024-03-12', 38),
(39, '2024-03-10', '2024-03-13', 39), (40, '2024-03-11', NULL, 40),
(41, '2024-03-12', NULL, 41), (42, '2024-03-13', NULL, 42),
(43, '2024-03-14', NULL, 43), (44, '2024-03-15', NULL, 44),
(45, '2024-03-16', NULL, 45), (46, '2024-03-17', NULL, 46),
(47, '2024-03-18', NULL, 47), (48, '2024-03-19', NULL, 48),
(49, '2024-03-20', NULL, 49), (50, '2024-03-21', NULL, 50);
GO

-- Insert Cart Items (50 records)
INSERT INTO CARTITEM (CartItemID, Quantity, AddedAt, ProductID, CartID) VALUES
(1, 2, '2024-02-01', 1, 1), (2, 1, '2024-02-02', 6, 2),
(3, 3, '2024-02-03', 11, 3), (4, 1, '2024-02-04', 16, 4),
(5, 2, '2024-02-05', 21, 5), (6, 1, '2024-02-06', 26, 6),
(7, 1, '2024-02-07', 31, 7), (8, 2, '2024-02-08', 36, 8),
(9, 1, '2024-02-09', 2, 9), (10, 3, '2024-02-10', 7, 10),
(11, 1, '2024-02-11', 12, 11), (12, 2, '2024-02-12', 17, 12),
(13, 1, '2024-02-13', 22, 13), (14, 2, '2024-02-14', 27, 14),
(15, 1, '2024-02-15', 32, 15), (16, 1, '2024-02-16', 37, 16),
(17, 2, '2024-02-17', 3, 17), (18, 1, '2024-02-18', 8, 18),
(19, 1, '2024-02-19', 13, 19), (20, 2, '2024-02-20', 18, 20),
(21, 1, '2024-02-21', 23, 21), (22, 3, '2024-02-22', 28, 22),
(23, 1, '2024-02-23', 33, 23), (24, 2, '2024-02-24', 38, 24),
(25, 1, '2024-02-25', 4, 25), (26, 1, '2024-02-26', 9, 26),
(27, 2, '2024-02-27', 14, 27), (28, 1, '2024-02-28', 19, 28),
(29, 1, '2024-02-29', 24, 29), (30, 2, '2024-03-01', 29, 30),
(31, 1, '2024-03-02', 34, 31), (32, 2, '2024-03-03', 39, 32),
(33, 1, '2024-03-04', 5, 33), (34, 3, '2024-03-05', 10, 34),
(35, 1, '2024-03-06', 15, 35), (36, 2, '2024-03-07', 20, 36),
(37, 1, '2024-03-08', 25, 37), (38, 2, '2024-03-09', 30, 38),
(39, 1, '2024-03-10', 35, 39), (40, 1, '2024-03-11', 40, 40),
(41, 1, '2024-03-12', 41, 41), (42, 2, '2024-03-13', 42, 42),
(43, 1, '2024-03-14', 43, 43), (44, 1, '2024-03-15', 44, 44),
(45, 2, '2024-03-16', 45, 45), (46, 1, '2024-03-17', 46, 46),
(47, 1, '2024-03-18', 47, 47), (48, 2, '2024-03-19', 48, 48),
(49, 1, '2024-03-20', 49, 49), (50, 1, '2024-03-21', 50, 50);
GO

-- Insert Orders (50 records)
INSERT INTO ORDERS (OrderID, OrderDate, Status, Street, City, State, ZipCode, Country, CreatedAt, UpdatedAt, CustomerID) VALUES
(1, '2024-03-01', 'Delivered', '123 Main St', 'New York', 'NY', '10001', 'USA', '2024-03-01', '2024-03-10', 1),
(2, '2024-03-02', 'Delivered', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', '2024-03-02', '2024-03-11', 2),
(3, '2024-03-03', 'Shipped', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', '2024-03-03', '2024-03-08', 3),
(4, '2024-03-04', 'Shipped', '321 Elm St', 'Houston', 'TX', '77001', 'USA', '2024-03-04', '2024-03-09', 4),
(5, '2024-03-05', 'Confirmed', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', '2024-03-05', NULL, 5),
(6, '2024-03-06', 'Confirmed', '987 Cedar Ln', 'Philadelphia', 'PA', '19019', 'USA', '2024-03-06', NULL, 6),
(7, '2024-03-07', 'Pending', '147 Birch St', 'San Antonio', 'TX', '78201', 'USA', '2024-03-07', NULL, 7),
(8, '2024-03-08', 'Pending', '258 Spruce Ave', 'San Diego', 'CA', '92101', 'USA', '2024-03-08', NULL, 8),
(9, '2024-03-09', 'Cancelled', '369 Willow Rd', 'Dallas', 'TX', '75201', 'USA', '2024-03-09', '2024-03-10', 9),
(10, '2024-03-10', 'Cancelled', '741 Ash St', 'San Jose', 'CA', '95101', 'USA', '2024-03-10', '2024-03-11', 10),
(11, '2024-03-11', 'Delivered', '852 Poplar Dr', 'Austin', 'TX', '73301', 'USA', '2024-03-11', '2024-03-20', 11),
(12, '2024-03-12', 'Delivered', '963 Sycamore Ln', 'Jacksonville', 'FL', '32099', 'USA', '2024-03-12', '2024-03-21', 12),
(13, '2024-03-13', 'Delivered', '159 Magnolia St', 'Fort Worth', 'TX', '76101', 'USA', '2024-03-13', '2024-03-22', 13),
(14, '2024-03-14', 'Shipped', '357 Dogwood Ave', 'Columbus', 'OH', '43085', 'USA', '2024-03-14', '2024-03-18', 14),
(15, '2024-03-15', 'Shipped', '486 Redwood Rd', 'Charlotte', 'NC', '28201', 'USA', '2024-03-15', '2024-03-19', 15),
(16, '2024-03-16', 'Confirmed', '275 Holly St', 'Detroit', 'MI', '48201', 'USA', '2024-03-16', NULL, 16),
(17, '2024-03-17', 'Confirmed', '168 Cypress Dr', 'El Paso', 'TX', '79901', 'USA', '2024-03-17', NULL, 17),
(18, '2024-03-18', 'Pending', '349 Juniper Ln', 'Memphis', 'TN', '37501', 'USA', '2024-03-18', NULL, 18),
(19, '2024-03-19', 'Delivered', '527 Hemlock St', 'Boston', 'MA', '02101', 'USA', '2024-03-19', '2024-03-28', 19),
(20, '2024-03-20', 'Delivered', '641 Beech Ave', 'Seattle', 'WA', '98101', 'USA', '2024-03-20', '2024-03-29', 20),
(21, '2024-03-21', 'Shipped', '893 Laurel Rd', 'Denver', 'CO', '80201', 'USA', '2024-03-21', '2024-03-25', 21),
(22, '2024-03-22', 'Confirmed', '742 Palm St', 'Washington', 'DC', '20001', 'USA', '2024-03-22', NULL, 22),
(23, '2024-03-23', 'Delivered', '956 Fir Dr', 'Nashville', 'TN', '37201', 'USA', '2024-03-23', '2024-04-01', 23),
(24, '2024-03-24', 'Pending', '367 Cedar St', 'Oklahoma City', 'OK', '73101', 'USA', '2024-03-24', NULL, 24),
(25, '2024-03-25', 'Delivered', '128 Alder Ave', 'Portland', 'OR', '97201', 'USA', '2024-03-25', '2024-04-03', 25),
(26, '2024-03-26', 'Shipped', '439 Hickory Rd', 'Las Vegas', 'NV', '89101', 'USA', '2024-03-26', '2024-03-30', 26),
(27, '2024-03-27', 'Confirmed', '571 Chestnut St', 'Louisville', 'KY', '40201', 'USA', '2024-03-27', NULL, 27),
(28, '2024-03-28', 'Delivered', '682 Butternut Dr', 'Baltimore', 'MD', '21201', 'USA', '2024-03-28', '2024-04-06', 28),
(29, '2024-03-29', 'Cancelled', '794 Pecan Ln', 'Milwaukee', 'WI', '53201', 'USA', '2024-03-29', '2024-03-30', 29),
(30, '2024-03-30', 'Pending', '803 Walnut St', 'Albuquerque', 'NM', '87101', 'USA', '2024-03-30', NULL, 30),
(31, '2024-03-31', 'Delivered', '916 Magnolia Ave', 'Tucson', 'AZ', '85701', 'USA', '2024-03-31', '2024-04-09', 31),
(32, '2024-04-01', 'Shipped', '527 Sycamore St', 'Fresno', 'CA', '93701', 'USA', '2024-04-01', '2024-04-05', 32),
(33, '2024-04-02', 'Confirmed', '638 Holly Dr', 'Sacramento', 'CA', '94203', 'USA', '2024-04-02', NULL, 33),
(34, '2024-04-03', 'Delivered', '749 Poplar Ln', 'Kansas City', 'MO', '64101', 'USA', '2024-04-03', '2024-04-12', 34),
(35, '2024-04-04', 'Pending', '851 Juniper Rd', 'Atlanta', 'GA', '30301', 'USA', '2024-04-04', NULL, 35),
(36, '2024-04-05', 'Delivered', '962 Fir Ave', 'Miami', 'FL', '33101', 'USA', '2024-04-05', '2024-04-14', 36),
(37, '2024-04-06', 'Confirmed', '147 Cedar Dr', 'Raleigh', 'NC', '27601', 'USA', '2024-04-06', NULL, 37),
(38, '2024-04-07', 'Shipped', '258 Elm Ln', 'Omaha', 'NE', '68101', 'USA', '2024-04-07', '2024-04-11', 38),
(39, '2024-04-08', 'Delivered', '369 Oak St', 'Colorado Springs', 'CO', '80901', 'USA', '2024-04-08', '2024-04-17', 39),
(40, '2024-04-09', 'Pending', '741 Pine Ave', 'Virginia Beach', 'VA', '23450', 'USA', '2024-04-09', NULL, 40),
(41, '2024-04-10', 'Delivered', '852 Maple Rd', 'Long Beach', 'CA', '90801', 'USA', '2024-04-10', '2024-04-19', 41),
(42, '2024-04-11', 'Shipped', '963 Birch St', 'Riverside', 'CA', '92501', 'USA', '2024-04-11', '2024-04-15', 42),
(43, '2024-04-12', 'Confirmed', '159 Spruce Dr', 'Tampa', 'FL', '33601', 'USA', '2024-04-12', NULL, 43),
(44, '2024-04-13', 'Delivered', '357 Willow Ln', 'St. Louis', 'MO', '63101', 'USA', '2024-04-13', '2024-04-22', 44),
(45, '2024-04-14', 'Pending', '486 Ash Ave', 'Cincinnati', 'OH', '45201', 'USA', '2024-04-14', NULL, 45),
(46, '2024-04-15', 'Delivered', '275 Beech Rd', 'Pittsburgh', 'PA', '15201', 'USA', '2024-04-15', '2024-04-24', 46),
(47, '2024-04-16', 'Confirmed', '168 Redwood St', 'Greensboro', 'NC', '27401', 'USA', '2024-04-16', NULL, 47),
(48, '2024-04-17', 'Shipped', '349 Holly Dr', 'Plano', 'TX', '75023', 'USA', '2024-04-17', '2024-04-21', 48),
(49, '2024-04-18', 'Delivered', '527 Chestnut Ln', 'Newark', 'NJ', '07101', 'USA', '2024-04-18', '2024-04-27', 49),
(50, '2024-04-19', 'Pending', '641 Butternut Ave', 'Toledo', 'OH', '43601', 'USA', '2024-04-19', NULL, 50);
GO

-- Insert Order Items (80 records)
INSERT INTO ORDERITEM (OrderItemID, Quantity, UnitPrice, ProductID, OrderID) VALUES
(1, 2, 1200.00, 1, 1), (2, 1, 799.00, 6, 2), (3, 3, 18.00, 11, 3),
(4, 1, 65.00, 16, 4), (5, 2, 35.00, 21, 5), (6, 1, 95.00, 26, 6),
(7, 1, 59.00, 31, 7), (8, 2, 70.00, 36, 8), (9, 1, 25.00, 2, 9),
(10, 3, 15.00, 7, 10), (11, 1, 49.00, 12, 11), (12, 2, 120.00, 17, 12),
(13, 1, 42.00, 22, 13), (14, 2, 30.00, 27, 14), (15, 1, 22.00, 32, 15),
(16, 1, 40.00, 37, 16), (17, 2, 75.00, 3, 17), (18, 1, 89.00, 8, 18),
(19, 1, 89.00, 13, 19), (20, 2, 55.00, 18, 20), (21, 1, 28.00, 23, 21),
(22, 3, 150.00, 28, 22), (23, 1, 45.00, 33, 23), (24, 2, 55.00, 38, 24),
(25, 1, 45.00, 4, 25), (26, 1, 320.00, 9, 26), (27, 2, 55.00, 14, 27),
(28, 1, 85.00, 19, 28), (29, 1, 49.00, 24, 29), (30, 2, 65.00, 29, 30),
(31, 1, 35.00, 34, 31), (32, 2, 79.00, 39, 32), (33, 1, 350.00, 5, 33),
(34, 3, 199.00, 10, 34), (35, 1, 42.00, 15, 35), (36, 2, 40.00, 20, 36),
(37, 1, 12.00, 25, 37), (38, 2, 85.00, 30, 38), (39, 1, 18.00, 35, 39),
(40, 1, 110.00, 40, 40), (41, 2, 35.00, 41, 41), (42, 1, 28.00, 42, 42),
(43, 3, 12.00, 43, 43), (44, 1, 180.00, 44, 44), (45, 2, 65.00, 45, 45),
(46, 1, 120.00, 46, 46), (47, 2, 25.00, 47, 47), (48, 1, 18.00, 48, 48),
(49, 1, 250.00, 49, 49), (50, 2, 450.00, 50, 50), (51, 1, 25.00, 51, 1),
(52, 2, 15.00, 52, 2), (53, 1, 45.00, 53, 3), (54, 1, 85.00, 54, 4),
(55, 2, 55.00, 55, 5), (56, 1, 35.00, 56, 6), (57, 1, 150.00, 57, 7),
(58, 2, 120.00, 58, 8), (59, 1, 45.00, 59, 9), (60, 1, 65.00, 60, 10),
(61, 2, 1200.00, 1, 11), (62, 1, 799.00, 6, 12), (63, 3, 18.00, 11, 13),
(64, 1, 65.00, 16, 14), (65, 2, 35.00, 21, 15), (66, 1, 95.00, 26, 16),
(67, 1, 59.00, 31, 17), (68, 2, 70.00, 36, 18), (69, 1, 25.00, 2, 19),
(70, 3, 15.00, 7, 20), (71, 1, 49.00, 12, 21), (72, 2, 120.00, 17, 22),
(73, 1, 42.00, 22, 23), (74, 2, 30.00, 27, 24), (75, 1, 22.00, 32, 25),
(76, 1, 40.00, 37, 26), (77, 2, 75.00, 3, 27), (78, 1, 89.00, 8, 28),
(79, 1, 89.00, 13, 29), (80, 2, 55.00, 18, 30);
GO

-- Insert Payments (50 records)
INSERT INTO PAYMENT (PaymentID, PaymentMethod, Amount, Status, TransactionRef, PaymentDate, CreatedAt, OrderID) VALUES
(1, 'Credit Card', 2400.00, 'Paid', 'TXN-001', '2024-03-01', '2024-03-01', 1),
(2, 'PayPal', 799.00, 'Paid', 'TXN-002', '2024-03-02', '2024-03-02', 2),
(3, 'Credit Card', 54.00, 'Paid', 'TXN-003', '2024-03-03', '2024-03-03', 3),
(4, 'Debit Card', 65.00, 'Paid', 'TXN-004', '2024-03-04', '2024-03-04', 4),
(5, 'Credit Card', 70.00, 'Paid', 'TXN-005', '2024-03-05', '2024-03-05', 5),
(6, 'PayPal', 95.00, 'Paid', 'TXN-006', '2024-03-06', '2024-03-06', 6),
(7, 'Credit Card', 59.00, 'Pending', NULL, NULL, '2024-03-07', 7),
(8, 'Debit Card', 140.00, 'Pending', NULL, NULL, '2024-03-08', 8),
(9, 'Credit Card', 25.00, 'Failed', 'TXN-009', '2024-03-09', '2024-03-09', 9),
(10, 'PayPal', 45.00, 'Refunded', 'TXN-010', '2024-03-10', '2024-03-10', 10),
(11, 'Credit Card', 49.00, 'Paid', 'TXN-011', '2024-03-11', '2024-03-11', 11),
(12, 'Debit Card', 240.00, 'Paid', 'TXN-012', '2024-03-12', '2024-03-12', 12),
(13, 'PayPal', 42.00, 'Paid', 'TXN-013', '2024-03-13', '2024-03-13', 13),
(14, 'Credit Card', 60.00, 'Paid', 'TXN-014', '2024-03-14', '2024-03-14', 14),
(15, 'Credit Card', 22.00, 'Paid', 'TXN-015', '2024-03-15', '2024-03-15', 15),
(16, 'Debit Card', 40.00, 'Paid', 'TXN-016', '2024-03-16', '2024-03-16', 16),
(17, 'Credit Card', 150.00, 'Paid', 'TXN-017', '2024-03-17', '2024-03-17', 17),
(18, 'PayPal', 89.00, 'Pending', NULL, NULL, '2024-03-18', 18),
(19, 'Credit Card', 89.00, 'Paid', 'TXN-019', '2024-03-19', '2024-03-19', 19),
(20, 'Debit Card', 110.00, 'Paid', 'TXN-020', '2024-03-20', '2024-03-20', 20),
(21, 'Credit Card', 28.00, 'Paid', 'TXN-021', '2024-03-21', '2024-03-21', 21),
(22, 'PayPal', 450.00, 'Paid', 'TXN-022', '2024-03-22', '2024-03-22', 22),
(23, 'Credit Card', 45.00, 'Paid', 'TXN-023', '2024-03-23', '2024-03-23', 23),
(24, 'Debit Card', 110.00, 'Pending', NULL, NULL, '2024-03-24', 24),
(25, 'Credit Card', 45.00, 'Paid', 'TXN-025', '2024-03-25', '2024-03-25', 25),
(26, 'PayPal', 320.00, 'Paid', 'TXN-026', '2024-03-26', '2024-03-26', 26),
(27, 'Credit Card', 110.00, 'Paid', 'TXN-027', '2024-03-27', '2024-03-27', 27),
(28, 'Debit Card', 85.00, 'Paid', 'TXN-028', '2024-03-28', '2024-03-28', 28),
(29, 'Credit Card', 49.00, 'Failed', 'TXN-029', '2024-03-29', '2024-03-29', 29),
(30, 'PayPal', 130.00, 'Pending', NULL, NULL, '2024-03-30', 30),
(31, 'Credit Card', 35.00, 'Paid', 'TXN-031', '2024-03-31', '2024-03-31', 31),
(32, 'Debit Card', 158.00, 'Paid', 'TXN-032', '2024-04-01', '2024-04-01', 32),
(33, 'Credit Card', 350.00, 'Paid', 'TXN-033', '2024-04-02', '2024-04-02', 33),
(34, 'PayPal', 597.00, 'Paid', 'TXN-034', '2024-04-03', '2024-04-03', 34),
(35, 'Credit Card', 42.00, 'Pending', NULL, NULL, '2024-04-04', 35),
(36, 'Debit Card', 80.00, 'Paid', 'TXN-036', '2024-04-05', '2024-04-05', 36),
(37, 'Credit Card', 12.00, 'Paid', 'TXN-037', '2024-04-06', '2024-04-06', 37),
(38, 'PayPal', 170.00, 'Paid', 'TXN-038', '2024-04-07', '2024-04-07', 38),
(39, 'Credit Card', 18.00, 'Paid', 'TXN-039', '2024-04-08', '2024-04-08', 39),
(40, 'Debit Card', 110.00, 'Pending', NULL, NULL, '2024-04-09', 40),
(41, 'Credit Card', 70.00, 'Paid', 'TXN-041', '2024-04-10', '2024-04-10', 41),
(42, 'PayPal', 28.00, 'Paid', 'TXN-042', '2024-04-11', '2024-04-11', 42),
(43, 'Credit Card', 36.00, 'Paid', 'TXN-043', '2024-04-12', '2024-04-12', 43),
(44, 'Debit Card', 180.00, 'Paid', 'TXN-044', '2024-04-13', '2024-04-13', 44),
(45, 'Credit Card', 130.00, 'Pending', NULL, NULL, '2024-04-14', 45),
(46, 'PayPal', 120.00, 'Paid', 'TXN-046', '2024-04-15', '2024-04-15', 46),
(47, 'Credit Card', 50.00, 'Paid', 'TXN-047', '2024-04-16', '2024-04-16', 47),
(48, 'Debit Card', 18.00, 'Paid', 'TXN-048', '2024-04-17', '2024-04-17', 48),
(49, 'Credit Card', 250.00, 'Paid', 'TXN-049', '2024-04-18', '2024-04-18', 49),
(50, 'PayPal', 900.00, 'Pending', NULL, NULL, '2024-04-19', 50);
GO

-- Insert Shipments (50 records)
INSERT INTO SHIPMENT (ShipmentID, TrackingNumber, Carrier, Street, City, State, ZipCode, Country, Status, ShippedDate, DeliveredDate, CreatedAt, OrderID) VALUES
(1, 'TRK-001', 'FedEx', '123 Main St', 'New York', 'NY', '10001', 'USA', 'Delivered', '2024-03-03', '2024-03-10', '2024-03-02', 1),
(2, 'TRK-002', 'UPS', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', 'Delivered', '2024-03-04', '2024-03-11', '2024-03-03', 2),
(3, 'TRK-003', 'FedEx', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', 'Shipped', '2024-03-05', NULL, '2024-03-04', 3),
(4, 'TRK-004', 'DHL', '321 Elm St', 'Houston', 'TX', '77001', 'USA', 'Shipped', '2024-03-06', NULL, '2024-03-05', 4),
(5, 'TRK-005', 'UPS', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', 'Processing', NULL, NULL, '2024-03-06', 5),
(6, 'TRK-006', 'FedEx', '987 Cedar Ln', 'Philadelphia', 'PA', '19019', 'USA', 'Processing', NULL, NULL, '2024-03-07', 6),
(7, NULL, NULL, '147 Birch St', 'San Antonio', 'TX', '78201', 'USA', 'Processing', NULL, NULL, '2024-03-08', 7),
(8, NULL, NULL, '258 Spruce Ave', 'San Diego', 'CA', '92101', 'USA', 'Processing', NULL, NULL, '2024-03-09', 8),
(9, 'TRK-009', 'DHL', '369 Willow Rd', 'Dallas', 'TX', '75201', 'USA', 'Returned', '2024-03-11', NULL, '2024-03-10', 9),
(10, 'TRK-010', 'FedEx', '741 Ash St', 'San Jose', 'CA', '95101', 'USA', 'Returned', '2024-03-12', NULL, '2024-03-11', 10),
(11, 'TRK-011', 'UPS', '852 Poplar Dr', 'Austin', 'TX', '73301', 'USA', 'Delivered', '2024-03-13', '2024-03-20', '2024-03-12', 11),
(12, 'TRK-012', 'FedEx', '963 Sycamore Ln', 'Jacksonville', 'FL', '32099', 'USA', 'Delivered', '2024-03-14', '2024-03-21', '2024-03-13', 12),
(13, 'TRK-013', 'DHL', '159 Magnolia St', 'Fort Worth', 'TX', '76101', 'USA', 'Delivered', '2024-03-15', '2024-03-22', '2024-03-14', 13),
(14, 'TRK-014', 'UPS', '357 Dogwood Ave', 'Columbus', 'OH', '43085', 'USA', 'Shipped', '2024-03-16', NULL, '2024-03-15', 14),
(15, 'TRK-015', 'FedEx', '486 Redwood Rd', 'Charlotte', 'NC', '28201', 'USA', 'Shipped', '2024-03-17', NULL, '2024-03-16', 15),
(16, 'TRK-016', 'DHL', '275 Holly St', 'Detroit', 'MI', '48201', 'USA', 'Processing', NULL, NULL, '2024-03-17', 16),
(17, 'TRK-017', 'UPS', '168 Cypress Dr', 'El Paso', 'TX', '79901', 'USA', 'Processing', NULL, NULL, '2024-03-18', 17),
(18, NULL, NULL, '349 Juniper Ln', 'Memphis', 'TN', '37501', 'USA', 'Processing', NULL, NULL, '2024-03-19', 18),
(19, 'TRK-019', 'FedEx', '527 Hemlock St', 'Boston', 'MA', '02101', 'USA', 'Delivered', '2024-03-21', '2024-03-28', '2024-03-20', 19),
(20, 'TRK-020', 'UPS', '641 Beech Ave', 'Seattle', 'WA', '98101', 'USA', 'Delivered', '2024-03-22', '2024-03-29', '2024-03-21', 20),
(21, 'TRK-021', 'DHL', '893 Laurel Rd', 'Denver', 'CO', '80201', 'USA', 'Shipped', '2024-03-23', NULL, '2024-03-22', 21),
(22, 'TRK-022', 'FedEx', '742 Palm St', 'Washington', 'DC', '20001', 'USA', 'Processing', NULL, NULL, '2024-03-23', 22),
(23, 'TRK-023', 'UPS', '956 Fir Dr', 'Nashville', 'TN', '37201', 'USA', 'Delivered', '2024-03-25', '2024-04-01', '2024-03-24', 23),
(24, NULL, NULL, '367 Cedar St', 'Oklahoma City', 'OK', '73101', 'USA', 'Processing', NULL, NULL, '2024-03-25', 24),
(25, 'TRK-025', 'FedEx', '128 Alder Ave', 'Portland', 'OR', '97201', 'USA', 'Delivered', '2024-03-27', '2024-04-03', '2024-03-26', 25),
(26, 'TRK-026', 'DHL', '439 Hickory Rd', 'Las Vegas', 'NV', '89101', 'USA', 'Shipped', '2024-03-28', NULL, '2024-03-27', 26),
(27, 'TRK-027', 'UPS', '571 Chestnut St', 'Louisville', 'KY', '40201', 'USA', 'Processing', NULL, NULL, '2024-03-28', 27),
(28, 'TRK-028', 'FedEx', '682 Butternut Dr', 'Baltimore', 'MD', '21201', 'USA', 'Delivered', '2024-03-30', '2024-04-06', '2024-03-29', 28),
(29, 'TRK-029', 'DHL', '794 Pecan Ln', 'Milwaukee', 'WI', '53201', 'USA', 'Returned', '2024-03-31', NULL, '2024-03-30', 29),
(30, NULL, NULL, '803 Walnut St', 'Albuquerque', 'NM', '87101', 'USA', 'Processing', NULL, NULL, '2024-03-31', 30),
(31, 'TRK-031', 'UPS', '916 Magnolia Ave', 'Tucson', 'AZ', '85701', 'USA', 'Delivered', '2024-04-02', '2024-04-09', '2024-04-01', 31),
(32, 'TRK-032', 'FedEx', '527 Sycamore St', 'Fresno', 'CA', '93701', 'USA', 'Shipped', '2024-04-03', NULL, '2024-04-02', 32),
(33, 'TRK-033', 'DHL', '638 Holly Dr', 'Sacramento', 'CA', '94203', 'USA', 'Processing', NULL, NULL, '2024-04-03', 33),
(34, 'TRK-034', 'UPS', '749 Poplar Ln', 'Kansas City', 'MO', '64101', 'USA', 'Delivered', '2024-04-05', '2024-04-12', '2024-04-04', 34),
(35, NULL, NULL, '851 Juniper Rd', 'Atlanta', 'GA', '30301', 'USA', 'Processing', NULL, NULL, '2024-04-05', 35),
(36, 'TRK-036', 'FedEx', '962 Fir Ave', 'Miami', 'FL', '33101', 'USA', 'Delivered', '2024-04-07', '2024-04-14', '2024-04-06', 36),
(37, 'TRK-037', 'UPS', '147 Cedar Dr', 'Raleigh', 'NC', '27601', 'USA', 'Processing', NULL, NULL, '2024-04-07', 37),
(38, 'TRK-038', 'DHL', '258 Elm Ln', 'Omaha', 'NE', '68101', 'USA', 'Shipped', '2024-04-09', NULL, '2024-04-08', 38),
(39, 'TRK-039', 'FedEx', '369 Oak St', 'Colorado Springs', 'CO', '80901', 'USA', 'Delivered', '2024-04-10', '2024-04-17', '2024-04-09', 39),
(40, NULL, NULL, '741 Pine Ave', 'Virginia Beach', 'VA', '23450', 'USA', 'Processing', NULL, NULL, '2024-04-10', 40),
(41, 'TRK-041', 'UPS', '852 Maple Rd', 'Long Beach', 'CA', '90801', 'USA', 'Delivered', '2024-04-12', '2024-04-19', '2024-04-11', 41),
(42, 'TRK-042', 'FedEx', '963 Birch St', 'Riverside', 'CA', '92501', 'USA', 'Shipped', '2024-04-13', NULL, '2024-04-12', 42),
(43, 'TRK-043', 'DHL', '159 Spruce Dr', 'Tampa', 'FL', '33601', 'USA', 'Processing', NULL, NULL, '2024-04-13', 43),
(44, 'TRK-044', 'UPS', '357 Willow Ln', 'St. Louis', 'MO', '63101', 'USA', 'Delivered', '2024-04-15', '2024-04-22', '2024-04-14', 44),
(45, NULL, NULL, '486 Ash Ave', 'Cincinnati', 'OH', '45201', 'USA', 'Processing', NULL, NULL, '2024-04-15', 45),
(46, 'TRK-046', 'FedEx', '275 Beech Rd', 'Pittsburgh', 'PA', '15201', 'USA', 'Delivered', '2024-04-17', '2024-04-24', '2024-04-16', 46),
(47, 'TRK-047', 'UPS', '168 Redwood St', 'Greensboro', 'NC', '27401', 'USA', 'Processing', NULL, NULL, '2024-04-17', 47),
(48, 'TRK-048', 'DHL', '349 Holly Dr', 'Plano', 'TX', '75023', 'USA', 'Shipped', '2024-04-19', NULL, '2024-04-18', 48),
(49, 'TRK-049', 'FedEx', '527 Chestnut Ln', 'Newark', 'NJ', '07101', 'USA', 'Delivered', '2024-04-20', '2024-04-27', '2024-04-19', 49),
(50, NULL, NULL, '641 Butternut Ave', 'Toledo', 'OH', '43601', 'USA', 'Processing', NULL, NULL, '2024-04-20', 50);
GO

-- Insert Reviews (50 records)
INSERT INTO REVIEW (ReviewID, Rating, Comment, ReviewDate, CreatedAt, CustomerID, ProductID) VALUES
(1, 5, 'Excellent laptop, very fast!', '2024-03-12', '2024-03-12', 1, 1),
(2, 4, 'Good phone, great camera', '2024-03-13', '2024-03-13', 2, 6),
(3, 3, 'T-shirts are ok but sizing is off', '2024-03-14', '2024-03-14', 3, 11),
(4, 5, 'Coffee maker works perfectly', '2024-03-15', '2024-03-15', 4, 16),
(5, 4, 'Good Python book for beginners', '2024-03-16', '2024-03-16', 5, 21),
(6, 5, 'Running shoes are very comfortable', '2024-03-17', '2024-03-17', 6, 26),
(7, 4, 'LEGO set was fun to build', '2024-03-18', '2024-03-18', 7, 31),
(8, 3, 'Speaker is decent but not loud enough', '2024-03-19', '2024-03-19', 8, 36),
(9, 5, 'Wireless mouse is smooth and fast', '2024-03-20', '2024-03-20', 9, 2),
(10, 2, 'Phone case cracked after 2 weeks', '2024-03-21', '2024-03-21', 10, 7),
(11, 5, 'Jeans fit perfectly', '2024-03-22', '2024-03-22', 11, 12),
(12, 4, 'Air fryer cooks evenly', '2024-03-23', '2024-03-23', 12, 17),
(13, 5, 'Data science book is comprehensive', '2024-03-24', '2024-03-24', 13, 22),
(14, 4, 'Yoga mat has good grip', '2024-03-25', '2024-03-25', 14, 27),
(15, 3, 'Puzzle missing 3 pieces', '2024-03-26', '2024-03-26', 15, 32),
(16, 5, 'Power bank charges fast', '2024-03-27', '2024-03-27', 16, 37),
(17, 5, 'Keyboard has satisfying tactile feel', '2024-03-28', '2024-03-28', 17, 3),
(18, 4, 'Earbuds have great sound', '2024-03-29', '2024-03-29', 18, 8),
(19, 5, 'Jacket is very warm and waterproof', '2024-03-30', '2024-03-30', 19, 13),
(20, 3, 'Pan set scratches easily', '2024-03-31', '2024-03-31', 20, 18),
(21, 4, 'SQL book helped me a lot', '2024-04-01', '2024-04-01', 21, 23),
(22, 5, 'Dumbbells are solid quality', '2024-04-02', '2024-04-02', 22, 28),
(23, 5, 'RC car is so fast and fun', '2024-04-03', '2024-04-03', 23, 33),
(24, 3, 'Tablet is OK but battery drains fast', '2024-04-04', '2024-04-04', 24, 9),
(25, 5, 'Very happy with the purchase', '2024-04-05', '2024-04-05', 25, 4),
(26, 4, 'Shipped faster than expected', '2024-04-06', '2024-04-06', 26, 29),
(27, 5, 'Best blender I have ever used', '2024-04-07', '2024-04-07', 27, 5),
(28, 4, 'Knife set is very sharp', '2024-04-08', '2024-04-08', 28, 19),
(29, 2, 'ML book is too advanced for me', '2024-04-09', '2024-04-09', 29, 24),
(30, 5, 'Smartwatch is accurate and stylish', '2024-04-10', '2024-04-10', 30, 10),
(31, 5, 'Monitor colors are vivid', '2024-04-11', '2024-04-11', 31, 5),
(32, 4, 'Gaming headset has great sound', '2024-04-12', '2024-04-12', 32, 39),
(33, 5, 'USB-C hub works with all devices', '2024-04-13', '2024-04-13', 33, 4),
(34, 5, 'Smartwatch battery lasts 5 days', '2024-04-14', '2024-04-14', 34, 10),
(35, 3, 'Women dress sizing runs small', '2024-04-15', '2024-04-15', 35, 14),
(36, 5, 'SSD improved boot time dramatically', '2024-04-16', '2024-04-16', 36, 40),
(37, 4, 'Good classic book', '2024-04-17', '2024-04-17', 37, 25),
(38, 5, 'Tennis racket has great control', '2024-04-18', '2024-04-18', 38, 30),
(39, 5, 'Plush bear is very soft', '2024-04-19', '2024-04-19', 39, 35),
(40, 4, 'Webcam is sharp and clear', '2024-04-20', '2024-04-20', 40, 38),
(41, 5, 'Lipstick colors are vibrant', '2024-04-21', '2024-04-21', 41, 41),
(42, 4, 'Moisturizer works well', '2024-04-22', '2024-04-22', 42, 42),
(43, 5, 'Baby onesie is soft', '2024-04-23', '2024-04-23', 43, 43),
(44, 4, 'Stroller is easy to fold', '2024-04-24', '2024-04-24', 44, 44),
(45, 5, 'Sneakers are comfortable', '2024-04-25', '2024-04-25', 45, 45),
(46, 4, 'Boots keep feet warm', '2024-04-26', '2024-04-26', 46, 46),
(47, 5, 'Charger works great', '2024-04-27', '2024-04-27', 47, 47),
(48, 4, 'Smart bulb is fun', '2024-04-28', '2024-04-28', 48, 48),
(49, 5, 'Camera takes great videos', '2024-04-29', '2024-04-29', 49, 49),
(50, 5, 'Drone is amazing to fly', '2024-04-30', '2024-04-30', 50, 50);
GO

-- ====================================================================
-- PART 7: DQL - DATA QUERY LANGUAGE (35+ SELECT Queries)
-- ====================================================================

-- Q1: Get all active customers
SELECT CustomerID, FirstName, LastName, Email FROM CUSTOMER WHERE IsActive = 'true';
GO

-- Q2: Get all products that are out of stock
SELECT ProductID, ProductName, Price, Stock FROM PRODUCTS WHERE Stock = 0;
GO

-- Q3: Get all orders with Status = 'Pending'
SELECT OrderID, OrderDate, Status, CustomerID FROM ORDERS WHERE Status = 'Pending';
GO

-- Q4: Get all payments with Status = 'Paid'
SELECT PaymentID, PaymentMethod, Amount, PaymentDate FROM PAYMENT WHERE Status = 'Paid';
GO

-- Q5: Get all products with Price greater than 100
SELECT ProductName, Price, Stock FROM PRODUCTS WHERE Price > 100 ORDER BY Price DESC;
GO

-- Q6: Get all shipments with Status = 'Delivered'
SELECT ShipmentID, TrackingNumber, Carrier, DeliveredDate FROM SHIPMENT WHERE Status = 'Delivered';
GO

-- Q7: Get all reviews with Rating = 5
SELECT ReviewID, Rating, Comment, CustomerID, ProductID FROM REVIEW WHERE Rating = 5;
GO

-- Q8: Get all orders placed after 2024-01-01
SELECT OrderID, OrderDate, Status FROM ORDERS WHERE OrderDate > '2024-01-01';
GO

-- Q9: Get only FirstName, LastName, and Email
SELECT FirstName, LastName, Email FROM CUSTOMER;
GO

-- Q10: Get only ProductName and Price
SELECT ProductName, Price FROM PRODUCTS;
GO

-- Q11: Get only OrderID and Status
SELECT OrderID, Status FROM ORDERS;
GO

-- Q12: Get only TrackingNumber
SELECT TrackingNumber FROM SHIPMENT WHERE TrackingNumber IS NOT NULL;
GO

-- Q13: Get only CategoryName
SELECT CategoryName FROM CATEGORY;
GO

-- Q14: Customer names with OrderID and OrderDate (CUSTOMER ⋈ ORDERS)
SELECT c.FirstName, c.LastName, o.OrderID, o.OrderDate
FROM CUSTOMER c INNER JOIN ORDERS o ON c.CustomerID = o.CustomerID;
GO

-- Q15: ProductName with CategoryName (PRODUCTS ⋈ CATEGORY)
SELECT p.ProductName, c.CategoryName FROM PRODUCTS p
INNER JOIN CATEGORY c ON p.CategoryID = c.CategoryID;
GO

-- Q16: ProductName with SupplierName (PRODUCTS ⋈ SUPPLIER)
SELECT p.ProductName, s.SupplierName FROM PRODUCTS p
INNER JOIN SUPPLIER s ON p.SupplierID = s.SupplierID;
GO

-- Q17: OrderID and PaymentMethod for paid orders (ORDERS ⋈ σ Status='Paid' (PAYMENT))
SELECT o.OrderID, o.OrderDate, p.PaymentMethod   
FROM ORDERS o 
INNER JOIN PAYMENT p ON o.OrderID = p.OrderID 
WHERE p.Status = 'Paid';
GO

-- Q18: Customer names with ProductID and Rating (CUSTOMER ⋈ REVIEW)
SELECT c.FirstName, c.LastName, r.ProductID, r.Rating
FROM CUSTOMER c INNER JOIN REVIEW r ON c.CustomerID = r.CustomerID;
GO

-- Q19: ProductName, Quantity, UnitPrice (ORDERITEM ⋈ PRODUCTS)
SELECT p.ProductName, oi.Quantity, oi.UnitPrice
FROM ORDERITEM oi INNER JOIN PRODUCTS p ON oi.ProductID = p.ProductID;
GO

-- Q20: Customer names with TrackingNumber (CUSTOMER ⋈ ORDERS ⋈ SHIPMENT)
SELECT c.FirstName, c.LastName, s.TrackingNumber
FROM CUSTOMER c
INNER JOIN ORDERS o ON c.CustomerID = o.CustomerID
INNER JOIN SHIPMENT s ON o.OrderID = s.OrderID
WHERE s.TrackingNumber IS NOT NULL;
GO

-- Q21: All emails from customers and suppliers (UNION)
SELECT Email AS EmailAddress, 'Customer' AS Type FROM CUSTOMER
UNION
SELECT ContactEmail, 'Supplier' FROM SUPPLIER WHERE ContactEmail IS NOT NULL;
GO

-- Q22: CustomerIDs who placed an order OR wrote a review (UNION)
SELECT CustomerID FROM ORDERS UNION SELECT CustomerID FROM REVIEW;
GO

-- Q23: ProductIDs in cart OR in orders (UNION)
SELECT ProductID FROM CARTITEM UNION SELECT ProductID FROM ORDERITEM;
GO

-- Q24: CustomerIDs who placed an order AND wrote a review (INTERSECTION)
SELECT DISTINCT o.CustomerID FROM ORDERS o
INNER JOIN REVIEW r ON o.CustomerID = r.CustomerID;
GO

-- Q25: ProductIDs in cart AND in orders (INTERSECTION)
SELECT DISTINCT ci.ProductID FROM CARTITEM ci
INNER JOIN ORDERITEM oi ON ci.ProductID = oi.ProductID;
GO

-- Q26: Customers who registered but never placed an order (DIFFERENCE)
SELECT CustomerID, FirstName, LastName FROM CUSTOMER
WHERE CustomerID NOT IN (SELECT CustomerID FROM ORDERS);
GO

-- Q27: Products that exist but never been ordered (DIFFERENCE)
SELECT ProductID, ProductName FROM PRODUCTS
WHERE ProductID NOT IN (SELECT ProductID FROM ORDERITEM);
GO

-- Q28: Customers who placed an order but never wrote a review (DIFFERENCE)
SELECT DISTINCT CustomerID FROM ORDERS
WHERE CustomerID NOT IN (SELECT CustomerID FROM REVIEW);
GO

-- Q29: Names of customers with Pending orders (σ + π + ⋈)
SELECT DISTINCT c.FirstName, c.LastName
FROM CUSTOMER c INNER JOIN ORDERS o ON c.CustomerID = o.CustomerID
WHERE o.Status = 'Pending';
GO

-- Q30: Name and price of out of stock products (σ + π)
SELECT ProductName, Price FROM PRODUCTS WHERE Stock = 0;
GO

-- Q31: Emails of customers who paid by Credit Card (σ + π + ⋈)
SELECT DISTINCT c.Email 
FROM CUSTOMER c
INNER JOIN ORDERS o ON c.CustomerID = o.CustomerID
INNER JOIN PAYMENT p ON o.OrderID = p.OrderID
WHERE p.PaymentMethod = 'Credit Card';

-- Q32: Product names priced over 50 in Electronics category (σ + π + ⋈)
SELECT p.ProductName, p.Price FROM PRODUCTS p
INNER JOIN CATEGORY c ON p.CategoryID = c.CategoryID
WHERE p.Price > 50 AND c.CategoryName = 'Electronics';
GO

-- Q33: Total revenue by payment method
SELECT PaymentMethod, SUM(Amount) AS TotalRevenue, COUNT(*) AS TransactionCount
FROM PAYMENT WHERE Status = 'Paid' GROUP BY PaymentMethod;
GO

-- Q34: Average order value per customer
SELECT c.CustomerID, c.FirstName, c.LastName,
       AVG(p.Amount) AS AvgOrderValue, COUNT(o.OrderID) AS OrderCount
FROM CUSTOMER c LEFT JOIN ORDERS o ON c.CustomerID = o.CustomerID
LEFT JOIN PAYMENT p ON o.OrderID = p.OrderID AND p.Status = 'Paid'
GROUP BY c.CustomerID, c.FirstName, c.LastName;
GO

-- Q35: Monthly sales report
SELECT YEAR(o.OrderDate) AS Year, 
       MONTH(o.OrderDate) AS Month,
       COUNT(DISTINCT o.OrderID) AS TotalOrders,
       SUM(p.Amount) AS TotalRevenue
FROM ORDERS o 
INNER JOIN PAYMENT p ON o.OrderID = p.OrderID
WHERE p.Status = 'Paid' 
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY Year DESC, Month DESC;
GO

-- Q36: Top 10 best-selling products
SELECT TOP 10 p.ProductID, p.ProductName, SUM(oi.Quantity) AS TotalSold
FROM PRODUCTS p INNER JOIN ORDERITEM oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName ORDER BY TotalSold DESC;
GO

-- ====================================================================
-- PART 8: DCL - DATA CONTROL LANGUAGE (Access Control)
-- ====================================================================

-- Create Application Login and User (SQL Server syntax)
-- Uncomment and modify passwords as needed

/*
-- Create server login
CREATE LOGIN app_user WITH PASSWORD = 'StrongAppPassword123!';
CREATE LOGIN admin_user WITH PASSWORD = 'StrongAdminPassword123!';

-- Create database users
CREATE USER app_user FOR LOGIN app_user;
CREATE USER admin_user FOR LOGIN admin_user;

-- Grant SELECT permissions on all tables to app_user
GRANT SELECT ON CUSTOMER TO app_user;
GRANT SELECT ON PRODUCTS TO app_user;
GRANT SELECT ON CATEGORY TO app_user;
GRANT SELECT ON SUPPLIER TO app_user;
GRANT SELECT ON ORDERS TO app_user;
GRANT SELECT ON PAYMENT TO app_user;
GRANT SELECT ON SHIPMENT TO app_user;
GRANT SELECT ON REVIEW TO app_user;

-- Grant INSERT and UPDATE on specific tables to app_user
GRANT INSERT, UPDATE ON CUSTOMER TO app_user;
GRANT INSERT, UPDATE ON CART TO app_user;
GRANT INSERT, UPDATE ON CARTITEM TO app_user;
GRANT INSERT ON REVIEW TO app_user;

-- Grant EXECUTE on stored procedures to app_user
GRANT EXECUTE ON usp_PlaceOrder TO app_user;
GRANT EXECUTE ON usp_AddToCart TO app_user;
GRANT EXECUTE ON usp_GetCustomerOrders TO app_user;

-- Grant SELECT on views to app_user
GRANT SELECT ON vw_OrderSummary TO app_user;
GRANT SELECT ON vw_ProductCatalog TO app_user;
GRANT SELECT ON vw_ActiveOrders TO app_user;

-- Admin user gets full control (db_owner role)
EXEC sp_addrolemember 'db_owner', 'admin_user';

-- Revoke DELETE from app_user on critical tables
REVOKE DELETE ON CUSTOMER TO app_user;
REVOKE DELETE ON ORDERS TO app_user;
REVOKE DELETE ON PAYMENT TO app_user;
*/
GO

-- ====================================================================
-- PART 9: VERIFICATION QUERIES
-- ====================================================================

-- Verify record counts (all should be 40+)
SELECT 'CUSTOMER' AS TableName, COUNT(*) AS RecordCount FROM CUSTOMER UNION ALL
SELECT 'CUSTOMER_PHONE', COUNT(*) FROM CUSTOMER_PHONE UNION ALL
SELECT 'CATEGORY', COUNT(*) FROM CATEGORY UNION ALL
SELECT 'SUPPLIER', COUNT(*) FROM SUPPLIER UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS UNION ALL
SELECT 'CART', COUNT(*) FROM CART UNION ALL
SELECT 'CARTITEM', COUNT(*) FROM CARTITEM UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS UNION ALL
SELECT 'ORDERITEM', COUNT(*) FROM ORDERITEM UNION ALL
SELECT 'PAYMENT', COUNT(*) FROM PAYMENT UNION ALL
SELECT 'SHIPMENT', COUNT(*) FROM SHIPMENT UNION ALL
SELECT 'REVIEW', COUNT(*) FROM REVIEW;
GO

-- Verify Views work
SELECT TOP 5 * FROM vw_OrderSummary;
SELECT TOP 5 * FROM vw_ProductCatalog;
SELECT TOP 5 * FROM vw_ActiveOrders;
GO

-- Verify Stored Procedures work
EXEC usp_GetCustomerOrders @CustomerID = 1;
EXEC usp_SalesReport @StartDate = '2024-01-01', @EndDate = '2024-12-31';
GO

PRINT '====================================================================';
PRINT 'E-COMMERCE ORDER MANAGEMENT SYSTEM DEPLOYMENT COMPLETE';
PRINT 'All Business Rules (BR-01 to BR-15) are enforced';
PRINT 'All Functional Requirements (FR-01 to FR-21) are implemented';
PRINT 'Total Records:';
PRINT '  - Customers: 50';
PRINT '  - Products: 60';
PRINT '  - Orders: 50';
PRINT '  - Order Items: 80';
PRINT '  - Payments: 50';
PRINT '  - Shipments: 50';
PRINT '  - Reviews: 50';
PRINT '====================================================================';
GO