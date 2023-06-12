
alter procedure rebuild_statements
as begin 
declare @sql nvarchar(400)
declare @table_name varchar(100)
declare @table_schema varchar(100)
declare @counter int
set @counter=1 
declare @max int 
--Create a table to store all values 
IF OBJECT_ID(N'tempdb.dbo.#rebuild_table_ssspl', N'U') IS NOT NULL  
   DROP TABLE #rebuild_table_ssspl;
select row_number() over(order by table_schema,table_name) id,table_Schema,table_name into #rebuild_table_ssspl from
INFORMATION_SCHEMA.TABLES
where table_type<>'VIEW'
set @max = (select count(*) from #rebuild_table_ssspl)
--print @max 

while (@counter <= 100)
begin 
set @table_Schema = (select table_schema from rebuild_table_ssspl where id=@counter) 
--print @table_schema
set @table_name = (select table_name from rebuild_table_ssspl where id=@counter) 
--print @table_name
set @sql= 'Alter index all on [' +@table_schema + '].[' + @table_name +'] rebuild ;'
exec (@sql)
print @sql 
set @counter = @counter+1 
end 
end 

--exec rebuild_statements

