--total user table 
select count(*)  from sys.objects 
where type_desc='USER_TABLE' and schema_id<>42

select count(*) from sys.tables where schema_id<>42

--to get base table names 
select s.name schema_name,t.name table_name,t.object_id from sys.tables t join sys.schemas s
on t.schema_id=s.schema_id and s.schema_id<>42
order by schema_name 


--Query to get table size in rows and MB
SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB DESC, t.Name

--cdc enabled tables 
select t.name table_name,s.name schema_name,t.object_id,t.is_tracked_by_cdc from sys.tables t join sys.schemas s on t.schema_id=s.schema_id
where t.schema_id<>42 and t.is_tracked_by_cdc=1

--List all Primary key
select schema_name(tab.schema_id) as [schema_name], 
    tab.[name] as table_name, 
    pk.[name] as pk_name,
    substring(column_names, 1, len(column_names)-1) as [columns]
from sys.tables tab
    left outer join sys.indexes pk
        on tab.object_id = pk.object_id 
        and pk.is_primary_key = 1
   cross apply (select col.[name] + ', '
                    from sys.index_columns ic
                        inner join sys.columns col
                            on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
                    where ic.object_id = tab.object_id
                        and ic.index_id = pk.index_id
                            order by col.column_id
                            for xml path ('') ) D (column_names)
order by schema_name(tab.schema_id),
    tab.[name]

--List all foreign keys 
SELECT  obj.object_id,obj.name AS FK_NAME,
    sch.name AS [schema_name],
    tab1.name AS [Table_name],
    col1.name AS [column],
    tab2.name AS [referenced_table],
    col2.name AS [referenced_column]
FROM sys.foreign_key_columns fkc
INNER JOIN sys.objects obj
    ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tab1
    ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas sch
    ON tab1.schema_id = sch.schema_id
INNER JOIN sys.columns col1
    ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN sys.tables tab2
    ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.columns col2
    ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
where sch.schema_id<>42

--List composite Primary Key
-- Let's get the columns of the Primary key into a CTE
;WITH mycte AS (SELECT o.object_id as object_id,SCHEMA_NAME(o.schema_id) AS 'Schema'
            , OBJECT_NAME(i2.object_id) AS 'TableName'
            , STUFF(
                (SELECT ',' + COL_NAME(ic.object_id,ic.column_id) 
                FROM sys.indexes i1
                    INNER JOIN sys.index_columns ic ON i1.object_id = ic.object_id AND i1.index_id = ic.index_id
                WHERE i1.is_primary_key = 1
                    AND i1.object_id = i2.object_id AND i1.index_id = i2.index_id
                FOR XML PATH('')),1,1,'') AS PK
FROM sys.indexes i2
INNER JOIN sys.objects o ON i2.object_id = o.object_id
WHERE i2.is_primary_key = 1
AND o.type_desc = 'USER_TABLE'
)


SELECT SCHEMA_NAME(o.schema_id) AS 'Schema'
, OBJECT_NAME(i.object_id) AS 'TableName',i.object_id object_id
, COUNT(COL_NAME(ic.object_id,ic.column_id)) AS 'Primary_Key_Column_Count'
, mycte.PK AS 'Primary_Key_Columns'
FROM sys.indexes i 
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.objects o ON i.object_id = o.object_id
INNER JOIN mycte ON mycte.TableName = OBJECT_NAME(i.object_id)
WHERE i.is_primary_key = 1
AND o.type_desc = 'USER_TABLE' and o.schema_id<>42
GROUP BY SCHEMA_NAME(o.schema_id)
, OBJECT_NAME(i.object_id),i.object_id
, mycte.PK
HAVING COUNT('Primay_Key_Column_Count') > 1
ORDER BY 'TableName' ASC

--List computed column
SELECT o.object_id,SCHEMA_NAME(o.schema_id) AS schema_name, 
    c.name AS column_name, 
    OBJECT_NAME(c.object_id) AS table_name, 
    TYPE_NAME(user_type_id) AS data_type, 
    definition
FROM sys.computed_columns c
  JOIN sys.objects o ON o.object_id = c.object_id
ORDER BY schema_name, 
      table_name, 
      column_id;

--user defined data types 
select s.name schema_name,t.name table_name,t.object_id,c.name col_name 
from sys.tables t join sys.schemas s 
on t.schema_id=s.schema_id 
join sys.columns c on c.object_id=t.object_id 
join sys.types ty on ty.user_type_id=c.user_type_id 
where ty.is_user_defined=1 and s.schema_id<>42

--list large objects data types
select s.name schema_name,t.name table_name,t.object_id,c.name col_name,ty.name col_type,c.max_length
from sys.tables t join sys.schemas s 
on t.schema_id=s.schema_id 
join sys.columns c on c.object_id=t.object_id 
join sys.types ty on ty.user_type_id=c.user_type_id 
where s.schema_id<>42 and c.max_length=-1

--List all the triggers
SELECT t.object_id,
     sysobjects.name AS trigger_name 
    ,USER_NAME(sysobjects.uid) AS trigger_owner 
    ,s.name AS table_schema 
    ,OBJECT_NAME(parent_obj) AS table_name 
    ,OBJECTPROPERTY( id, 'ExecIsUpdateTrigger') AS isupdate 
    ,OBJECTPROPERTY( id, 'ExecIsDeleteTrigger') AS isdelete 
    ,OBJECTPROPERTY( id, 'ExecIsInsertTrigger') AS isinsert 
    ,OBJECTPROPERTY( id, 'ExecIsAfterTrigger') AS isafter 
    ,OBJECTPROPERTY( id, 'ExecIsInsteadOfTrigger') AS isinsteadof 
    ,OBJECTPROPERTY(id, 'ExecIsTriggerDisabled') AS [disabled] 
FROM sysobjects 
INNER JOIN sysusers 
    ON sysobjects.uid = sysusers.uid 
INNER JOIN sys.tables t 
    ON sysobjects.parent_obj = t.object_id 
INNER JOIN sys.schemas s 
    ON t.schema_id = s.schema_id 
WHERE sysobjects.type = 'TR' and s.schema_id<>42

--List all the indexes
select schema_name(t.schema_id) schema_name,t.[name] table_name,t.object_id,i.[name] as index_name,
    substring(column_names, 1, len(column_names)-1) as [columns],
    case when i.[type] = 1 then 'Clustered index'
        when i.[type] = 2 then 'Nonclustered unique index'
        when i.[type] = 3 then 'XML index'
        when i.[type] = 4 then 'Spatial index'
        when i.[type] = 5 then 'Clustered columnstore index'
        when i.[type] = 6 then 'Nonclustered columnstore index'
        when i.[type] = 7 then 'Nonclustered hash index'
        end as index_type,
    case when i.is_unique = 1 then 'Unique'
        else 'Not unique' end as [unique],
    schema_name(t.schema_id) + '.' + t.[name] as table_view, 
    case when t.[type] = 'U' then 'Table'
        when t.[type] = 'V' then 'View'
        end as [object_type]
from sys.objects t
    inner join sys.indexes i
        on t.object_id = i.object_id
    cross apply (select col.[name] + ', '
                    from sys.index_columns ic
                        inner join sys.columns col
                            on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
                    where ic.object_id = t.object_id
                        and ic.index_id = i.index_id
                            order by key_ordinal
                            for xml path ('') ) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
order by i.[name]

--List table along with modify date
with cte as (
select object_name(object_id) table_name,object_id,sum(rows) rows from sys.partitions 
where object_id in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE')
group by object_id) 

select cte.table_name,cte.object_id,cte.rows,t.create_date,t.modify_date from cte join sys.tables t on cte.object_id=t.object_id 

--Identify identity column out of some table list
select * from sys.tables 
where object_id in 
('728441719', '1418540187', '1948742195', '39827354', '869174442', '358552611', '1851153640', '1596076972', '661785615', '654885650', '1130083412', '1205735498', '1238503691', '1239219715', '1066083184', '2050926478', '132403741', '1013838924', '2015554464', '1179919325', '1433368471')
and object_id not in (select object_id  from sys.columns 
where is_identity=1 and object_id in ('728441719', '1418540187', '1948742195', '39827354', '869174442', '358552611', '1851153640', '1596076972', '661785615', '654885650', '1130083412', '1205735498', '1238503691', '1239219715', '1066083184', '2050926478', '132403741', '1013838924', '2015554464', '1179919325', '1433368471')
)

