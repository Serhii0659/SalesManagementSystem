USE ComputerSalesCRM;
GO

/* ===== ************************************* ===== */
/* ===== ��������� 1: ��������� ������ ������� ===== */
/* ===== ************************************* ===== */
-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('AddCustomer', 'P') IS NOT NULL
    DROP PROCEDURE AddCustomer;
GO

-- ��������� ��� ��������� ������ �������
CREATE PROCEDURE AddCustomer
    @FullName VARCHAR(255),
    @Phone VARCHAR(20),
    @Email VARCHAR(255)

AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @ExistingCustomerID CHAR(10);

    -- ��������, �� ���� �������� � ����� ������ ��'��
    SELECT @ExistingCustomerID = CustomerID
    FROM Customer
    WHERE FullName = @FullName;

    -- ���� �������� ���������, ��������� ���� ID � ��������
    IF @ExistingCustomerID IS NOT NULL
    BEGIN
        SELECT @ExistingCustomerID AS CustomerID;
        RETURN; -- ��������� ��������� ���������
    END

    -- ���� �������� �� ���������, �������� ����� ID � ������ ����

    DECLARE @NewCustomerID CHAR(10);
    DECLARE @MaxNumericID INT;
    DECLARE @NextNumericID INT;
    DECLARE @Prefix CHAR(4) = 'CUST';
    DECLARE @NumericLength INT = 6; -- ʳ������ ���� � ������� ������� ID (10 - 4 = 6)

    -- ��������� ����������� ������� �������� � �������� CustomerID
    SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(CustomerID, LEN(@Prefix) + 1, LEN(CustomerID) - LEN(@Prefix)) AS INT)), 0)
    FROM Customer
    WHERE CustomerID LIKE @Prefix + '%'; -- ������������, �� ���������� ����� �������� ID

    SET @NextNumericID = @MaxNumericID + 1;

    -- ������� ����� CustomerID � 6 ������� � ������� �������
    SET @NewCustomerID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength)); -- ���������, 'CUST' + '000004'

    -- ��������, �� ������������ ID ��� ���� (��������� ��������)
    WHILE EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @NewCustomerID)
    BEGIN
        SET @NextNumericID = @NextNumericID + 1;
        SET @NewCustomerID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
    END

    -- ��������� ������ �������
    INSERT INTO Customer (CustomerID, FullName, Phone, Email)
    VALUES (@NewCustomerID, @FullName, @Phone, @Email);

    -- ��������� ID ������ �������
    SELECT @NewCustomerID AS CustomerID;

	SET NOCOUNT OFF;
END

-- ��������� ������������ ���������
/*
GO
EXEC AddCustomer
    @FullName = '����� �������',
    @Phone = '0672233445',
    @Email = 'hanna.melnyk@example.com';
*/


/* ===== ******************************************* ===== */
/* ===== ��������� 2: ��������� ������ ������������� ===== */
/* ===== ******************************************* ===== */

GO

-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('AddSupplier', 'P') IS NOT NULL
    DROP PROCEDURE AddSupplier;
GO

-- ��������� ��� ��������� ������ �������������
CREATE PROCEDURE AddSupplier
    @OrganizationName VARCHAR(255),
    @Phone VARCHAR(20),
    @Email VARCHAR(255)

AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @ExistingSupplierID CHAR(10);

    -- ��������, �� ���� ������������ � ����� ������ �����������
    SELECT @ExistingSupplierID = SupplierID
    FROM Supplier
    WHERE OrganizationName = @OrganizationName;

    -- ���� ������������ ���������, ��������� ���� ID � ��������
    IF @ExistingSupplierID IS NOT NULL
    BEGIN
        SELECT @ExistingSupplierID AS SupplierID;
        RETURN; -- ��������� ��������� ���������
    END

    -- ���� ������������ �� ���������, �������� ����� ID � ������ ����

    DECLARE @NewSupplierID CHAR(10);
    DECLARE @MaxNumericID INT;
    DECLARE @NextNumericID INT;
    DECLARE @Prefix CHAR(4) = 'SUPP'; -- ������� ��� ID �������������
    DECLARE @NumericLength INT = 6;  -- ʳ������ ���� � ������� ������� ID (10 - 4 = 6)

    -- ��������� ����������� ������� �������� � �������� SupplierID
    SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(SupplierID, LEN(@Prefix) + 1, LEN(SupplierID) - LEN(@Prefix)) AS INT)), 0)
    FROM Supplier
    WHERE SupplierID LIKE @Prefix + '%'; -- ���������� ����� ID � ��������� ���������

    SET @NextNumericID = @MaxNumericID + 1;

    -- ������� ����� SupplierID � 6 ������� � ������� �������
    SET @NewSupplierID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));

    -- ��������, �� ������������ ID ��� ���� (��������� ��������)
    WHILE EXISTS (SELECT 1 FROM Supplier WHERE SupplierID = @NewSupplierID)
    BEGIN
        SET @NextNumericID = @NextNumericID + 1;
        SET @NewSupplierID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
    END

    -- ��������� ������ �������������
    INSERT INTO Supplier (SupplierID, OrganizationName, Phone, Email)
    VALUES (@NewSupplierID, @OrganizationName, @Phone, @Email);

    -- ��������� ID ������ �������������
    SELECT @NewSupplierID AS SupplierID;

	SET NOCOUNT OFF;
END

-- ��������� ������������ ���������
/*
GO
EXEC AddSupplier
    @OrganizationName = '����''������� ������ ���',
    @Phone = '0441234567',
    @Email = 'info@compvsesvit.ua';
*/

/* ===== ************************************** ===== */
/* ===== ��������� 3: ��������� ���� ������� ===== */
/* ===== ************************************** ===== */

GO

-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('AddCategory', 'P') IS NOT NULL
    DROP PROCEDURE AddCategory;
GO

-- ��������� ��� ��������� ���� �������
CREATE PROCEDURE AddCategory
    @CategoryName VARCHAR(255)

AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @ExistingCategoryID CHAR(10);

    -- ��������, �� ���� �������� � ����� ������
    SELECT @ExistingCategoryID = CategoryID
    FROM Category
    WHERE CategoryName = @CategoryName;

    -- ���� �������� ��������, ��������� �� ID � ��������
    IF @ExistingCategoryID IS NOT NULL
    BEGIN
        SELECT @ExistingCategoryID AS CategoryID;
        RETURN; -- ��������� ��������� ���������
    END

    -- ���� �������� �� ��������, �������� ����� ID � ������ ��

    DECLARE @NewCategoryID CHAR(10);
    DECLARE @MaxNumericID INT;
    DECLARE @NextNumericID INT;
    DECLARE @Prefix CHAR(3) = 'CAT'; -- ������� ��� ID �������
    DECLARE @NumericLength INT = 7;  -- ʳ������ ���� � ������� ������� ID (10 - 3 = 7)

    -- ��������� ����������� ������� �������� � �������� CategoryID
    SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(CategoryID, LEN(@Prefix) + 1, LEN(CategoryID) - LEN(@Prefix)) AS INT)), 0)
    FROM Category
    WHERE CategoryID LIKE @Prefix + '%'; -- ���������� ����� ID � ��������� ���������

    SET @NextNumericID = @MaxNumericID + 1;

    -- ������� ����� CategoryID � 7 ������� � ������� �������
    SET @NewCategoryID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength)); -- ���������, 'CAT' + '0000006'

    -- ��������, �� ������������ ID ��� ���� (��������� ��������)
    WHILE EXISTS (SELECT 1 FROM Category WHERE CategoryID = @NewCategoryID)
    BEGIN
        SET @NextNumericID = @NextNumericID + 1;
        SET @NewCategoryID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
    END

    -- ��������� ���� �������
    INSERT INTO Category (CategoryID, CategoryName)
    VALUES (@NewCategoryID, @CategoryName);

    -- ��������� ID ���� �������
    SELECT @NewCategoryID AS CategoryID;

	SET NOCOUNT OFF;
END

-- ��������� ������������ ���������
/*
GO
EXEC AddCategory
��� @CategoryName = '�������� �� �������';
*/


/* ===== **************************************** ===== */
/* ===== ��������� 4: ��������� ������ ���������� ===== */
/* ===== **************************************** ===== */

GO

-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('AddEmployee', 'P') IS NOT NULL
��� DROP PROCEDURE AddEmployee;
GO

-- ��������� ��� ��������� ������ ����������
CREATE PROCEDURE AddEmployee
��� @FullName VARCHAR(255),
��� @Phone VARCHAR(20),
��� @Email VARCHAR(255),
��� @Position VARCHAR(100)

AS
BEGIN
	SET NOCOUNT ON;

��� DECLARE @ExistingEmployeeID CHAR(10);

��� -- ��������, �� ���� ��������� � ����� ������ ��'��
��� SELECT @ExistingEmployeeID = EmployeeID
��� FROM Employee
��� WHERE FullName = @FullName;

��� -- ���� ��������� ���������, ��������� ���� ID � ��������
��� IF @ExistingEmployeeID IS NOT NULL
��� BEGIN
������� SELECT @ExistingEmployeeID AS EmployeeID;
������� RETURN; -- ��������� ��������� ���������
��� END

��� -- ���� ��������� �� ���������, �������� ����� ID � ������ ����

��� DECLARE @NewEmployeeID CHAR(10);
��� DECLARE @MaxNumericID INT;
��� DECLARE @NextNumericID INT;
��� DECLARE @Prefix CHAR(3) = 'EMP'; -- ������� ��� ID ����������
��� DECLARE @NumericLength INT = 7;� -- ʳ������ ���� � ������� ������� ID (10 - 3 = 7)

��� -- ��������� ����������� ������� �������� � �������� EmployeeID
��� SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(EmployeeID, LEN(@Prefix) + 1, LEN(EmployeeID) - LEN(@Prefix)) AS INT)), 0)
��� FROM Employee
��� WHERE EmployeeID LIKE @Prefix + '%'; -- ���������� ����� ID � ��������� ���������

��� SET @NextNumericID = @MaxNumericID + 1;

��� -- ������� ����� EmployeeID � 7 ������� � ������� �������
��� SET @NewEmployeeID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength)); -- ���������, 'EMP' + '0000003'

��� -- ��������, �� ������������ ID ��� ���� (��������� ��������)
��� WHILE EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @NewEmployeeID)
��� BEGIN
������� SET @NextNumericID = @NextNumericID + 1;
������� SET @NewEmployeeID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
��� END

��� -- ��������� ������ ����������
��� INSERT INTO Employee (EmployeeID, FullName, Phone, Email, Position)
��� VALUES (@NewEmployeeID, @FullName, @Phone, @Email, @Position);

��� -- ��������� ID ������ ����������
��� SELECT @NewEmployeeID AS EmployeeID;

	SET NOCOUNT OFF;
END

-- ��������� ������������ ���������:
/*
GO
EXEC AddEmployee
��� @FullName = '����� ���������',
��� @Phone = '0637788990',
��� @Email = 'serhii.kovalchuk@example.com',
��� @Position = '�������� � �������';
*/

/* ************************************************ */
/* ===== ��������� 5: ��������� ������ ������ ===== */
/* ************************************************ */

GO
-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('AddProduct', 'P') IS NOT NULL
��� DROP PROCEDURE AddProduct;
GO

-- ��������� ��� ��������� ������ ������
CREATE PROCEDURE AddProduct
��� @CategoryID CHAR(10),
��� @ProductName VARCHAR(255),
��� @Price DECIMAL(10,2),
��� @StockQuantity INT = 0 -- ���������� ������� ��������� �������, �� ������������� 0

AS
BEGIN
	SET NOCOUNT ON;

��� DECLARE @ExistingProductID CHAR(10);

��� -- ��������, �� ���� ����� � ����� ������
��� SELECT @ExistingProductID = ProductID
��� FROM [Product]
��� WHERE ProductName = @ProductName;

��� -- ���� ����� ���������, ��������� ���� ID � ��������
��� IF @ExistingProductID IS NOT NULL
��� BEGIN
������� SELECT @ExistingProductID AS ProductID;
������� RETURN; -- ��������� ��������� ���������
��� END

��� -- ���� ����� �� ���������, �������� ����� ID � ������ ����

��� DECLARE @NewProductID CHAR(10);
��� DECLARE @MaxNumericID INT;
��� DECLARE @NextNumericID INT;
��� DECLARE @Prefix CHAR(4) = 'PROD'; -- ������� ��� ID ������
��� DECLARE @NumericLength INT = 6;� -- ʳ������ ���� � ������� ������� ID (10 - 4 = 6)

��� -- ��������� ����������� ������� �������� � �������� ProductID
��� SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(ProductID, LEN(@Prefix) + 1, LEN(ProductID) - LEN(@Prefix)) AS INT)), 0)
��� FROM [Product]
��� WHERE ProductID LIKE @Prefix + '%'; -- ���������� ����� ID � ��������� ���������

��� SET @NextNumericID = @MaxNumericID + 1;

��� -- ������� ����� ProductID � 6 ������� � ������� �������
��� SET @NewProductID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength)); -- ���������, 'PROD' + '000006'

��� -- ��������, �� ������������ ID ��� ���� (��������� ��������)
��� WHILE EXISTS (SELECT 1 FROM [Product] WHERE ProductID = @NewProductID)
��� BEGIN
������� SET @NextNumericID = @NextNumericID + 1;
������� SET @NewProductID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
��� END

��� -- �������� �������� CategoryID
��� IF NOT EXISTS (SELECT 1 FROM Category WHERE CategoryID = @CategoryID)
��� BEGIN
������� -- ����� ��������� ����������� ��� ������� ��� ��� �������
        PRINT '�������: �������� ' + @CategoryID + ' �� ����!';
������� THROW 51000, '�������� � �������� ID �� ����.', 1;
������� RETURN;
��� END


��� -- ��������� ������ ������
��� INSERT INTO [Product] (ProductID, CategoryID, ProductName, Price, StockQuantity)
��� VALUES (@NewProductID, @CategoryID, @ProductName, @Price, @StockQuantity);

��� -- ��������� ID ������ ������
��� SELECT @NewProductID AS ProductID;

	SET NOCOUNT OFF;
END

-- ��������� ������������ ���������:
/*
GO
EXEC AddProduct
��� @CategoryID = 'CAT002', -- ������������
��� @ProductName = '���������� ���''��� 8GB DDR4',
��� @Price = 1500.00,
��� @StockQuantity = 20;
GO

-- �������� ������ �����, ���� ��� ���� (���������, "������� Acer" ��� �)
EXEC AddProduct
��� @CategoryID = 'CAT001', -- ������ ������� ���� ��������, �������� �� ProductName
��� @ProductName = '������� Acer',
��� @Price = 26000.00, -- ������ ������� ���� ����/�������
��� @StockQuantity = 5;
*/
-- (��)��������� ������������ ��������� (������� �� ����):
/*
EXEC AddProduct
 �� @CategoryID = 'CAT999',
��� @ProductName = '�������� �����',
��� @Price = 100.00,
��� @StockQuantity = 1;
GO
*/

/* ************************************************ */
/* ===== ��������� 6: ��������� ���� ������ ===== */
/* ************************************************ */

GO

-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('CreateSale', 'P') IS NOT NULL
    DROP PROCEDURE CreateSale;
GO

-- ��������� ��� ��������� ������ �������
CREATE PROCEDURE CreateSale
    @EmployeeID CHAR(10),
    @CustomerID CHAR(10),
    @SaleDate DATETIME = NULL,  -- �������� �� �������������
    @SaleDetails UDTT_SaleDetailsType READONLY, -- �������� ���� ������� ��� ������� �������
    @PaymentMethod VARCHAR(50)

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewSaleID CHAR(10);
    DECLARE @SaleGrandTotal DECIMAL(10,2);
    DECLARE @MaxNumericID INT;
    DECLARE @NextNumericID INT;
    DECLARE @Prefix CHAR(4) = 'SALE'; -- ������� ��� ID �������
    DECLARE @NumericLength INT = 6;  -- ʳ������ ���� � ������� ������� ID (10 - 4 = 6)

    -- �������� ����� ���������� SaleID
    PRINT '��������� ������ ID �������';
    SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(SaleID, LEN(@Prefix) + 1, LEN(SaleID) - LEN(@Prefix)) AS INT)), 0)
    FROM Sale
    WHERE SaleID LIKE @Prefix + '%';

    SET @NextNumericID = @MaxNumericID + 1;
    SET @NewSaleID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
    PRINT '����� ID �������: ' + @NewSaleID;

    -- ����������, �� ������������ ID ��� ���� (���� ��� ���������� ����� MAX + 1 �� �����������, ��� �������� ��� �������)
    WHILE EXISTS (SELECT 1 FROM Sale WHERE SaleID = @NewSaleID)
    BEGIN
        SET @NextNumericID = @NextNumericID + 1;
        SET @NewSaleID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
        PRINT '����� ������������ ID ������� (����� �������� ���������): ' + @NewSaleID;
    END

    -- �������� ��������� SaleDetailID ��� ������� ����� � @SaleDetails
    PRINT '��������� SaleDetailID ��� ������� �������';
    CREATE TABLE #TempSaleDetailsWithID (
        SaleDetailID CHAR(10),
        SaleID CHAR(10),
        ProductID CHAR(10),
        Quantity INT,
        UnitPrice DECIMAL(10,2)
    );

    DECLARE @DetailPrefix CHAR(4) = 'SDTL'; -- ������� ��� ID ����� �������
    DECLARE @DetailNumericLength INT = 6;
    DECLARE @MaxDetailNumericID INT;
    -- DECLARE @NextDetailNumericID INT; -- �� ����� ����� �� �������
    -- DECLARE @CurrentDetailNumericID INT; -- �� ����� ����� �� �������

    -- ��������� ������������ �������� �������� ID ��� SaleDetail
    SELECT @MaxDetailNumericID = ISNULL(MAX(CAST(SUBSTRING(SaleDetailID, LEN(@DetailPrefix) + 1, LEN(SaleDetailID) - LEN(@DetailPrefix)) AS INT)), 0)
    FROM SaleDetails
    WHERE SaleDetailID LIKE @DetailPrefix + '%';

    -- SET @CurrentDetailNumericID = @MaxDetailNumericID + 1; -- ��� ����� ��������� ������� ������
    PRINT '������������ �������� ID ����� �������: ' + CAST(@MaxDetailNumericID AS VARCHAR);

    -- ���������� ��������� �������, ��������� SaleDetailID
    -- �����������: ������ ROW_NUMBER() ������������� �� @MaxDetailNumericID
    INSERT INTO #TempSaleDetailsWithID (SaleDetailID, SaleID, ProductID, Quantity, UnitPrice)
    SELECT
        @DetailPrefix + FORMAT(@MaxDetailNumericID + ROW_NUMBER() OVER (ORDER BY ProductID), REPLICATE('0', @DetailNumericLength)),
        @NewSaleID, -- ����'����� �� ����� �� ������ �������
        d.ProductID,
        d.Quantity,
        d.UnitPrice
    FROM @SaleDetails AS d;

    -- �������� �������� EmployeeID �� CustomerID (���������)
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
    BEGIN
        PRINT '�������, ��������� � ID: ' + @EmployeeID + ' �� ����';
        THROW 51002, '��������� � �������� ID �� ����.', 1;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
    BEGIN
        PRINT '�������, �������� � ID: ' + @CustomerID + ' �� ����';
        THROW 51003, '�������� � �������� ID �� ����.', 1;
        RETURN;
    END

    BEGIN TRANSACTION; -- �������� ����������
    PRINT '���������� ���������';

    BEGIN TRY
        -- ������ �������� ����� ��� ������
        PRINT '��������� ��������� ������ ��� ������';
        -- ������������� GETDATE() ��� SaleDate, ���� @SaleDate �� ������ (���� � ������� ���� NULL, ��� ���� ���� ������ ����)
        INSERT INTO Sale (SaleID, EmployeeID, CustomerID, SaleDate, SaleGrandTotal, PaymentMethod)
        VALUES (@NewSaleID, @EmployeeID, @CustomerID, ISNULL(@SaleDate, GETDATE()), 0, @PaymentMethod); -- SaleGrandTotal ��������� 0

        -- ������ ����� �������. ��� INSERT ���� ����������� �������� trg_SaleDetails_StockCheck_Insert.
        -- ���� ������ ������� ������� (���������, ����������� ������), ���������� ���� ��������.
        PRINT '��������� ������� �������';
        INSERT INTO SaleDetails (SaleDetailID, SaleID, ProductID, Quantity, UnitPrice)
        SELECT SaleDetailID, SaleID, ProductID, Quantity, UnitPrice
        FROM #TempSaleDetailsWithID;

        -- ����������� �������� ���� ������� ���� ������ ������� ������� (����� ������)
        PRINT '���������� �������� ���� �������';
        SELECT @SaleGrandTotal = SUM(Quantity * UnitPrice)
        FROM SaleDetails
        WHERE SaleID = @NewSaleID;

        -- ��������� �������� ���� � ��������� ����� �������
        UPDATE Sale
        SET SaleGrandTotal = @SaleGrandTotal
        WHERE SaleID = @NewSaleID;
        PRINT '��������� �������� ���� �������';

        COMMIT TRANSACTION; -- Գ����� ����������, ���� ��� ������� ������
        PRINT '���������� �����������';

        -- ��������� ID ������ ������� �� �������� ����
        SELECT @NewSaleID AS NewSaleID, @SaleGrandTotal AS SaleGrandTotal;

    END TRY
    BEGIN CATCH
        -- ���� ������� ����-��� ������� (��������� ������� �� �������)
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION; -- ³������� ����������
        PRINT '���������� �������� ����� �������. ����������� ��� �������: ' + ERROR_MESSAGE();
        -- ���������� ������� ���
        THROW;
    END CATCH

    -- ����������, �� ���� ��������� ������� ����� ����������
    IF OBJECT_ID('tempdb..#TempSaleDetailsWithID') IS NOT NULL
        DROP TABLE #TempSaleDetailsWithID; -- ��������� ��������� �������
    PRINT '��������� ������� �������� (���� ��������)';

    SET NOCOUNT OFF;
END
/*
-- ��������� ������������ ���������:

-- ����������, � ��� � CustomerID = 'CUST000005', EmployeeID = 'EMP0000003'
-- �� ProductID = 'PROD001' (������� Acer), 'PROD002' (����� TP-Link)

-- ��������� ����� ���� ������� ��� ������� �������
GO
DECLARE @Details AS UDTT_SaleDetailsType;

-- ������ ������� �� ����
INSERT INTO @Details (ProductID, Quantity, UnitPrice) VALUES
('PROD001', 1, 25000.00), -- 1 �������
('PROD002', 2, 500.00);   -- 2 ������ (���� �� �������)

-- ��������� ��������� ��������� �������
EXEC CreateSale
    @EmployeeID = 'EMP0000003', -- ����������, ����� ��������� ����
    @CustomerID = 'CUST000005', -- ����������, ����� �������� ����
    @PaymentMethod = '�����',
    @SaleDetails = @Details;
*/

/* ****************************************************************** */
/* ===== ��������� 7: ��������� ������ ���������� ������������� ===== */
/* ****************************************************************** */

GO
-- ��������� ���������, ���� ���� ��� ����
IF OBJECT_ID('CreateSupplierOrder', 'P') IS NOT NULL
    DROP PROCEDURE CreateSupplierOrder;
GO

-- ��������� ��� ��������� ������ ���������� �������������
CREATE PROCEDURE CreateSupplierOrder
    @SupplierID CHAR(10),
    @OrderDate DATETIME = NULL,� -- �������� �� ������������� (������� ����/���)
    @OrderDetails UDTT_OrderDetailsType READONLY -- �������� ���� ������� ��� ������� ����������

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewOrderID CHAR(10);
    DECLARE @OrderGrandTotal DECIMAL(10,2);
    DECLARE @MaxNumericID INT;
    DECLARE @NextNumericID INT;
    DECLARE @Prefix CHAR(4) = 'ORDR'; -- ������� ��� ID ���������� �������������
    DECLARE @NumericLength INT = 6;� -- ʳ������ ���� � ������� ������� ID (10 - 4 = 6)

    -- ��������, �� � ����� � ����������
    IF (SELECT COUNT(*) FROM @OrderDetails) = 0
    BEGIN
        PRINT '�������: ���������� ������������� �� ������ ������� ������.';
        THROW 51004, '���������� ������������� �� ������ ������� ������.', 1;
        RETURN;
    END


    -- �������� ����� ���������� OrderID
    PRINT '��������� ������ ID ���������� �������������';
    SELECT @MaxNumericID = ISNULL(MAX(CAST(SUBSTRING(OrderID, LEN(@Prefix) + 1, LEN(OrderID) - LEN(@Prefix)) AS INT)), 0)
    FROM SupplierOrder
    WHERE OrderID LIKE @Prefix + '%';

    SET @NextNumericID = @MaxNumericID + 1;
    SET @NewOrderID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
    PRINT '����� ID ����������: ' + @NewOrderID;

    -- ����������, �� ������������ ID ��� ���� (��������� ��������)
    WHILE EXISTS (SELECT 1 FROM SupplierOrder WHERE OrderID = @NewOrderID)
    BEGIN
        SET @NextNumericID = @NextNumericID + 1;
        SET @NewOrderID = @Prefix + FORMAT(@NextNumericID, REPLICATE('0', @NumericLength));
        PRINT '����� ������������ ID ���������� (����� �������� ���������): ' + @NewOrderID;
    END

    -- �������� ��������� OrderDetailID ��� ������� ����� � @OrderDetails
    PRINT '��������� OrderDetailID ��� ������� ����������';
    CREATE TABLE #TempOrderDetailsWithID (
        OrderDetailID CHAR(10),
        OrderID CHAR(10),
        ProductID CHAR(10),
        OrderQuantity INT,
        UnitPrice DECIMAL(10,2)
    );

    DECLARE @DetailPrefix CHAR(4) = 'ORDT'; -- ������� ��� ID ����� ����������
    DECLARE @DetailNumericLength INT = 6;
    DECLARE @MaxDetailNumericID INT;

    -- ��������� ������������ �������� �������� ID ��� OrderDetail
    SELECT @MaxDetailNumericID = ISNULL(MAX(CAST(SUBSTRING(OrderDetailID, LEN(@DetailPrefix) + 1, LEN(OrderDetailID) - LEN(@DetailPrefix)) AS INT)), 0)
    FROM OrderDetails
    WHERE OrderDetailID LIKE @DetailPrefix + '%';

    -- ���������� ��������� �������, ��������� OrderDetailID
    -- ������ ROW_NUMBER() �� @MaxDetailNumericID ��� ����������� � ������ ������� �������
    INSERT INTO #TempOrderDetailsWithID (OrderDetailID, OrderID, ProductID, OrderQuantity, UnitPrice)
    SELECT
        @DetailPrefix + FORMAT(@MaxDetailNumericID + ROW_NUMBER() OVER (ORDER BY ProductID), REPLICATE('0', @DetailNumericLength)),
        @NewOrderID, -- ����'����� �� ����� �� ������ ����������
        d.ProductID,
        d.OrderQuantity,
        d.UnitPrice
    FROM @OrderDetails AS d;

    -- �������� �������� SupplierID (���������)
    IF NOT EXISTS (SELECT 1 FROM Supplier WHERE SupplierID = @SupplierID)
    BEGIN
        PRINT '�������, ������������ � ID: ' + @SupplierID + ' �� ����';
        THROW 51005, '������������ � �������� ID �� ����.', 1;
        RETURN;
    END

    -- �������� �������� ProductID � ������� ������� ����������
    -- ������������� ��������� ������� ��� ��������, ������� ���� ������ �� ProductID ��� ����� ����������
    IF EXISTS (
        SELECT 1
        FROM #TempOrderDetailsWithID AS temp
        LEFT JOIN [Product] AS p ON temp.ProductID = p.ProductID
        WHERE p.ProductID IS NULL
    )
    BEGIN
        -- ����� ��������, �� ���� ProductID �� �������
        DECLARE @InvalidProductIDs NVARCHAR(MAX);
        SELECT @InvalidProductIDs = STRING_AGG(temp.ProductID, ', ')
        FROM #TempOrderDetailsWithID AS temp
        LEFT JOIN [Product] AS p ON temp.ProductID = p.ProductID
        WHERE p.ProductID IS NULL;

        PRINT '�������: ���� ��� ����� ������ � ���������� �� ������� � �������� ������. �������� ProductID: ' + @InvalidProductIDs;
        THROW 51006, '���� ��� ����� ������ � ���������� �� �������.', 1;
        RETURN;
    END

    -- �������� �� ����������� ������� (>= 1) � ������� ����������
     IF EXISTS (
        SELECT 1
        FROM #TempOrderDetailsWithID AS temp
        WHERE temp.OrderQuantity <= 0 OR temp.OrderQuantity IS NULL
    )
    BEGIN
        PRINT '�������: ʳ������ ������ � ���������� �� ���� ����� ����.';
        THROW 51007, 'ʳ������ ������ � ���������� �� ���� ����� ����.', 1;
        RETURN;
    END


    BEGIN TRANSACTION; -- �������� ����������

    BEGIN TRY
        -- ������ �������� ����� ��� ���������� �������������
        PRINT '��������� ��������� ������ ��� ���������� �������������';
        INSERT INTO SupplierOrder (OrderID, SupplierID, OrderDate, OrderGrandTotal)
        VALUES (@NewOrderID, @SupplierID, ISNULL(@OrderDate, CAST(GETDATE() AS DATE)), 0); -- OrderGrandTotal ��������� 0

        -- ������ ����� ����������. ��� INSERT ������� ������ trg_OrderDetails_StockUpdate_Insert.
        PRINT '��������� ������� ���������� �������������';
        INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, OrderQuantity, UnitPrice)
        SELECT OrderDetailID, OrderID, ProductID, OrderQuantity, UnitPrice
        FROM #TempOrderDetailsWithID;

        -- ����������� �������� ���� ���������� ���� ������ ������� �������
        PRINT '���������� �������� ���� ���������� �������������';
        SELECT @OrderGrandTotal = SUM(CAST(OrderQuantity AS DECIMAL(10,2)) * UnitPrice) -- ������������ ��� �������
        FROM OrderDetails
        WHERE OrderID = @NewOrderID;

        -- ��������� �������� ���� � ��������� ����� ���������� �������������
        UPDATE SupplierOrder
        SET OrderGrandTotal = @OrderGrandTotal
        WHERE OrderID = @NewOrderID;
        PRINT '��������� �������� ���� ���������� �������������';

        COMMIT TRANSACTION; -- Գ����� ����������, ���� ��� ������� ������
        PRINT '���������� �����������';

        -- ��������� ID ������ ���������� �� �������� ����
        SELECT @NewOrderID AS NewOrderID, @OrderGrandTotal AS OrderGrandTotal;

    END TRY
    BEGIN CATCH
        -- ���� ������� ����-��� �������
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION; -- ³������� ����������
        PRINT '���������� �������� ����� �������. ����������� ��� �������: ' + ERROR_MESSAGE();
        -- ���������� ������� ���
        THROW;
    END CATCH

    -- ����������, �� ���� ��������� ������� ����� ����������
    IF OBJECT_ID('tempdb..#TempOrderDetailsWithID') IS NOT NULL
        DROP TABLE #TempOrderDetailsWithID; -- ��������� ��������� �������
    PRINT '��������� ������� �������� (���� ��������)';

    SET NOCOUNT OFF;
END

/*
-- ��������� ������������ ���������:
-- ��������� ����� ���� ������� ��� ������� ���������� �������������
GO
DECLARE @OrderItems AS UDTT_OrderDetailsType;

-- ������ ������� �� ����������
INSERT INTO @OrderItems (ProductID, OrderQuantity, UnitPrice) VALUES
('PROD002', 200, 480.00), -- ���������� 200 ������ �� 480.00
('PROD005', 100, 950.00); -- ���������� 100 ��������� �� 950.00

EXEC CreateSupplierOrder
    @SupplierID = 'SUPP000003', -- �������������� ��������� ID �������������
    @OrderDetails = @OrderItems;

-- ϳ��� �������� ��������� ������ �� �������� �����
-- ��������� ����� ������ TP-Link ���� ����������
SELECT StockQuantity FROM Product WHERE ProductID = 'PROD002' OR ProductID = 'PROD005'; -- �� ����� �� 100 �����
*/

-- ****************************************************** --
-- ===== ��������� ����������� (Update Procedures) ===== --
-- ****************************************************** --
GO
-- ��������� ����������� �������
IF OBJECT_ID('usp_UpdateCustomer', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateCustomer;
GO
CREATE PROCEDURE usp_UpdateCustomer
    @CustomerID CHAR(10),
    @FullName VARCHAR(255),
    @Phone VARCHAR(20),
    @Email VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Customer
        SET
            FullName = @FullName,
            Phone = @Phone,
            Email = @Email
        WHERE CustomerID = @CustomerID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        -- ���������� ������� ���
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� ����������
IF OBJECT_ID('usp_UpdateEmployee', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateEmployee;
GO
CREATE PROCEDURE usp_UpdateEmployee
    @EmployeeID CHAR(10),
    @FullName VARCHAR(255),
    @Phone VARCHAR(20),
    @Email VARCHAR(255),
    @Position VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Employee
        SET
            FullName = @FullName,
            Phone = @Phone,
            Email = @Email,
            Position = @Position
        WHERE EmployeeID = @EmployeeID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '���������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� �������
IF OBJECT_ID('usp_UpdateCategory', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateCategory;
GO
CREATE PROCEDURE usp_UpdateCategory
    @CategoryID CHAR(10),
    @CategoryName VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Category
        SET
            CategoryName = @CategoryName
        WHERE CategoryID = @CategoryID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '�������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� ������
IF OBJECT_ID('usp_UpdateProduct', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateProduct;
GO
CREATE PROCEDURE usp_UpdateProduct
    @ProductID CHAR(10),
    @CategoryID CHAR(10),
    @ProductName VARCHAR(255),
    @Price DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �������� CategoryID
        IF NOT EXISTS (SELECT 1 FROM Category WHERE CategoryID = @CategoryID)
        BEGIN
            -- ������� 51000: �������� �� ����
            THROW 51000, '�������� � �������� ID �� ����.', 1;
        END

        UPDATE [Product]
        SET
            CategoryID = @CategoryID,
            ProductName = @ProductName,
            Price = @Price
        WHERE ProductID = @ProductID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '����� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� �������������
IF OBJECT_ID('usp_UpdateSupplier', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateSupplier;
GO
CREATE PROCEDURE usp_UpdateSupplier
    @SupplierID CHAR(10),
    @OrganizationName VARCHAR(255),
    @Phone VARCHAR(20),
    @Email VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Supplier
        SET
            OrganizationName = @OrganizationName,
            Phone = @Phone,
            Email = @Email
        WHERE SupplierID = @SupplierID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� ��������� ������ �������
IF OBJECT_ID('usp_UpdateSale', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateSale;
GO
CREATE PROCEDURE usp_UpdateSale
    @SaleID CHAR(10),
    @EmployeeID CHAR(10),
    @CustomerID CHAR(10),
    @SaleDate DATE,
    @PaymentMethod VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �������� EmployeeID
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmployeeID = @EmployeeID)
        BEGIN
            -- ������� 51002: ��������� �� ����
            THROW 51002, '��������� � �������� ID �� ����.', 1;
        END

        -- �������� �������� CustomerID
        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
        BEGIN
            -- ������� 51003: �������� �� ����
            THROW 51003, '�������� � �������� ID �� ����.', 1;
        END

        UPDATE Sale
        SET
            EmployeeID = @EmployeeID,
            CustomerID = @CustomerID,
            SaleDate = @SaleDate,
            PaymentMethod = @PaymentMethod
        WHERE SaleID = @SaleID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������ � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� ����� �������
IF OBJECT_ID('usp_UpdateSaleDetail', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateSaleDetail;
GO
CREATE PROCEDURE usp_UpdateSaleDetail
    @SaleDetailID CHAR(10),
    @Quantity INT,
    @UnitPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ����������� �������
        IF @Quantity <= 0 OR @Quantity IS NULL
        BEGIN
            -- ������� 50005: ʳ������ ������ ����������
            THROW 50005, 'ʳ������ ������ ������� ���� ���������� ������.', 1;
        END

        -- �������� �� �������� ������� �� ����� ����� ����������
        DECLARE @CurrentQuantity INT, @ProductID CHAR(10), @StockQuantity INT;

        SELECT @CurrentQuantity = sd.Quantity,
               @ProductID = sd.ProductID
        FROM SaleDetails sd
        WHERE sd.SaleDetailID = @SaleDetailID;

        IF @ProductID IS NULL
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������ ������� � ����� ID �� ��������.', 1;
        END

        SELECT @StockQuantity = p.StockQuantity
        FROM [Product] p
        WHERE p.ProductID = @ProductID;

        -- ���������� ������������ ������ ���� ������:
        -- �������� ������� �� ����� + (ʳ������ � ����� ������� �� ����) - (ʳ������ � ����� ������� ���� ����)
        -- ���� ��������� ����� 0, �� ������ �����������
        IF (@StockQuantity + @CurrentQuantity - @Quantity) < 0
        BEGIN
            -- ������� 51001: ����������� ������ �� �����
            THROW 51001, '����������� ������ �� ����� ��� ��������� �������.', 1;
        END

        UPDATE SaleDetails
        SET
            Quantity = @Quantity,
            UnitPrice = @UnitPrice
        WHERE SaleDetailID = @SaleDetailID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������ ������� � ����� ID �� ��������.', 1;
        END
        -- �������: AFTER UPDATE ������ 'trg_SaleDetails_StockAndTotal_Update' �����������
        -- ������� StockQuantity �� �������� SaleGrandTotal.

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� ��������� ������ ���������� �������������
IF OBJECT_ID('usp_UpdateSupplierOrder', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateSupplierOrder;
GO
CREATE PROCEDURE usp_UpdateSupplierOrder
    @OrderID CHAR(10),
    @SupplierID CHAR(10),
    @OrderDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �������� SupplierID
        IF NOT EXISTS (SELECT 1 FROM Supplier WHERE SupplierID = @SupplierID)
        BEGIN
            -- ������� 51004: ������������ �� ����
            THROW 51004, '������������ � �������� ID �� ����.', 1;
        END

        UPDATE SupplierOrder
        SET
            SupplierID = @SupplierID,
            OrderDate = @OrderDate
        WHERE OrderID = @OrderID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '���������� ������������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ����������� ����� ���������� �������������
IF OBJECT_ID('usp_UpdateOrderDetail', 'P') IS NOT NULL
    DROP PROCEDURE usp_UpdateOrderDetail;
GO
CREATE PROCEDURE usp_UpdateOrderDetail
    @OrderDetailID CHAR(10),
    @OrderQuantity INT,
    @UnitPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ����������� �������
        IF @OrderQuantity <= 0 OR @OrderQuantity IS NULL
        BEGIN
            -- ������� 50005: ʳ������ ������ ����������
            THROW 50005, 'ʳ������ ����������� ������ ������� ���� ���������� ������.', 1;
        END

        UPDATE OrderDetails
        SET
            OrderQuantity = @OrderQuantity,
            UnitPrice = @UnitPrice
        WHERE OrderDetailID = @OrderDetailID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������ ���������� � ����� ID �� ��������.', 1;
        END
        -- �������: AFTER UPDATE ������ 'trg_OrderDetails_StockAndTotal_Update' �����������
        -- ������� StockQuantity �� �������� OrderGrandTotal.
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ****************************************************** --
-- ===== ��������� ��������� (Delete Procedures) ===== --
-- ****************************************************** --

-- ��������� ��������� �������
IF OBJECT_ID('usp_DeleteCustomer', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteCustomer;
GO
CREATE PROCEDURE usp_DeleteCustomer
    @CustomerID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ��������� ���'������ �������
        IF EXISTS (SELECT 1 FROM Sale WHERE CustomerID = @CustomerID)
        BEGIN
            -- ������� 50002: ���'����� ������ �������
            THROW 50002, '��������� �������� �������, ������� ������� ���''����� ������.', 1;
        END

        DELETE FROM Customer
        WHERE CustomerID = @CustomerID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� ����������
IF OBJECT_ID('usp_DeleteEmployee', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteEmployee;
GO
CREATE PROCEDURE usp_DeleteEmployee
    @EmployeeID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ��������� ���'������ �������
        IF EXISTS (SELECT 1 FROM Sale WHERE EmployeeID = @EmployeeID)
        BEGIN
            -- ������� 50002: ���'����� ������ �������
            THROW 50002, '��������� �������� ����������, ������� ������� ���''����� ������.', 1;
        END

        DELETE FROM Employee
        WHERE EmployeeID = @EmployeeID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '���������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� �������
IF OBJECT_ID('usp_DeleteCategory', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteCategory;
GO
CREATE PROCEDURE usp_DeleteCategory
    @CategoryID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ��������� ���'������ ������
        IF EXISTS (SELECT 1 FROM [Product] WHERE CategoryID = @CategoryID)
        BEGIN
            -- ������� 50002: ���'����� ������ �������
            THROW 50002, '��������� �������� ��������, ������� ������� ���''����� ������.', 1;
        END

        DELETE FROM Category
        WHERE CategoryID = @CategoryID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '�������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� ������
IF OBJECT_ID('usp_DeleteProduct', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteProduct;
GO
CREATE PROCEDURE usp_DeleteProduct
    @ProductID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ��������� � ������� �������
        IF EXISTS (SELECT 1 FROM SaleDetails WHERE ProductID = @ProductID)
        BEGIN
            -- ������� 50002: ���'����� ������ �������
            THROW 50002, '��������� �������� �����, ������� �� ��������� � ��������.', 1;
        END

        -- �������� �� ��������� � ������� ��������� �������������
        IF EXISTS (SELECT 1 FROM OrderDetails WHERE ProductID = @ProductID)
        BEGIN
            -- ������� 50002: ���'����� ������ �������
            THROW 50002, '��������� �������� �����, ������� �� ��������� � ����������� �������������.', 1;
        END

        DELETE FROM [Product]
        WHERE ProductID = @ProductID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '����� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� �������������
IF OBJECT_ID('usp_DeleteSupplier', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteSupplier;
GO
CREATE PROCEDURE usp_DeleteSupplier
    @SupplierID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- �������� �� ��������� ���'������ ���������
        IF EXISTS (SELECT 1 FROM SupplierOrder WHERE SupplierID = @SupplierID)
        BEGIN
            -- ������� 50002: ���'����� ������ �������
            THROW 50002, '��������� �������� �������������, ������� ������� ���''����� ����������.', 1;
        END

        DELETE FROM Supplier
        WHERE SupplierID = @SupplierID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������������� � ����� ID �� ��������.', 1;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� �������
IF OBJECT_ID('usp_DeleteSale', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteSale;
GO
CREATE PROCEDURE usp_DeleteSale
    @SaleID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ��� ������� � ����������, ��� ���������� ����������

    BEGIN TRANSACTION;
    BEGIN TRY
        -- �������� ��������� ����� �������. ������ AFTER DELETE �� SaleDetails
        -- ������� ������� ������ �� ����� �� �������� SaleGrandTotal.
        DELETE FROM SaleDetails
        WHERE SaleID = @SaleID;

        -- ���� ��������� �������� ����� �������
        DELETE FROM Sale
        WHERE SaleID = @SaleID;

        -- ����������, �� ����� ��� ������ ��� �������� ���������
        IF @@ROWCOUNT = 0
        BEGIN
            -- ���� ����� ��� ������ �� �������� (� �� �� ��� � 'deleted' ������� � ���������� ��������,
            -- �� ������, �� ���� ������ �� ��������), �� ������ �������.
            IF NOT EXISTS (SELECT 1 FROM Sale WHERE SaleID = @SaleID)
            BEGIN
                THROW 50001, '������ � ����� ID �� ��������.', 1;
            END
        END

        COMMIT TRANSACTION; -- Գ����� ����������, ���� ��� ������� ������
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION; -- ³������� ���������� � ������� �������
        THROW; -- ���������� ������� ���
    END CATCH
END;
GO

-- ��������� ��������� ����� �������
IF OBJECT_ID('usp_DeleteSaleDetail', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteSaleDetail;
GO
CREATE PROCEDURE usp_DeleteSaleDetail
    @SaleDetailID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM SaleDetails
        WHERE SaleDetailID = @SaleDetailID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������ ������� � ����� ID �� ��������.', 1;
        END
        -- �������: AFTER DELETE ������ 'trg_SaleDetails_StockAndTotal_Delete' �����������
        -- ������� StockQuantity �� �������� SaleGrandTotal.
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� ���������� �������������
IF OBJECT_ID('usp_DeleteSupplierOrder', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteSupplierOrder;
GO
CREATE PROCEDURE usp_DeleteSupplierOrder
    @OrderID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- �������� ��������� ����� ����������. ������ AFTER DELETE �� OrderDetails
        -- ������� ������� ������ �� ����� �� �������� OrderGrandTotal.
        DELETE FROM OrderDetails
        WHERE OrderID = @OrderID;

        -- ���� ��������� �������� ����� ����������
        DELETE FROM SupplierOrder
        WHERE OrderID = @OrderID;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM SupplierOrder WHERE OrderID = @OrderID)
            BEGIN
                THROW 50001, '���������� ������������� � ����� ID �� ��������.', 1;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ��������� ��������� ����� ���������� �������������
IF OBJECT_ID('usp_DeleteOrderDetail', 'P') IS NOT NULL
    DROP PROCEDURE usp_DeleteOrderDetail;
GO
CREATE PROCEDURE usp_DeleteOrderDetail
    @OrderDetailID CHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM OrderDetails
        WHERE OrderDetailID = @OrderDetailID;

        IF @@ROWCOUNT = 0
        BEGIN
            -- ������� 50001: ����� � ����� ID �� ��������
            THROW 50001, '������ ���������� ������������� � ����� ID �� ��������.', 1;
        END
        -- �������: AFTER DELETE ������ 'trg_OrderDetails_StockAndTotal_Delete' �����������
        -- ������� StockQuantity �� �������� OrderGrandTotal.
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO