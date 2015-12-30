
IF OBJECT_ID(N'$view') is not null
	DROP VIEW $view
go
------------------------------------------------------------------------------------
--		$user, $date
create view $view
as
	select 
[all		$,$colNick~ -- $type 	$null $identity	$default	$ref_table
all]	from $table
go


IF  OBJECT_ID(N'$gschema.stp_$tableNick_Get') is not null
	DROP procedure $gschema.stp_$tableNick_Get
go
------------------------------------------------------------------------------------
--		$user, $date
create procedure $gschema.stp_$tableNick_Get
(
[pk	$,@$colNick $type
pk])
AS
begin
	select 
[all		$,$dbFullName
all][join[all		,$dbFullName as $colNick
all]join]	from $view as $viewNick
[join	$join join]	

--[desc		,isnull(trans.translated ,$tableNick.name ) 
--desc]
--		left join vew_translation as trans
--		on trans.translation_type=@$tableNick_trans_type 
--		and trans.language_id = @language_id
--		and trans.translated_id=[pk	$colNick pk]

where
[pk	$and $colNick = @$colNick
pk]
	for xml raw('$tableNick'),root('$tableNicks')
end
/*test:
exec stp_$tableNick_Get 
[pk	$,@$colNick	= 1
pk]
*/
go


IF  OBJECT_ID(N'$gschema.stp_$tableNick_Insert') is not null
	DROP procedure $gschema.stp_$tableNick_Insert
go
------------------------------------------------------------------------------------
--		$user, $date
create procedure $gschema.stp_$tableNick_Insert
(
[pk	$,@$colNick		 $type out
pk]	,@details		xml
) 
AS 
begin 
[pk_not_id	---not recommended:
	set @$colNick=isnull((select max($colNick)+1 from $view),1)
	---------
pk_not_id]

 	insert into $view
	(
[not_id		$,$colNick
not_id]
	)
	select
[not_id		$,x.r.value('@$colNick','$type') as [$colNick]
not_id]
	from @details.nodes('*/*') as x(r)

[pk_id	set @$colNick = scope_identity()
pk_id]
end
/*test:
exec stp_$tableNick_Insert 
[pk	$,@$colNick	= null
pk]	,@details = N'<$tableNicks><$tableNick[not_pk $colNick="$type_name"
							not_pk]/></root>'
*/

go

IF  OBJECT_ID(N'$gschema.stp_$tableNick_Update') is not null
	DROP procedure $gschema.stp_$tableNick_Update
go
------------------------------------------------------------------------------------
--		$user, $date
create procedure $gschema.stp_$tableNick_Update
(
	@details	xml
) 
AS 
begin 
	update $viewNick
	set  
[not_pk		$,$colNick~	 = x.r.value('@$colNick','$type')
not_pk][getdate		,$colNick~	 = getdate()
getdate]	from $view  as $viewNick
	inner join @details.nodes('*/*') as x(r)
	on [pk$and $colNick~	 = x.r.value('@$colNick','$type')
	pk]
end
/*test:
exec stp_$tableNick_Update 
	@details = N'<$tableNicks><$tableNick[pk $colNick="$type_name"
							pk][not_pk $colNick="$type_name"
							not_pk]/></root>'
*/
go
IF  OBJECT_ID(N'$gschema.stp_$tableNick_Delete') is not null
	DROP procedure $gschema.stp_$tableNick_Delete
go
------------------------------------------------------------------------------------
--		$user, $date
create procedure $gschema.stp_$tableNick_Delete
(
	@details xml
)
AS
begin
[fkTo
   delete $viewNick
	from $view as $viewNick
	inner join @details.nodes('*/*') as x(r)
	on [opk$and $colNick~	= x.r.value('@$colNick','$type')
	opk]
 fkTo]
 
   delete $viewNick
	from $view as $viewNick
	inner join @details.nodes('*/*') as x(r)
	on [pk$and $colNick~	= x.r.value('@$colNick','$type')
	pk]
end

/*test
exec stp_$tableNick_Delete 
	@details = N'<$tableNicks><$tableNick[pk $colNick="$1"
								pk]/></root>'
*/
go


IF  OBJECT_ID(N'$gschema.stp_$tableNick_Search') is not null
	DROP procedure $gschema.stp_$tableNick_Search
go
------------------------------------------------------------------------------------
--		$user, $date

create procedure $gschema.stp_$tableNick_Search
(
	@orderColumn varchar(100)      
	,@orderDir int      
	,@orderByExpr nvarchar(100)      
	,@pageSize int      
	,@page int      
	,@fromRow int
	,@tillRow int
	,@total_rows int      
	,@search varchar(100)  
[search[all	,@$colNick $type
all]search][search[date	, @$colNick_from $type
	,@$colNick_until $type
date]search]
) 
AS 
begin 
declare @sql nvarchar(max)      
	,@where nvarchar(max)    
	
set @where = ''
[search[not_date if (@$colNick is not null)	set @where=@where+N' and $dbFullName=@$colNick' 
not_date][date 
if (@$colNick is not null)	
	select @$colNick_from=@$colNick, @$colNick_until=dateadd(day,1,@$colNick)
if (@$colNick_from is not null)	set @where=@where+N' and $dbFullName>=@$colNick_from' 
if (@$colNick_until is not null)	set @where=@where+N' and $dbFullName<=@$colNick_until' 

date]search]
[quickSearch
if (@search is not null)	set @where=@where+N' and (
[all 	  $or cast($dbFullName as varchar(50)) $quickSearchLike 
all]							)'
quickSearch]

set @sql =
N'with cte
	as
	(select *, ROW_NUMBER() over (order by ' + @orderByExpr + ') as row_number
		from (
			
		select 
[result[all			$,$dbFullName as $colNick
all][join' set @sql =  @sql +N'[all		,$dbFullName as $colNick
all]join]result]			
		from $view as $viewNick
[result[join	$join join]result]		
		where 1=1' + @where + '
		) as data_tbl
	)
	select (select isnull(@total_rows,max(row_number) as total_rows from cte)) as total_rows
			,@page as page
			,@pageSize as pageSize
			,@orderColumn as orderColumn
			,@orderDir as orderDir
			,(select *  from cte 
				where row_number between @fromRow and @tillRow
				order by row_number
				for xml raw(''$tableNick''), TYPE)
	for xml raw(''$tableNicks'')';

EXECUTE sp_executesql @sql
	, N'@page int
	,@pageSize	int
	,@orderColumn varchar(50)
	,@orderDir	int
	,@fromRow	int
	,@tillRow	int
	,@total_rows int      
	,@search varchar(100)
[search[not_date	, @$colNick $type
not_date][date	,@$colNick_from $type
	,@$colNick_until $type
date]search]
	',@page	= @page
	,@pageSize	= @pageSize
	,@orderColumn = @orderColumn
	,@orderDir	= @orderDir
	,@fromRow	= @fromRow
	,@tillRow	= @tillRow
	,@total_rows = @total_rows      
	,@search = @search
[search[not_date	,@$colNick = @$colNick
not_date][date	,@$colNick_from = @$colNick_from
		,@$colNick_until = @$colNick_until
date]search]
end
/*test
exec stp_$tableNick_Search 
*/
go