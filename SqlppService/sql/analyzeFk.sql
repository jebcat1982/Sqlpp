

declare @name varchar(100)
set @name= '$like'

select top 1 '['+schemas.name+'].'+objects.name as fkName
,'['+schemasParent.name+'].'+objectsParent.name as fromTable
,'['+schemasreferenced.name+'].'+objectsreferenced.name as toTable
,(select top 1 name from sys.columns where object_id= f.parent_object_id and column_id=parent_column_id) as fromCol
,(select top 1 name from sys.columns where object_id= f.referenced_object_id and column_id=referenced_column_id) as toCol
FROM sys.foreign_key_columns as f
inner JOIN sys.objects AS objects 
   ON objects.object_id = f.constraint_object_id 
inner JOIN sys.schemas AS schemas 
   ON objects.schema_id = schemas.schema_id 
   
inner JOIN sys.objects AS objectsParent
   ON objectsParent.object_id = f.parent_object_id 
inner JOIN sys.schemas AS schemasParent
   ON objectsParent.schema_id = schemasParent.schema_id 
   
inner JOIN sys.objects AS objectsreferenced
   ON objectsreferenced.object_id = f.referenced_object_id 
inner JOIN sys.schemas AS schemasreferenced
   ON objectsreferenced.schema_id = schemasreferenced.schema_id 
   
where  lower(schemas.name)+'.'+lower(objects.name)=lower(@name) 
	 or lower(objects.name)='$gschema.' + lower(@name) 
	 or lower(objects.name)=lower(@name) 
	order by case when lower(schemas.name)+'.'+lower(objects.name)=lower(@name) then 1
	 when lower(objects.name)='$gschema.' + lower(@name) then 2
	 when lower(objects.name)=lower(@name) then 3
		else 100 end
for xml raw