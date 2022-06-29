CREATE TYPE [sst].[GetSynonymData] AS TABLE (
    [Datenbank]            NVARCHAR (128) NOT NULL,
    [Id]                   INT            NOT NULL,
    [Schema_Name]          NVARCHAR (128) NOT NULL,
    [Synonym_Name]         NVARCHAR (128) NOT NULL,
    [Synonym_Fullname]     NVARCHAR (256) NOT NULL,
    [Referenz_Objekt_Name] NVARCHAR (128) NOT NULL);

