USE [WideWorldImporters]
go

-- NOTE: Enable the trace flag based on your SQL Server version

--DBCC TRACEON(2363,3604,-1) -- For SQL Server 2014+
--DBCC TRACEON(9204,3604,-1) -- For SQL Server 2012

-- Lets supose that your application only allows you to list the 
-- of orders for a customer for the last sixty days

-- NOTE: We use a fixed date and not getdate() because
--       the table conly contains records up to 2016-06-01


-- Include Actual Execution Plan (Ctrl-M)

set statistics io on

DBCC FREEPROCCACHE

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'

-- This query uses an Index Seek operator, a reduced number of logical reads
-- and due to partition elimination, it is quite efficient
-- However:
-- Look at the Actual Number of Rows and the Estimated Number of Rows

-- You can check the Message tab to see which histograms were loaded 
-- and use the following query to see existing statitics on the table
select * from sys.stats
where object_id = object_id ('[Sales].[P_Orders]')

-- To get better estimations, lets create filtered statistics 
-- for the last three months (3 partitions)

CREATE STATISTICS [STAT_Sales_P_Order_CustomerID_2016_05] ON [Sales].[P_Orders] 
([CustomerID] )  
WHERE ( OrderDate >= '2016-05-01' and OrderDate < '2016-06-01' )
WITH FULLSCAN

CREATE STATISTICS [STAT_Sales_P_Order_CustomerID_2016_04] ON [Sales].[P_Orders] 
([CustomerID] )  
WHERE ( OrderDate >= '2016-04-01' and OrderDate < '2016-05-01' )
WITH FULLSCAN

CREATE STATISTICS [STAT_Sales_P_Order_CustomerID_2016_03] ON [Sales].[P_Orders] 
([CustomerID] )  
WHERE ( OrderDate >= '2016-03-01' and OrderDate < '2016-04-01' )
WITH FULLSCAN

-- Let´s run the same query again

DBCC FREEPROCCACHE

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'

-- Look at the Actual Number of Rows and the Estimated Number of Rows.  
-- Can SQL Server make better estimations?

-- You can check the Message tab to see which histograms were loaded 
-- Notice that the filtered statistic for April 2016 was loaded

select * from sys.stats
where object_id = object_id ('[Sales].[P_Orders]')

-- Lets execute the original query but using variables


DBCC FREEPROCCACHE

declare @fecha_inicial date = '2016-04-01'
declare @fecha_final date = '2016-05-01'

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= @fecha_inicial and OrderDate < @fecha_final
GO
-- Notice that the estimation is not that good.
-- You can check the Message tab to see which histograms were loaded 
-- No statistic was loaded (or maybe a system generated statistic)
-- Why?

-- Lets use the option RECOMPILE

DBCC FREEPROCCACHE

declare @fecha_inicial date = '2016-04-01'
declare @fecha_final date = '2016-05-01'

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= @fecha_inicial and OrderDate < @fecha_final
option (recompile)

-- You get better estimations, Why?
-- Notice that the filtered statistic for April 2016 was loaded

select * from sys.stats
where object_id = object_id ('[Sales].[P_Orders]')

-- Lets expand the range of search

DBCC FREEPROCCACHE

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-06-01'

-- Notice that the estimation is not that good.
-- You can check the Message tab to see which histograms were loaded 
-- The filtered statistics were not loaded even when the three
-- statistics (combined) cover the range
-- Why?

-- To get better estimations, lets create filtered statistics 
-- for the last Quarter

CREATE STATISTICS [STAT_Sales_P_Order_CustomerId2016_Q2] ON [Sales].[P_Orders] 
([CustomerID] )  
WHERE ( OrderDate >= '2016-04-01' and OrderDate < '2016-07-01' )
WITH FULLSCAN


DBCC FREEPROCCACHE

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-06-01'

-- Notice that you have better estimations
-- check the message tab and confirm you are now using
-- the filterd statistic for the quarter

select * from sys.stats
where object_id = object_id ('[Sales].[P_Orders]')