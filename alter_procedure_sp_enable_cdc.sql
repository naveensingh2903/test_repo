alter procedure sp_enable_cdc  
as begin
declare @max int 
set @max=(select count(*) from list_of_cdc_tables)          --dump all the table details in this new table
declare @counter int 
declare @table_name varchar(300)
declare @table_schema varchar(300)
declare @sql varchar(max)
set @counter=1
while @counter<=@max 
    begin 
    set @table_name=(select table_name from stats_table where id=@counter)
    set @table_schema=(select table_schema from stats_table where id=@counter)
    set @sql='''EXEC sys.sp_cdc_enable_table
                @source_schema =  N'+@table_schema+',
                @source_name = N'+@table_name+',
                @role_name =NULL,
                @supports_net_changes = 1
                GO '''

    print @table_name
    print @table_schema
--    exec (@sql)
    print @sql 
    set @counter=@counter+1 
    end 

EXEC sys.sp_cdc_enable_table  
@source_schema = N'dbo',  
@source_name   = N'jdbc_computed_test',  
@role_name     = NULL,  
@supports_net_changes = 1  
GO  

'''EXEC sys.sp_cdc_enable_table
@source_schema =  N'+@table_schema+',
@source_name = N'+@table_name+',
@role_name =NULL,
@supports_net_changes = 1
GO '''



