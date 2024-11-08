USE [WideWorldImporters]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-----------------------------------------------------------------
-- 1. Create the partitioned table
-----------------------------------------------------------------

CREATE TABLE [Sales].[P_Orders](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL -- this column does not exists in the original table. It is created for demonstration purposes

 CONSTRAINT [PK_Sales_P_Orders] PRIMARY KEY CLUSTERED 
 (	[OrderID] ASC  )
ON [PS_SalesOrder_MONTHLY](OrderDate)
)
GO

-- You get an error. Why?
-- NOTE: Consider that this table has a self reference
-- What is the impact of this limitation?
-- What can I do to force uniqueness of OrderID?


CREATE TABLE [Sales].[P_Orders](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[BackorderOrderDate] [date] NULL, -- This new column is necessary because the PK changed
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL -- this column does not exists in the original table. It is create for demostration pourposes
 CONSTRAINT [PK_Sales_P_Orders] PRIMARY KEY CLUSTERED 
(	[OrderID] ASC,
	[OrderDate]
)
ON [PS_SalesOrder_MONTHLY](OrderDate)
)
GO

-----------------------------------------------------------------
-- 2. Create constraints CHECK, DEFAULT and FKs
-----------------------------------------------------------------

--This FK changes its definition because the PK changed, and it is a self-reference

ALTER TABLE [Sales].[P_Orders]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_BackorderOrderID_Sales_P_Orders] FOREIGN KEY([BackorderOrderID],[BackorderOrderDate])
REFERENCES [Sales].[P_Orders] ([OrderID],[OrderDate])
GO
ALTER TABLE [Sales].[P_Orders] CHECK CONSTRAINT [FK_Sales_P_Orders_BackorderOrderID_Sales_P_Orders]
GO

-- No other modification is necessary on constraints

ALTER TABLE [Sales].[P_Orders] ADD  CONSTRAINT [DF_Sales_P_Orders_OrderID]  DEFAULT (NEXT VALUE FOR [Sequences].[OrderID]) FOR [OrderID]
GO

ALTER TABLE [Sales].[P_Orders] ADD  CONSTRAINT [DF_Sales_P_Orders_LastEditedWhen]  DEFAULT (sysdatetime()) FOR [LastEditedWhen]
GO

ALTER TABLE [Sales].[P_Orders]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_Application_People] FOREIGN KEY([LastEditedBy])
REFERENCES [Application].[People] ([PersonID])
GO
ALTER TABLE [Sales].[P_Orders] CHECK CONSTRAINT [FK_Sales_P_Orders_Application_People]
GO

ALTER TABLE [Sales].[P_Orders]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_ContactPersonID_Application_People] FOREIGN KEY([ContactPersonID])
REFERENCES [Application].[People] ([PersonID])
GO
ALTER TABLE [Sales].[P_Orders] CHECK CONSTRAINT [FK_Sales_P_Orders_ContactPersonID_Application_People]
GO

ALTER TABLE [Sales].[P_Orders]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_CustomerID_Sales_Customers] FOREIGN KEY([CustomerID])
REFERENCES [Sales].[Customers] ([CustomerID])
GO
ALTER TABLE [Sales].[P_Orders] CHECK CONSTRAINT [FK_Sales_P_Orders_CustomerID_Sales_Customers]
GO

ALTER TABLE [Sales].[P_Orders]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_PickedByPersonID_Application_People] FOREIGN KEY([PickedByPersonID])
REFERENCES [Application].[People] ([PersonID])
GO
ALTER TABLE [Sales].[P_Orders] CHECK CONSTRAINT [FK_Sales_P_Orders_PickedByPersonID_Application_People]
GO

ALTER TABLE [Sales].[P_Orders]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_SalespersonPersonID_Application_People] FOREIGN KEY([SalespersonPersonID])
REFERENCES [Application].[People] ([PersonID])
GO
ALTER TABLE [Sales].[P_Orders] CHECK CONSTRAINT [FK_Sales_P_Orders_SalespersonPersonID_Application_People]
GO

-- To see details about the partitions on the table 
-- execute Query 1 on "1-A partition_info.sql"
-- Discuss what you see with participants


-----------------------------------------------------------------
-- 3. Create aligned indexes 
-----------------------------------------------------------------

-- NOTE: Create indexes one by one to discuss restrictions 

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_ContactPersonID] ON [Sales].[P_Orders]
(
	[ContactPersonID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_CustomerID] ON [Sales].[P_Orders]
(
	[CustomerID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_PickedByPersonID] ON [Sales].[P_Orders]
(
	[PickedByPersonID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_SalespersonPersonID] ON [Sales].[P_Orders]
(
	[SalespersonPersonID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)


-- To see details about the partitions on the table and indexes 
-- execute Query 2 on "1-A partition_info.sql"
-- Discuss what you see with participants


-- The following index does not exists in the original table 
-- but is created to show a concept
CREATE UNIQUE NONCLUSTERED INDEX [AK_Sales_P_Order_rowguid] ON [Sales].[P_Orders]
(
	[rowguid] ASC
)ON [PS_SalesOrder_MONTHLY](OrderDate)
GO

--- You get an error. Why?

CREATE UNIQUE NONCLUSTERED INDEX [AK_Sales_P_Order_rowguid] ON [Sales].[P_Orders]
(
	[rowguid] ASC,
	[OrderDate]
)ON [PS_SalesOrder_MONTHLY](OrderDate)
GO

-- What problems in data integrity can this create?
-- Does it make sense to create this UNIQUE index?
-- What can I do to force data uniqueness?

