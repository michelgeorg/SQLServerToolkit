-- =============================================
-- Author:		Michel Georg
-- Create date: 20.7.2021
-- Description:	wandelt die Definition einer Spalte aus DB2 in eine entsprechende Deklaration für SQL Server um.
-- =============================================
CREATE   FUNCTION [sst].[FormatSQLColumnType]
(
	-- Add the parameters for the function here
	@coltype varchar(50),
	@precision int,
	@scale int
)
RETURNS varchar(100)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @formattedString varchar(100)

	-- Add the T-SQL statements to compute the return value here
	select @formattedString =
		case @coltype 
			when 'TIMESTMP' then 'datetime2(7)'
			when 'ROWID' then 'uniqueidentifier'
			when 'BLOB' then 'varbinary(max)'
			when 'CLOB' then 'varbinary(max)'
			when 'LONGVAR' then 'varchar(max)'
			when 'VARCHAR' then 'VARCHAR(' + case when @precision > 4000 then 'max' when @precision = -1 then 'max' else convert(nvarchar(50),@precision) end + ')'
			when 'VARBINARY' then 'VARBINARY(' + case when @precision > 4000 then 'max' when @precision = -1 then 'max' else convert(nvarchar(50),@precision) end + ')'
			when 'INTEGER' then 'INT'
			else RTRIM(@coltype) +
			case when @coltype in ('BIGINT','INTEGER','SMALLINT','DATE','INT','UNIQUEIDENTIFIER') then ''
				when @coltype in ('DATETIME','DATETIME2','TIME') then '(' + convert(nvarchar(5),@scale) + ')'
				else '(' + convert(nvarchar(50), @precision) + case when @scale > 0 then ',' + convert(nvarchar(5),@scale) else '' end + ')' 
				end
			end

	-- Return the result of the function
	RETURN LOWER(@formattedString)

END