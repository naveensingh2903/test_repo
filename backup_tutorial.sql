--Full backup 
BACKUP DATABASE dvdrental TO DISK = 'c:\backup\dvdrental.bak'

--Full backup with multiple files
BACKUP DATABASE dvdrental TO 
DISK = 'c:\backup\dvdrental_1.bak',
DISK = 'c:\backup\dvdrental_2.bak',
DISK = 'c:\backup\dvdrental_3.bak'

--Full backup with mirror location
BACKUP DATABASE DVDRENTAL TO DISK =	'c:\backup\dvdrental_bak_mir.bak'
MIRROR TO DISK = 'd:\dvdrental_mirror.bak'
WITH FORMAT

--Differential backup
BACKUP DATABASE DVDRENTAL TO DISK = 'c:\backup\diff\dvdrental_2.dif' 
WITH DIFFERENTIAL 

--Differential backup
BACKUP DATABASE DVDRENTAL TO DISK = 'c:\backup\diff\dvdrental_2.bak'
WITH DIFFERENTIAL

--To check recovery model of databases 
select name,recovery_model,recovery_model_desc from sys.databases 

--To change the rcovery model of a database
USE MASTER
ALTER database_name MODEL SET RECOVERY SIMPLE;
ALTER database_name MODEL SET RECOVERY FULL;
ALTER database_name MODEL SET RECOVERY BULK_LOGGED;

--Change recovery model of all databases
EXEC sp_msforeachdb "
IF '?' not in ('tempdb')
begin
    exec ('ALTER DATABASE [?] SET RECOVERY FULL;')
    print '?'
end" 

SELECT name, recovery_model,recovery_model_desc FROM sys.databases

--Query to get mdf and ldf file size
SELECT database_id,CONVERT(VARCHAR(25), DB.name) AS dbName,
(SELECT SUM((size*8)/1024) FROM sys.master_files 
WHERE DB_NAME(database_id) = db.name AND type_desc = 'rows') DATA_MB,
(SELECT SUM((size*8)/1024) FROM sys.master_files 
WHERE DB_NAME(database_id) = db.name AND type_desc = 'log') AS [Log MB] FROM sys.databases DB
WHERE name in (select name from sys.databases)

--Query to get log size of databases 
DBCC SQLPERF(logspace)

--Query to get log info
DBCC LOGINFO

--Query to get mdf and ldf file size
SELECT DB_NAME(database_id) AS database_name, 
    type_desc, 
    name AS FileName, 
    size/128.0 AS CurrentSizeMB
FROM sys.master_files
WHERE database_id > 6 AND type IN (0,1)

--Restore a database from backup file 
RESTORE DATABASE Adventureworks FROM DISK = 'D:\Adventureworks_full.bak'

--Restore a database with norecovery option
RESTORE DATABASE Adventureworks FROM DISK = 'D:\Adventureworks_full.bak' WITH NORECOVERY

--Restore a differential backup
RESTORE DATABASE Adventureworks FROM DISK = 'D:\Adventureworks_full.bak' WITH NORECOVERY
GO
RESTORE DATABASE Adventureworks FROM DISK = 'D:\AdventureWorks_diff.dif' WITH RECOVERY
GO

--Restore a transactional log backup
RESTORE DATABASE Adventureworks FROM DISK = 'D:\Adventureworks_full.bak' WITH NORECOVERY
GO
RESTORE DATABASE Adventureworks FROM DISK = 'D:\AdventureWorks_diff.dif' WITH NORECOVERY
GO
RESTORE LOG Adventureworks FROM DISK = 'D:\Adventureworks_log1.trn' WITH NORECOVERY
GO
RESTORE LOG Adventureworks FROM DISK = 'D:\Adventureworks_log2.trn' WITH RECOVERY
GO

--To check the vlf files 
USE dvdrental;
CHECKPOINT
select * from sys.dm_db_log_info(db_id('dvdrental'))

--To reduce the size of log file 
USE database_name
DBCC SHRINKFILE (AdventureWorksDW2017_log , 1)

DBCC SHRINKFILE (N'StackOverflow2010_log' , 0, TRUNCATEONLY)
