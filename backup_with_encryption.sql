--full backup 
BACKUP DATABASE AdventureWorks TO DISK = 'C:\AdventureWorks.BAK'
GO

--Transactional log backup
BACKUP LOG AdventureWorks TO DISK = 'C:\AdventureWorks.TRN'
GO

--Differential backup
BACKUP DATABASE AdventureWorks TO DISK = 'C:\AdventureWorks.DIF' WITH DIFFERENTIAL
GO

--Full backup with multiple files
BACKUP DATABASE sql_database TO 
DISK = 'f:\PowerSQL\sql_database_1.BAK', 
DISK = 'f:\PowerSQL\sql_database_2.BAK', 
DISK = 'f:\PowerSQL\sql_database_3.BAK', 
DISK = 'f:\PowerSQL\sql_database_4.BAK' 
WITH INIT, NAME = 'FULL sql_database backup', STATS = 5


--Generate master key
USE MASTER;
GO
-- create master key and certificate
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '!@Api1401@2015!!';
GO

--Create certificate
CREATE CERTIFICATE SQLShackDBCert
    WITH SUBJECT = 'SQLShackDB Backup Certificate';
GO

--Export the backup certificate to a file
BACKUP CERTIFICATE SQLShackDBCert TO FILE = 'f:\Program Files\SQLShackDBCert.cert'
WITH PRIVATE KEY (
FILE = 'f:\Program Files\SQLShackDBCert.key',
ENCRYPTION BY PASSWORD = 'Api1401@2015!!')

--Backup the database with encryption
BACKUP DATABASE SQLShack
TO DISK = 'g:\Program Files\SQLShack.bak'
WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = SQLShackDBCert)

--Clean up the instance
DROP DATABASE SQLShack;
GO
DROP CERTIFICATE SQLShackDBCert;
GO
DROP MASTER KEY;
GO

--Before restoration, we need to create the certificate and master key on destination server
--Recreate master key and certificate
 CREATE MASTER KEY ENCRYPTION BY PASSWORD = '!@Api1401@2015!!';
GO

--Restore the certificate
CREATE CERTIFICATE SQLShackDBCert
FROM FILE = 'f:\Program Files\SQLShackDBCert.cert'
WITH PRIVATE KEY (FILE = 'f:\Program Files\SQLShackDBCert.key',
DECRYPTION BY PASSWORD = 'Api1401@2015!!');
GO

--Use RESTORE WITH MOVE to move and/or rename database files to a new path.
RESTORE DATABASE SQLShack FROM DISK = 'g:\Program Files\SQLShack.bak'
WITH NORECOVERY,
MOVE 'SQLShack' TO 'f:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\SQLShack_Data.mdf', 
MOVE 'SQLShack_Log' TO 'g:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\SQLShack_Log.ldf', 
REPLACE, STATS = 10;
GO

--Attempt the restore log again
RESTORE LOG SQLShack
FROM DISK = 'g:\Program Files\SQLShackTailLogDB.log';
GO 

--Clean up the instance
DROP DATABASE SQLShack;
GO
DROP CERTIFICATE SQLShackDBCert;
GO
DROP MASTER KEY;
GO



