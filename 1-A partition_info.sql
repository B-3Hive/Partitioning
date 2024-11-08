--- Query 1

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


--- Query 2

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
order by p.object_id, p.partition_number, i.index_id


--- Query 3

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
AND p.partition_number = 2
order by p.object_id, p.partition_number, i.index_id



