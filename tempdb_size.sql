----------------------------------------------------------------------------------------------------------
SELECT (SUM(unallocated_extent_page_count)*1.0/128) AS TempDB_FreeSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
    
SELECT (SUM(version_store_reserved_page_count)*1.0/128) AS TempDB_VersionStoreSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
    
SELECT (SUM(internal_object_reserved_page_count)*1.0/128) AS TempDB_InternalObjSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
    
SELECT (SUM(user_object_reserved_page_count)*1.0/128) AS TempDB_UserObjSpaceAmount_InMB
FROM sys.dm_db_file_space_usage;
----------------------------------------------------------------------------------------------------------
SELECT session_id,
    SUM(internal_objects_alloc_page_count) AS NumOfPagesAllocatedInTempDBforInternalTask,
    SUM(internal_objects_dealloc_page_count) AS NumOfPagesDellocatedInTempDBforInternalTask,
    SUM(user_objects_alloc_page_count) AS NumOfPagesAllocatedInTempDBforUserTask,
    SUM(user_objects_dealloc_page_count) AS NumOfPagesDellocatedInTempDBforUserTask
FROM sys.dm_db_task_space_usage
GROUP BY session_id
ORDER BY NumOfPagesAllocatedInTempDBforInternalTask DESC, NumOfPagesAllocatedInTempDBforUserTask DESC
----------------------------------------------------------------------------------------------------------
sys.dm_db_file_space_usage 
sys.dm_db_session_space_usage 
sys.dm_db_task_space_usage 
----------------------------------------------------------------------------------------------------------


  