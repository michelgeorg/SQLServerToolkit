

-- =============================================
-- Author:		Michel Georg
-- Create date: 7.6.2022
-- Description:	kopiert alle Daten aus einer Datenbank in eine andere Datenbank. Einschränkungen nach Schema und Tabellen mit bestimmten Namensmuster sind möglich.
-- =============================================
CREATE   PROCEDURE [sst].[ExecuteDataCopy]
	@SourceDatabase nvarchar(125) = N'a18t',
	@SourceSchema nvarchar(125) = N'dbo',
	@DestinationDatabase nvarchar(125) = N'interview',
	@DestinationSchema nvarchar(125) = N'dbo',
	@TablePattern nvarchar(125) = N'%',
	@action nvarchar(10) = N'COPY',
	@CreateScriptOnly bit = 1,
	@Debug bit = 0
AS
BEGIN

SET NOCOUNT ON;

declare 
	@copy_tables_statements as sst.ExecuteScriptParameter,
	@table_structures as sst.GetTablesStructureData,
	@tables_referenz as sst.GetTablesData,
	@max_level int = 0,
	@row_count int = 0; 

/**

Validierung der Parameter und Eingaben

1. Regel: nur folgende Actions sind erlaubt: COPY, OVERWRITE, MOVE, DUPLICATE

COPY => in Quelle und Ziel befinden sich die gleichen Tabellen mit den gleichen Strukturen, Daten werden kopiert. Ziel ist Referenz zur Berechnung der Aktionen.
OVERWRITE => in Quelle und Ziel befinden sich die gleichen Tabellen, Strukturen von Quelle werden auf Ziel übertragen, Daten werden kopiert. Quelle ist Referenz zur Berechnung der Aktionen.
MOVE => die Tabellen sind nur in Quelle vorhanden, Tabellen werden in Ziel erstellt, Daten werden kopiert, Tabelle aus Quelle entfernt. Quelle ist Referenz zur Berechnung der Aktionen.
			falls die Tabellen dennoch in Ziel bereits vorhanden sind, werden sie vor Erstellung gelöscht (Kombination aus MOVE und OVERWRITE).
DUPLICATE => die Tabellen sind nur in Quelle vorhanden, Tabellen werden in Ziel erstellt, Daten werden kopiert. Quelle ist Referenz zur Berechnung der Aktionen.

**/

select a.Aktion
into #COPY_ACTIONS
from ( values ('COPY'),('OVERWRITE'),('MOVE'),('DUPLICATE') ) as a(Aktion);

if not exists ( select 1 from #COPY_ACTIONS a where a.Aktion = @action )
begin
	raiserror (N'Nur die Aktionen COPY, OVERWRITE, MOVE oder DUPLICATE sind erlaubt', 16, 1);
	return;
end

if @action = 'COPY'
begin
	insert into @table_structures
	execute sst.GetTablesStructureInfo @datenbank = @DestinationDatabase, @schema = @DestinationSchema, @filter = @TablePattern;
end
else
begin
	insert into @table_structures
	execute sst.GetTablesStructureInfo @datenbank = @SourceDatabase , @schema = @SourceSchema, @filter = @TablePattern;
end


insert into @tables_referenz
execute sst.GetTablesInfo @table_structures;

if @Debug = 1
begin
	select * from @tables_referenz order by [Level];
	select * from @table_structures order by Schema_Name, Tabelle, Spalte_Order;
end


insert into @copy_tables_statements
(Zieldatenbank,Zielobjekt,Skript,Meldung,SortOrder)
select
	Datenbank,
	dt.Tabelle,
	Skript = case dt.Is_Max_Level when 1 then 'truncate table ' else 'delete from ' end + dt.Fullname + ';',
	Meldung = 'Lösche Daten in der Tabelle ' + dt.Tabelle,
	dt.[Level] * -1 + dt.MaxLevel as SortOrder
from @tables_referenz dt;

WITH TABLE_COPY_LIST AS
(
	select
		dt.Datenbank,
		dt.Tabelle,
		sst.GetDbObjectFullname(@SourceDatabase, @SourceSchema, dt.Tabelle) as source_table,
		dt.Fullname as destination_table,
		dt.[Level] as on_level,
		BEFORE_SCRIPT = case dt.Has_Identity when 1 then 'set identity_insert ' + dt.Fullname + ' on; ' else '' end,
		AFTER_SCRIPT = case dt.Has_Identity when 1 then 'set identity_insert ' + dt.Fullname + ' off; ' else '' end,
		dt.Spaltenliste as ColumnList
	from @tables_referenz dt
)
insert into @copy_tables_statements
(Zieldatenbank,Zielobjekt,Skript,Meldung,Sortorder)
select
	tcl.Datenbank,
	tcl.Tabelle,
	Skript = tcl.BEFORE_SCRIPT + 'insert into ' + tcl.destination_table + ' (' + tcl.ColumnList + ') select ' + tcl.ColumnList + ' from ' + tcl.source_table + '; ' + tcl.AFTER_SCRIPT,
	Meldung = 'Befülle die Tabelle ' + tcl.Tabelle,
	on_level + 10 as SortOrder
from TABLE_COPY_LIST tcl;

execute @row_count = sst.ExecuteSQLScripts @copy_tables_statements, @CreateScriptOnly, @Debug;

return @row_count;

END