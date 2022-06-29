CREATE TYPE [sst].[GetUsersData] AS TABLE (
    [Datenbank]            NVARCHAR (128) NOT NULL,
    [Id]                   INT            NOT NULL,
    [UserName]             NVARCHAR (128) NULL,
    [UserType]             NVARCHAR (60)  NULL,
    [UserDefaultSchema]    NVARCHAR (128) NULL,
    [UserDefaultSprache]   NVARCHAR (128) NULL,
    [Rolle]                NVARCHAR (128) NULL,
    [LoginId]              VARBINARY (85) NULL,
    [LoginName]            NVARCHAR (128) NULL,
    [LoginDefaultDatabase] NVARCHAR (128) NULL,
    [LoginAktiv]           BIT            NULL);

