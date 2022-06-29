use [workbench]
go

select 
	s.[name] as schema_name,
	coalesce(ds.[name],'HEAP') as filegroup_name,
	t.[object_id] as id,
	t.[name] as table_name,
	c.[name] as column_name,
	c.[column_id] as column_order,
	sst.FormatSQLColumnType(ct.name, case when ct.precision > 0 then ct.precision else c.max_length end, ct.scale) as sql_type,
	c.is_nullable,
	case when not pkc.column_id is null then 1 else 0 end as is_primary_key,
	case when not cic.column_id is null then 1 else 0 end as is_clustered_key,
	case when not fkc.constraint_object_id is null then 1 else 0 end as is_foreign_key,
	case when not dc.[object_id] is null then 1 else 0 end as has_default_constraint,
	default_definition = 'constraint ' + dc.[name] + ' default ' + dc.[definition],
	c.is_identity,
	case when not pkc.column_id is null then pk.[name] else null end as pk_name,
	case when not cic.column_id is null then ci.[name] else null end as clustered_key_name,
	case when not fkc.constraint_object_id is null then fk.[name] else null end as fk_name,
	case when not fkc.constraint_object_id is null then p.[object_id] else null end as parent_tabelle_id,
	case when not fkc.constraint_object_id is null then p.[name] else null end as parent_tabelle
from a18t.sys.tables t
inner join a18t.sys.schemas s on t.schema_id = s.schema_id
inner join a18t.sys.columns c on t.object_id = c.object_id
inner join a18t.sys.types ct on c.user_type_id = ct.user_type_id
left join a18t.sys.indexes ci on t.object_id = ci.object_id and ci.type_desc = 'CLUSTERED'
left join a18t.sys.index_columns cic on ci.object_id = cic.object_id and ci.index_id = cic.index_id and cic.column_id = c.column_id
left join a18t.sys.data_spaces ds on ci.data_space_id = ds.data_space_id and ds.type = 'FG'
left join a18t.sys.indexes pk on t.object_id = pk.object_id and pk.is_primary_key = 1
left join a18t.sys.index_columns pkc on pk.object_id = pkc.object_id and pk.index_id = pkc.index_id and pkc.column_id = c.column_id
left join a18t.sys.foreign_key_columns fkc on t.object_id = fkc.parent_object_id and fkc.parent_column_id = c.column_id
left join a18t.sys.foreign_keys fk on fkc.constraint_object_id = fk.object_id
left join a18t.sys.tables p on fkc.referenced_object_id = p.object_id
left join a18t.sys.default_constraints dc on dc.parent_object_id = t.object_id and dc.parent_column_id = c.column_id
where s.[name] = 'ps'