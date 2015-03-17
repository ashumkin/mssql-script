if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ViewUsesTable]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[ViewUsesTable]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.ViewUsesTable
AS
    SELECT 1, 2, 3
    FROM dbo.a2_Addition
GO

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

