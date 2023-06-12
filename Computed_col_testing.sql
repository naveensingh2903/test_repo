--Computed column testing
create table jdbc_computed_test(a int primary key,b int,c as (a*b) )

select * from computed_test 

insert into computed_test values (1,4);
insert into computed_test values (2,4);
insert into computed_test values (3,4);
insert into computed_test values (4,4);
insert into computed_test values (5,4);

EXEC sys.sp_cdc_enable_table  
@source_schema = N'dbo',  
@source_name   = N'jdbc_computed_test',  
@role_name     = NULL,  
@supports_net_changes = 1  
GO  


--User defined data types testing
create table jdbc_uddt_test(a state primary key,b pincode,c flag,d emailid)

select * from jdbc_uddt_test 

EXEC sys.sp_cdc_enable_table  
@source_schema = N'dbo',  
@source_name   = N'jdbc_uddt_test',  
@role_name     = NULL,  
@supports_net_changes = 1  
GO  

insert into jdbc_uddt_test values ('1',123456,1,'thinkpad@gmail.com');
insert into jdbc_uddt_test values ('a',124567,2,'thinkpad@gmail.com');
insert into jdbc_uddt_test values ('3',123678,3,'thinkpad@gmail.com');

