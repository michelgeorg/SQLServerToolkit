CREATE Function [sst].[PrepareQueryStringForEachDatabase]
(
	@datenbank nvarchar(128),
	@query_template nvarchar(3500),
	@extend_sys_objects bit = 1,
	@include_database_in_selection bit = 1
)
RETURNS NVARCHAR(MAX)
as
begin
	
declare 
	@databases as sst.GetDatabaseData,
	@query_over_all_db as nvarchar(max) = '',
	@union_string as nvarchar(20),
	@db_placeholder as nvarchar(8) = '#DBNAME#',
	@row_count int = 0;

set @union_string =
N'

union all

';

if @extend_sys_objects = 1
begin
	set @query_template = REPLACE(@query_template, ' sys.', ' ' + @db_placeholder + '.sys.')
end

if @include_database_in_selection = 1
begin
	set @query_template = REPLACE(@query_template, 'select', 'select ''#DBNAME#'' as Datenbank,')
end

insert into @databases
select Datenbank from sst.GetDatabaseInfo(@datenbank);

select @row_count = count(*) from @databases;
if not @datenbank is null and @row_count = 0
begin
	return CONCAT(N'ERROR: Datenbank ', @datenbank, N' nicht gefunden');
end

select
	@query_over_all_db = @query_over_all_db +
	case when len(@query_over_all_db) = 0 then '' else @union_string end
	+ REPLACE(@query_template, @db_placeholder, Datenbank)
from @databases;

return @query_over_all_db;

end