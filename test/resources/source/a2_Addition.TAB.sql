if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[a2_Addition]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[a2_Addition]


GO

CREATE TABLE [dbo].[a2_Addition] (
	[ID_C] [bigint] NOT NULL ,   
	[ID_T] [bigint] NOT NULL ,
	[BeeSumBilling] [numeric](14, 2) NULL ,
	[BeeSumAdd] [numeric](14, 2) NULL ,
	[BeeSumAll] [numeric](14, 2) NULL ,
	[Date4] datetime2(4) NOT NULL,
	[Date21] datetime2 NULL,
	[Date22] [datetime2] NULL ,
	[Date23] [datetime2](3) NULL 
) ON [PRIMARY]



GO


 CREATE  INDEX [ind_a2_Addition_ID_T] ON [dbo].[a2_Addition]([ID_T]) ON [PRIMARY]  

 
GO
 CREATE  INDEX [ind_a2_Addition_ID_C] ON [dbo].[a2_Addition]([ID_C]) ON [PRIMARY]
GO

exec sp_addextendedproperty N'MS_Description', N'Кэш для b_Addition при расчетах', N'user', N'dbo', N'table', N'a2_Addition'
GO
