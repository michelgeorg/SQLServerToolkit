



-- =============================================
-- Author:		Michel Georg
-- Create date: 10.06.2022
-- Description:	Starter für ExecuteSQLScript. 
--				In Debug-Modus werden lediglich die Skriptinhalte ausgegeben,
--				ansonsten werden die Skripte gestartet.
-- =============================================
CREATE     PROCEDURE [sst].[ExecuteSQLScripts]
	@scripts as sst.ExecuteScriptParameter READONLY,
	@CreateScriptOnly bit = 0,
	@Debug bit = 0
AS
BEGIN

	declare @count_statements int;
	SET NOCOUNT ON;

	if @Debug = 1
	begin		
		select @count_statements = count(*) from @scripts;
		select * from @scripts order by Id;
		return @count_statements;
	end

	create table #PREPARE_STATEMENTS
	(
		ScriptId int not null,
		Zieldatenbank nvarchar(128),
		Zielobjekt nvarchar(128),
		Skript nvarchar(max),
		Meldung nvarchar(1000),
		SortOrder tinyint
	);

	insert into #PREPARE_STATEMENTS
	select s.Id as ScriptId, s.Zieldatenbank, s.Zielobjekt, s.Skript, s.Meldung, s.SortOrder
	from @scripts s
	where s.[Validierung] is null and s.[Obsolete] = 0;

	-- Variablen für Inhalt der Skripte bzw. Statements. Wird für die Cursor gebraucht.
	declare	
		@script_id int,
		@datenbank varchar(128),
		@target varchar(128),
		@script varchar(max),
		@meldung varchar(1000),
		@validation_script nvarchar(3500),
		@expected_result bit;

	-- lokale Variablen für den Cursor mit den Validierungsskripts
	declare @check_result table ( valid bit );
	declare 
		@validation_result bit,
		@validation_executable nvarchar(4000);

	declare loop_validation cursor for
	select
		s.Id,
		s.Zieldatenbank,
		Validierung = N'select case when exists ( ' + s.Validierung + ' ) then 1 else 0 end',
		s.ValidierungResultat
	from @scripts s
	where not s.Validierung is null and s.[Obsolete] = 0;

	open loop_validation;
	fetch next from loop_validation into @script_id, @datenbank, @validation_script, @expected_result;

	while @@FETCH_STATUS = 0
	begin
		set @validation_executable = 
				'execute ' +
				@datenbank + 
				'.sys.sp_executesql @stmt = N''' +
				REPLACE(@validation_script, '''','''''') +
				'''';

		insert into @check_result exec ( @validation_executable );
		select top 1 @validation_result = valid from @check_result;

		if @validation_result = @expected_result
		begin
			insert into #PREPARE_STATEMENTS
			select
				s.Id, s.Zieldatenbank, s.Zielobjekt, s.Skript, s.Meldung, s.SortOrder
			from @scripts s
			where s.Id = @script_id;
		end

		fetch next from loop_validation into @script_id, @datenbank, @validation_script, @expected_result;
	end

	close loop_validation;
	deallocate loop_validation;


	select ROW_NUMBER() OVER (ORDER BY SortOrder, ScriptId) as Schritt, 
	s.ScriptId, s.Zieldatenbank, s.Zielobjekt, s.Skript, s.Meldung, s.SortOrder
	into #EXECUTE_STATEMENTS 
	from #PREPARE_STATEMENTS s
	order by SortOrder, ScriptId;


    if @CreateScriptOnly = 1
	begin
		select @count_statements = count(*) from #EXECUTE_STATEMENTS;
		select Schritt, Skript from #EXECUTE_STATEMENTS order by Schritt;
		return @count_statements;
	end

	declare @count_changes int = 0;

	declare exec_script cursor for
	select
		Zieldatenbank, Zielobjekt, 
		ToBeExecuted = Zieldatenbank + '.sys.sp_executesql N''' + REPLACE(Skript, '''', '''''') + ''';', 
		Meldung
	from #EXECUTE_STATEMENTS
	order by Schritt;

	open exec_script;
	fetch next from exec_script into @datenbank,@target,@script,@meldung;

	while @@FETCH_STATUS = 0
	begin
		begin try
			print @meldung;
			exec (@script);
			set @count_changes = @count_changes + 1
		end try
		begin catch
			declare @err_message varchar(4000) = 
				'Fehler bei Objekt ' + @target + ': ' + ERROR_MESSAGE() + '; Skript: ' + @script;
			RAISERROR(@err_message, 16 , 1)
		end catch

		fetch next from exec_script into @datenbank,@target,@script,@meldung;
	end

	close exec_script;
	deallocate exec_script;

	return @count_changes;

END