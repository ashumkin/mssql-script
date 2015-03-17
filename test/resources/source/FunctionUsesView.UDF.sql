if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[FunctionUsesView]') and xtype in (N'FN', N'IF', N'TF'))
drop function [dbo].[FunctionUsesView]
GO

SET QUOTED_IDENTIFIER ON 
GO

SET ANSI_NULLS ON 
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

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

