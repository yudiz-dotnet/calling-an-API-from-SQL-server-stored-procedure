SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
 
CREATE TRIGGER [dbo].[QueueLimitDetails_Insert_Update]
ON  [dbo].[QueueLimitDetails]
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN -- Call SP here
		EXEC [dbo].[QueueLimitDetails_Update]
	END -- Call SP here
END