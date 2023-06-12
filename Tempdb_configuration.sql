--Tempdb configuration 

--Configure tempdb to reduce contention
alter database <database name> MODIFY FILEGROUP [PRIMARY] AUTOGROW_ALL_FILES

--Configuring and using memory-optimized tempdb metadata
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA = ON;

--To check if it is memory optimised or not 
SELECT SERVERPROPERTY('IsTempdbMetadataMemoryOptimized');

--Create 2 data files and log files to new location 
ALTER DATABASE tempdb 
MODIFY FILE (NAME = tempdev, FILENAME = 'T:\TempDB\Data\tempdb.mdf');
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = temp2, FILENAME = 'T:\TempDB\Data\tempdb_mssql_2.ndf');
GO
ALTER DATABASE tempdb 
MODIFY FILE (NAME = templog, FILENAME = 'T:\TempDB\Log\templog.ldf');

--Change tempdb location 
USE master
GO
ALTER DATABASE TempDB MODIFY FILE (NAME = tempdev, FILENAME = 'T:\tempdb.mdf',SIZE =
 524288KB)
GO
ALTER DATABASE TempDB MODIFY FILE (NAME = temp2, FILENAME = 'T:
\tempdb_mssql_2.ndf',SIZE = 524288KB)
GO
ALTER DATABASE TempDB MODIFY FILE (NAME = temp3, FILENAME = 'T:
\tempdb_mssql_3.ndf',SIZE = 524288KB)
GO
ALTER DATABASE TempDB MODIFY FILE (NAME = temp4, FILENAME = 'T:
\tempdb_mssql_4.ndf',SIZE = 524288KB)
GO
ALTER DATABASE TempDB MODIFY FILE (NAME = templog, FILENAME = 'T:\templog.ldf')
GO

--Monitoring tempdb use
-- Determining the amount of free space in tempdb
SELECT SUM(unallocated_extent_page_count) AS [free pages],
  (SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Determining the amount of space used by the version store
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
  (SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Determining the amount of space used by internal objects
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
  (SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Determining the amount of space used by user objects
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
  (SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

-- Obtaining the space consumed by internal objects in all currently running tasks in each session
SELECT session_id,
  SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
  SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count
FROM sys.dm_db_task_space_usage
GROUP BY session_id;

-- Obtaining the space consumed by internal objects in the current session for both running and completed tasks
SELECT R2.session_id,
  R1.internal_objects_alloc_page_count
  + SUM(R2.internal_objects_alloc_page_count) AS session_internal_objects_alloc_page_count,
  R1.internal_objects_dealloc_page_count
  + SUM(R2.internal_objects_dealloc_page_count) AS session_internal_objects_dealloc_page_count
FROM sys.dm_db_session_space_usage AS R1
INNER JOIN sys.dm_db_task_space_usage AS R2 ON R1.session_id = R2.session_id
GROUP BY R2.session_id, R1.internal_objects_alloc_page_count,
  R1.internal_objects_dealloc_page_count;


--Server configuration
select @@SERVERNAME,
SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),
cpu_count,
hyperthread_ratio,
softnuma_configuration,
softnuma_configuration_desc,
socket_count,
numa_node_count
from
sys.dm_os_sys_info

sp_configure 'max_degree_of_parallelism';

sp_configure 'cost_threshold_for_parallelism'

--MAXDOP recoommendation
declare @hyperthreadingRatio bit
declare @logicalCPUs int
declare @HTEnabled int
declare @physicalCPU int
declare @SOCKET int
declare @logicalCPUPerNuma int
declare @NoOfNUMA int

select @logicalCPUs = cpu_count -- [Logical CPU Count]
    ,@hyperthreadingRatio = hyperthread_ratio --  [Hyperthread Ratio]
    ,@physicalCPU = cpu_count / hyperthread_ratio -- [Physical CPU Count]
    ,@HTEnabled = case 
        when cpu_count > hyperthread_ratio
            then 1
        else 0
        end -- HTEnabled
from sys.dm_os_sys_info
option (recompile);

select @logicalCPUPerNuma = COUNT(parent_node_id) -- [NumberOfLogicalProcessorsPerNuma]
from sys.dm_os_schedulers
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64
group by parent_node_id
option (recompile);

select @NoOfNUMA = count(distinct parent_node_id)
from sys.dm_os_schedulers -- find NO OF NUMA Nodes 
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64

-- Report the recommendations ....
declare @hyperthreadingRatio bit
declare @logicalCPUs int
declare @HTEnabled int
declare @physicalCPU int
declare @SOCKET int
declare @logicalCPUPerNuma int
declare @NoOfNUMA int

select @logicalCPUs = cpu_count -- [Logical CPU Count]
    ,@hyperthreadingRatio = hyperthread_ratio --  [Hyperthread Ratio]
    ,@physicalCPU = cpu_count / hyperthread_ratio -- [Physical CPU Count]
    ,@HTEnabled = case 
        when cpu_count > hyperthread_ratio
            then 1
        else 0
        end -- HTEnabled
from sys.dm_os_sys_info
option (recompile);

select @logicalCPUPerNuma = COUNT(parent_node_id) -- [NumberOfLogicalProcessorsPerNuma]
from sys.dm_os_schedulers
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64
group by parent_node_id
option (recompile);

select @NoOfNUMA = count(distinct parent_node_id)
from sys.dm_os_schedulers -- find NO OF NUMA Nodes 
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64

-- Report the recommendations ....
select
    --- 8 or less processors and NO HT enabled
    case 
        when @logicalCPUs < 8
            and @HTEnabled = 0
            then 'MAXDOP setting should be : ' + CAST(@logicalCPUs as varchar(3))
                --- 8 or more processors and NO HT enabled
        when @logicalCPUs >= 8
            and @HTEnabled = 0
            then 'MAXDOP setting should be : 8'
                --- 8 or more processors and HT enabled and NO NUMA
        when @logicalCPUs >= 8
            and @HTEnabled = 1
            and @NoofNUMA = 1
            then 'MaxDop setting should be : ' + CAST(@logicalCPUPerNuma / @physicalCPU as varchar(3))
                --- 8 or more processors and HT enabled and NUMA
        when @logicalCPUs >= 8
            and @HTEnabled = 1
            and @NoofNUMA > 1
            then 'MaxDop setting should be : ' + CAST(@logicalCPUPerNuma / @physicalCPU as varchar(3))
        else ''
        end as Recommendations

--compatibility level 
select name, compatibility_level from sys.databases


