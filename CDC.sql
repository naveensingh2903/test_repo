-- =========  
-- To check if cdc is enabled or not
-- =========  
select name,is_cdc_enabled from sys.databases 
-- =========  
-- Enable Database for CDC template   
-- =========  
USE MyDB  
GO  
EXEC sys.sp_cdc_enable_db  
GO
-- =========  
-- Disable Database for change data capture template   
-- =========  
USE MyDB  
GO  
EXEC sys.sp_cdc_disable_db  
GO
-- =========  
-- Enable a Table Specifying Filegroup Option Template  
-- =========  
USE MyDB  
GO  
EXEC sys.sp_cdc_enable_table  
@source_schema = N'dbo',  
@source_name   = N'MyTable',  
@role_name     = N'MyRole',  
@filegroup_name = N'MyDB_CT',  
@supports_net_changes = 1  
GO
-- =========  
-- Enable a Table Without Using a Gating Role template   
-- =========  
USE MyDB  
GO  
EXEC sys.sp_cdc_enable_table  
@source_schema = N'dbo',  
@source_name   = N'MyTable',  
@role_name     = NULL,  
@supports_net_changes = 1  
GO
-- =========  
-- Tables present in cdc schema 
-- =========  
select * from cdc.change_tables
select * from cdc.ddl_history
select * from cdc.lsn_time_mapping
select * from cdc.captured_columns
select * from cdc.index_columns

