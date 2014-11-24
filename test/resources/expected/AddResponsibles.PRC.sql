if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddResponsibles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddResponsibles]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.AddResponsibles
(
    @ID_C int
/*
    процедура заносит список ответственных для группы @ID_C 
	на основе списка из временной таблицы aTmpID_C
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

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO
