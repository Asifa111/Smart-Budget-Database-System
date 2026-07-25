DROP VIEW IF EXISTS dbo.vw_UserCategoryNetSpend;

DROP PROCEDURE IF EXISTS dbo.usp_RecordPurchase;
DROP PROCEDURE IF EXISTS dbo.usp_SetCategoryBudget;

DROP TRIGGER IF EXISTS dbo.trg_Budget_MonthlyLimit_History;

DROP TABLE IF EXISTS dbo.Refund;
DROP TABLE IF EXISTS dbo.Item_return;
DROP TABLE IF EXISTS dbo.Purchase_item;
DROP TABLE IF EXISTS dbo.Alert;
DROP TABLE IF EXISTS dbo.Budget_Limit_History;
DROP TABLE IF EXISTS dbo.Budget;
DROP TABLE IF EXISTS dbo.Report_category;
DROP TABLE IF EXISTS dbo.Report;
DROP TABLE IF EXISTS dbo.Transaction_user;
DROP TABLE IF EXISTS dbo.In_store_transaction;
DROP TABLE IF EXISTS dbo.Online_transaction;
DROP TABLE IF EXISTS dbo.Transactions;
DROP TABLE IF EXISTS dbo.Product;
DROP TABLE IF EXISTS dbo.Category;
DROP TABLE IF EXISTS dbo.Users;

DROP SEQUENCE IF EXISTS dbo.refundID_seq;
DROP SEQUENCE IF EXISTS dbo.itemReturnID_seq;
DROP SEQUENCE IF EXISTS dbo.purchaseItemID_seq;
DROP SEQUENCE IF EXISTS dbo.alertID_seq;
DROP SEQUENCE IF EXISTS dbo.budgetLimitHistoryID_seq;
DROP SEQUENCE IF EXISTS dbo.budgetID_seq;
DROP SEQUENCE IF EXISTS dbo.categoryID_seq;
DROP SEQUENCE IF EXISTS dbo.productID_seq;
DROP SEQUENCE IF EXISTS dbo.reportCategoryID_seq;
DROP SEQUENCE IF EXISTS dbo.reportID_seq;
DROP SEQUENCE IF EXISTS dbo.transactionUserID_seq;
DROP SEQUENCE IF EXISTS dbo.transactionID_seq;
DROP SEQUENCE IF EXISTS dbo.UserID_seq;

CREATE SEQUENCE dbo.UserID_seq START WITH 1;
CREATE SEQUENCE dbo.transactionID_seq START WITH 1;
CREATE SEQUENCE dbo.transactionUserID_seq START WITH 1;
CREATE SEQUENCE dbo.reportID_seq START WITH 1;
CREATE SEQUENCE dbo.reportCategoryID_seq START WITH 1;
CREATE SEQUENCE dbo.productID_seq START WITH 1;
CREATE SEQUENCE dbo.categoryID_seq START WITH 1;
CREATE SEQUENCE dbo.budgetID_seq START WITH 1;
CREATE SEQUENCE dbo.budgetLimitHistoryID_seq START WITH 1;
CREATE SEQUENCE dbo.alertID_seq START WITH 1;
CREATE SEQUENCE dbo.purchaseItemID_seq START WITH 1;
CREATE SEQUENCE dbo.itemReturnID_seq START WITH 1;
CREATE SEQUENCE dbo.refundID_seq START WITH 1;

CREATE TABLE dbo.Users(userID INT, firstName VARCHAR(32) NOT NULL, lastName VARCHAR(32) NOT NULL,
    email VARCHAR(128) NOT NULL UNIQUE, createdDate DATE NOT NULL DEFAULT GETDATE(), 
    PRIMARY KEY(userID) );

CREATE TABLE dbo.Category(categoryID INT, categoryName VARCHAR(32) UNIQUE, 
    description VARCHAR(128) NULL,
    PRIMARY KEY(categoryID) );

CREATE TABLE dbo.Product(productID INT, productName VARCHAR(64), brand VARCHAR(32) NULL,
    upc VARCHAR(32) NULL UNIQUE, defaultPrice DECIMAL(10,2) NULL,
    PRIMARY KEY(productID) );

CREATE TABLE dbo.Transactions(transactionID INT, transactionType CHAR(1), transactionDate DATE,
    merchantName VARCHAR(64),totalAmount DECIMAL(10,2), 
    PRIMARY KEY(transactionID),
    CONSTRAINT chk_transaction_type CHECK (transactionType IN ('O','I')) );

CREATE TABLE dbo.Online_transaction(transactionID INT, platform VARCHAR(64), orderNumber VARCHAR(32),
    trackingNumber VARCHAR(32), 
    PRIMARY KEY(transactionID), 
    FOREIGN KEY(transactionID) REFERENCES dbo.Transactions(transactionID) );

CREATE TABLE dbo.In_store_transaction(transactionID INT, storeName VARCHAR(64), storeLocation VARCHAR(64),
    recieptNumber VARCHAR(32), 
    PRIMARY KEY(transactionID),
    FOREIGN KEY(transactionID) REFERENCES dbo.Transactions(transactionID) );

CREATE TABLE dbo.Transaction_user(transactionUserID INT, userID INT NOT NULL, transactionID INT NOT NULL, 
    PRIMARY KEY(transactionUserID), FOREIGN KEY(userID) references Users,
    FOREIGN KEY(transactionID) REFERENCES dbo.transactions(transactionID) );

CREATE TABLE dbo.Budget(budgetID INT, userID INT NOT NULL, categoryID INT NOT NULL, monthlyLimit DECIMAL(10,2),
    startDate DATE, endDate DATE, 
    PRIMARY KEY(budgetID), 
    FOREIGN KEY(userID) REFERENCES dbo.Users(userID),
    FOREIGN KEY(categoryID) REFERENCES dbo.Category(categoryID),
    CONSTRAINT chk_budget_dates CHECK (startDate <= endDate),
    CONSTRAINT chk_budget_limit CHECK (monthlyLimit > 0) );

CREATE TABLE dbo.Alert(alertID INT, budgetID INT NOT NULL,
    PRIMARY KEY(alertID), 
    FOREIGN KEY(budgetID) REFERENCES dbo.Budget(budgetID) );

CREATE TABLE dbo.Report(reportID INT, userID INT NOT NULL, reportType VARCHAR(24), periodStart DATE,
    periodEnd DATE, generatedOn DATETIME,
    PRIMARY KEY(reportID), 
    FOREIGN KEY(userID) REFERENCES dbo.Users(userID) );

CREATE TABLE dbo.Report_category(reportCategoryID INT, reportID INT NOT NULL, categoryID INT NOT NULL,
    PRIMARY KEY(reportCategoryID),
    FOREIGN KEY(reportID) REFERENCES dbo.Report(reportID),
    FOREIGN KEY(categoryID) REFERENCES dbo.Category(categoryID)  );

CREATE TABLE dbo.Purchase_item(purchaseItemID INT, userID INT NOT NULL, transactionID INT NOT NULL, 
    productID INT NOT NULL, categoryID INT NOT NULL, quantity DECIMAL(10,2), unitPrice decimal(10,2),
    PRIMARY KEY(purchaseItemID),
    FOREIGN KEY(userID) REFERENCES dbo.Users(userID),
    FOREIGN KEY(transactionID) REFERENCES dbo.Transactions(transactionID), 
    FOREIGN KEY(productID) REFERENCES dbo.Product(productID),
    FOREIGN KEY(categoryID) REFERENCES dbo.Category(categoryID),
    CONSTRAINT chk_purchase_qty CHECK (quantity > 0),
    CONSTRAINT chk_purchase_unitprice CHECK (unitPrice > 0) );

CREATE TABLE dbo.Item_return(ItemReturnID INT, purchaseItemID INT NOT NULL, userID INT NOT NULL, returnDate DATE,
    returnQuantity INT, returnReason VARCHAR(128), returnStatus VARCHAR(20),
    PRIMARY KEY(ItemReturnID),
    FOREIGN KEY(purchaseItemID) REFERENCES dbo.Purchase_item(purchaseItemID),
    FOREIGN KEY (userID) REFERENCES dbo.Users(userID),
    CONSTRAINT chk_return_qty CHECK (returnQuantity > 0) );

CREATE TABLE dbo.Refund(refundID INT, purchaseItemID INT NOT NULL, refundAmount DECIMAL(10,2),
    refundDate DATE, refundMethod VARCHAR(16) NULL,
    PRIMARY KEY(refundID),
    FOREIGN KEY(purchaseItemID) REFERENCES dbo.Purchase_item(purchaseItemID),
    CONSTRAINT chk_refund_amount CHECK (refundAmount > 0) );

CREATE TABLE dbo.Budget_Limit_History ( budgetLimitHistoryID INT, budgetID INT NOT NULL,
    oldMonthlyLimit DECIMAL(10,2) NOT NULL, newMonthlyLimit DECIMAL(10,2) NOT NULL,
    changedAt DATETIME2(0) NOT NULL
    CONSTRAINT df_BudgetLimitHistory_changedAt DEFAULT SYSDATETIME(),
    PRIMARY KEY (budgetLimitHistoryID),
    FOREIGN KEY (budgetID) REFERENCES dbo.Budget(budgetID),
    CONSTRAINT chk_BudgetLimitHistory_changed CHECK (oldMonthlyLimit <> newMonthlyLimit) );

-- Index
CREATE UNIQUE INDEX uq_online_order ON dbo.Online_transaction(platform, orderNumber);
CREATE UNIQUE INDEX uq_store_reciept ON dbo.In_store_transaction(storeName, recieptNumber);
CREATE INDEX IX_transaction_user_userID ON dbo.Transaction_user(userID);
CREATE INDEX IX_transaction_user_transactionID ON dbo.Transaction_user(transactionID);
CREATE UNIQUE INDEX UX_transaction_user_userID_transactionID ON dbo.Transaction_user(userID, transactionID);
CREATE INDEX IX_Budget_userID ON dbo.Budget(userID);
CREATE INDEX IX_Budget_categoryID ON dbo.Budget(categoryID);
CREATE INDEX IX_Budget_user_dates ON dbo.Budget(userID, startDate, endDate);
CREATE INDEX IX_Alert_budgetID ON dbo.Alert(budgetID);
CREATE INDEX IX_Budget_Limit_History_budgetID ON dbo.Budget_Limit_History(budgetID);
CREATE INDEX IX_Report_category_reportID ON dbo.Report_category(reportID);
CREATE INDEX IX_Report_category_categoryID ON dbo.Report_category(categoryID);
CREATE INDEX IX_Purchase_item_userID ON dbo.Purchase_item(userID);
CREATE INDEX IX_Purchase_item_transactionID ON dbo.Purchase_item(transactionID);
CREATE INDEX IX_Purchase_item_categoryID ON dbo.Purchase_item(categoryID);
CREATE INDEX IX_Purchase_item_productID ON dbo.Purchase_item(productID);
CREATE INDEX IX_Purchase_item_transactionID_categoryID ON dbo.Purchase_item(transactionID, categoryID);
CREATE INDEX IX_Item_return_userID ON dbo.Item_return(userID);
CREATE INDEX IX_Refund_purchaseItemID ON dbo.Refund(purchaseItemID);
CREATE INDEX IX_Transactions_transactionDate ON dbo.Transactions(transactionDate);
CREATE INDEX IX_Transactions_merchantName ON dbo.Transactions(merchantName);
CREATE INDEX IX_Transactions_transactionDate_merchantName ON dbo.Transactions(transactionDate, merchantName);

-- Data insertion
INSERT INTO dbo.Users(userID, firstName, lastName, email)
VALUES (NEXT VALUE FOR dbo.UserID_seq, 'Asifa', 'Kamran', 'asifa@test.com');

INSERT INTO dbo.Category(categoryID, categoryName, description)
VALUES (NEXT VALUE FOR dbo.categoryID_seq, 'Groceries', 'Food & groceries'), (NEXT VALUE FOR dbo.categoryID_seq, 'Health', 'Pharmacy & health'),
(NEXT VALUE FOR dbo.categoryID_seq, 'Dining', 'Restaurants & takeout'), (NEXT VALUE FOR dbo.categoryID_seq, 'Other', 'General shopping'),
(NEXT VALUE FOR dbo.categoryID_seq, 'Education', 'School & learning'), (NEXT VALUE FOR dbo.categoryID_seq, 'Utilities', 'Bills & utilities'),
(NEXT VALUE FOR dbo.categoryID_seq, 'Shopping', 'Personal items'), (NEXT VALUE FOR dbo.categoryID_seq, 'Kid1', 'Kid 1 shopping'),
(NEXT VALUE FOR dbo.categoryID_seq, 'Entertainment', 'Movies & fun'), (NEXT VALUE FOR dbo.categoryID_seq, 'Kid2', 'kid 2 shopping');

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 600.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Groceries' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 200.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Health' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 120.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Dining' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 500.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Shopping' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 500.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Education' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 500.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Utilities' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 200.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Kid1' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 200.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Kid2' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 40.00, '2026-01-01', '2026-01-31'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Entertainment' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Budget(budgetID, userID, categoryID, monthlyLimit, startDate, endDate)
SELECT NEXT VALUE FOR dbo.budgetID_seq, u.userID, c.categoryID, 40.00, '2026-02-01', '2026-02-28'
FROM dbo.Users u JOIN dbo.Category c ON c.categoryName='Other' WHERE u.email='asifa@test.com';

INSERT INTO dbo.Product(productID, productName, brand, upc, defaultPrice)
VALUES (NEXT VALUE FOR dbo.productID_seq, 'Sweater', 'CK', '000000000001', 39.99),
(NEXT VALUE FOR dbo.productID_seq,'Shampoo', 'Dove', '000000000002', 6.49), (NEXT VALUE FOR dbo.productID_seq, 'Shirt', 'Nine West', '000000000003', 23.89),
(NEXT VALUE FOR dbo.productID_seq, 'Socks', 'Nike', '000000000004', 11.29), (NEXT VALUE FOR dbo.productID_seq, 'Contact lens', 'Dallies', '000000000005', 99.99),
(NEXT VALUE FOR dbo.productID_seq, 'Chips', 'Lays', '000000000006', 2.50), (NEXT VALUE FOR dbo.productID_seq, 'Notebook', 'Staples', '000000000007', 1.99),
(NEXT VALUE FOR dbo.productID_seq, 'Pen', 'Papermate', '000000000008', 2.49), (NEXT VALUE FOR dbo.productID_seq, 'Movie Ticket','AMC', '000000000009', 12.00);

DECLARE @tOnline TABLE (transactionID INT);
INSERT INTO dbo.Transactions(transactionID, transactionType, transactionDate, merchantName, totalAmount)
OUTPUT inserted.transactionID INTO @tOnline(transactionID)
VALUES (NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-01', 'Amazon', 19.99), (NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-02', 'Amazon', 25.50),
(NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-03', 'Costco', 180.00), (NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-04', 'Target', 40.00),
(NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-05', 'Amazon', 12.75), (NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-06', 'BestBuy', 60.00),
(NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-07', 'Amazon', 9.99), (NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-08', 'Etsy', 22.00),
(NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-09', 'Amazon', 28.25), (NEXT VALUE FOR dbo.transactionID_seq, 'O', '2026-01-10', 'Chewy', 35.00);
INSERT INTO Online_transaction(transactionID, platform, orderNumber, trackingNumber)
SELECT t.transactionID, 'OnlinePlatform', CONCAT('ORD-', RIGHT(CONCAT('0000', ROW_NUMBER() OVER (ORDER BY t.transactionID)), 4)),
CONCAT('TRK-', RIGHT(CONCAT('0000', ROW_NUMBER() OVER (ORDER BY t.transactionID)), 4) ) FROM @tOnline t;

DECLARE @tStore TABLE (transactionID INT);
INSERT INTO dbo.Transactions(transactionID, transactionType, transactionDate, merchantName, totalAmount)
OUTPUT inserted.transactionID INTO @tStore(transactionID)
VALUES (NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-01', 'CVS', 8.99), (NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-02', 'CVS', 14.50),
(NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-03', 'Target', 55.00), (NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-04', 'Walmart', 32.10),
(NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-05', 'Trader Joes', 28.45), (NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-06', 'Costco', 120.00),
(NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-07', 'Whole Foods', 46.70), (NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-08', 'CVS', 6.25),
(NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-09', 'Kroger', 22.80), (NEXT VALUE FOR dbo.transactionID_seq, 'I', '2026-01-10', 'BestBuy', 82.60);
INSERT INTO dbo.In_store_transaction(transactionID, storeName, storeLocation, recieptNumber)
SELECT t.transactionID, 'StoreName', 'NY', CONCAT('RCPT-', RIGHT(CONCAT('0000', ROW_NUMBER() OVER (ORDER BY t.transactionID)), 4)) FROM @tStore t;

INSERT INTO dbo.Transaction_user (transactionUserID, userID, transactionID)
SELECT NEXT VALUE FOR dbo.transactionUserID_seq, u.userID, t.transactionID FROM dbo.Users u JOIN dbo.Transactions t ON u.email = 'asifa@test.com';

INSERT INTO dbo.Purchase_item(purchaseItemID, transactionID, productID, categoryID, userID, quantity, unitPrice)
SELECT NEXT VALUE FOR dbo.purchaseItemID_seq, t.transactionID, p.productID, c.categoryID, u.userID, t.qty AS quantity,
CAST(t.totalAmount / NULLIF(t.qty,0) AS DECIMAL(10,2)) AS unitPrice FROM 
( SELECT transactionID, totalAmount, ROW_NUMBER() OVER (ORDER BY transactionID) AS rn,
CAST((ROW_NUMBER() OVER (ORDER BY transactionID) % 3) + 1 AS DECIMAL(10,2)) AS qty FROM dbo.Transactions ) t
JOIN ( SELECT productID, defaultPrice, ROW_NUMBER() OVER (ORDER BY productID) AS rn, COUNT(*) OVER () AS cnt
FROM dbo.Product ) p ON p.rn = ((t.rn - 1) % p.cnt) + 1 JOIN 
( SELECT categoryID, ROW_NUMBER() OVER (ORDER BY categoryID) AS rn, COUNT(*) OVER () AS cnt FROM dbo.Category ) c
ON c.rn = ((t.rn - 1) % c.cnt) + 1 JOIN dbo.Users u ON u.email = 'asifa@test.com';

SELECT 'Users' AS TableName, COUNT(*) AS [RowCount] FROM Users UNION ALL SELECT 'Category', COUNT(*) FROM dbo.Category
UNION ALL SELECT 'Budget', COUNT(*) FROM dbo.Budget UNION ALL SELECT 'Product', COUNT(*) FROM dbo.Product
UNION ALL SELECT 'Transactions', COUNT(*) FROM dbo.Transactions UNION ALL SELECT 'Online_transaction', COUNT(*) FROM dbo.Online_transaction
UNION ALL SELECT 'In_store_transaction', COUNT(*) FROM dbo.In_store_transaction UNION ALL SELECT 'transaction_user', COUNT(*) FROM dbo.Transaction_user
UNION ALL SELECT 'Purchase_item', COUNT(*) FROM dbo.Purchase_item;

-- Use case: Set Category Budget
GO
CREATE PROCEDURE dbo.usp_SetCategoryBudget(@userEmail VARCHAR(128),@categoryName VARCHAR(32),@monthlyLimit DECIMAL(10,2),
@startDate DATE,@endDate DATE) AS BEGIN
IF @userEmail IS NULL OR LTRIM(RTRIM(@userEmail))='' THROW 50001,'Email cannot be blank.',1;
IF @userEmail NOT LIKE '%_@_%._%' THROW 50002,'Email format is invalid.',1;
IF @categoryName IS NULL OR LTRIM(RTRIM(@categoryName))='' THROW 50003,'Category name cannot be blank.',1;
IF @monthlyLimit IS NULL OR @monthlyLimit<=0 THROW 50004,'monthlyLimit must be > 0.',1;
IF @startDate IS NULL OR @endDate IS NULL THROW 50005,'startDate and endDate are required.',1;
IF @startDate>@endDate THROW 50006,'startDate must be <= endDate.',1;
DECLARE @userID INT,@categoryID INT;SELECT @userID=userID FROM dbo.Users WHERE email=@userEmail;
IF @userID IS NULL THROW 50007,'Invalid user email (user not found).',1;
SELECT @categoryID=categoryID FROM dbo.Category WHERE categoryName=@categoryName;
IF @categoryID IS NULL THROW 50008,'Invalid category (not found).',1;
IF EXISTS(SELECT 1 FROM dbo.Budget WHERE userID=@userID AND categoryID=@categoryID AND 
startDate=@startDate AND endDate=@endDate) THROW 50009,'Budget already exists for this user/category and exact period.',1;
INSERT INTO dbo.Budget(budgetID,userID,categoryID,monthlyLimit,startDate,endDate) 
VALUES(NEXT VALUE FOR dbo.budgetID_seq,@userID,@categoryID,@monthlyLimit,@startDate,@endDate); END;
GO

-- Use case: Record Purchase
GO
CREATE PROCEDURE dbo.usp_RecordPurchase(@transactionType CHAR(1),@transactionDate DATE,@merchantName VARCHAR(64),
@totalAmount DECIMAL(10,2),@userEmail VARCHAR(128),@categoryName VARCHAR(32),@productName VARCHAR(64),
@brand VARCHAR(32),@upc VARCHAR(32),@quantity DECIMAL(10,2),@unitPrice DECIMAL(10,2)) AS BEGIN
IF @userEmail IS NULL OR LTRIM(RTRIM(@userEmail))='' THROW 50101,'userEmail cannot be blank.',1;
IF @userEmail NOT LIKE '%_@_%._%' THROW 50102,'userEmail format is invalid.',1;
IF @categoryName IS NULL OR LTRIM(RTRIM(@categoryName))='' THROW 50103,'categoryName cannot be blank.',1;
IF @productName IS NULL OR LTRIM(RTRIM(@productName))='' THROW 50104,'productName cannot be blank.',1;
IF @upc IS NOT NULL AND LTRIM(RTRIM(@upc))='' THROW 50105,'upc cannot be blank when provided.',1;
IF @transactionType NOT IN('O','I') THROW 50106,'transactionType must be O or I.',1;
IF @totalAmount IS NULL OR @totalAmount<0 THROW 50107,'totalAmount must be >= 0.',1;
IF @transactionDate IS NULL THROW 50108,'transactionDate is required.',1;
IF @transactionDate>CAST(GETDATE() AS DATE) THROW 50109,'transactionDate cannot be in the future.',1;
IF @merchantName IS NULL OR LTRIM(RTRIM(@merchantName))='' THROW 50110,'merchant name cannot be blank.',1;
IF @quantity IS NULL OR @quantity<=0 THROW 50111,'quantity must be > 0.',1;
IF @unitPrice IS NULL OR @unitPrice<0 THROW 50112,'unitPrice must be >= 0.',1;
DECLARE @userID INT,@categoryID INT,@productID INT;DECLARE @transactionID INT=NEXT VALUE FOR dbo.transactionID_seq;
SELECT @userID=userID FROM dbo.Users WHERE email=@userEmail;
IF @userID IS NULL THROW 50114,'Invalid userEmail (user not found).',1;
SELECT @categoryID=categoryID FROM dbo.Category WHERE categoryName=@categoryName;
IF @categoryID IS NULL THROW 50115,'Invalid categoryName (category not found).',1;
INSERT INTO dbo.Transactions(transactionID,transactionType,transactionDate,merchantName,totalAmount) 
VALUES(@transactionID,@transactionType,@transactionDate,@merchantName,@totalAmount);
IF @upc IS NOT NULL SELECT @productID=productID FROM dbo.Product WHERE upc=@upc;
IF @productID IS NULL BEGIN SET @productID=NEXT VALUE FOR dbo.productID_seq;INSERT INTO 
dbo.Product(productID,productName,brand,upc,defaultPrice) VALUES(@productID,@productName,@brand,@upc,NULL);END
INSERT INTO dbo.Purchase_item(purchaseItemID,userID,transactionID,productID,categoryID,quantity,unitPrice) 
VALUES(NEXT VALUE FOR dbo.purchaseItemID_seq,@userID,@transactionID,@productID,@categoryID,@quantity,@unitPrice);
INSERT INTO dbo.Transaction_user(transactionUserID,userID,transactionID) 
VALUES(NEXT VALUE FOR dbo.transactionUserID_seq,@userID,@transactionID); END;
GO

-- Execute procedure usp_SetCategoryBudget
EXEC dbo.usp_SetCategoryBudget 
@userEmail='asifa@test.com', @categoryName='Shopping', @monthlyLimit=500.00,
@startDate='2026-02-01', @endDate='2026-02-28';

-- Execute procedure usp_RecordPurchase
EXEC dbo.usp_RecordPurchase
@transactionType='O', @transactionDate='2026-02-05', @merchantName='Amazon', @totalAmount=49.99,
@userEmail='asifa@test.com', @categoryName='Shopping', @productName='Jacket', @brand='CK',
@upc='012345678901', @quantity=1, @unitPrice=45.99;

--Question 1: For a specific user and month, what is the budget vs. actual spend per category?
DECLARE @StartDate DATE='2026-01-01';DECLARE @EndDate DATE='2026-01-31';
SELECT TOP 5 t.merchantName,COUNT(*) AS numTransactions,FORMAT(SUM(t.totalAmount),'$#,##0.00') AS totalSpent,
FORMAT(SUM(CASE WHEN ot.transactionID IS NOT NULL THEN t.totalAmount ELSE 0 END),'$#,##0.00') AS onlineSpent,
FORMAT(SUM(CASE WHEN ist.transactionID IS NOT NULL THEN t.totalAmount ELSE 0 END),'$#,##0.00') AS inStoreSpent
FROM dbo.Transactions t LEFT JOIN dbo.Online_transaction ot ON ot.transactionID=t.transactionID
LEFT JOIN dbo.In_store_transaction ist ON ist.transactionID=t.transactionID
WHERE t.transactionDate BETWEEN @StartDate AND @EndDate
GROUP BY t.merchantName HAVING SUM(t.totalAmount)>0 ORDER BY SUM(t.totalAmount) DESC;
GO

-- Question 2: Which merchants have the highest total spending in a given date range, 
-- and how much of that spending came from Online vs In-Store transactions?
DECLARE @StartDate DATE = '2026-01-01'; DECLARE @EndDate DATE = '2026-01-31';
SELECT TOP 5 t.merchantName, COUNT(*) AS numTransactions, FORMAT(SUM(t.totalAmount),'$.00') 
AS totalSpent, FORMAT(SUM(CASE WHEN ot.transactionID IS NOT NULL THEN t.totalAmount ELSE 0 END),'$.00') 
AS onlineSpent, FORMAT(SUM(CASE WHEN ist.transactionID IS NOT NULL THEN t.totalAmount ELSE 0 END),'$.00') 
AS inStoreSpent FROM dbo.Transactions t LEFT JOIN dbo.Online_transaction ot ON ot.transactionID = t.transactionID 
LEFT JOIN dbo.In_store_transaction ist ON ist.transactionID = t.transactionID WHERE t.transactionDate BETWEEN @StartDate 
AND @EndDate GROUP BY t.merchantName HAVING SUM(t.totalAmount) > 0 ORDER BY SUM(t.totalAmount) DESC;

-- Question 3: For a given user and month, which categories have the highest net spending
-- (purchases minus refunds), and how does that compare to the category budget?
GO
CREATE VIEW dbo.vw_UserCategoryNetSpend 
AS WITH RefundAgg AS (SELECT purchaseItemID,SUM(refundAmount) AS refundAmount FROM dbo.Refund GROUP BY purchaseItemID)
SELECT u.userID,u.email,c.categoryID,c.categoryName,t.transactionDate,
CAST(pi.quantity*pi.unitPrice AS DECIMAL(10,2)) AS grossSpend, CAST(ISNULL(ra.refundAmount,0) AS DECIMAL(10,2)) AS refundAmount,
CAST((pi.quantity*pi.unitPrice)-ISNULL(ra.refundAmount,0) AS DECIMAL(10,2)) AS netSpend
FROM dbo.Users u JOIN dbo.Transaction_user tu ON tu.userID=u.userID JOIN dbo.Transactions t ON t.transactionID=tu.transactionID
JOIN dbo.Purchase_item pi ON pi.transactionID=t.transactionID JOIN Category c ON c.categoryID=pi.categoryID
LEFT JOIN RefundAgg ra ON ra.purchaseItemID=pi.purchaseItemID;
GO

--Use the view
DECLARE @UserEmail3 VARCHAR(128)='asifa@test.com';DECLARE @MonthStart3 DATE='2026-01-01';DECLARE @MonthEnd3 DATE='2026-01-31';
SELECT v.categoryName,FORMAT(b.monthlyLimit,'$.00') AS budgetAmount,FORMAT(SUM(v.netSpend),'$.00') AS netSpend,
FORMAT(b.monthlyLimit-SUM(v.netSpend),'$.00') AS remaining,
CASE WHEN SUM(v.netSpend)>b.monthlyLimit THEN 'OVER' ELSE 'OK' END AS budgetStatus
FROM dbo.vw_UserCategoryNetSpend v JOIN dbo.Users u ON u.userID=v.userID
JOIN dbo.Budget b ON b.userID=v.userID AND b.categoryID=v.categoryID
WHERE u.email=@UserEmail3 AND v.transactionDate BETWEEN @MonthStart3 AND @MonthEnd3
AND b.startDate<=@MonthEnd3 AND b.endDate>=@MonthStart3 GROUP BY v.categoryName,b.monthlyLimit
HAVING SUM(v.netSpend)>0 ORDER BY SUM(v.netSpend) DESC;

-- trigger that will maintain the history table
GO
CREATE TRIGGER dbo.trg_Budget_MonthlyLimit_History ON dbo.Budget
AFTER UPDATE AS BEGIN IF NOT UPDATE(monthlyLimit) RETURN;
INSERT INTO dbo.Budget_Limit_History(budgetLimitHistoryID,budgetID,oldMonthlyLimit,newMonthlyLimit)
SELECT NEXT VALUE FOR dbo.budgetLimitHistoryID_seq,i.budgetID,d.monthlyLimit,i.monthlyLimit
FROM inserted i JOIN deleted d ON d.budgetID=i.budgetID
WHERE d.monthlyLimit IS NOT NULL AND i.monthlyLimit IS NOT NULL AND d.monthlyLimit<>i.monthlyLimit; END;
GO

-- update the history table
UPDATE dbo.Budget SET monthlyLimit=300.00 WHERE budgetID=1;
SELECT * FROM dbo.Budget_Limit_History;

-- Query for Bar chart(same as Question 1)

-- Query for Pie Chart Data (Spending by Category for January 2026)
DECLARE @StartDatePie DATE = '2026-01-01'; DECLARE @EndDatePie   DATE = '2026-01-31';
SELECT c.categoryName, CAST(SUM(pi.quantity * pi.unitPrice) AS DECIMAL(10,2)) AS totalCategorySpend
FROM dbo.Purchase_item pi JOIN dbo.Transactions t ON t.transactionID = pi.transactionID
JOIN dbo.Category c ON c.categoryID = pi.categoryID WHERE t.transactionDate BETWEEN @StartDatePie AND @EndDatePie
GROUP BY c.categoryName HAVING SUM(pi.quantity * pi.unitPrice) > 0 ORDER BY SUM(pi.quantity * pi.unitPrice) DESC;
