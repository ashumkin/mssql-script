if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AddTimeServices]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AddTimeServices]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
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

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

