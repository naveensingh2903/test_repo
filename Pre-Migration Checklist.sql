/*
Pre-Migration Checklist
1. Analyze the disk space of the target server for the new database, if the disk space is not enough add more space on the target server
2. Confirm the data and log file location for the target server
*3. Collect the information about the Database properties (Auto Stats, DB Owner, Recovery Model, Compatibility level, Trustworthy option etc)
4. Collect the information of dependent applications, make sure application services will be stopped during the database migration
5. Collect the information of database logins, users and their permissions. (Optional)
6. Check the database for the Orphan users if any
7. Check the SQL Server for any dependent objects (SQL Agent Jobs and Linked Servers)
8. Check, if the database is part of any maintenance plan
*/

--Script to check the disk size
-- Procedure to check disc free space
exec master..xp_fixeddrives

-- To Check database size
exec sp_helpdb [dbName]

--We can use the below command to check file size
use [dbName]
select str(sum(convert(dec(17,2),size)) / 128,10,2)  + 'MB'
from dbo.sysfiles
GO

--Script to check database properties
select 
 sysDB.database_id,
 sysDB.Name as 'Database Name',
 syslogin.Name as 'DB Owner',
 sysDB.state_desc,
 sysDB.recovery_model_desc,
 sysDB.collation_name, 
 sysDB.user_access_desc,
 sysDB.compatibility_level, 
 sysDB.is_read_only,
 sysDB.is_auto_close_on,
 sysDB.is_auto_shrink_on,
 sysDB.is_auto_create_stats_on,
 sysDB.is_auto_update_stats_on,
 sysDB.is_fulltext_enabled,
 sysDB.is_trustworthy_on
from sys.databases sysDB
INNER JOIN sys.syslogins syslogin ON sysDB.owner_sid = syslogin.sid

--Script to check orphan users 
sp_change_users_login 'report'
GO

--To list orphaned users 
SELECT dp.type_desc, dp.sid, dp.name AS user_name  
FROM sys.database_principals AS dp  
LEFT JOIN sys.server_principals AS sp  
    ON dp.sid = sp.sid  
WHERE sp.sid IS NULL  
    AND dp.authentication_type_desc = 'INSTANCE';  

--To fix the orphaned users, to run the below command we need sysadmin server role
--Command to map an orphaned users
USE database 
sp_change_users_login @Action='update_one', 
@UserNamePattern='TestUser1', 
@LoginName='TestUser1'
GO

--If the login_name and user_name are same then we can use the below command 
EXEC sp_change_users_login 'Auto_Fix', 'TestUser2'

--Script to check and fix orphan users
-- Script to check the orphan user
EXEC sp_change_users_login 'Report'

--Script to list linked services 
select  * from sys.sysservers

--Script to list dependent jobs 
select  distinct name,database_name
from sysjobs sj
INNER JOIN sysjobsteps sjt on sj.job_id = sjt.job_id

/*
--Database Migration checklist
1. Stop the application services
2. Change the database to read-only mode (Optional)
3. Take the latest backup of all the databases involved in migration
4. Restore the databases on the target server on the appropriate drives
5. Cross check the database properties as per the database property script output, change the database properties as per the pre migration- checklist
6. Execute the output of Login transfer script on the target server, to create logins on the target server you can get the code from this technet article: http://support.microsoft.com/kb/246133.
7. Check for Orphan Users and Fix Orphan Users
8. Execute DBCC UPDATEUSAGE on the restored database.
9. Rebuild Indexes (Optional) As per the requirement and time window you can execute this option.
10. Update index statistics.
11. Recompile procedures.
12. Start the application services, check the application functionality and check the Windows event logs.
13. Check the SQL Server Error Log for login failures and other errors.
14. Once the application team confirms that application is running fine take the databases offline on the source server or make them read only.

*/

--7 
--Use below code to fix the Orphan User issue
DECLARE @username varchar(25)
DECLARE fixusers CURSOR 
FOR
SELECT UserName = name FROM sysusers
WHERE issqluser = 1 and (sid is not null and sid <> 0x0)
and suser_sname(sid) is null
ORDER BY name
OPEN fixusers
FETCH NEXT FROM fixusers
INTO @username
WHILE @@FETCH_STATUS = 0
BEGIN
EXEC sp_change_users_login 'update_one', @username, @username
FETCH NEXT FROM fixusers
INTO @username
END
CLOSE fixusers
DEALLOCATE fixusers


--8 
DBCC UPDATEUSAGE('database_name') WITH COUNT_ROWS
DBCC CHECKDB 
OR
DBCC CHECKDB('database_name') WITH ALL_ERRORMSGS

--11 Recompile all Stored Procedures and Triggers on a Database
USE database;
GO
EXEC sp_MSforeachtable @command1="EXEC sp_recompile '?'";
GO

--13 
EXEC xp_readerrorlog 0,1,"Error",Null

--14 
-- Script to make the database readonly
USE [master]
GO
ALTER DATABASE [DBName] SET  READ_ONLY WITH NO_WAIT
GO
ALTER DATABASE [DBName] SET  READ_ONLY 
GO
-- Script to take the database offline
EXEC sp_dboption N'DBName', N'offline', N'true'
OR
ALTER DATABASE [DBName] SET OFFLINE WITH
ROLLBACK IMMEDIATE
