CREATE FUNCTION [sst].[GetSpaltenliste]
(
	@structure as sst.GetTablesStructureData READONLY,
	@datenbank nvarchar(128),
	@tabelle_id int,
	@pk_only bit = 0,
	@ci_only bit = 0,
	@use_definition bit = 0
)
RETURNS NVARCHAR(4000)
AS
BEGIN
	declare @result nvarchar(4000);

	select @result = 
		STUFF ( 
				(
					select 
						',' + 
						case @use_definition when 0 then QUOTENAME(s.Spalte) else s.Definition end +
						case s.DefaultConstraint when 1 then ' ' + s.DefaultConstraintDefinition else '' end
					from @structure s
					where s.Datenbank = @datenbank
					and s.Id = @tabelle_id
					and s.PK = case when @pk_only = 1 then 1 else s.PK end
					and s.[Clustered] = case when @ci_only = 1 then 1 else s.[Clustered] end
					order by s.Spalte_Order
					FOR XML PATH(N''), TYPE
				).value('.', 'NVARCHAR(4000)'),
				1, 1, '')

	return @result;
END
