

declare @name varchar(100)
set @name= '$like'

select top 1  ind.name as name,'index' as [type]
		,schemas.name  as schema_name
from sys.indexes ind
		inner join sys.objects as o 
	   ON ind.object_id = o.object_id
		left join sys.schemas  
		on o.schema_id = schemas.schema_id
where  o.type='U'

and  lower(schemas.name)+'.'+lower(ind.name)=lower(@name) 
	 or lower(ind.name)='$gschema.' + lower(@name) 
	 or lower(ind.name)=lower(@name) 
	order by case when lower(schemas.name)+'.'+lower(ind.name)=lower(@name) then 1
	 when lower(ind.name)='$gschema.' + lower(@name) then 2
	 when lower(ind.name)=lower(@name) then 3
		else 100 end
		
for xml raw
		