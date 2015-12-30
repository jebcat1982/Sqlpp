

declare @name varchar(100)
set @name= '$table'


select top 1 
		schemas.name + '.' + objects.name as [table]
		,columns.name  as col

 FROM sys.columns as columns
inner JOIN sys.objects AS objects 
   ON columns.object_id = objects.object_id 
inner JOIN sys.schemas AS schemas 
   ON objects.schema_id = schemas.schema_id

where (objects.name like '%' +  @name  +'%'
	 or schemas.name+'.'+ objects.name  like '%' +  @name  +'%')
 and objects.type ='U'
	
and exists (
				SELECT 1 FROM sys.indexes ind
				INNER JOIN sys.index_columns indcol
				ON ind.index_id = indcol.index_id
				AND ind.object_id = indcol.object_id
				AND columns.column_id = indcol.column_id
				WHERE ind.object_id = columns.object_id
				AND ind.is_primary_key =  1 
				)

	order by case when lower(schemas.name)+'.'+lower(objects.name)=lower(@name) then 1
	 when lower(objects.name)='$gschema.' + lower(@name) then 2
	 when lower(objects.name)=lower(@name) then 3
	 when @name like '%' + objects.name  then 4
	 when @name like objects.name +'%' then 5
	 when @name like  schemas.name  then 6
		else 100 end,len(objects.name) 
for xml raw