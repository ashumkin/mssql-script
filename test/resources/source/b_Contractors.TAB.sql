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


