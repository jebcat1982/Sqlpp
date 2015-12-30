

declare @name varchar(100)
set @name= '$like'

select top 1
		schemas.name  + '.' +objects.name as table_name
,	schemas.name  as [schema]
,	objects.name  
,objects.type
, (select top 1 columns.name
	FROM sys.columns as columns
	left JOIN sys.types AS columns_types 
	   ON columns.user_type_id = columns_types.user_type_id 
	   where columns.object_id = objects.object_id 
	 		order by case when columns.name like 'name'  then 0
				when   columns.name like '%name' and columns_types.name  like '%varchar%' then 1
				when   columns.name like '%name%'  and columns_types.name  like '%varchar%'  then 2
				when columns.name  like '%desc%' and columns_types.name  like '%varchar%'  then 3
				when columns_types.name  like '%varchar%' then 5
				 else 10   end
	   ) as desc_col
,(select columns.name   as bind
		,  columns.name   
		, columns.is_nullable
		,columns.is_identity 
		,(select top 1 1
		from  sys.index_columns indcol
		 left JOIN sys.indexes ind
	   ON ind.index_id = indcol.index_id
		AND ind.object_id = indcol.object_id
		where ind.is_primary_key=1
		AND columns.object_id = indcol.object_id
		AND columns.column_id = indcol.column_id
		) as is_primary_key
		,(select top 1 1
		from  sys.index_columns indcol
		 left JOIN sys.indexes ind
	   ON ind.index_id = indcol.index_id
		AND ind.object_id = indcol.object_id
		where ind.is_unique=1
		AND columns.object_id = indcol.object_id
		AND columns.column_id = indcol.column_id
		) as is_unique
		,(select top 1 ind.name
		from  sys.index_columns indcol
		 left JOIN sys.indexes ind
	   ON ind.index_id = indcol.index_id
		AND ind.object_id = indcol.object_id
		where ind.is_primary_key=1
		AND columns.object_id = indcol.object_id
		AND columns.column_id = indcol.column_id
		) as index_name
		,defaults.definition as [default_def]
		,defaults.name as [default_name]
		
		,columns_types.name as type_name
				
		 ,columns_types.name +
                  case when columns_types.name='numeric'
                  
					 --or columns_types.name='money' 
					 or columns_types.name='decimal' then '(' + cast(columns.PRECISION as varchar(10)) + ',' + cast(columns.SCALE as varchar(10)) + ')'
                  when columns_types.name='varchar' 
					or columns_types.name='varbinary'
					or columns_types.name='char' 
					or columns_types.name='nchar'  then '(' +
					case when columns.MAX_LENGTH<0 then 'max' 
							else  cast(columns.MAX_LENGTH as varchar(10))  end + ')'
                 when  columns_types.name='nvarchar'  then '(' +
							case when columns.MAX_LENGTH<0 then 'max' 
							else  cast(columns.MAX_LENGTH/2 as varchar(10))  end + ')'
                  else '' end  as data_type
		
            ,case columns_types.name
                  when 'xml' then 'XmlDocument'
                  when 'varchar'  then 'string'
                  when 'nvarchar' then 'string'
                  when 'smallint' then 'short'
                  when 'tinyint' then 'short'
                  when 'numeric' then 'int'
                  when 'money' then 'decimal'
                  when 'bigint' then 'long'
                  when 'bit' then 'bool'
                  when 'datetime' then 'DateTime' 
                  when 'smalldatetime' then 'DateTime' 
                  else columns_types.name
            end +
            case  when columns_types.name in ('xml','varchar' ,'nvarchar') then ''
                  when columns.is_nullable =1 then '?'
                  else '?' end
                   as cs_type
	,case when exists (select  1 
		FROM sys.foreign_key_columns AS fkc
		 where (objects.object_id =fkc.parent_object_id
		 and columns.column_id = fkc.parent_column_id)) then 1 end as is_fk
	,case when exists (select  1 
		FROM sys.foreign_key_columns AS fkc
		 where (objects.object_id =fkc.referenced_object_id
		 and columns.column_id = fkc.referenced_column_id)) then 1 end as has_fk
	 FROM sys.columns as columns
	left JOIN sys.types AS columns_types 
	   ON columns.user_type_id = columns_types.user_type_id 
	left JOIN sys.default_constraints AS defaults
	   ON columns.column_id = defaults.parent_column_id 
	   and columns.object_id =  defaults.parent_object_id
	   where columns.object_id = objects.object_id 
	order by is_primary_key desc--,cs_type--,columns.name
	for xml raw('col'),type)
	,(select 
		ref_schemas.name  + '.' + ref_objects.name as table_name
				,ref_schemas.name as [schema]
		, ref_objects.name  as name
		,foreigns.name as fk_name
		, (select top 1 columns.name
	FROM sys.columns as columns
	left JOIN sys.types AS columns_types 
	   ON columns.user_type_id = columns_types.user_type_id 
	   where columns.object_id = ref_objects.object_id 
	 		order by case when columns.name like 'name'  then 0
				when   columns.name like '%name' and columns_types.name  like '%varchar%' then 1
				when   columns.name like '%name%'  and columns_types.name  like '%varchar%'  then 2
				when columns.name  like '%desc%' and columns_types.name  like '%varchar%'  then 3
				when columns_types.name  like '%varchar%' then 5
				 else 10   end
	   ) as desc_col
		,(select
				fcolumns.name as [to]
				, columns.is_nullable
				,columns.name  as [by]
				,columns.name  as [name]
				 from sys.foreign_key_columns AS fkc 
				 inner join sys.columns AS fcolumns
			   on fcolumns.column_id = fkc.referenced_column_id 
			   and fcolumns.object_id = fkc.referenced_object_id 
				 inner join sys.columns AS columns
			   on columns.column_id = fkc.parent_column_id 
			   and columns.object_id = fkc.parent_object_id 
			where  fkc.constraint_object_id = foreigns.object_id 
				for xml raw('fk'),type)
	 FROM   sys.foreign_keys AS foreigns
		inner JOIN   sys.objects AS ref_objects
		   ON ref_objects.object_id =  foreigns.referenced_object_id
		inner JOIN sys.schemas AS ref_schemas
		   ON ref_schemas.schema_id =  ref_objects.schema_id 
	 where foreigns.parent_object_id = objects.object_id
		for xml raw('fk'),type
		)
		
	,(select 
		ref_schemas.name  + '.' + ref_objects.name as table_name
		,ref_schemas.name as [schema]
		, ref_objects.name   as name
		,foreigns.name as fk_name
		, (select top 1 columns.name
	FROM sys.columns as columns
	left JOIN sys.types AS columns_types 
	   ON columns.user_type_id = columns_types.user_type_id 
	   where columns.object_id = ref_objects.object_id 
	 		order by case when columns.name like 'name'  then 0
				when   columns.name like '%name' and columns_types.name  like '%varchar%' then 1
				when   columns.name like '%name%'  and columns_types.name  like '%varchar%'  then 2
				when columns.name  like '%desc%' and columns_types.name  like '%varchar%'  then 3
				when columns_types.name  like '%varchar%' then 5
				 else 10   end
	   ) as desc_col
		,(select
				columns.name   as [to]
				,fcolumns.name as [by]
				,columns.name  as [name]
				 from sys.foreign_key_columns AS fkc 
				 inner join sys.columns AS fcolumns
			   on fcolumns.column_id = fkc.referenced_column_id 
			   and fcolumns.object_id = fkc.referenced_object_id 
				 inner join sys.columns AS columns
			   on columns.column_id = fkc.parent_column_id 
			   and columns.object_id = fkc.parent_object_id 
			where  fkc.constraint_object_id = foreigns.object_id 
				for xml raw('fk'),type)
	 FROM   sys.foreign_keys AS foreigns
		inner JOIN   sys.objects AS ref_objects
		   ON ref_objects.object_id =  foreigns.parent_object_id
		inner JOIN sys.schemas AS ref_schemas
		   ON ref_schemas.schema_id =  ref_objects.schema_id 
	 where foreigns.referenced_object_id = objects.object_id
	 order by ref_objects.name
		for xml raw('fkTo'),type
		)
from sys.objects AS objects 
inner JOIN sys.schemas AS schemas 
   ON objects.schema_id = schemas.schema_id 
where (objects.name like '%' +  @name  +'%'
	 or schemas.name+'.'+ objects.name  like '%' +  @name  +'%')
 and objects.type ='U'
	  
	 
	order by case when lower(schemas.name)+'.'+lower(objects.name)=lower(@name) then 1
	 when lower(objects.name)='$gschema.' + lower(@name) then 2
	 when lower(objects.name)=lower(@name) then 3
	 when @name like '%' + objects.name  then 4
	 when @name like objects.name +'%' then 5
	 when @name like  schemas.name  then 6
		else 100 end,len(objects.name) 
		for xml raw('table')
