


CREATE        procedure [sst].[GetTablesInfo]
	@table_data as sst.GetTablesStructureData READONLY
as
begin

declare 
	@result as sst.GetTablesData,
	@max_level as int;

WITH SELECT_TABLES_DATA AS
(
	select Datenbank, Schema_Name, Id, Tabelle, 1 as [Level], convert(nvarchar(1000),Tabelle) as LPath from @table_data
	where ParentTabelle is null
	group by Datenbank, Schema_Name, Id, Tabelle

	union all

	select 
		r.Datenbank, r.Schema_Name, r.Id, r.Tabelle, 
		p.[Level] + 1 as [Level], 
		convert(nvarchar(1000), p.LPath + r.Tabelle) as LPath from @table_data r 
	join SELECT_TABLES_DATA p on r.ParentTabelleId = p.Id and r.Datenbank = p.Datenbank and r.Schema_Name = p.Schema_Name
	where not r.ParentTabelle is null and not p.LPath like '%' + r.Tabelle + '%'
),
SELECT_TABLES_LEVEL AS
(
	select Datenbank, Schema_Name, Id, Tabelle, MAX([Level]) as [Level] from SELECT_TABLES_DATA
	group by Datenbank, Schema_Name, Id, Tabelle
)
insert into @result
(Datenbank,Schema_Name,Tabelle,Id,[Level],[Fullname],TabelleSchemaName,
Has_Primary_Key,Has_Clustered_Key,Has_Identity,Spaltenliste,Is_Max_Level,MaxLevel,DropTableStatement,CreateTableStatement)
select
	stl.Datenbank,stl.Schema_Name,stl.Tabelle,stl.Id,stl.[Level],
	fn.FullName,fn.TabelleSchemaName,
	Has_Primary_Key = case when exists ( select 1 from @table_data td where td.Id = stl.Id and td.PK = 1 ) then 1 else 0 end,
	Has_Clustered_Key = case when exists ( select 1 from @table_data td where td.Id = stl.Id and td.[Clustered] = 1 ) then 1 else 0 end,
	Has_Identity = case when exists ( select 1 from @table_data td where td.Id = stl.Id and td.IdentityColumn = 1 ) then 1 else 0 end,
	Spaltenliste = sst.GetSpaltenliste(@table_data,stl.Datenbank, stl.Id, 0, 0, 0),
	0 as Is_Max_Level,
	1 as MaxLevel,
	DropTableStatement = 'drop table if exists ' + fn.Fullname,
	CreateTableStatement = 'create table ' + fn.Fullname + ' ( ' + sst.GetSpaltenliste(@table_data, stl.Datenbank, stl.Id, 0, 0, 1) + ' )'
from SELECT_TABLES_LEVEL stl
cross apply ( 
	values ( 
		sst.GetDbObjectFullname(stl.Datenbank,stl.Schema_Name, stl.Tabelle),
		sst.GetDbObjectFullname(null,stl.Schema_Name,stl.Tabelle)
		)) as fn(Fullname,TabelleSchemaName);

select @max_level = MAX([Level]) from @result;
update @result set
MaxLevel = @max_level,
Is_Max_Level = case when [Level] = @max_level then 1 else 0 end;

update @result set
SelectTableStatement = N'select ' + Spaltenliste + ' from ' + Fullname;

select
	td.Datenbank,
	td.Id,
	td.PK_Name,
	case when td.PK_Name = td.Clustered_Index_Name then 1 else 0 end as is_pk_clustered,
	PK_Spalten =  sst.GetSpaltenliste(@table_data, td.Datenbank, td.Id, 1, 0, 0)
into #PRIMARY_KEY_DATA
from @table_data td 
where td.PK = 1
group by td.Datenbank, td.Id, td.PK_Name, td.Clustered_Index_Name;

update r set
r.CreatePrimaryKeyStatement = 
		'alter table ' + 
		r.Fullname + 
		' add constraint ' + 
		QUOTENAME(pkd.PK_Name) + 
		' primary key' + 
		case is_pk_clustered when 1 then ' clustered' else '' end + 
		' (' + pkd.PK_Spalten + ')'
from @result r join #PRIMARY_KEY_DATA pkd on r.Id = pkd.Id;

select
	td.Datenbank,
	td.Id,
	td.Clustered_Index_Name,
	Clustered_Spalten =  sst.GetSpaltenliste(@table_data, td.Datenbank, td.Id, 0, 1, 0)
into #CLUSTERED_INDEX_DATA
from @table_data td
where td.[Clustered] = 1 -- clustered key ist vorhanden
and not td.PK_Name = td.Clustered_Index_Name -- falls der Primärschlüssel bereits clustered ist (d.h. er heisst gleich wie der Clustered Index), braucht es keinen zusätzlichen Index
group by td.Datenbank, td.Id, td.Clustered_Index_Name;

update r set
r.CreateClusteredIndexStatement = 'create clustered index ' + QUOTENAME(cid.[Clustered_Index_Name]) + ' on ' + r.Fullname + ' ( ' + cid.Clustered_Spalten + ' )'
from @result r join #CLUSTERED_INDEX_DATA cid on r.Id = cid.Id;

select * from @result
order by Datenbank, Schema_Name, Tabelle;

return @@ROWCOUNT;

end