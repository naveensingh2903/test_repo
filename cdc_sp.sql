--cdc stored procedure 
--create base table 
select row_number() over(order by name) id,name table_name,schema_name(schema_id) table_schema 
into list_of_cdc_tables from sys.tables  
where object_id in ('869174442', '1569440665', '1418540187', '2050926478', '1392776069', '1238503691', '1205735498', '1179919325', '1239219715', '1610749091', '1948742195', '1596076972', '1408776126', '947794734', '654885650', '1851153640', '359984659', '708509903', '1433368471', '2015554464', '661785615', '132403741', '728441719', '954746754', '1013838924', '358552611', '1066083184', '1130083412', '39827354')
and is_tracked_by_cdc<>1

--stored procedure definition
alter procedure sp_enable_cdc  
as begin
declare @max int 
set @max=(select count(*) from list_of_cdc_tables)          --dump all the table details in this new table
declare @counter int 
declare @table_name varchar(300)
declare @table_schema varchar(300)
declare @sql varchar(max)
set @counter=2
while @counter<=@max 
    begin 
    set @table_name=(select table_name from list_of_cdc_tables where id=@counter)
    set @table_schema=(select table_schema from list_of_cdc_tables where id=@counter)
set @sql='EXEC sys.sp_cdc_enable_table  
            @source_schema = N'''+@table_schema+''',@source_name = N'''+@table_name+'''  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO' 
--WAITFOR DELAY '00:00:10';
    --print @table_name
    --print @table_schema
    print @sql 
	--exec (@sql)
    set @counter=@counter+1 
    end 
end

--execute the stored procedure
exec sp_enable_cdc


