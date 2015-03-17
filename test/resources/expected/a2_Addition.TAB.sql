if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[a2_Addition]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[a2_Addition]
GO

CREATE table [dbo].[a2_Addition] (
	[ID_C] [bigint] NOT NULL ,
	[ID_T] [bigint] NOT NULL ,
	[BeeSumBilling] [numeric](14, 2) NULL ,
	[BeeSumAdd] [numeric](14, 2) NULL ,
	[BeeSumAll] [numeric](14, 2) NULL ,
	[Date4] datetime2(4) NOT NULL,
--	comment about datetime2
	[Date21] datetime2(3) NULL,
--	another comment about datetime2 type
	[Date22] [datetime2](3) NULL , -- comment after description
	[Date23] [datetime2](3) NULL
) ON [PRIMARY]
GO

 CREATE  INDEX [ind_a2_Addition_ID_C] ON [dbo].[a2_Addition]([ID_C]) ON [PRIMARY]
GO

 CREATE  INDEX [ind_a2_Addition_ID_T] ON [dbo].[a2_Addition]([ID_T]) ON [PRIMARY]
GO

exec sp_addextendedproperty N'MS_Description', N'Кэш для b_Addition при расчетах', N'user', N'dbo', N'table', N'a2_Addition'
GO

