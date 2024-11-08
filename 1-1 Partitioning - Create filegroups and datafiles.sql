-----------------------------------------------------------------
-- 1. Create Filegroups to be used by partition schema of Sales.P_Orders
-----------------------------------------------------------------

-- A monthly partition will be implemented.
-- Filegroups will be reused every three months. 
-- ¿Why? Because it was the result of previous analysis, this is just one way to define FGs 
-- and save as much space as possible when data compression is implemented

-- The original table contains data from January 2013 to May 2016
-- FG_SalesOrder_OldEmpty will originally contain data from negative infinity to December 2013
-- FG_SalesOrder_M_1_5_9 will contain data from January, May and September for all years
-- FG_SalesOrder_M_2_6_10 will contain data from February, June and October for all years
-- FG_SalesOrder_M_3_7_11 will contain data from March, July and November for all years
-- FG_SalesOrder_M_4_8_12 will contain data from April, August and December for all years

USE [WideWorldImporters] 
GO
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [FG_SalesOrder_OldEmpty]
GO
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [FG_SalesOrder_M_1_5_9]
GO
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [FG_SalesOrder_M_2_6_10]
GO
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [FG_SalesOrder_M_3_7_11]
GO
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [FG_SalesOrder_M_4_8_12]
GO

-----------------------------------------------------------------
-- 2. Create at least one datafile on each filegroup used 
--    by partition scheme of Sales.P_Orders
-----------------------------------------------------------------

-- SalesOrder_OldEmpty will not contain any row as it cover
-- from negative infinity to the first partition boundary, 
-- so it can be placed in the same disk than any of the other datafiles

-- NOTE: Make sure to adjust the path for datafiles to one that exists on your demo machine

ALTER DATABASE [WideWorldImporters] 
ADD FILE ( NAME = N'SalesOrder_OldEmpty', 
		   FILENAME = N'C:\data\SalesOrder_OldEmpty.ndf' , 
		   SIZE = 4096KB , 
		   FILEGROWTH = 1024KB ) 
TO FILEGROUP [FG_SalesOrder_OldEmpty]
GO

ALTER DATABASE [WideWorldImporters] 
ADD FILE ( NAME = N'SalesOrder_M_1_5_9', 
		   FILENAME = N'C:\data\SalesOrder_M_1_5_9.ndf' , 
		   SIZE = 64MB , 
		   FILEGROWTH = 128MB ) 
TO FILEGROUP [FG_SalesOrder_M_1_5_9]
GO

ALTER DATABASE [WideWorldImporters] 
ADD FILE ( NAME = N'SalesOrder_M_2_6_10', 
		   FILENAME = N'C:\data\SalesOrder_M_2_6_10.ndf' , 
		   SIZE = 64MB , 
		   FILEGROWTH = 128MB ) 
TO FILEGROUP [FG_SalesOrder_M_2_6_10]
GO

ALTER DATABASE [WideWorldImporters] 
ADD FILE ( NAME = N'SalesOrder_M_3_7_11', 
		   FILENAME = N'C:\data\SalesOrder_M_3_7_11.ndf' , 
		   SIZE = 64MB , 
		   FILEGROWTH = 128MB ) 
TO FILEGROUP [FG_SalesOrder_M_3_7_11]
GO

ALTER DATABASE [WideWorldImporters] 
ADD FILE ( NAME = N'SalesOrder_M_4_8_12', 
		   FILENAME = N'C:\data\SalesOrder_M_4_8_12.ndf' , 
		   SIZE = 64MB , 
		   FILEGROWTH = 128MB ) 
TO FILEGROUP [FG_SalesOrder_M_4_8_12]
GO

