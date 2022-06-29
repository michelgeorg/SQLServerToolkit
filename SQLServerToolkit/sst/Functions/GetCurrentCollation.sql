-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION sst.GetCurrentCollation
(
)
RETURNS sysname
AS
BEGIN

	declare @collation sysname;

	select top 1 @collation = collation_name from sys.databases where [name] = DB_NAME();

	return @collation;

END