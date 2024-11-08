USE [WideWorldImporters]
go


-- Let's see the locks held when doing a Select operation
Set Transaction Isolation Level Repeatable Read

BEGIN TRANSACTION

	SELECT * FROM  [Sales].[P_Orders]
	WHERE OrderDate = '2016-04-14' 

	Select * from sys.dm_tran_locks 
	where request_session_id = @@SPID 
	order by resource_type

	-- How many locks do you see? 
	-- Why do you see PAGE KEY, PAGE, OBJECT and DATABASE locks 

ROLLBACK

-- Let's read more than 5000 rows

BEGIN TRANSACTION

	SELECT * FROM  [Sales].[P_Orders]
	WHERE OrderDate > '2016-02-14' 

	Select * from sys.dm_tran_locks 
	where request_session_id = @@SPID 
	order by resource_type

-- Even when there more than 5000 locks, 
-- there are not 5000 locks on a single partition, 
-- so there is no lock scalation to table

ROLLBACK


-- Lets load around 50000 rows on a sigle partition

DECLARE @rows_in_partition int = 1

SELECT @rows_in_partition = COUNT(*) FROM [Sales].[P_Orders]
WHERE OrderDate>='2015-07-01' AND OrderDate < '2015-08-01'

while  @rows_in_partition < 50000
BEGIN

	INSERT INTO [Sales].[P_Orders]
	SELECT O.[OrderID] + 100000 + @rows_in_partition
      ,O.[CustomerID]
      ,O.[SalespersonPersonID]
      ,O.[PickedByPersonID]
      ,O.[ContactPersonID]
      ,NULL --[BackorderOrderID]
      ,NULL --[BackorderOrderDate]
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
  WHERE OrderDate>='2015-07-01' AND OrderDate < '2015-08-01'
  Order by OrderID DESC

  SELECT @rows_in_partition = COUNT(*) FROM [Sales].[P_Orders]
  WHERE OrderDate>='2015-07-01' AND OrderDate < '2015-08-01'

END
 
-- Let's read more than 5000 locks from a single partition

BEGIN TRANSACTION

	select * FROM  [Sales].[P_Orders]
	WHERE OrderDate >= '2015-07-03'  and OrderDate < '2015-07-15' 

	Select * from sys.dm_tran_locks 
	where request_session_id = @@SPID 
	order by resource_type

	-- Notice that olny have 2 locks now.
	-- the lock with resource_type = OBJECT is the lock a the table level

	-- In another session execute the following two sentences
	select * FROM  [Sales].[P_Orders]
	WHERE OrderId  = 100

	delete FROM  [Sales].[P_Orders]
	WHERE OrderId  = 100

	-- Notice that the query gets blocked even when the row you
	-- are trying to delete is in other partition, Why?		
	-- Stop the query on the second session and close it

ROLLBACK


-- Let´s change the scalation mode for the table to AUTO
ALTER TABLE [Sales].[P_Orders]SET (LOCK_ESCALATION = AUTO);  
GO  

-- Let´s execute the same query and see how the behavior changes
BEGIN TRANSACTION

	select * FROM  [Sales].[P_Orders]
	WHERE OrderDate >= '2015-07-03'  and OrderDate < '2015-07-15' 

	Select * from sys.dm_tran_locks 
	where request_session_id = @@SPID 
	order by resource_type

	-- Notice that now you have 3 locks.
	-- the lock with resource_type = HOBT is the lock a the partition level
	
	-- In another session execute the following two sentences
	select * FROM  [Sales].[P_Orders]
	WHERE OrderId  = 101

	delete FROM  [Sales].[P_Orders]
	WHERE OrderId  = 101

	-- Notice that the query gets blocked even when the rou you
	-- are trying to delete is in other partition, Why?		
	-- Stop the query
	
	-- On the second session, execute the following query 
	-- to try to delete the record making a small change to the query 

	delete FROM  [Sales].[P_Orders]
	WHERE OrderId  = 101
	and OrderDate = '2013-01-02'

	-- Notice that now you can delete the row, Why?

ROLLBACK