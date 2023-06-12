CREATE PROC dbo.sp_log_space
AS 
DBCC SQLPERF(logspace) 
GO 
  
CREATE TABLE dbo.tb_space_stats1
( 
   id INT IDENTITY (1,1), 
   logDate datetime DEFAULT GETDATE(), 
   databaseName sysname, 
   logSize decimal(18,5), 
   logUsed decimal(18,5) 
) 
GO 
 
alter PROC dbo.sp_log_space_history
AS 
SET NOCOUNT ON 

CREATE TABLE #temp_table
( 
   databaseName sysname, 
   logSize decimal(18,5), 
   logUsed decimal(18,5), 
   status INT 
) 

INSERT INTO #temp_table 
       EXEC sp_log_space

INSERT INTO dbo.tb_space_stats1 (databaseName, logSize, logUsed) 
SELECT databasename, logSize, logUsed 
FROM #temp_table 

DROP TABLE #temp_table 
GO

exec dbo.sp_log_space

exec dbo.sp_log_space_history

select * from dbo.tb_space_stats1

dbcc sqlperf(logspace)
