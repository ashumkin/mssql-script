if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ViewUsesFunction]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].[ViewUsesFunction]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
GO

CREATE VIEW dbo.ViewUsesFunction
AS
    SELECT 4, 5, 6, *
    FROM dbo.ViewUsesTable
    WHERE dbo.ScalarFunction(2) = 1
GO

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

