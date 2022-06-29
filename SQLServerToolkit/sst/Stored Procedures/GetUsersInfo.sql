CREATE   procedure [sst].[GetUsersInfo]
	@datenbank nvarchar(128) = null,
	@rolle nvarchar(128) = null
as
begin
	
declare @collation nvarchar(128) = sst.GetCurrentCollation();
declare @user_query_template as nvarchar(3500);
declare @user_query as nvarchar(max);

set @user_query_template = 
N'
	select
		p.principal_id as Id,
		p.[name] COLLATE ' + @collation + ' as UserName, 
		p.type_desc as UserType, 
		p.default_schema_name COLLATE ' + @collation + ' as DefaultSchema, 
		coalesce(p.default_language_name, l.default_language_name) COLLATE ' + @collation + ' as UserDefaultSprache,
		r.[name] COLLATE ' + @collation + ' as Rolle, 
		l.sid as LoginId, 
		l.[name] as LoginName, 
		l.default_database_name as UserDefaultDatabase,
		case when l.is_disabled = 1 then 0 else 1 end as LoginAktiv
	from sys.database_principals p
	join sys.database_role_members drm on p.principal_id = drm.member_principal_id
	join sys.database_principals r on r.principal_id = drm.role_principal_id
	join sys.sql_logins l on l.sid = p.sid
	where p.type = ''S'' and LEN(p.[name]) = 4
	and r.type = ''R''
	and r.[name] = coalesce(@rolle_name,r.[name])
';

set @user_query = sst.PrepareQueryStringForEachDatabase(@datenbank,@user_query_template,1,1);

if @user_query like 'ERROR:%'
begin
	declare @error_msg as nvarchar(200) = REPLACE(@user_query, 'ERROR: ', '');
	raiserror(@error_msg, 16, 1);
	return;
end

execute sp_executesql
		@stmt = @user_query,
		@params = N'@rolle_name nvarchar(128)',
		@rolle_name = @rolle;

return @@ROWCOUNT;

end