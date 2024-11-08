USE [WideWorldImporters]
GO

-----------------------------------------------------------------
-- 0. Calculate the number of rows per month in the unpartitioned table
--    to identify partition boundaries
-----------------------------------------------------------------

select year(OrderDate), month(OrderDate), count(*)  
from [Sales].[Orders]
group by year(OrderDate), month(OrderDate)
order by year(OrderDate), month(OrderDate)

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
-- 2. Create partition schema for Sales.Orders
-----------------------------------------------------------------

-- NOTE: Explain who each filegroup maps to a partition

CREATE PARTITION SCHEME [PS_SalesOrder_MONTHLY] 
AS PARTITION [PF_SalesOrder_MONTHLY] 
TO ([FG_SalesOrder_OldEmpty]

  , [FG_SalesOrder_M_1_5_9] -- Jan 2013
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9]
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9]
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12] -- Dic 2013

  , [FG_SalesOrder_M_1_5_9] -- Jan 2014
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9]
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9]
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12] -- Dic 2014
  
  , [FG_SalesOrder_M_1_5_9] -- Jan 2015
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9]
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9]
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12] -- Dic 2015
  
  , [FG_SalesOrder_M_1_5_9] -- Jan 2016
  , [FG_SalesOrder_M_2_6_10]  
  , [FG_SalesOrder_M_3_7_11]
  , [FG_SalesOrder_M_4_8_12]  
  , [FG_SalesOrder_M_1_5_9] -- May 2016
)  
GO
