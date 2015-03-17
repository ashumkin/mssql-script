--Version=123

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddTimeServices]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddTimeServices]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddResponsibles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddResponsibles]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FunctionUsesView]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[FunctionUsesView]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ViewUsesFunction]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[ViewUsesFunction]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ViewUsesTable]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[ViewUsesTable]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ScalarFunction]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[ScalarFunction]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b_ContractorsAddInfo]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[b_ContractorsAddInfo]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[a2_Addition]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[a2_Addition]


GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_ContractorsAddInfo_ID_C]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_ContractorsAddInfo] DROP CONSTRAINT FK_b_ContractorsAddInfo_ID_C
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_ContractorsResponsibles_ID_C]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_ContractorsResponsibles] DROP CONSTRAINT FK_b_ContractorsResponsibles_ID_C
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_ContractorsResponsibles_ID_C_Group]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_ContractorsResponsibles] DROP CONSTRAINT FK_b_ContractorsResponsibles_ID_C_Group
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_ContractorsTree_ID_C]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_ContractorsTree] DROP CONSTRAINT FK_b_ContractorsTree_ID_C
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_Doc_b_Contractors]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_Doc] DROP CONSTRAINT FK_b_Doc_b_Contractors
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_Telefons_b_Contractors]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_Telefons] DROP CONSTRAINT FK_b_Telefons_b_Contractors
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FK_b_Telefons_b_Contractors1]') and OBJECTPROPERTY(id, N'IsForeignKey') = 1)
ALTER TABLE [dbo].[b_Telefons] DROP CONSTRAINT FK_b_Telefons_b_Contractors1
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b_Contractors]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[b_Contractors]
GO

CREATE TABLE [dbo].[b_Contractors] (
	[ID_C] [int] IDENTITY (1, 1) NOT NULL ,
	[ParentID] [int] NULL ,
	[ID_GS] [bigint] NULL ,
	[PLatID] [int] NULL ,
	[Type] [smallint] NULL ,
	[telefon] [varchar] (50) COLLATE Cyrillic_General_CI_AS NULL ,
	[Kod1C] [varchar] (20) COLLATE Cyrillic_General_CI_AS NULL ,
	[Sotrud] [smallint] NULL ,
	[Removed] [smallint] NULL ,
	[Dogovor] [ntext] COLLATE Cyrillic_General_CI_AS NULL ,
	[Name_c] [varchar] (100) COLLATE Cyrillic_General_CI_AS NULL ,
	[ContactPerson] [varchar] (100) COLLATE Cyrillic_General_CI_AS NULL ,
	[Email_c] [varchar] (100) COLLATE Cyrillic_General_CI_AS NULL ,
	[DopInfo] [varchar] (3000) COLLATE Cyrillic_General_CI_AS NULL ,
	[Limit] [money] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE table [dbo].[a2_Addition] (
	[ID_C] [bigint] NOT NULL ,   
	[ID_T] [bigint] NOT NULL ,
	[BeeSumBilling] [numeric](14, 2) NULL ,
	[BeeSumAdd] [numeric](14, 2) NULL ,
	[BeeSumAll] [numeric](14, 2) NULL ,
	[Date4] datetime2(4) NOT NULL,
--	comment about datetime2
	[Date21] datetime2 NULL,
--	another comment about datetime2 type
	[Date22] [datetime2] NULL , -- comment after description
	[Date23] [datetime2](3) NULL 
) ON [PRIMARY]



GO

CREATE TABLE [dbo].[b_ContractorsAddInfo] (
	[ID_C] [int] NOT NULL ,
	[UseGroupCertificate] [bit] NOT NULL ,
	[UseGroupDetails] [bit] NOT NULL
) ON [PRIMARY]
GO

CREATE FUNCTION dbo.ScalarFunction
(
/*
    function returns integer
*/
    @Value bit
)
RETURNS int
AS
BEGIN
    RETURN CAST(@Value as int)
END
GO

CREATE VIEW dbo.ViewUsesTable
AS
    SELECT 1, 2, 3
    FROM dbo.a2_Addition
GO

CREATE VIEW dbo.ViewUsesFunction
AS
    SELECT 4, 5, 6, *
    FROM dbo.ViewUsesTable
    WHERE dbo.ScalarFunction(2) = 1
GO

CREATE FUNCTION dbo.FunctionUsesView
(
/*
    function uses View in it's SELECT
*/
    @Key varchar(50)
)
RETURNS varchar(4096)
AS
BEGIN
    DECLARE @Value varchar(4096)
    SELECT @Value = ISNULL([Value], '')
    FROM dbo.ViewUsesTable WITH (NOLOCK)
    WHERE [Key] = @Key

    RETURN ISNULL(@Value, '')
END
GO

CREATE PROCEDURE dbo.AddResponsibles
(
    @ID_C int
/*
    procedure description
*/	
)
--ENCRYPTION--
AS
BEGIN
    DELETE FROM dbo.b_ContractorsResponsibles
	WHERE ID_C_Group = @ID_C
	
	INSERT INTO dbo.b_ContractorsResponsibles (ID_C_Group, ID_C)
	SELECT @ID_C, ID_C
	FROM dbo.aTmpID_C WITH (NOLOCK)
END


GO

CREATE PROCEDURE dbo.AddTimeServices
(
/*
    procedure description
*/	
    @ID_S bigint,
    @TimeA varchar(8),
    @TimeB varchar(8),
    @Weeks varchar(7)
)
--ENCRYPTION--
AS
    -- a word about datetime2 type
    DELETE FROM dbo.b_TimeServices
	WHERE ID_S = @ID_S
	
	IF ISNULL(@Weeks, '') <> '' 
		INSERT INTO dbo.b_TimeServices(ID_S, TimeA, TimeB, Weeks)
		VALUES (@ID_S, @TimeA, @TimeB, @Weeks)
GO



ALTER TABLE [dbo].[b_Contractors] WITH NOCHECK ADD
	CONSTRAINT [PK_b_contractors] PRIMARY KEY  CLUSTERED
	(
		[ID_C]
	)  ON [PRIMARY]


GO
ALTER TABLE [dbo].[b_Contractors] WITH NOCHECK ADD
	CONSTRAINT [DF_b_Contractors_PLatID] DEFAULT (0) FOR [PLatID],
	CONSTRAINT [DF_b_Contractors_Remover] DEFAULT (0) FOR [Removed]
GO


 CREATE  INDEX [ind_b_Contractors_ParentID] ON [dbo].[b_Contractors]([ParentID]) ON [PRIMARY]
GO

exec sp_addextendedproperty N'MS_Description', N'"Removed" flag. 1 - YES, 0 - NO', N'user', N'dbo', N'table', N'b_Contractors', N'column', N'Removed'
GO
exec sp_addextendedproperty N'MS_Description', null, N'user', N'dbo', N'table', N'b_Contractors', N'column', N'DopInfo'
GO
exec sp_addextendedproperty N'MS_Description', N'Contractors list', N'user', N'dbo', N'table', N'b_Contractors'
GO

CREATE  INDEX [ind_a2_Addition_ID_T] ON [dbo].[a2_Addition]([ID_T]) ON [PRIMARY]  

 
GO
 CREATE  INDEX [ind_a2_Addition_ID_C] ON [dbo].[a2_Addition]([ID_C]) ON [PRIMARY]
GO

exec sp_addextendedproperty N'MS_Description', N'Cache of b_Addition while processing', N'user', N'dbo', N'table', N'a2_Addition'
GO

ALTER TABLE [dbo].[b_ContractorsAddInfo] WITH NOCHECK ADD
	CONSTRAINT [PK_b_ContractorsAddInfo] PRIMARY KEY  CLUSTERED
	(
		[ID_C]
	)  ON [PRIMARY]
GO

ALTER TABLE [dbo].[b_ContractorsAddInfo] WITH NOCHECK ADD
	CONSTRAINT [FK_b_ContractorsAddInfo_ID_C] FOREIGN KEY
	(
		[ID_C]
	) REFERENCES [dbo].[b_Contractors] (
		[ID_C]
	) ON DELETE CASCADE
GO

