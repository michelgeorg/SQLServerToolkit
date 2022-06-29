CREATE TYPE [sst].[ExecuteScriptParameter] AS TABLE (
    [Id]                    INT             IDENTITY (1, 1) NOT NULL,
    [Zieldatenbank]         NVARCHAR (128)  NOT NULL,
    [Zielobjekt]            NVARCHAR (128)  NOT NULL,
    [Skript]                NVARCHAR (MAX)  NOT NULL,
    [Meldung]               NVARCHAR (1000) NULL,
    [SortOrder]             TINYINT         DEFAULT ((0)) NOT NULL,
    [Validierung]           NVARCHAR (3500) NULL,
    [ValidierungResultat]   BIT             NULL,
	[Obsolete]           BIT             DEFAULT (1) NOT NULL);



