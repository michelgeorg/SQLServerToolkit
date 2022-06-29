CREATE TYPE [sst].[GetViewsData] AS TABLE (
    [Datenbank]   NVARCHAR (128) NULL,
    [Schema_Name] NVARCHAR (128) NULL,
    [Ansicht]     NVARCHAR (128) NULL,
	[AnsichtSchemaName] NVARCHAR (256) NULL,
	[Fullname]    NVARCHAR (256) NULL);

