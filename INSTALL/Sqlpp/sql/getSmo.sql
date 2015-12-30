declare @name varchar(100)
set @name= '$like'

select top 1 * from (
	select * from (
	select top 1
			schemas.name as s
			,objects.name as o
			,case when objects.type_desc like 'USER_TABLE' then objects.name 
				 when objects.type_desc like 'FOREIGN_KEY_CONSTRAINT' then (select  top 1 tables.name
				from sys.objects AS tables 
					inner join sys.foreign_key_columns AS fkc
					 on tables.object_id =fkc.parent_object_id
					 and objects.object_id = fkc.constraint_object_id )
				else '' end as tbl
			,objects.type_desc as t
	from sys.objects AS objects 
	inner JOIN sys.schemas AS schemas 
	   ON objects.schema_id = schemas.schema_id 
	where  lower(schemas.name)+'.'+lower(objects.name)=lower(@name) 
		 or lower(objects.name)='dbo.' + lower(@name) 
		 or lower(objects.name)=lower(@name) 
		order by case when lower(schemas.name)+'.'+lower(objects.name)=lower(@name) then 1
		 when lower(objects.name)='dbo.' + lower(@name) then 2
		 when lower(objects.name)=lower(@name) then 3
			else 100 end
	) as a
	union all 
	select * from (

	select top 1  
			schemas.name  as s
			,ind.name as o
			,o.name as tbl
			,'index' as t
	from sys.indexes ind
			inner join sys.objects as o 
		   ON ind.object_id = o.object_id
			left join sys.schemas  
			on o.schema_id = schemas.schema_id
	where  o.type='U'

	and  lower(schemas.name)+'.'+lower(ind.name)=lower(@name) 
		 or lower(ind.name)='dbo.' + lower(@name) 
		 or lower(ind.name)=lower(@name) 
		order by case when lower(schemas.name)+'.'+lower(ind.name)=lower(@name) then 1
		 when lower(ind.name)='dbo.' + lower(@name) then 2
		 when lower(ind.name)=lower(@name) then 3
			else 100 end
			
	) as a
) as a
		
