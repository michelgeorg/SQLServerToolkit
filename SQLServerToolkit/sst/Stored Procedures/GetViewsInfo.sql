CREATE   procedure [sst].[GetViewsInfo]
@database nvarchar(128) = null,
@schema nvarchar(128) = null,
@filter nvarchar(100) = '%'
as
begin

declare 
	@view_query_template nvarchar(3500),
	@view_query nvarchar(max),
	@collation nvarchar(128) = sst.GetCurrentCollation();

set @view_query_template =
N'
	select 
		s.[name] COLLATE ' + @collation + ' as Schema_Name, 
		v.[name] COLLATE ' + @collation + ' as Ansicht, 
		sst.GetDbObjectFullname(null, s.[name], v.[name]) COLLATE ' + @collation + ' as AnsichtSchemaName,
		sst.GetDbObjectFullname(''#DBNAME#'', s.[name], v.[name]) COLLATE ' + @collation + ' as Fullname
	from sys.views v join sys.schemas s on v.schema_id = s.schema_id
	where s.[name] = coalesce(@schema_name, s.[name])
	and v.[name] like @view_filter
';

set @view_query = sst.PrepareQueryStringForEachDatabase(@database,@view_query_template,1,1);

if @view_query like 'ERROR:%'
begin
	declare @error_msg as nvarchar(200) = REPLACE(@view_query, 'ERROR: ', '');
	raiserror(@error_msg, 16, 1);
	return;
end

execute sp_executesql
		@stmt = @view_query,
		@params = N'@view_filter nvarchar(128), @schema_name nvarchar(128)',
		@schema_name = @schema,
		@view_filter = @filter;

return @@ROWCOUNT;


end;