--This will iterate through all the databases.
EXEC sp_MSforeachdb 'USE [?] SELECT ''[?]'' as DBname'

--Update the stats for the current database.
sp_updatestats

--Update the stats for all databases all tables.
sp_MSforeachdb 'use [?]; exec sp_updatestats'


--Update a specific database statistics.
DECLARE @TSQL nvarchar(2000)

-- Filtering system databases and user databases from execution.
SET @TSQL = '
IF (DB_ID(''?'') > 4
   AND ''?'' NOT IN(''distribution'',''SSISDB'',''ReportServer'',''ReportServertempdb'')
   )
BEGIN
   PRINT ''********** Rebuilding statistics on database: [?] ************''
   USE [?]; exec sp_updatestats
END
'
-- Executing TSQL for each database
EXEC sp_MSforeachdb @TSQL

