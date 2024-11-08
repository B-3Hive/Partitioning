-- IMPORTANT: This Demo is much simplier that the one for On Premise
--           The only reason is that everything works almost exactly the same
--           with two exception: 
--				* You can not create FILEGROUPS or datafiles in Azure 
--				   SQL Database so all the partition must go to PRIMARY
--				* sp_estimate_data_compression_savings  is not supported

-----------------------------------------------------------------
-- 1. Create the partition function for Sales.Orders just for existing months
-----------------------------------------------------------------

CREATE PARTITION FUNCTION [PF_SalesOrder_MONTHLY](date) 
AS RANGE RIGHT 
FOR VALUES ( N'2013-01-01'
			,N'2013-02-01'
			,N'2013-03-01'
			,N'2013-04-01'
			,N'2013-05-01'
			,N'2013-06-01'
			,N'2013-07-01'
			,N'2013-08-01'
			,N'2013-09-01'
			,N'2013-10-01'
			,N'2013-11-01'
			,N'2013-12-01'
			,N'2014-01-01'
			,N'2014-02-01'
			,N'2014-03-01'
			,N'2014-04-01'
			,N'2014-05-01'
			,N'2014-06-01'
			,N'2014-07-01'
			,N'2014-08-01'
			,N'2014-09-01'
			,N'2014-10-01'
			,N'2014-11-01'
			,N'2014-12-01'
			,N'2015-01-01'
			,N'2015-02-01'
			,N'2015-03-01'
			,N'2015-04-01'
			,N'2015-05-01'
			,N'2015-06-01'
			,N'2015-07-01'
			,N'2015-08-01'
			,N'2015-09-01'
			,N'2015-10-01'
			,N'2015-11-01'
			,N'2015-12-01'
			,N'2016-01-01'
			,N'2016-02-01'
			,N'2016-03-01'
			,N'2016-04-01'
			,N'2016-05-01'
		  )
GO

-----------------------------------------------------------------
-- 2. Create partition schema for Sales.P_Orders
-----------------------------------------------------------------

CREATE PARTITION SCHEME [PS_SalesOrder_MONTHLY] 
AS PARTITION [PF_SalesOrder_MONTHLY] 
ALL TO ([PRIMARY]);
GO

-----------------------------------------------------------------
-- 3. Create the partitioned table
-----------------------------------------------------------------

CREATE SCHEMA Sales
GO

CREATE TABLE [Sales].[P_Orders](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[BackorderOrderDate] [date] NULL, 
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
	[rowguid] [uniqueidentifier] ROWGUIDCOL  
 CONSTRAINT [PK_Sales_P_Orders] PRIMARY KEY CLUSTERED 
(	[OrderID] ASC,
	[OrderDate]
)
ON [PS_SalesOrder_MONTHLY](OrderDate)
)
GO

-----------------------------------------------------------------
-- 4. Create constraints CHECK, DEFAULT and FKs
-----------------------------------------------------------------

-- We are not doing it in thi demo because do not have the
-- all database and inserts will fail due to FKs 
-- However, it works exactly as in SQL Server 

-----------------------------------------------------------------
-- 5. Create indexes and see that the same restriction apllies
-----------------------------------------------------------------
CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_CustomerID] ON [Sales].[P_Orders]
(
	[CustomerID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

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

-- To simplify the data load for the demo on Azure SQL Database
-- Let's drop the unique index

DROP INDEX [AK_Sales_P_Order_rowguid] ON [Sales].[P_Orders]
GO

-- To see details about the partitions on the table 
-- execute the following query

SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.index_id, p.partition_number

-----------------------------------------------------------------
-- 6. Load data
-----------------------------------------------------------------

-- using any tool you want, move data from 
-- [WideWorldImporters].[Sales].[Orders] to
-- [Sales].[P_Orders] in the Azure SQL Database

-- check how many rows were inserted into each partition

SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.index_id, p.partition_number

-----------------------------------------------------------------
-- 7. Index Maintenance
-----------------------------------------------------------------

-- Calculate the fragmentation for all partitions of index_id = 1 for [Sales].[P_Orders]

select database_id, object_id, index_id, partition_number, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats (db_id(), object_id('[Sales].[P_Orders]'),1,null,'LIMITED' )

-- Calculate the fragmentation for all partitions of all indexes of [Sales].[P_Orders]

select database_id, object_id, index_id, partition_number, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats (db_id(), object_id('[Sales].[P_Orders]'),null,null,'LIMITED' )

-- Calculate the fragmentation for partition 10 for index_id=1 of [Sales].[P_Orders]

select database_id, object_id, index_id, partition_number, avg_fragmentation_in_percent
from sys.dm_db_index_physical_stats (db_id(), object_id('[Sales].[P_Orders]'),1,10,'LIMITED' )

-- Rebuild a single partition of [Sales].[P_Orders]

ALTER INDEX [PK_Sales_P_Orders]
ON [Sales].[P_Orders]
REBUILD Partition = 10
WITH ( ONLINE = ON )  -- ONLINE is a new option in SQL Server 2014

-- Rebuild all partitions of [Sales].[P_Orders]

ALTER INDEX [PK_Sales_P_Orders]
ON [Sales].[P_Orders]
REBUILD 
WITH ( ONLINE = ON )  -- ONLINE is a new option in SQL Server 2014

-- Reorganize a single partition of [Sales].[P_Orders]

ALTER INDEX [PK_Sales_P_Orders]
ON [Sales].[P_Orders]
REORGANIZE Partition = 8

-- Reorganize all partitions of [Sales].[P_Orders]

ALTER INDEX [PK_Sales_P_Orders]
ON [Sales].[P_Orders]
REORGANIZE 


-----------------------------------------------------------------
-- 8. Partition Maintenance
-----------------------------------------------------------------

-- See the original state
SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.index_id, p.partition_number


--You can truncate partitions
TRUNCATE TABLE [Sales].[P_Orders]
WITH (PARTITIONS (2));

-- you can merge partitions
ALTER PARTITION FUNCTION [PF_SalesOrder_MONTHLY]()
MERGE RANGE ('2013-02-01')

-- Let's validate that the partition was deleted
-- Notice the boundaries between partitionNumber 1 and 2
-- Notice that after the MERGE the table has 41 partitions 

SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.index_id, p.partition_number

-- You can create a new partition
-- You do not have to use the NEXT USED because all partitions go to PRIMARY

--ALTER PARTITION SCHEME [PS_SalesOrder_MONTHLY] 
--NEXT USED [PRIMARY];

ALTER PARTITION FUNCTION [PF_SalesOrder_MONTHLY]()
SPLIT RANGE ('2016-06-01');

-- Let's validate that a the partition was created
-- Notice that after the SPLIT the table has 42 partitions 
-- Notice the boudnaries for PartitionNumber=42

SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.partition_number, i.index_id


-----------------------------------------------------------------
-- 11. Data Compression
-----------------------------------------------------------------

-- sp_estimate_data_compression_savings is not supported on Azure SQL Databases

EXEC sp_estimate_data_compression_savings 'Sales', 'Orders', 1, NULL, 'ROW' ;
GO

-- Lets compress some specific partitions of index_id=1
alter index [PK_Sales_P_Orders]  on [Sales].[P_Orders] 
REBUILD PARTITION=2 with (data_compression = ROW)
go
alter index [PK_Sales_P_Orders] on [Sales].[P_Orders] 
REBUILD PARTITION=3 with (data_compression = PAGE)
go

-- Confirm that partitions 2 and 3 got compresses

SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.index_id, p.partition_number


-- You can also compress several partitions of index_id=1 at once
alter index [PK_Sales_P_Orders]  on [Sales].[P_Orders] 
REBUILD PARTITION = ALL with (data_compression = PAGE ON PARTITIONS (2 to 41))

-- Confirm that partitions 2 to 41 got compressed 

SELECT
	OBJECT_NAME(p.object_id) AS ObjectName, 
	i.name AS IndexName, 
	p.index_id AS IndexID, 
	ds.name AS PartitionScheme, 
	p.partition_number AS PartitionNumber, 
	p.data_compression_desc as compression_level,
	fg.name AS FileGroupName, 
	prv_left.value AS LowerBoundaryValue, 
	prv_right.value AS UpperBoundaryValue, 
	CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS PartitionFunctionRange, 
	p.rows AS Rows
FROM
	sys.partitions AS p INNER JOIN
	sys.indexes AS i ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN
	sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id INNER JOIN
	sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id INNER JOIN
	sys.partition_functions AS pf ON pf.function_id = ps.function_id INNER JOIN
	sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number INNER JOIN
	sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id LEFT OUTER JOIN
	sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id AND prv_left.boundary_id = p.partition_number - 1 LEFT OUTER JOIN
	sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id AND prv_right.boundary_id = p.partition_number
WHERE
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]') )
AND p.index_id = 1
order by p.object_id, p.index_id, p.partition_number

-----------------------------------------------------------------
-- 12. Filtered indexes 
-----------------------------------------------------------------

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

-- This index covers data for the all table but we
-- only search rows for the last sixty days 

-- How to improve it? Lets delete the original inde
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

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'
option (recompile) --- this is used just becasue DBCC FREEPROCCACHE does not exists in Azure SQL DB

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

-- Let's execute the original query but using variables

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

-- Only when you use RECOMPLIE the query uses the filtered index, Why?

-- Let's expand the range of search

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-06-01'

-- Notice that you do not use filtered indexes and SQL scans the table.
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

-----------------------------------------------------------------
-- 13. Filtered  statistics
-----------------------------------------------------------------

-- Lets supose that your application only allows you to list the 
-- of orders for a customer for the last sixty days

-- NOTE: We use a fixed date and not getdate() because
--       the table conly contains records up to 2016-06-01

set statistics io on

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'

-- This query uses an Index Seek operator, a reduced number of logical reads
-- and due to partition elimination, it is quite efficient
-- However:
-- Look at the Actual Number of Rows and the Estimated Number of Rows

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

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-05-01'

-- Look at the Actual Number of Rows and the Estimated Number of Rows.  
-- Can SQL Server make better estimations?

-- Lets execute the original query but using variables

declare @fecha_inicial date = '2016-04-01'
declare @fecha_final date = '2016-05-01'

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= @fecha_inicial and OrderDate < @fecha_final
GO
-- Notice that the estimation is not that good. Why?

-- Lets use the option RECOMPILE

declare @fecha_inicial date = '2016-04-01'
declare @fecha_final date = '2016-05-01'

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= @fecha_inicial and OrderDate < @fecha_final
option (recompile)

-- You get better estimations, Why?

-- Lets expand the range of search

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-06-01'

-- Notice that the estimation is not that good. Why?

-- To get better estimations, lets create filtered statistics 
-- for the last Quarter

CREATE STATISTICS [STAT_Sales_P_Order_CustomerId2016_Q2] ON [Sales].[P_Orders] 
([CustomerID] )  
WHERE ( OrderDate >= '2016-04-01' and OrderDate < '2016-07-01' )
WITH FULLSCAN

SELECT * 
FROM [Sales].[P_Orders]
WHERE CustomerID = 404
AND OrderDate >= '2016-04-01' and OrderDate < '2016-06-01'
OPTION (RECOMPILE)  --- this is used just becasue DBCC FREEPROCCACHE does not exists in Azure SQL DB

-- Notice that you have better estimations
