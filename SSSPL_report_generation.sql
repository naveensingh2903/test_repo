--SSSPL report generation 
--Query to get last accessed time of a table 
select object_name(object_id) table_name,object_id from sys.dm_db_index_usage_stats
where object_id in (select object_id from sys.objects where schema_id<>42 and type_desc='USER_TABLE')

--Query to get trigger name and parent table name
select object_name(parent_object_id) table_name,parent_object_id object_id,name trgger_name from sys.objects 
where type_desc='SQL_TRIGGER'

--Query to get computed column
select object_name(c.object_id) as table_name,
c.object_id,column_id,
c.name as column_name
from sys.computed_columns c
join sys.objects o on o.object_id = c.object_id

--Query to get primary key and table name
select object_name(object_id) table_name,object_id,name PK_name from sys.indexes ind
where  is_primary_key=1
and object_id in (select object_id from sys.objects where schema_id<>42)

--Query to get overview of a database 
select type_desc,count(*) from sys.objects 
where schema_id<>42
group by type_desc 

--Query to get cdc tables
select name,object_id from sys.tables 
where is_tracked_by_cdc=1 

select name table_name,object_id from sys.objects where object_id in (select object_id from cdc.change_tables) 

--Query to get top 150 table sizes. Query to get table size in rows and MB
with cte as (SELECT row_number() over(order by (SUM(a.total_pages) * 8) desc) row_num,
t.NAME AS TableName,s.Name AS SchemaName,p.rows,
SUM(a.total_pages) * 8 AS TotalSpaceKB, 
CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
SUM(a.used_pages) * 8 AS UsedSpaceKB, 
CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.NAME NOT LIKE 'dt%' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 
GROUP BY t.Name, s.Name, p.Rows)
select tablename,totalspacekb,CONSTRAINT_NAME from cte 
join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk on cte.TableName=pk.table_name
where cte.row_num<=150 and 
OBJECTPROPERTY(OBJECT_ID(pk.CONSTRAINT_SCHEMA + '.' + QUOTENAME(pk.CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
order by totalspacekb desc

--Query to get row count
select object_name(object_id) table_name,object_id,sum(rows) rows from sys.partitions 
where object_id in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE')
group by object_id 
order by 3 desc

--Query to get table sizes in MB
;with cte as (
SELECT
object_name(t.object_id) as TableName,
t.object_id as obj,
SUM (s.used_page_count) as used_pages_count,
SUM (CASE
WHEN (i.index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
ELSE lob_used_page_count + row_overflow_used_page_count
END) as pages
FROM sys.dm_db_partition_stats  AS s 
JOIN sys.tables AS t ON s.object_id = t.object_id
JOIN sys.indexes AS i ON i.[object_id] = t.[object_id] AND s.index_id = i.index_id
GROUP BY t.object_id
)
select
cte.obj as object_id,sch.name schema_name,cte.TableName,
cast((cte.pages * 8.)/1024 as decimal(10,3)) as TableSizeInMB, 
cast(((CASE WHEN cte.used_pages_count > cte.pages 
THEN cte.used_pages_count - cte.pages
ELSE 0 
END) * 8./1024) as decimal(10,3)) as IndexSizeInMB
from cte join sys.tables tbl on cte.obj=tbl.object_id join sys.schemas sch on tbl.schema_id=sch.schema_id
where  cte.obj in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE')
order by 2 desc




