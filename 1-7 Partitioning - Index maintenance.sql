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



