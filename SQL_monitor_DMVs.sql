--SQL monitoring queries
--Added one more code
select * from sys.dm_exec_requests where session_id in (select session_id from sys.dm_exec_sessions where is_user_process=1)
---------------------------------------------------------------------------------------------
--Select @@version 
Microsoft SQL Server 2019 (RTM-CU12) (KB5004524) - 15.0.4153.1 (X64)   Jul 19 2021 15:37:34   Copyright (C) 2019 Microsoft Corporation  Enterprise Edition: Core-based Licensing (64-bit) on Windows Server 2016 Datacenter 10.0 <X64> (Build 14393: ) (Hypervisor) 
---------------------------------------------------------------------------------------------
--Get cpu cores 
select * from sys.dm_os_schedulers
order by 4
---------------------------------------------------------------------------------------------
--Get hardware info
SELECT * FROM sys.dm_os_sys_info;
---------------------------------------------------------------------------------------------
--Get ram size in KB
SELECT object_name, cntr_value 
  FROM sys.dm_os_performance_counters
  WHERE counter_name = 'Total Server Memory (KB)';
---------------------------------------------------------------------------------------------
--Current running sessions
select * from sys.dm_exec_sessions
where status='running'
---------------------------------------------------------------------------------------------
--Query to get all database sizes
select  db.name,(sum(f.size)*8)/1024 size_in_mb
from sys.master_files f join sys.databases db 
on f.database_id=db.database_id 
group by db.name
order by 2 desc 
---------------------------------------------------------------------------------------------
--Query to get separate mdf and ldf file size 
select  db.name,db.create_date,f.name file_name,((f.size)*8/1024) size_in_mb
from sys.master_files f join sys.databases db 
on f.database_id=db.database_id 
order by 3,4 desc
---------------------------------------------------------------------------------------------
--Query to get individual database size 
exec sp_spaceused 
---------------------------------------------------------------------------------------------
--Query to get file size and increment size
SELECT 
db.name AS                                   [Database Name], 
mf.name AS                                   [Logical Name], 
mf.type_desc AS                              [File Type], 
mf.physical_name AS                          [Path], 
CAST(
(mf.Size /1024
)*8 AS float) AS         [Initial Size (MB)], 
'By '+IIF(
mf.is_percent_growth = 1, CAST(mf.growth AS VARCHAR(1000))+'%', CONVERT(VARCHAR(30), CAST(
(mf.growth * 8
) / 1024.0 AS bigint))+' MB') AS [Autogrowth], 
IIF(mf.max_size = 0, 'No growth is allowed', IIF(mf.max_size = -1, 'Unlimited', CAST(
(
CAST(mf.max_size AS BIGINT) * 8
) / 1024 AS VARCHAR(30))+' MB')) AS      [MaximumSize]
FROM 
sys.master_files AS mf
INNER JOIN sys.databases AS db ON
db.database_id = mf.database_id
---------------------------------------------------------------------------------------------
-- Calculates the size of the database.
SELECT SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 AS DatabaseSizeInMB
FROM sys.database_files
WHERE type_desc = 'ROWS';
GO
---------------------------------------------------------------------------------------------
-- Calculates the size of individual database objects.
SELECT sys.objects.name, SUM(reserved_page_count) * 8.0 / 1024 table_size_MB
FROM sys.dm_db_partition_stats, sys.objects
WHERE sys.dm_db_partition_stats.object_id = sys.objects.object_id
GROUP BY sys.objects.name order by 2 desc;
GO
---------------------------------------------------------------------------------------------
--Concurrent requests at server level
SELECT COUNT(*) AS [Concurrent_Requests]
FROM sys.dm_exec_requests R;
---------------------------------------------------------------------------------------------
--Concurrent request for a database 
SELECT COUNT(*) AS [Concurrent_Requests]
FROM sys.dm_exec_requests R
INNER JOIN sys.databases D ON D.database_id = R.database_id
AND D.name = 'SSSPL';
---------------------------------------------------------------------------------------------
--Concurrent sessions at server level 
SELECT COUNT(*) AS [Sessions]
FROM sys.dm_exec_connections;
---------------------------------------------------------------------------------------------
--Concurrent session at database level 
SELECT COUNT(*) AS [Sessions]
FROM sys.dm_exec_connections C
INNER JOIN sys.dm_exec_sessions S ON (S.session_id = C.session_id)
INNER JOIN sys.databases D ON (D.database_id = S.database_id)
WHERE D.name = 'SSSPL';
---------------------------------------------------------------------------------------------
--Query to get connection pool size, used and unused connections
SELECT ConnectionStatus = CASE WHEN dec.most_recent_sql_handle = 0x0 THEN 'Unused' ELSE 'Used' END , CASE WHEN des.status = 'Sleeping' THEN 'sleeping' ELSE 'Not Sleeping' END , ConnectionCount = COUNT(1) FROM sys.dm_exec_connections dec INNER JOIN sys.dm_exec_sessions des ON dec.session_id = des.session_id GROUP BY CASE WHEN des.status = 'Sleeping' THEN 'sleeping' ELSE 'Not Sleeping' END , CASE WHEN dec.most_recent_sql_handle = 0x0 THEN 'Unused' ELSE 'Used' END;
---------------------------------------------------------------------------------------------
--Current active user sessions
SELECT s.session_id, s.login_time, s.host_name, s.program_name,
s.login_name, s.nt_user_name, s.is_user_process,
database_id, DB_NAME(s.database_id) AS [database], -- return the database name
s.status,
s.reads, s.writes, s.logical_reads
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1
---------------------------------------------------------------------------------------------
--Specific session details 
SELECT s.session_id, s.login_time, s.host_name, s.program_name,
s.login_name, s.nt_user_name, s.is_user_process,
database_id, DB_NAME(s.database_id) AS [database], 
s.status,
s.reads, s.writes, s.logical_reads, s.row_count
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1 
AND s.session_id = @@SPID -- just return info for our query
---------------------------------------------------------------------------------------------
--Current running queries 
SELECT sqltext.TEXT,
req.session_id,
req.status,
req.command,
req.cpu_time,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
---------------------------------------------------------------------------------------------
--Find query based on query text
with cte as (SELECT sqltext.TEXT query_text,
req.session_id sesssion_id,
req.status status,
req.command command,
req.cpu_time cpu,
req.total_elapsed_time elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
)
select * from cte where query_text like '%usermanagement.tblcustomer%'
---------------------------------------------------------------------------------------------
--Query to see cached stored procedures
SELECT SCHEMA_NAME(SCHEMA_ID) SchemaName, name ProcedureName,
last_execution_time LastExecuted,
last_elapsed_time LastElapsedTime,
execution_count ExecutionCount,
cached_time CachedTime
FROM sys.dm_exec_procedure_stats ps JOIN
sys.objects o ON ps.object_id = o.object_id
WHERE ps.database_id = DB_ID();
---------------------------------------------------------------------------------------------
--Query to get the top 10 most expensive TSQL calls – by logical (storage) reads:
SELECT top 10 DB_NAME(t.[dbid]) AS [Database],
REPLACE(REPLACE(LEFT(t.[text], 255), CHAR(10),''), CHAR(13),'') AS [ShortQueryTXT], 
qs.total_logical_reads AS [TotalLogicalReads],
qs.min_logical_reads AS [MinLogicalReads],
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.max_logical_reads AS [MaxLogicalReads],   
qs.min_worker_time AS [MinWorkerTime],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.max_worker_time AS [MaxWorkerTime], 
qs.min_elapsed_time AS [MinElapsedTime], 
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime], 
qs.max_elapsed_time AS [MaxElapsedTime],
qs.execution_count AS [ExecutionCount], 
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX],
qs.creation_time AS [CreationTime]
,t.[text] AS [Complete Query Text], qp.query_plan AS [QueryPlan]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
ORDER BY qs.total_logical_reads DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Query to get the top 10 most expensive TSQL CPU consumers.
SELECT TOP(10) DB_NAME(t.[dbid]) AS [Database], 
REPLACE(REPLACE(LEFT(t.[text], 255), CHAR(10),''), CHAR(13),'') AS [ShortQueryText],  
qs.total_worker_time AS [Total Worker Time], qs.min_worker_time AS [MinWorkerTime],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.max_worker_time AS [MaxWorkerTime], 
qs.min_elapsed_time AS [MinElapsedTime], 
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime], 
qs.max_elapsed_time AS [MaxElapsedTime],
qs.min_logical_reads AS [MinLogicalReads],
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.max_logical_reads AS [MaxLogicalReads], 
qs.execution_count AS [ExecutionCount],
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX], 
qs.creation_time AS [CreationTime]
,t.[text] AS [Query Text], qp.query_plan AS [QueryPlan]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Run the query below to get the top 10 most  TSQL calls.
SELECT TOP(10) LEFT(t.[text], 50) AS [ShortQueryText],
qs.execution_count AS [ExecutionCount],
qs.total_logical_reads AS [TotalLogicalReads],
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.total_elapsed_time AS [TotalElapsedTime],
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime],
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX], 
qs.creation_time AS [CreationTime]
,t.[text] AS [CompleteQueryText], 
qp.query_plan AS [Query Plan] 
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
WHERE t.dbid = DB_ID()
ORDER BY [ExecutionCount] DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Run the query below to get the top 10 stored procedures by average variable time:
SELECT TOP(10) p.name AS [SPName],
qs.min_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime], 
qs.max_elapsed_time, qs.last_elapsed_time, qs.total_elapsed_time, qs.execution_count, 
ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.total_worker_time AS [TotalWorkerTime],
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX],
FORMAT(qs.last_execution_time, 'yyyy-MM-dd HH:mm:ss', 'en-US') AS [LastExecutionTime], 
FORMAT(qs.cached_time, 'yyyy-MM-dd HH:mm:ss', 'en-US') AS [PlanCachedTime]
,qp.query_plan AS [QueryPlan]
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.database_id = DB_ID()
AND DATEDIFF(Minute, qs.cached_time, GETDATE()) > 0
ORDER BY [AvgElapsedTime] DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Run the query below to get the top 10 most expensive stored procedures by CPU.
SELECT TOP(10) p.name AS [SPName], 
qs.total_worker_time AS [TotalWorkerTime], 
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count AS [ExecutionCount], 
ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime],
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX],
FORMAT(qs.last_execution_time, 'yyyy-MM-dd HH:mm:ss', 'en-US') AS [LastExecutionTime], 
FORMAT(qs.cached_time, 'yyyy-MM-dd HH:mm:ss', 'en-US') AS [PlanCachedTime]
,qp.query_plan AS [Query Plan]
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.database_id = DB_ID()
AND DATEDIFF(Minute, qs.cached_time, GETDATE()) > 0
ORDER BY qs.total_worker_time DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Run the query below to get the top 10 most executed stored procedures.
SELECT TOP(10) p.name AS [SPName], 
qs.execution_count AS [ExecutionCount],
ISNULL(qs.execution_count/DATEDIFF(Minute, qs.cached_time, GETDATE()), 0) AS [Calls/Minute],
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],    
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%%' THEN 1 ELSE 0 END AS [HasMissingIX],
FORMAT(qs.last_execution_time, 'yyyy-MM-dd HH:mm:ss', 'en-US') AS [LastExecutionTime], 
FORMAT(qs.cached_time, 'yyyy-MM-dd HH:mm:ss', 'en-US') AS [PlanCachedTime]
,qp.query_plan AS [QueryPlan]
FROM sys.procedures AS p WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
ON p.[object_id] = qs.[object_id]
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.database_id = DB_ID()
AND DATEDIFF(Minute, qs.cached_time, GETDATE()) > 0
ORDER BY [ExecutionCount] DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Run the query below to get the top 10 most expensive store procudere calls – by Average I/O.
SELECT TOP(10) OBJECT_NAME(qt.objectid, dbid) AS [SPName],
(qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [AvgIO], 
qs.execution_count AS [ExecutionCount],
SUBSTRING(qt.[text],qs.statement_start_offset/2,
(CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) AS [QueryText]	
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.[dbid] = DB_ID()
ORDER BY [AvgIO] DESC OPTION (RECOMPILE)
---------------------------------------------------------------------------------------------
--Disk space
SELECT DISTINCT 
volume_mount_point [Disk Mount Point], 
file_system_type [File System Type], 
logical_volume_name as [Logical Drive Name], 
CONVERT(DECIMAL(18,2),total_bytes/1073741824.0) AS [Total Size in GB], ---1GB = 1073741824 bytes
CONVERT(DECIMAL(18,2),available_bytes/1073741824.0) AS [Available Size in GB],  
CAST(CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %] 
FROM sys.master_files 
CROSS APPLY sys.dm_os_volume_stats(database_id, file_id)
---------------------------------------------------------------------------------------------
--Total memory and available memory
SELECT
(total_physical_memory_kb/1024) AS Total_OS_Memory_MB,
(available_physical_memory_kb/1024)  AS Available_OS_Memory_MB
FROM sys.dm_os_sys_memory;
---------------------------------------------------------------------------------------------
--Get physical ram used by SQL server
SELECT (physical_memory_in_use_kb/1024) AS Used_Memory_By_SqlServer_MB
FROM sys.dm_os_process_memory
---------------------------------------------------------------------------------------------
SELECT  
(physical_memory_in_use_kb/1024) AS Memory_used_by_Sqlserver_MB,  
(locked_page_allocations_kb/1024) AS Locked_pages_used_by_Sqlserver_MB,  
(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
process_physical_memory_low,  
process_virtual_memory_low  
FROM sys.dm_os_process_memory;
---------------------------------------------------------------------------------------------
--Get current memory utilisation and target memory available
SELECT
sqlserver_start_time,
(committed_kb/1024) AS Total_Server_Memory_MB,
(committed_target_kb/1024)  AS Target_Server_Memory_MB
FROM sys.dm_os_sys_info;
---------------------------------------------------------------------------------------------
--One minute pinger query
SELECT s.session_id,r.STATUS,r.command
,COALESCE(QUOTENAME(DB_NAME(st.dbid)) + N'.' + QUOTENAME(OBJECT_SCHEMA_NAME(st.objectid, st.dbid)) + N'.' +
QUOTENAME(OBJECT_NAME(st.objectid, st.dbid)), '') AS 'stored_proc'
,r.blocking_session_id AS 'blocked_by',r.wait_type,r.wait_resource
,CONVERT(VARCHAR, DATEADD(ms, r.wait_time, 0), 8) AS 'wait_time',r.cpu_time,r.logical_reads
,r.reads,r.writes,CONVERT(varchar, (r.total_elapsed_time/1000 / 86400))+ 'd ' +
CONVERT(VARCHAR, DATEADD(ms, r.total_elapsed_time, 0), 8)   AS 'elapsed_time'
,CAST((
'<?query --  ' + CHAR(13) + CHAR(13) + Substring(st.TEXT, (r.statement_start_offset / 2) + 1, (
(
CASE r.statement_end_offset WHEN - 1 THEN Datalength(st.TEXT) ELSE r.statement_end_offset END - r.statement_start_offset
) / 2
) + 1) + CHAR(13) + CHAR(13) + '--?>'
) AS XML) AS 'query_text'
,qp.query_plan AS 'xml_plan'  ,s.login_name,s.host_name,s.program_name,
s.host_process_id,s.last_request_end_time,s.login_time,r.open_transaction_count
FROM sys.dm_exec_sessions AS s INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp 
WHERE r.wait_type NOT LIKE 'SP_SERVER_DIAGNOSTICS%' OR r.session_id != @@SPID
ORDER BY r.cpu_time DESC ,r.STATUS ,r.blocking_session_id,s.session_id
---------------------------------------------------------------------------------------------
SELECT r.session_id ,r.cpu_time, r.total_elapsed_time ,r.logical_reads, r.writes, r.dop,
st.TEXT AS batch_text ,SUBSTRING(st.TEXT, statement_start_offset / 2 + 1, ( ( CASE WHEN r.statement_end_offset = - 1 THEN (LEN(CONVERT(NVARCHAR(max), st.TEXT)) * 2) ELSE r.statement_end_offset END ) - r.statement_start_offset ) / 2 + 1) AS statement_text ,qp.query_plan AS 'XML Plan'  FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp ORDER BY cpu_time DESC
---------------------------------------------------------------------------------------------
--See statistics for a specific table
SELECT Object_name(s.object_id) AS table_name, 
       s.NAME                   AS stat_name, 
       s.is_temporary, 
       ds.last_updated, 
       ds.modification_counter, 
       ds.rows, 
       ds.rows_sampled 
FROM   sys.stats AS s (nolock) 
       CROSS apply sys.Dm_db_stats_properties(s.object_id, s.stats_id) AS ds 
WHERE  Object_name(s.object_id) = 'tbltest'
---------------------------------------------------------------------------------------------
--Configure max memory
DECLARE @maxMem INT = 2147483647 --Max. memory for SQL Server instance in MB
EXEC sp_configure 'show advanced options', 1
RECONFIGURE

EXEC sp_configure 'max server memory', @maxMem
RECONFIGURE
---------------------------------------------------------------------------------------------
--Memory query
SELECT 
physical_memory_in_use_kb/1024 AS sql_physical_memory_in_use_MB, 
    large_page_allocations_kb/1024 AS sql_large_page_allocations_MB, 
    locked_page_allocations_kb/1024 AS sql_locked_page_allocations_MB,
    virtual_address_space_reserved_kb/1024 AS sql_VAS_reserved_MB, 
    virtual_address_space_committed_kb/1024 AS sql_VAS_committed_MB, 
    virtual_address_space_available_kb/1024 AS sql_VAS_available_MB,
    page_fault_count AS sql_page_fault_count,
    memory_utilization_percentage AS sql_memory_utilization_percentage, 
    process_physical_memory_low AS sql_process_physical_memory_low, 
    process_virtual_memory_low AS sql_process_virtual_memory_low
FROM sys.dm_os_process_memory;
---------------------------------------------------------------------------------------------
--Query to check current state and last failover timings
DECLARE @FileName NVARCHAR(4000)
SELECT @FileName = target_data.value('(EventFileTarget/File/@name)[1]', 'nvarchar(4000)')
FROM (
SELECT CAST(target_data AS XML) target_data
FROM sys.dm_xe_sessions s
JOIN sys.dm_xe_session_targets t
ON s.address = t.event_session_address
WHERE s.name = N'AlwaysOn_health'
) ft;

WITH base
AS (
SELECT XEData.value('(event/@timestamp)[1]', 'datetime2(3)') AS event_timestamp
,XEData.value('(event/data/text)[1]', 'VARCHAR(255)') AS previous_state
,XEData.value('(event/data/text)[2]', 'VARCHAR(255)') AS current_state
,ar.replica_server_name
FROM (
SELECT CAST(event_data AS XML) XEData
,*
FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
WHERE object_name = 'availability_replica_state_change'
) event_data
JOIN sys.availability_replicas ar
ON ar.replica_id = XEData.value('(event/data/value)[5]', 'VARCHAR(255)')
)
SELECT DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), event_timestamp) AS event_timestamp
,previous_state
,current_state
,replica_server_name
FROM base
ORDER BY event_timestamp DESC;
---------------------------------------------------------------------------------------------
--check backup and location of file
SELECT bs.database_name, bs.first_lsn, bs.last_lsn , 
    backuptype = CASE 
        WHEN bs.type = 'D' AND bs.is_copy_only = 0 THEN 'Full Database'
        WHEN bs.type = 'D' AND bs.is_copy_only = 1 THEN 'Full Copy-Only Database'
        WHEN bs.type = 'I' THEN 'Differential database backup'
        WHEN bs.type = 'L' THEN 'Transaction Log'
        WHEN bs.type = 'F' THEN 'File or filegroup'
        WHEN bs.type = 'G' THEN 'Differential file'
        WHEN bs.type = 'P' THEN 'Partial'
        WHEN bs.type = 'Q' THEN 'Differential partial'
        END + ' Backup',
    CASE bf.device_type
        WHEN 2 THEN 'Disk'
        WHEN 5 THEN 'Tape'
        WHEN 7 THEN 'Virtual device'
        WHEN 9 THEN 'Azure Storage'
        WHEN 105 THEN 'A permanent backup device'
        ELSE 'Other Device'
        END AS DeviceType,
    bms.software_name AS backup_software,
    bs.recovery_model,
    bs.compatibility_level,
    BackupStartDate = bs.Backup_Start_Date,
    BackupFinishDate = bs.Backup_Finish_Date,
    LatestBackupLocation = bf.physical_device_name,
    backup_size_mb = CONVERT(DECIMAL(10, 2), bs.backup_size / 1024. / 1024.),
    compressed_backup_size_mb = CONVERT(DECIMAL(10, 2), bs.compressed_backup_size / 1024. / 1024.),
    database_backup_lsn, -- For tlog and differential backups, this is the checkpoint_lsn of the FULL backup it is based on.
    checkpoint_lsn,
    begins_log_chain,
    bms.is_password_protected
FROM msdb.dbo.backupset bs
LEFT JOIN msdb.dbo.backupmediafamily bf
    ON bs.[media_set_id] = bf.[media_set_id]
INNER JOIN msdb.dbo.backupmediaset bms
    ON bs.[media_set_id] = bms.[media_set_id]
WHERE  database_name = 'SSSPL' -- and bs.type='L' --and first_lsn <= 6402270000036885600001 
---------------------------------------------------------------------------------------------
--Change remote connection timeout
EXEC SP_CONFIGURE 'remote query timeout', 0
reconfigure
EXEC sp_configure
---------------------------------------------------------------------------------------------
--Make database read only
USE [master]
GO
ALTER DATABASE [TESTDB] SET READ_ONLY WITH NO_WAIT
GO
---------------------------------------------------------------------------------------------
--Make database read and write
USE [master]
GO
ALTER DATABASE [TESTDB] SET READ_WRITE WITH NO_WAIT
GO
---------------------------------------------------------------------------------------------
--The transactions that left uncommitted from the database side and disconnected from the application side is called Orphaned Transactions.
--Get all active transactions
SELECT transaction_id , 
	   database_ID , 
	   database_Transaction_Begin_Time,
	   database_transaction_log_record_count,
	   database_transaction_begin_lsn ,
	   database_transaction_last_lsn,
	  CASE database_transaction_state
         WHEN 1 THEN 'The transaction has not been initialized.'
         WHEN 3 THEN 'The transaction has been initialized but has not generated any log recorst.'
         WHEN 4 THEN 'The transaction has generated log records.'
         WHEN 5 THEN 'The transaction has been prepared.'
         WHEN 10 THEN 'The transaction has been committed.'
         WHEN 11 THEN 'The transaction has been rolled back.'
         WHEN 12 THEN 'The transaction is being committed. In this state the log record is being generated, but it has not been materialized or persisted'
      END database_transaction_state
FROM   sys.dm_tran_database_transactions 
---------------------------------------------------------------------------------------------
--Get the session id which are having orphaned transactions
SELECT   session_id
FROM    sys.dm_tran_session_transactions
WHERE transaction_id in (874,877,879,881,886)
---------------------------------------------------------------------------------------------
--Monitor tempdb
SELECT 
(SUM(unallocated_extent_page_count)*1.0/128) AS [Free space(MB)]
,(SUM(version_store_reserved_page_count)*1.0/128)  AS [Used Space by VersionStore(MB)]
,(SUM(internal_object_reserved_page_count)*1.0/128)  AS [Used Space by InternalObjects(MB)]
,(SUM(user_object_reserved_page_count)*1.0/128)  AS [Used Space by UserObjects(MB)]
FROM tempdb.sys.dm_db_file_space_usage;
---------------------------------------------------------------------------------------------
--Monitor tempdb for specific session
select * from sys.dm_db_session_space_usage
where session_id=187
---------------------------------------------------------------------------------------------
--Kill all sessions in specific database
DECLARE @kill varchar(8000) = '';  
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('FKHPDBAdmin') and session_id<>session_id

EXEC(@kill);
---------------------------------------------------------------------------------------------
--Number of connections per database
SELECT     DB_NAME(dbid) as DBName,     COUNT(dbid) as NumberOfConnections,loginame as LoginName
FROM sys.sysprocesses
WHERE     dbid > 0
GROUP BY dbid, loginame
---------------------------------------------------------------------------------------------





concurrent queries and running queries
what is the latency?
what is the CPU usage?


Get it reviewed 
Restore it back to database  
Alert system for failed backup
Get the similar RPO and RTO as of RDS


NFR testing- points to check
    Max running quries
    Max connections
    What is the max cpu when max running queries hit?
    What is the latency?
    Match RDS current benchmark
    Find the choke point in EC2

cases
1 million inserts
5 sample queries    
Parallel queries to fire      
Check for synthetic testing tool 








