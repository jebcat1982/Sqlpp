

declare @name varchar(100)
set @name= '$like'

select 1 as result
from sys.objects AS objects 
inner JOIN sys.schemas AS schemas 
   ON objects.schema_id = schemas.schema_id 
where  lower(schemas.name)+'.'+lower(objects.name)=lower(@name) 
		
		