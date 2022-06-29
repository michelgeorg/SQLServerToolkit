
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [sst].[GetDbObjectFullname]
(
	@datenbank nvarchar(128),
	@schema nvarchar(128),
	@objekt_name nvarchar(128)
)
RETURNS nvarchar(256)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result nvarchar(256);

	set @result = COALESCE(QUOTENAME(@datenbank) + '.','') + QUOTENAME(@schema) + '.' + QUOTENAME(@objekt_name);

	RETURN @result;

END