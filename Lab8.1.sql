USE ComputerSalesCRM;
GO

/* ************************************************************* */
/* ===== ˜˜˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜˜˜ ===== */
/* ************************************************************* */

-- 1. ˜˜˜˜˜˜ INSTEAD OF INSERT ˜˜ SaleDetails (˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜)
IF OBJECT_ID('trg_SaleDetails_StockCheck_Insert', 'TR') IS NOT NULL
    DROP TRIGGER trg_SaleDetails_StockCheck_Insert;
GO

CREATE TRIGGER trg_SaleDetails_StockCheck_Insert
ON SaleDetails
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        LEFT JOIN [Product] AS p ON i.ProductID = p.ProductID
        WHERE i.Quantity <= 0 OR i.Quantity IS NULL
           OR p.StockQuantity < i.Quantity
           OR p.ProductID IS NULL
    )
    BEGIN
        PRINT '˜˜˜˜˜˜˜: ˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜˜˜˜.';
        THROW 51001, '˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜ ˜˜ ˜˜˜˜˜ ˜˜˜ ˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜˜˜˜˜.', 1;
        RETURN;
    END

    INSERT INTO SaleDetails (SaleDetailID, SaleID, ProductID, Quantity, UnitPrice)
    SELECT i.SaleDetailID, i.SaleID, i.ProductID, i.Quantity, i.UnitPrice
    FROM inserted AS i;

    UPDATE p
    SET p.StockQuantity = p.StockQuantity - i.Quantity
    FROM [Product] AS p
    JOIN inserted AS i ON p.ProductID = i.ProductID;
END;
GO

-- 2. ˜˜˜˜˜˜ AFTER INSERT ˜˜ OrderDetails (˜˜˜˜˜˜˜˜˜ ˜˜˜˜˜˜˜)
IF OBJECT_ID('trg_OrderDetails_StockUpdate_Insert', 'TR') IS NOT NULL
    DROP TRIGGER trg_OrderDetails_StockUpdate_Insert;
GO

CREATE TRIGGER trg_OrderDetails_StockUpdate_Insert
ON OrderDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + i.OrderQuantity
        FROM [Product] AS p
        JOIN inserted AS i ON p.ProductID = i.ProductID;
    END
END;
GO

-- 3. AFTER UPDATE/DELETE ˜˜˜˜˜˜˜ ˜˜˜ SaleDetails (˜˜˜˜˜˜˜˜ StockQuantity ˜˜ SaleGrandTotal)
IF OBJECT_ID('trg_SaleDetails_StockAndTotal_Update', 'TR') IS NOT NULL
    DROP TRIGGER trg_SaleDetails_StockAndTotal_Update;
GO

CREATE TRIGGER trg_SaleDetails_StockAndTotal_Update
ON SaleDetails
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Quantity) OR UPDATE(UnitPrice)
    BEGIN
        BEGIN TRY
            UPDATE p
            SET p.StockQuantity = p.StockQuantity + d.Quantity - i.Quantity
            FROM [Product] AS p
            JOIN deleted AS d ON p.ProductID = d.ProductID
            JOIN inserted AS i ON p.ProductID = i.ProductID AND i.SaleDetailID = d.SaleDetailID;

            UPDATE s
            SET s.SaleGrandTotal = (SELECT SUM(sd.Quantity * sd.UnitPrice)
                                    FROM SaleDetails sd
                                    WHERE sd.SaleID = s.SaleID)
            FROM Sale AS s
            JOIN inserted AS i ON s.SaleID = i.SaleID;
        END TRY
        BEGIN CATCH
            THROW;
        END CATCH
    END
END;
GO

IF OBJECT_ID('trg_SaleDetails_StockAndTotal_Delete', 'TR') IS NOT NULL
    DROP TRIGGER trg_SaleDetails_StockAndTotal_Delete;
GO

CREATE TRIGGER trg_SaleDetails_StockAndTotal_Delete
ON SaleDetails
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + d.Quantity
        FROM [Product] AS p
        JOIN deleted AS d ON p.ProductID = d.ProductID;

        UPDATE s
        SET s.SaleGrandTotal = ISNULL((SELECT SUM(sd.Quantity * sd.UnitPrice)
                                        FROM SaleDetails sd
                                        WHERE sd.SaleID = s.SaleID), 0)
        FROM Sale AS s
        JOIN deleted AS d ON s.SaleID = d.SaleID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- 4. AFTER UPDATE/DELETE ˜˜˜˜˜˜˜ ˜˜˜ OrderDetails (˜˜˜˜˜˜˜˜ StockQuantity ˜˜ OrderGrandTotal)
IF OBJECT_ID('trg_OrderDetails_StockAndTotal_Update', 'TR') IS NOT NULL
    DROP TRIGGER trg_OrderDetails_StockAndTotal_Update;
GO

CREATE TRIGGER trg_OrderDetails_StockAndTotal_Update
ON OrderDetails
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(OrderQuantity) OR UPDATE(UnitPrice)
    BEGIN
        BEGIN TRY
            UPDATE p
            SET p.StockQuantity = p.StockQuantity + i.OrderQuantity - d.OrderQuantity
            FROM [Product] AS p
            JOIN inserted AS i ON p.ProductID = i.ProductID
            JOIN deleted AS d ON p.ProductID = d.ProductID AND i.OrderDetailID = d.OrderDetailID;

            UPDATE so
            SET so.OrderGrandTotal = (SELECT SUM(od.OrderQuantity * od.UnitPrice)
                                      FROM OrderDetails od
                                      WHERE od.OrderID = so.OrderID)
            FROM SupplierOrder AS so
            JOIN inserted AS i ON so.OrderID = i.OrderID;
        END TRY
        BEGIN CATCH
            THROW;
        END CATCH
    END
END;
GO

IF OBJECT_ID('trg_OrderDetails_StockAndTotal_Delete', 'TR') IS NOT NULL
    DROP TRIGGER trg_OrderDetails_StockAndTotal_Delete;
GO

CREATE TRIGGER trg_OrderDetails_StockAndTotal_Delete
ON OrderDetails
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE p
        SET p.StockQuantity = p.StockQuantity - d.OrderQuantity
        FROM [Product] AS p
        JOIN deleted AS d ON p.ProductID = d.ProductID;

        UPDATE so
        SET so.OrderGrandTotal = ISNULL((SELECT SUM(od.OrderQuantity * od.UnitPrice)
                                          FROM OrderDetails od
                                          WHERE od.OrderID = so.OrderID), 0)
        FROM SupplierOrder AS so
        JOIN deleted AS d ON so.OrderID = d.OrderID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

/* ***************************************** */
/* ===== ˜˜˜˜˜˜˜˜˜˜˜˜ ˜˜˜˜ ˜˜˜ TVP ======== */
/* ***************************************** */

IF TYPE_ID('UDTT_OrderDetailsType') IS NULL
CREATE TYPE UDTT_OrderDetailsType AS TABLE
(
    ProductID CHAR(10) NOT NULL,
    OrderQuantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
);
GO

IF TYPE_ID('UDTT_SaleDetailsType') IS NULL
    CREATE TYPE UDTT_SaleDetailsType AS TABLE
    (
        ProductID CHAR(10) NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(10,2) NOT NULL
    );