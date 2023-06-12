--Testing git 
select * from sys.dm_exec_sessions where session_id between 100 and 120 

--Testing git branch 
--Added "test" branch

--32 different datatypes 
select distinct ty.name from sys.columns col join sys.types ty on col.system_type_id=ty.system_type_id 
where col.object_id in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE')

--1045 tables are using user defined datatypes
select count(distinct col.object_id) from sys.columns col join sys.types ty on col.system_type_id=ty.system_type_id 
where col.object_id in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE') and col.name in ('AddressLine'
,'MobileNo'
,'EmailId'
,'PinCode'
,'ProductUnit'
,'uniqueidentifier'
,'Country'
,'City'
,'State')

--1338 tables are having identity column
SELECT 
OBJECT_SCHEMA_NAME(tables.object_id, db_id())
AS SchemaName,
tables.name As TableName,
columns.name as ColumnName
FROM sys.tables tables 
JOIN sys.columns columns 
ON tables.object_id=columns.object_id
WHERE columns.is_identity=1 and tables.object_id in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE')

--32 different datatypes 
--1045 tables are using user defined datatypes
--1338 tables are having identity column


DECLARE  @SqlStatment AS NVARCHAR(1000) 
DECLARE  @PhoneIdType AS INT
DECLARE  @Result AS INT 
    
SET @SqlStatment='SELECT @RowNumber= COUNT(PhoneNumber) from Person.PersonPhone WHERE PhoneNumberTypeID=@PhoneType'

SET @PhoneIdType=1

EXEC sp_executesql @SqlStatment , N'@PhoneType INT,@RowNumber INT OUTPUT' , @PhoneType=@PhoneIdType ,@RowNumber=@Result OUTPUT
    
SELECT @Result AS [TableRowNumber]

select  object_id,object_name(col.object_id) table_name,
col.name col_name,ty.name data_type,col.max_length from sys.columns col join sys.types ty on col.user_type_id=ty.user_type_id
where ty.name='varchar' and ty.is_user_defined<>1 and col.object_id in ('1179919325', '1784497536', '1408776126', '1392776069', '1706541213', '728441719', '1418540187', '1948742195', '7827240', '39827354', '699305701', '715305758', '1586260856', '1721265387', '1914594009', '2002822197', '358552611', '869174442', '947794734', '979794848', '1851153640', '1596076972', '1927170111', '1224443486', '1910297865', '1958298036', '103827582', '487217036', '570745386', '618745557', '654885650', '661785615', '954746754', '969366818', '986746868', '1066083184', '1130083412', '1205735498', '1238503691', '1239219715', '1569440665', '1601440779', '1610749091', '1662681021', '1831989903', '1872322030', '2044794592', '2054298378', '2102298549', '84507680', '601365507', '933734529', '354816326', '359984659', '1560548793', '2050926478', '132403741', '212404026', '377312654', '1013838924', '708509903', '204840092', '274308237', '309784361', '373784589', '459356901', '1032442802', '1653073125', '2015554464', '2132462921', '1186871345', '1319727804', '1433368471', '1539796843', '1915466198', '2101842800')
order by 5 desc
