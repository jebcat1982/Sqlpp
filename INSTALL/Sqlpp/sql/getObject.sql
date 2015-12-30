
select top 2
		schemas.name  + '.' +objects.name as dbName
,objects.type
,objects.type_desc
from sys.objects AS objects 
inner JOIN sys.schemas AS schemas 
   ON objects.schema_id = schemas.schema_id 
where  lower(schemas.name)+'.'+lower(objects.name)=lower(@name) 
	 or lower(objects.name)=lower(@name) 
	order by case when lower(schemas.name)+'.'+lower(objects.name)=lower(@name) then 1
	 when lower(objects.name)=lower(@name) then 3
		else 100 end
		
		