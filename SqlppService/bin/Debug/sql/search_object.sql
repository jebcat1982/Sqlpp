select oname from (
select s.name + '.' + o.name as oname,o.type
		,case when s.name + '.' + o.name = @name then 1
			when  o.name = @name then 2
			when s.name + '.' + o.name like @name + '%' then 3
			when o.type ='U' then 20
		when o.type ='V' then 30
		when o.type ='P' then 40
		when o.type ='FN' then 50 
		when o.type ='TF' then 60
		when o.type ='FK' then 70
		when o.type ='F' then 80
		when o.type ='PK' then 90
		when o.type ='D' then 100
			else 100 end
			 as mach
from sys.objects as o 
left join sys.schemas  as s
on o.schema_id = s.schema_id
where  type!='S' 
and (o.name like '%' + @name + '%' or s.name + '.' + o.name like '%' + @name + '%')
union all
select  s.name + '.' + ind.name as oname,o.type
		,case when s.name + '.' + o.name = @name then 2
			when  o.name = @name then 2
			when s.name + '.' + o.name like @name + '%' then 21
			when o.type ='U' then 20
		when o.type ='V' then 30
		when o.type ='P' then 40
		when o.type ='FN' then 50 
		when o.type ='TF' then 60
		when o.type ='FK' then 70
		when o.type ='F' then 80
		when o.type ='PK' then 90
		when o.type ='D' then 100
			else 100 end
			 as mach
from sys.indexes ind
	inner join sys.objects as o 
	ON ind.object_id = o.object_id
	left join sys.schemas  as s
	on o.schema_id = s.schema_id
where  o.type='U' and ind.name !=o.name
and (ind.name like '%' + @name + '%' or s.name + '.' + ind.name like '%' + @name + '%')
and not exists (select top 1 1 from sys.objects as o2 where o2.name=ind.name)
) as a
	order by mach , oname
