-----------------------------------------------------------------
-- 1. Compare changes on the execution plan and logical reads when
--    querying partitioned tables and non-partitioned tables
-----------------------------------------------------------------
--NOTE: For each scenario, execute both query together to easily compare 
--      results in the non-partitioned table vs the partitioned table

USE [WideWorldImporters]
GO

-- Include Actual Execution Plan (Ctrl-M)

set statistics io on

-- Let's Search in both tables by the partition column for Sales.P_Orders
select * from [Sales].[Orders]
where OrderDate = '2013-07-04'

select * from [Sales].[P_Orders]
where OrderDate = '2013-07-04'

-- You read less pages using the partitioned table
-- even when both queries scan the clustered index, Why?

-- Review the Cluster Index Scan Operator and the Actual Partition Count information

-- Let's Search in both tables by an indexed column other that the partition column for Sales.P_Orders
select * from [Sales].[Orders]
where OrderId = 73548

select * from [Sales].[P_Orders]
where OrderId = 73548

-- You read mores pages using the partitioned table
-- even when both queries use a Clustered Index Seek, Why?

-- Let's add the partition column in the WHERE clause to the previous query
select * from [Sales].[Orders]
where OrderId = 73548
and OrderDate = '2016-05-31'

select * from [Sales].[P_Orders]
where OrderId = 73548
and OrderDate = '2016-05-31'

--What changed?

-- Let’s see the behavior of the TOP, MIN y MAX functions

-- top
select top 1 * from [Sales].[Orders]
where OrderId = 73548
order by OrderId

select top 1 * from [Sales].[P_Orders]
where OrderId = 73548
order by OrderId

-- The query reads more pages using the partitioned table	
-- even when both queries look using the first column of the clustered index, Why?

-- MAX
select max(OrderId) from [Sales].[Orders]

select max(OrderId) from [Sales].[P_Orders]

-- The query reads more pages using the partitioned table
-- even when both queries are looking using the first column of the clustered index, Why?


-- MIN
select min(OrderId) from [Sales].[Orders]

select min(OrderId) from [Sales].[P_Orders]

--  The query reads more pages using the partitioned table
-- even when both are looking using the first column of the clustered index, Why?

