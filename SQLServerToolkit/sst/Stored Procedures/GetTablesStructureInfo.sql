
CREATE   procedure [sst].[GetTablesStructureInfo]
	@datenbank nvarchar(128) = null,
	@schema nvarchar(128) = null,
	@filter nvarchar(100) = null
as
begin

declare @result as sst.GetTablesStructureData;
declare @table_query_template as nvarchar(3500);
declare @table_query as nvarchar(max);
declare @collation as sysname = sst.GetCurrentCollation();

set @filter = coalesce(@filter, '%');

set @table_query_template =
N'
select 
	s.[name] COLLATE ' + @collation + ' as schema_name,
	coalesce(ds.[name],''HEAP'') as filegroup_name,
	t.[object_id] as id,
	t.[name] COLLATE ' + @collation + ' as table_name,
	c.[name] COLLATE ' + @collation + ' as column_name,
	c.[column_id] as column_order,
	sst.FormatSQLColumnType(ct.name, case when ct.precision > 0 then ct.precision else c.max_length end, ct.scale) COLLATE ' + @collation + ' as sql_type,
	c.is_nullable,
	case when not pkc.column_id is null then 1 else 0 end as is_primary_key,
	case when not cic.column_id is null then 1 else 0 end as is_clustered_key,
	case when not fkc.constraint_object_id is null then 1 else 0 end as is_foreign_key,
	c.is_identity,
	case when not dc.[object_id] is null then 1 else 0 end as has_default_constraint,
	default_definition = ''constraint '' + dc.[name] + '' default '' + dc.[definition],
	case when not pkc.column_id is null then pk.[name] else null end COLLATE ' + @collation + ' as pk_name,
	case when not cic.column_id is null then ci.[name] else null end COLLATE ' + @collation + ' as clustered_key_name,
	case when not fkc.constraint_object_id is null then fk.[name] else null end COLLATE ' + @collation + ' as fk_name,
	case when not fkc.constraint_object_id is null then p.[object_id] else null end as parent_tabelle_id,
	case when not fkc.constraint_object_id is null then p.[name] else null end COLLATE ' + @collation + ' as parent_tabelle
from sys.tables t
inner join sys.schemas s on t.schema_id = s.schema_id
inner join sys.columns c on t.object_id = c.object_id
inner join sys.types ct on c.user_type_id = ct.user_type_id
left join sys.indexes ci on t.object_id = ci.object_id and ci.type_desc = ''CLUSTERED''
left join sys.index_columns cic on ci.object_id = cic.object_id and ci.index_id = cic.index_id and cic.column_id = c.column_id
left join sys.data_spaces ds on ci.data_space_id = ds.data_space_id and ds.type = ''FG''
left join sys.indexes pk on t.object_id = pk.object_id and pk.is_primary_key = 1
left join sys.index_columns pkc on pk.object_id = pkc.object_id and pk.index_id = pkc.index_id and pkc.column_id = c.column_id
left join sys.foreign_key_columns fkc on t.object_id = fkc.parent_object_id and fkc.parent_column_id = c.column_id
left join sys.foreign_keys fk on fkc.constraint_object_id = fk.object_id
left join sys.tables p on fkc.referenced_object_id = p.object_id
left join sys.default_constraints dc on dc.parent_object_id = t.object_id and dc.parent_column_id = c.column_id
where t.[name] like @table_filter
and s.[name] = coalesce(@schema_name,s.[name])
';

set @table_query = sst.PrepareQueryStringForEachDatabase(@datenbank, @table_query_template, 1, 1);

if @table_query like 'ERROR:%'
begin
	declare @error_msg as nvarchar(200) = REPLACE(@table_query, 'ERROR: ', '');
	raiserror(@error_msg, 16, 1);
	return;
end

execute sp_executesql
	@stmt = @table_query,
	@params = N'@table_filter nvarchar(100), @schema_name nvarchar(128)',
	@table_filter = @filter,
	@schema_name = @schema;

return @@ROWCOUNT;

end