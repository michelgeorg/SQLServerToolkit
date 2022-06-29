-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION sst.GetDatabaseInfo
(
	@datenbank nvarchar(128)
)
RETURNS 
@result TABLE 
(
	Datenbank nvarchar(128)
)
AS
BEGIN

insert into @result
select d.[name] from sys.databases d
where not d.[name] in ('master','model','ssisdb','ssis','workbench','tempdb','msdb')
and d.[name] = coalesce(@datenbank,d.[name]);

return;

END