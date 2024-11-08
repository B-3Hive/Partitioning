USE [WideWorldImporters]
go
-- IMPORTANT ------
-- Let’s suppose that your application only allows you to list the 
-- orders for a customer for the last sixty days
-- so, it does not make sense to index that all table by customerId

-- NOTE: We use a fixed date and not getdate() because
--       the table only contains records up to 2016-06-01

-- Include Actual Execution Plan (Ctrl-M)

set statistics io on

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'

-- This query uses an Index Seek operator, a reduced number of logical reads
-- and due to partition elimination, it is quite efficient
-- However:
-- Look at the Actual Number of Rows and the Estimated Number of Rows
-- See how much space the index uses with the following script

SELECT i.[name] AS IndexName ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    AND s.[index_id] = i.[index_id]
AND i.object_id = object_id('Sales.P_Orders')
WHERE i.name = 'FK_Sales_P_Orders_CustomerID'
GROUP BY i.[name]
GO

-- This index covers all data in the table but we
-- only search rows for the last sixty days 

-- How to improve it? Lets delete the original index
-- and create three indexes, covering the last three months

DROP INDEX [FK_Sales_P_Orders_CustomerID] ON [Sales].[P_Orders]
GO

CREATE NONCLUSTERED INDEX [FI_Sales_P_Orders_CustomerID_2016_05] ON [Sales].[P_Orders]
(	[CustomerID] ASC	)
WHERE OrderDate >= '2016-05-01' and OrderDate < '2016-06-01'
ON [PS_SalesOrder_MONTHLY](OrderDate)
GO

CREATE NONCLUSTERED INDEX [FI_Sales_P_Orders_CustomerID_2016_04] ON [Sales].[P_Orders]
(	[CustomerID] ASC	)
WHERE OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'
ON [PS_SalesOrder_MONTHLY](OrderDate)
GO

CREATE NONCLUSTERED INDEX [FI_Sales_P_Orders_CustomerID_2016_03] ON [Sales].[P_Orders]
(	[CustomerID] ASC	)
WHERE OrderDate >= '2016-03-01' and OrderDate < '2016-04-01'
ON [PS_SalesOrder_MONTHLY](OrderDate)
GO

-- Let´s run the same query again

DBCC FREEPROCCACHE

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'

-- Look at the Actual Number of Rows and the Estimated Number of Rows.  
-- Do SQL Server can make better estimations?
-- Does the query do less logical read?
-- See how much space the index uses with the following script

SELECT i.[name] AS IndexName ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    AND s.[index_id] = i.[index_id]
AND i.object_id = object_id('Sales.P_Orders')
WHERE i.name like 'FI_Sales_P_Orders_CustomerID%'
GROUP BY i.[name]
GO

-- Let's do the same search but using variables

DBCC FREEPROCCACHE

declare @fecha_inicial date = '2016-04-01'
declare @fecha_final date = '2016-05-01'

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= @fecha_inicial and OrderDate < @fecha_final

-- Notice that the estimation is not that good 
-- and the filtered index is not used. why?

-- Let's use the option RECOMPILE

declare @fecha_inicial date = '2016-04-01'
declare @fecha_final date = '2016-05-01'

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= @fecha_inicial and OrderDate < @fecha_final
OPTION (RECOMPILE)

-- The query uses the filtered index only when you use RECOMPILE, Why?

-- Let's expand the range of search

DBCC FREEPROCCACHE

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-06-01'

-- Notice that you do not use filtered indexes and SQL scans the table.
-- even when the three indexes (combined) cover the range
-- Why?

-- Is there anything you can do to improve performance 
-- using filtered indexes in this scenario? Think of maintenance effors

-- Just to leave the database as it as originally 
-- execute the following commands

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_CustomerID] ON [Sales].[P_Orders]
(
	[CustomerID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)


DROP INDEX [FI_Sales_P_Orders_CustomerID_2016_03] ON [Sales].[P_Orders]
GO
DROP INDEX [FI_Sales_P_Orders_CustomerID_2016_04] ON [Sales].[P_Orders]
GO
DROP INDEX [FI_Sales_P_Orders_CustomerID_2016_05] ON [Sales].[P_Orders]
GO



