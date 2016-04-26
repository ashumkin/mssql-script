if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[b_ContractorsAddInfo]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[b_ContractorsAddInfo]
GO

CREATE TABLE [dbo].[b_ContractorsAddInfo] (
	[ID_C] [int] NOT NULL ,
	[UseGroupCertificate] [bit] NOT NULL ,
	[UseGroupDetails] [bit] NOT NULL
) ON [PRIMARY]
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

