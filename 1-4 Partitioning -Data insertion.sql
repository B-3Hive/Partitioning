USE [WideWorldImporters]
GO

-----------------------------------------------------------------
-- 1. Let's see how you can tell in which partition a row will fall
-----------------------------------------------------------------

-- In which partition will the following row be inserted on Sales.P_Orders?
select top 1 * 
from sales.Orders
where OrderDate = '2013-04-02'

select top 1 $partition.[PF_SalesOrder_MONTHLY](OrderDate) as partition, * 
from sales.Orders
where OrderDate = '2013-04-02'

-- You can see that a row for a different month falls in another partition 

select top 1 $partition.[PF_SalesOrder_MONTHLY](OrderDate) as partition, * 
from sales.Orders
where OrderDate = '2014-11-07'


-----------------------------------------------------------------
-- 2. Let's load data from the original table Sales.Orders
-----------------------------------------------------------------

-- NOTE: The SELECT statement is not as simple as SELECT * FROM TABLE
--       because you there is a self-reference and the PK changed

--truncate table [Sales].[P_Orders]

INSERT INTO [Sales].[P_Orders]
           ([OrderID]
           ,[CustomerID]
           ,[SalespersonPersonID]
           ,[PickedByPersonID]
           ,[ContactPersonID]
           ,[BackorderOrderID]
           ,[BackorderOrderDate]
           ,[OrderDate]
           ,[ExpectedDeliveryDate]
           ,[CustomerPurchaseOrderNumber]
           ,[IsUndersupplyBackordered]
           ,[Comments]
           ,[DeliveryInstructions]
           ,[InternalComments]
           ,[PickingCompletedWhen]
           ,[LastEditedBy]
           ,[LastEditedWhen]
           ,[rowguid])
SELECT O.[OrderID]
      ,O.[CustomerID]
      ,O.[SalespersonPersonID]
      ,O.[PickedByPersonID]
      ,O.[ContactPersonID]
      ,O.[BackorderOrderID]
      ,BO.[OrderDate]
      ,O.[OrderDate]
      ,O.[ExpectedDeliveryDate]
      ,O.[CustomerPurchaseOrderNumber]
      ,O.[IsUndersupplyBackordered]
      ,O.[Comments]
      ,O.[DeliveryInstructions]
      ,O.[InternalComments]
      ,O.[PickingCompletedWhen]
      ,O.[LastEditedBy]
      ,O.[LastEditedWhen]
	  ,NEWID()
  FROM [Sales].[Orders] O
  LEFT JOIN [Sales].[Orders] BO
	ON O.BackorderOrderID = BO.OrderID
  Order by O.OrderId desc
GO

-- To see details about the partitions on the table 
-- execute query 1 on "1-A partition_info.sql"
-- Check the column "rows" and compare with the number of rows per month
-- in the original table Sales.Orders
-- Notice that the rows were assigned to the right partition based on the Order Date

select year(OrderDate), month(OrderDate), count(*)  
from sales.Orders
group by year(OrderDate), month(OrderDate)
order by year(OrderDate), month(OrderDate)