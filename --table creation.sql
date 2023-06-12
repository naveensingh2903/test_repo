------------------------------------------------------------------------------------------------------
--table creation 
create table metadata 
(id int,object_id varchar(30),schema_name varchar(50),
table_name varchar(100),batch_id int,row_count bigint,primary_key_col varchar(100),Max_of_PK varchar(100),
batch_size bigint,rows_copied bigint,start_time datetime,iteration_no int,batch_start_time datetime)
------------------------------------------------------------------------------------------------------
--data insertion 
with cte as(select 
object_name(object_id) table_name,object_id,sum(rows) rows 
from sys.partitions 
where object_id in (select distinct object_id from sys.objects 
where schema_id<>42 and type_desc='USER_TABLE')
group by object_id )
------------------------------------------------------------------------------------------------------
select row_number() over(order by rows desc) id,cte.object_id,schema_name(t.schema_id) schema_name,
cte.table_name,ntile(4) over(order by rows) batch_id,rows row_count into #temp1
from cte join sys.tables t on cte.object_id=t.object_id and table_name not like '%metadata%'
------------------------------------------------------------------------------------------------------
insert into metadata(id,object_id,schema_name,table_name,batch_id,row_count)
select * from #temp1 
------------------------------------------------------------------------------------------------------
--update the batch_size data
update metadata set batch_size=100
where batch_id in (1,2)
------------------------------------------------------------------------------------------------------
update metadata set batch_size=5000
where batch_id=3 
------------------------------------------------------------------------------------------------------
update metadata set batch_size=50000
where batch_id=4
------------------------------------------------------------------------------------------------------
--Query gives the PK for the table 
select tab.object_id,schema_name(tab.schema_id) as [schema_name], 
    tab.[name] as table_name, 
    pk.[name] as pk_name,
    substring(column_names, 1, len(column_names)-1) as [columns] into #temp2 
from sys.tables tab
    left outer join sys.indexes pk
        on tab.object_id = pk.object_id 
        and pk.is_primary_key = 1
   cross apply (select col.[name] + ', '
                    from sys.index_columns ic
                        inner join sys.columns col
                            on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
                    where ic.object_id = tab.object_id
                        and ic.index_id = pk.index_id
                            order by col.column_id
                            for xml path ('') ) D (column_names)
order by schema_name(tab.schema_id),
    tab.[name]
------------------------------------------------------------------------------------------------------
--update primary key column
update metadata set primary_key_col=t.columns 
from metadata m join #temp2 t on m.object_id=t.object_id 
------------------------------------------------------------------------------------------------------


