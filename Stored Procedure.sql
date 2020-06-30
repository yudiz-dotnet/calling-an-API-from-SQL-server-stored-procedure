USE [DBName]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
/*

Author:              Uditsing Khati
Create date:          --/--/2020
Description:          Update Details
Modification Log:
	Date:
Test:      
	[dbo].[QueueLimitDetails_Update]

*/

CREATE PROCEDURE [dbo].[QueueLimitDetails_Update]
AS
BEGIN
	SET NOCOUNT ON;
 
	IF EXISTS(SELECT Id FROM QueueLimitDetails WHERE Success = 0)
	BEGIN
	
		BEGIN TRY -– Try block start
		
			BEGIN -- Variable declaration
				SET TEXTSIZE 2147483647;
				DECLARE @ContentType NVARCHAR(64);
				DECLARE @ResponseText AS TABLE(ResponseText NVARCHAR(MAX));
				DECLARE @Status NVARCHAR(32);
				DECLARE @StatusText NVARCHAR(32);
				DECLARE @URL NVARCHAR(MAX);
				DECLARE @Result AS INT;
				DECLARE @RequestBody NVARCHAR(MAX);
				DECLARE @Object INT;
				DECLARE @Method NVARCHAR(10);
				DECLARE @ErrorMessage NVARCHAR(MAX);
				DECLARE @ContentLength INT;
			END -- Variable declaration
			
			BEGIN -- Set Header
				SET @ContentType = 'application/json';
					SET @Method = 'POST'
			END -- Set Header
			
			BEGIN -- Set your desired URL where you want to fire API request
				SET @URL = 'http://localhost:5000/api/v1/sa/setbetlimit'
			END -- Set your desired URL where you want to fire API request
			
			BEGIN -- Set RequestBody parameter value
				SET @RequestBody ='{
					"username": "{Username}",
					"currency": "{Currency}",
					"Gametype": "{GameType}"
				}';
				
				-- Here we get data from the existing table
					DECLARE @Username NVARCHAR(50),
						@Currency NVARCHAR(50),
						@GameType NVARCHAR(50);
					
					SELECT TOP (1) @Username = Username 
					FROM QueueLimitDetails 
					WHERE Success = 0;
					
					SELECT TOP (1) @Currency = Currency 
					FROM QueueLimitDetails 
					WHERE Username = @Username	
					
					-- We have multiple game type
						SELECT TOP (1) @GameType = Gametype 
						FROM QueueLimitDetails 
						WHERE Username = @Username 
							AND Success = 0;
					
					SET @RequestBody = REPLACE (@requestBody, '{Username}', @Username)
					SET @requestBody = REPLACE (@requestBody, '{Currency}', @Currency)
					SET @requestBody = REPLACE (@requestBody, '{GameType}', @GameType)
			END -- Set RequestBody parameter value           
			
			BEGIN -- Open a connection
				EXEC @Result = sp_OACreate 'MSXML2.ServerXMLHTTP', @Object OUTPUT;
				IF @Result <> 0 BEGIN RAISERROR('Unable to open HTTP connection.', 10, 1) RETURN END;
			END -- Open a connection  
			
			BEGIN -- Make a request
				EXEC @Result = sp_OAMethod @Object, 'open', NULL, @Method, @URL, 'false'
				IF @Result <> 0 BEGIN RAISERROR('sp_OAMethod Open failed.', 16, 1) RETURN END;
		
				EXEC @Result = sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Type', @ContentType
				IF @Result <> 0 BEGIN RAISERROR('sp_OAMethod setRequestHeader(Content-Type) failed.', 16, 1) RETURN END;
		
				SET @ContentLength = LEN(@requestBody)
				EXEC @Result = sp_OAMethod @Object, 'setRequestHeader', null, 'Content-Length', @ContentLength
				IF @Result <> 0 BEGIN RAISERROR('sp_OAMethod setRequestHeader(Content-Length) failed.', 16, 1) RETURN END;
		
				EXEC @Result = sp_OAMethod @Object, send, null, @requestBody
				IF @Result <> 0 BEGIN RAISERROR('sp_OAMethod Send failed.', 16, 1) RETURN END;
			END -- Make a request
			
			BEGIN -- Handle response
				EXEC @Result = sp_OAGetProperty @Object, 'Status', @Status OUT
				IF @Result <> 0 BEGIN RAISERROR('sp_OAGetProperty Status not fetch.', 16, 1) RETURN END;
		
				EXEC @Result = sp_OAGetProperty @Object, 'StatusText', @StatusText OUT;
				IF @Result <> 0 BEGIN RAISERROR('sp_OAGetProperty StatusText not fetch.', 16, 1) RETURN END;
				
				-- Insert response into @ResponseText Table
					INSERT INTO @ResponseText (ResponseText) EXEC sp_OAGetProperty @Object, 'responseText'
					IF @Result <> 0 EXEC sp_OAGetErrorInfo @Object
			END -- Handle response
			
			BEGIN -- Destroy Object
				EXEC sp_OADestroy @Object
			END -- Destroy Object
			
			BEGIN -- Manage response
				-- Check response HTTP status code
					IF (@Status = '200')
					BEGIN -- Update QueueLimitDetails
						UPDATE QueueLimitDetails
						SET Success = 1
						WHERE Username = @Username
							AND GameType = @Gametype
							AND Success = 0
					END -- Update QueueLimitDetails
					ELSE
					BEGIN
						DECLARE @JSONResponseText NVARCHAR(MAX);
						SELECT @JSONResponseText = responseText FROM @responseText;
						-- Error Log Table
							INSERT INTO QueueLimitDetails_ErrorLog
							(
								ResquestBody
								, Response
							)
							VALUES
							(
								@RequestBody
								,'FAIL:'+ @JSONResponseText
							)
					END
			END -- Manage response
		END TRY -- Try block end
		BEGIN CATCH -- Catch block start
			
			BEGIN -- Destroy Object
				EXEC sp_OADestroy @Object
			END -- Destroy Object
			
			BEGIN -- Error Log Table
				INSERT INTO QueueLimitDetails_ErrorLog
				(
					ResquestBody
					, Response
				)
				VALUES
				(
					@RequestBody
					,'ERROR:'+ ERROR_MESSAGE ()
				)
			END -- Error Log Table
			RAISERROR (@ErrorMessage, 16, 1)
			RETURN;
		END CATCH -- Catch block end
	END
END