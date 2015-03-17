if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ScalarFunction]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[ScalarFunction]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
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

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

