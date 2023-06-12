--EC2 master key and certificate
-- create master key and certificate
-- Create below master key and certificate in master database 

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '!@Api1401@2015!!';
GO

--Create certificate
CREATE CERTIFICATE SQLbackupcert
WITH SUBJECT = 'SQL Backup Certificate',EXPIRY_DATE = '20231231';
GO

--Export the backup certificate to a file
BACKUP CERTIFICATE SQLbackupcert TO FILE = 'D:\dbbackup\SSMPLINVENTORY\SQLbackupCert.cert'
WITH PRIVATE KEY (
FILE = 'D:\dbbackup\SSMPLINVENTORY\SQLbackupCert.key',
ENCRYPTION BY PASSWORD = 'Api1401@2015!!')

--Backup the database
BACKUP DATABASE [SMPLINVENTORY]
TO DISK = 'D:\dbbackup\SSMPLINVENTORY\SMPLINVENTORY.bak'
WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = SQLbackupcert)
,stats = 10

--select convert(varchar, getdate(), 34)
declare @a varchar(20) 
set @a= (select replace(convert(varchar, getdate(), 111),'/','_') + '_' +replace(convert(varchar, getdate(),108),':','_'))
print @a 

declare @loc varchar(100)
set @loc='D:\dbbackup\SSMPLINVENTORY\tran_file\SSMPLINVENTORY_'+@a+'.TRN'
print @loc

BACKUP LOG [SMPLINVENTORY] TO DISK = @loc
WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = SQLbackupcert)
,stats = 5

--Drop certificate and master key
DROP CERTIFICATE SQLbackupcert;

DROP MASTER KEY;

--Check all certificates 
select * from sys.certificates 


--Copy the data from local to s3
--list all the existing buckets 
aws s3 ls 

--copy single file to s3 bucket
aws s3 cp file.txt s3://<bucket name>

--Copy multiple file
aws s3 cp <local directory path> s3://<bucket name> -RECURSIVE

--Copy multiple file but exclude a specific file
aws s3 cp <local directory path>s3://<bucket name> --recursive --exclude "*.jpg"

aws s3 cp D:/dbbackup/testdb2.bak s3://ss-mssql-backup/backupfolder/

D:\dbbackup\SSMPLINVENTORY\tran_file\


D:\dbbackup\SSMPLINVENTORY\all_files

D:\dbbackup\SSMPLINVENTORY\tran_file

move D:\dbbackup\SSMPLINVENTORY\tran_file\* D:\dbbackup\SSMPLINVENTORY\all_files

aws s3 cp D:\dbbackup\SSMPLINVENTORY\tran_file\* s3://ss-mssql-backup/backupfolder/

