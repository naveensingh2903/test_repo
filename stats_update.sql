ALTER PROCEDURE stats_update 
AS 
BEGIN 
DECLARE @max INT 
SET @max=(SELECT count(*) FROM stats_table)
DECLARE @counter INT 
DECLARE @table_name VARCHAR(300)
DECLARE @table_schema VARCHAR(300)
DECLARE @stats VARCHAR(max)
DECLARE @INDEX VARCHAR(max)
DECLARE @flag INT 
SET @flag=(SELECT max(flag) FROM stats_table )
IF @flag<=5
BEGIN
SET @counter=(SELECT min(id) FROM stats_table WHERE bucket=@flag)
WHILE @counter<=@max 
BEGIN 
SET @table_name=(SELECT table_name FROM stats_table WHERE id=@ counter AND bucket=@flag)
SET @table_schema=(SELECT table_schema FROM stats_table WHERE id=@counter AND bucket=@flag)
SET @stats='update statistics '+@table_schema+'.'+@table_name+' with sample 10 percent;'print @table_nameprint @table_schema 
exec (@stats)
print @stats 
SET @counter=@counter+1 
END 
UPDATE stats_table SET flag=@flag+1
END 
ELSE 
BEGIN 
UPDATE stats_table SET flag=1
EXEC stats_update 
end 
END 


--Other way to iterate over a item
select 'ALTER INDEX [' + I.name + '] ON [' + T.name + '] DISABLE' 
from sys.indexes I
inner join sys.tables T on I.object_id = T.object_id
where I.type_desc = 'NONCLUSTERED'
and I.name is not null
