

-- =============================================
-- Author:		Michel Georg
-- Create date: 09.06.2022
-- Description:	selektiert Metdadaten zu Synonymen
-- =============================================
CREATE       PROCEDURE [sst].[GetSynonymsInfo]
(
	@datenbank nvarchar(128) = null,
	@schema nvarchar(128) = null,
	@filter nvarchar(100) = null
)
AS
BEGIN

declare 
	@result as sst.GetSynonymData,
	@synonyms_query_template nvarchar(3500),
	@synonyms_query nvarchar(max),
	@row_count int = 0;

set @schema = coalesce(@schema,'dbo');
set @filter = coalesce(@filter,'%');

set @synonyms_query_template =
N'
select
	sy.object_id,
	s.name  COLLATE Latin1_General_CI_AS as schema_name,
	sy.name COLLATE Latin1_General_CI_AS as synonym
	sst.GetDbObjectFullname(null,s.name,sy.name) COLLATE Latin1_General_CI_AS as Fullname,
	sy.base_object_name COLLATE Latin1_General_CI_AS
from sys.synonyms sy
join sys.schemas s on sy.schema_id = s.schema_id
where sy.name like @synonym_filter
and s.name = coalesce(@schema_name,s.name)
';

set @synonyms_query = sst.PrepareQueryStringForEachDatabase(@datenbank,@synonyms_query_template,1,1);

if @synonyms_query like 'ERROR:%'
begin
	declare @error_msg as nvarchar(200) = REPLACE(@synonyms_query, 'ERROR: ', '');
	raiserror(@error_msg, 16, 1);
	return;
end

execute sp_executesql
		@stmt = @synonyms_query,
		@params = N'@synonym_filter nvarchar(100), @schema_name nvarchar(128)',
		@synonym_filter = @filter,
		@schema_name = @schema;

return @@ROWCOUNT;

END