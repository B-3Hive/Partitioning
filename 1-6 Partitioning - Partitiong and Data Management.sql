USE [WideWorldImporters]
GO

-----------------------------------------------------------------
-- 1. Deleting a partition using a staging table (SQL 2005 to SQL 2016).
--    Later in the demo you will see how to do it using partition truncation (SQL 2016 +)
-----------------------------------------------------------------

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Sales].[P_Orders_AUX](
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
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL 
	CONSTRAINT [PK_Sales_P_Orders_AUX] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC,
	[OrderDate]
)
ON [PS_SalesOrder_MONTHLY](OrderDate)
)
GO

ALTER TABLE [Sales].[P_Orders_AUX]  WITH CHECK ADD  CONSTRAINT [FK_Sales_P_Orders_AUX_BackorderOrderID_Sales_P_Orders_AUX] FOREIGN KEY([BackorderOrderID],[BackorderOrderDate])
REFERENCES [Sales].[P_Orders_AUX] ([OrderID],[OrderDate])
GO
ALTER TABLE [Sales].[P_Orders_AUX] CHECK CONSTRAINT [FK_Sales_P_Orders_AUX_BackorderOrderID_Sales_P_Orders_AUX]
GO


CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_AUX_ContactPersonID] ON [Sales].[P_Orders_AUX]
(
	[ContactPersonID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)


CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_AUX_CustomerID] ON [Sales].[P_Orders_AUX]
(
	[CustomerID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_AUX_PickedByPersonID] ON [Sales].[P_Orders_AUX]
(
	[PickedByPersonID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

CREATE NONCLUSTERED INDEX [FK_Sales_P_Orders_AUX_SalespersonPersonID] ON [Sales].[P_Orders_AUX]
(
	[SalespersonPersonID] ASC
)
ON [PS_SalesOrder_MONTHLY](OrderDate)

CREATE UNIQUE NONCLUSTERED INDEX [AK_Sales_P_Order_AUX_rowguid] ON [Sales].[P_Orders_AUX]
(
	[rowguid] ASC,
	[OrderDate]
)ON [PS_SalesOrder_MONTHLY](OrderDate)
GO


-----------------------------------------------------
-- What is the partition with the oldest data 
-- should it be always partition 2? or not?

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

-- Answer: for this case, based on the table and partitions design
--         Partition 2 should always be the one with the oldest data

-- Let´s see partitionNumber 2 for the original partitioned table
-- and the staging table. Notice the number of rows for this partition
-- on each table

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
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]'),  OBJECT_id ('[Sales].[P_Orders_AUX]') )
AND p.index_id = 1
and p.partition_number = 2
order by p.object_id, p.partition_number, i.index_id

--- Switch partitions

ALTER TABLE [Sales].[P_Orders] SWITCH PARTITION 2
TO [Sales].[P_Orders_AUX] PARTITION 2;

-- You get an error, why?

-- This is a limitation of the SWITCH operation if you have a self-reference 
-- One solution is to delete the FK. 
-- Discuss the implications of deleting the FK?
ALTER TABLE [Sales].[P_Orders] 
DROP CONSTRAINT [FK_Sales_P_Orders_BackorderOrderID_Sales_P_Orders]
GO
ALTER TABLE [Sales].[P_Orders_AUX] 
DROP CONSTRAINT [FK_Sales_P_Orders_AUX_BackorderOrderID_Sales_P_Orders_AUX]
GO

ALTER TABLE [Sales].[P_Orders] SWITCH PARTITION 2
TO [Sales].[P_Orders_AUX] PARTITION 2;

-- How long this operation should take on partition with millions of rows

-- Let's see partition 2 info for partitioned table and staging table 
-- Notice that the rows are now in the staging table 

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
p.OBJECT_id in ( OBJECT_id ('[Sales].[P_Orders]'),  OBJECT_id ('[Sales].[P_Orders_AUX]') )
AND p.index_id = 1
and p.partition_number = 2
order by p.object_id, p.partition_number, i.index_id

-- As the ol data is not in the original partitioned table
-- you can delete or truncate the staging table 
drop table [Sales].[P_Orders_AUX]


--  Now P_Orders has 2 empty partitions (PartitionNumber=1 and ParitionNumber=2)
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


-- Let's drop the partition that was emptied after the switch
-- Notice that before the MERGE the table has 42 partitions 

ALTER PARTITION FUNCTION [PF_SalesOrder_MONTHLY]()
MERGE RANGE ('2013-01-01')

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
order by p.object_id, p.partition_number, i.index_id

-----------------------------------------------------------------
-- 2. Starting SQL Server 2016 you can truncate a partition
-----------------------------------------------------------------

TRUNCATE TABLE [Sales].[P_Orders]
WITH (PARTITIONS (2));

--  Now P_Orders has 2 empty partitions (PartitionNumber=1 and ParitionNumber=2)

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

-- Let's drop the partition that was truncated
-- Notice the boundaries between partitionNumber 1 and 2
-- Notice that before the MERGE the table has 41 partitions 

ALTER PARTITION FUNCTION [PF_SalesOrder_MONTHLY]()
MERGE RANGE ('2013-02-01')

-- Let's validate that the partition was deleted
-- Notice the boundaries between partitionNumber 1 and 2
-- Notice that after the MERGE the table has 40 partitions 


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
-- 3. Let's create a partition for the next month
-----------------------------------------------------------------

ALTER PARTITION SCHEME [PS_SalesOrder_MONTHLY] 
NEXT USED [FG_SalesOrder_M_2_6_10];

ALTER PARTITION FUNCTION [PF_SalesOrder_MONTHLY]()
SPLIT RANGE ('2016-06-01');

-- Let's validate that a the partition was created
-- Notice that after the SPLIT the table has 41 partitions 
-- NOtice the boudnaries for PartitionNumber=41

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

