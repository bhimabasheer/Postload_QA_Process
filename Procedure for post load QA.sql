USE [Data_Load]
GO
/****** Object:  StoredProcedure [dbo].[Get_postload_QA]    Script Date: 12/14/2023 3:43:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Get_postload_QA]
    @ClientId NVARCHAR(20),
    @FilerCode NVARCHAR(20)
	
AS

/***

AUTHOR        : BEEMA & TONCY
CREATED DATE  : 11/27/2023
MODIFIED USER : 
MODIFIED DATE : 11/27/2023

TO RUN THIS PROCEDURE PLEASE FOLLOW THIS

EXEC Get_postload_QA @ClientId = 'n5a' , @FilerCode = 'br'

@ClientId is the client id its a varchar value
@FilerCode is also a vachar value and it the code of Filler

***/

BEGIN
	SET NOCOUNT ON

    DECLARE @Count INT, @IssueID INT, @SQL NVARCHAR(MAX), @AccTableName NVARCHAR(100), @BalTableName NVARCHAR(100),
			@TranTableName NVARCHAR(100), @ParmDefinition nvarchar(500)  

	SET @AccTableName = 'Accounts_Stg_'+@ClientId+ '_' +@FilerCode
	SET @BalTableName = 'Balance_Stg_'+@ClientId+ '_' +@FilerCode
	SET @TranTableName = 'Trade_Stg_'+@ClientId+ '_' +@FilerCode
	SET @ParmDefinition = '@Count INT OUTPUT'




	BEGIN

		INSERT INTO [Postload_QA_Details] (CLIENTID, FILERID) VALUES(@ClientId,@FilerCode)

		SET @IssueID = scope_identity()
		select @IssueID
	



		-- INSERTING DATA TO POAST LOAD TABLE AND RETRIVING THE ISSUE ID --

		--IF((SELECT COUNT(*) FROM [Postload_QA_Details] WHERE [ClientID]=@ClientId AND [FilerID] = @FilerCode) = 0)
		--	BEGIN
		--		INSERT INTO [Postload_QA_Details] (CLIENTID, FILERID) VALUES(@ClientId,@FilerCode)

		--		SET @IssueID = (SELECT IssueID FROM [Postload_QA_Details] WHERE [ClientID]=@ClientId AND [FilerID] = @FilerCode)
		--		-Print('Inserted new issue ID')
		--	END

		--ELSE
		--	BEGIN

		--		SET @IssueID = (SELECT IssueID FROM [Postload_QA_Details] WHERE [ClientID]=@ClientId AND [FilerID] = @FilerCode)

		--	END

	END
	

	BEGIN

	    --Print ('Post load QA Accounts Stated')

		-- 1. CHECK Account_Number Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@AccTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Account_Number],'''')='''')'
		
		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT
		
		
		IF(@Count>0)
	
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [A_Acc_Num_Null] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 2. CHECK Account_Number Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@AccTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Account_Number] like ''%E+%'')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [A_Acc_Num_Exp] = 1
				WHERE IssueID = @IssueID

			END

	END
	BEGIN
		-- 3. CHECK Filing_Mailing

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@AccTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Filing_or_MailingFlag_F_M],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET Filing_Mailing = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 4. CHECK [Closed Accounts (Y N)]

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@AccTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Closed_Accounts_Y_N],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET Closed_Acc = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 5. CHECK Duplicate rows


		SET @SQL= ';with cte as
                    (
						select row_number() over( partition by FileName,RowNum order by 
						FileName,RowNum) as rw
						FROM '+@AccTableName+'
						WHERE Client_ID = '''+@ClientId+''' 
					)
                    select @Count = COUNT(*)
                    from cte
                    where rw>1'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				SET @SQL= ';with cte as
							(
								select row_number() over( partition by FileName,RowNum order by 
								FileName,RowNum) as rw
								FROM '+@AccTableName+'
								WHERE Client_ID = '''+@ClientId+''' 
							)
							DELETE
							from cte
							where rw>1'

				EXEC sp_executesql @SQL

				UPDATE [dbo].[Postload_QA_Details]
				SET Isdup_row_deleted = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 6. CHECK Duplicate Account_Number and Account Name


		SET @SQL= ';with cte as
                    (
						select row_number() over( partition by [Account_Number],[Account_Name] order by 
						[Account_Number],[Account_Name]) as rw
						FROM '+@AccTableName+'
						WHERE Client_ID = '''+@ClientId+''' 
					)
                    select @Count = COUNT(*)
                    from cte
                    where rw>1'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				SET @SQL= ';with cte as
							(
								select Accounts_ID,row_number() over( partition by [Account_Number],[Account_Name] order by 
								[Account_Number],[Account_Name]) as rw
								FROM '+@AccTableName+'
								WHERE Client_ID = '''+@ClientId+''' 
							)
							update '+@AccTableName+' set Isdelete = 1 where Accounts_ID in (select Accounts_ID from cte where rw>1)'

				EXEC sp_executesql @SQL

			END

	END

	BEGIN
		-- 6. CHECK Multiple Account Name for same Account_Number


		SET @SQL= ';with cte as
                    (
						SELECT [Account_Number],[Account_Name],Isdelete,COUNT(*) OVER (PARTITION BY [Account_Number]) AS rw
						FROM '+@AccTableName+'
						WHERE Client_ID = '''+@ClientId+''' AND isnull(Isdelete,0)<>1
					)
                    select @Count = COUNT(*)
                    from cte
                    where rw>1 '

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET Mul_Acc_Name = 1
				WHERE IssueID = @IssueID

			END

	END

	print('Post load QA Accounts successfully completed')

	BEGIN 

    --Print('Post load QA Balance Started')

	--1. CHECK Account_Number Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Account_Number],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_Acc_Num_Null] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 2. CHECK Account_Number Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Account_Number] like ''%E+%'')'
		

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_Acc_Num_Exp] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 3. CHECK CUSIP Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_IdentifierNumber_CUSIP] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_ISIN],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
							   ISNULL(TICKER,'''')='''' )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_CUSIP_Exp] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 4. CHECK ISIN Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_IdentifierNumber_ISIN] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
							   ISNULL(TICKER,'''')='''' )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_ISIN_Exp] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 5. CHECK TICKER Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [TICKER] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_ISIN],'''')=''''  )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_TICKER_Exp] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 6. CHECK SEDOL Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_IdentifierNumber_SEDOL] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([TICKER],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_ISIN],'''')=''''  )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_SEDOL_Exp] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 7. CHECK CUSIP Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN([Security_IdentifierNumber_CUSIP])<>9)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of CUSIP exceeded.')

			END

	END

	BEGIN
		-- 8. CHECK ISIN Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN([Security_IdentifierNumber_ISIN])<>12)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of ISIN exceeded.')

			END

	END

	BEGIN
		-- 9. CHECK SEDOL Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN([Security_IdentifierNumber_SEDOL])<>7)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of SEDOL exceeded.')

			END

	END

	BEGIN
		-- 9. CHECK TICKER Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN(TICKER)<>11)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of TICKER exceeded.')

			END

	END

	BEGIN
		-- 10. CHECK Coupon Rate is Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_Name] like ''%[%]%'' and [Coupon_Rate] is null)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Coupon Rate is Null Presented.')

			END

	END

	BEGIN
		-- 11. CHECK Blank Security of Balance

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([TICKER],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_ISIN],'''')='''')'
							   --AND ISNULL([Call_Put_Indicator],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_Blank_Security] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 12. CHECK Call_Put_Indicator is Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
						 [Security_Name] like ''% CALL %'' or [Security_Name] like ''% PUT %'' or [Security_Name] like ''%CALL %''
						 or [Security_Name] like ''%PUT %''
						 and ISNULL([Call_Put_Indicator],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Call_Put_Indicator Null presented.')

			END

	END

	BEGIN
		-- 13. CHECK As Of Date Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [As_of_Date_YearEnd_or_MonthEnd] is null )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_AsofDate_Null] = 1
				WHERE IssueID = @IssueID

			END
			

	END

	BEGIN
		-- 14. CHECK Quantity is  Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Quantity_Face_Value] is null )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

			SET @SQL= 	'UPDATE '+@BalTableName+'
				SET [Quantity_Face_Value] = 0.0000
				WHERE Client_ID = '''+@ClientId+'''  AND  [Quantity_Face_Value] is null'

				EXEC sp_executesql @SQL
			END
			

	END

	BEGIN
		-- 15. CHECK Account Reconciliation

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@BalTableName+'
						 WHERE Client_ID = '''+@ClientId+''' and [Account_Number] not in 
						 (select distinct isnull([Account_Number],'''') from '+@AccTableName+' where Client_ID='''+@ClientId+''' ))'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_Acc_Recon] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 16. CHECK Duplicate rows in Balance


		SET @SQL= ';with cte as
                    (
						select row_number() over( partition by FileName,RowNum order by 
						FileName,RowNum) as rw
						FROM '+@BalTableName+'
						WHERE Client_ID = '''+@ClientId+''' 
					)
                    select @Count = COUNT(*)
                    from cte
                    where rw>1'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				SET @SQL= ';with cte as
							(
								select row_number() over( partition by FileName,RowNum order by 
								FileName,RowNum) as rw
								FROM '+@BalTableName+'
								WHERE Client_ID = '''+@ClientId+''' 
							)
							DELETE
							from cte
							where rw>1'

				EXEC sp_executesql @SQL

				UPDATE [dbo].[Postload_QA_Details]
				SET [B_Isdup_row_deleted] = 1
				WHERE IssueID = @IssueID

			END
			
	END
	


    BEGIN 

		--Print('Post load QA of Trade Started')

		--1. CHECK Account_Number Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Account_Number],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Acc_Num_Null] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 2. CHECK Account_Number Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Account_Number] like ''%E+%'')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Acc_Num_Exp] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 3. CHECK CUSIP Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_IdentifierNumber_CUSIP] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_ISIN],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
							   ISNULL(TICKER,'''')='''' )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_CUSIP_Exp] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 4. CHECK ISIN Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_IdentifierNumber_ISIN] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
							   ISNULL(TICKER,'''')='''' )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_ISIN_Exp] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 5. CHECK TICKER Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [TICKER] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_ISIN],'''')=''''  )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_TICKER_Exp] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 6. CHECK SEDOL Exponential

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_IdentifierNumber_SEDOL] like ''%E+%'' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([TICKER],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_ISIN],'''')=''''  )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_SEDOL_Exp] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 7. CHECK CUSIP Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN([Security_IdentifierNumber_CUSIP])<>9)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of CUSIP exceeded.')

			END
            
	END

	BEGIN
		-- 8. CHECK ISIN Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN([Security_IdentifierNumber_ISIN])<>12)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of ISIN exceeded.')

			END
			
	END

	BEGIN
		-- 9. CHECK SEDOL Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN([Security_IdentifierNumber_SEDOL])<>7)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of SEDOL exceeded.')

			END
			
	END

	BEGIN
		-- 9. CHECK TICKER Length

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   LEN(TICKER)<>11)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Length of TICKER exceeded.')

			END
			
	END

	BEGIN
		-- 10. CHECK Coupon Rate is Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   [Security_Name] like ''%[%]%'' and [Coupon_Rate] is null)'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Coupon Rate is Null.')

			END
			
	END

	BEGIN
		-- 11. CHECK Blank Security of Trade

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
							   ISNULL([Security_IdentifierNumber_SEDOL],'''')='''' AND 
                               ISNULL([Security_IdentifierNumber_CUSIP],'''')='''' AND 
							   ISNULL([TICKER],'''')='''' AND 
							   ISNULL([Security_IdentifierNumber_ISIN],'''')='''' AND 
							   [ReMapped_Transaction_Type]<>''X'')'
							   --AND ISNULL([Call_Put_Indicator],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Blank_Security] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 12. CHECK Call_Put_Indicator is Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
						 [Security_Name] like ''% CALL %'' or [Security_Name] like ''% PUT %'' or [Security_Name] like ''%CALL %''
						 or [Security_Name] like ''%PUT %''
						 and ISNULL([Call_Put_Indicator],'''')='''')'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				print('Call_Put_Indicator is Null.')

			END
			
	END

	BEGIN
		-- 13. CHECK Trade_Date Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Trade_Date] is null )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Trade_Date_Null] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 14. CHECK Quantity is  Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Quantity_Face_Value] is Null )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

			SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [ReMapped_Transaction_Type] = ''X''
				WHERE Client_ID = '''+@ClientId+'''  AND  [Quantity_Face_Value] is Null'

				EXEC sp_executesql @SQL
			END
			
	END

	BEGIN
		-- 15. CHECK Quantity is  Zero

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Quantity_Face_Value] =0 )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

			SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [ReMapped_Transaction_Type] = ''X''
				WHERE Client_ID = '''+@ClientId+'''  AND  [Quantity_Face_Value] =0 ' 

				EXEC sp_executesql @SQL
			END
			
	END

	BEGIN
		-- 16. CHECK Quantity is  absolute or not

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Quantity_Face_Value] <0 )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

			SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [Quantity_Face_Value] = abs([Quantity_Face_Value])
				WHERE Client_ID = '''+@ClientId+'''  AND  [Quantity_Face_Value] <0 '

				EXEC sp_executesql @SQL
			END
			
	END

	BEGIN
		-- 17. CHECK Net Total is  absolute or not

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Net_Total] <0 )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

			SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [Net_Total] = abs([Net_Total])
				WHERE Client_ID = '''+@ClientId+''' '

				EXEC sp_executesql @SQL
			END
			
	END

	BEGIN
		-- 18. CHECK Commission is  absolute or not

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Commission] <0 )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

			SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [Commission] = abs([Commission])
				WHERE Client_ID = '''+@ClientId+''' '

				EXEC sp_executesql @SQL
			END
			
	END

	BEGIN
		-- 19. CHECK Transaction Type is  Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [Transaction_Type] is null )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Tran_Type_Null] = 1
				WHERE IssueID = @IssueID

			END
			
	END


	BEGIN
		-- 20. CHECK ReMapped_Transaction_Type is  Null

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND  [ReMapped_Transaction_Type] is Null )'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Remapped_Trantype_Null] = 1
				WHERE IssueID = @IssueID

			END
			
	END
	BEGIN
		-- 21. CHECK Account Reconciliation

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' and [Account_Number] not in 
						 (select distinct [Account_Number] from '+@AccTableName+' where Client_ID='''+@ClientId+''' ))'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Acc_Recon] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 22. CHECK Duplicate rows in Trade


		SET @SQL= ';with cte as
                    (
						select row_number() over( partition by FileName,RowNum order by 
						FileName,RowNum) as rw
						FROM '+@TranTableName+'
						WHERE Client_ID = '''+@ClientId+''' 
					)
                    select @Count = COUNT(*)
                    from cte
                    where rw>1'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				SET @SQL= ';with cte as
							(
								select row_number() over( partition by FileName,RowNum order by 
								FileName,RowNum) as rw
								FROM '+@TranTableName+'
								WHERE Client_ID = '''+@ClientId+''' 
							)
							DELETE
							from cte
							where rw>1'

				EXEC sp_executesql @SQL

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Isdup_row_deleted] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 23. CHECK Free Deliver OUT

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
						 ISNULL([Gross_Price_perShare],0)=0 AND 
                         ISNULL([Principal_Aggregate_Cost],0)=0 AND 
                         [ReMapped_Transaction_Type] in (''S'',''P'') AND 
						 [Quantity_Face_Value]>0)'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
			BEGIN

				SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [ReMapped_Transaction_Type] = ''TO''
				WHERE Client_ID = '''+@ClientId+''' AND 
				ISNULL([Gross_Price_perShare],0)=0 AND 
                ISNULL([Principal_Aggregate_Cost],0)=0 AND 
                [ReMapped_Transaction_Type] =''S'' AND 
				[Quantity_Face_Value]>0'

				EXEC sp_executesql @SQL

			END
			
	END

	BEGIN
		-- 24. CHECK Free Deliver IN

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
						 ISNULL([Gross_Price_perShare],0)=0 AND 
                         ISNULL([Principal_Aggregate_Cost],0)=0 AND 
                         [ReMapped_Transaction_Type] in (''P'',''S''))'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
			BEGIN

				SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [ReMapped_Transaction_Type] = ''TI''
				WHERE Client_ID = '''+@ClientId+''' AND 
				ISNULL([Gross_Price_perShare],0)=0 AND 
                ISNULL([Principal_Aggregate_Cost],0)=0 AND 
                [ReMapped_Transaction_Type] =''P'' '

				EXEC sp_executesql @SQL

			END
			
	END

	BEGIN
		-- 25. Calculate Principal

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
						 ISNULL([Principal_Aggregate_Cost],0)=0 and 
                         ISNULL([Quantity_Face_Value],0)<>0 and 
                         ISNULL([Gross_Price_perShare],0)<>0)'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
	
			BEGIN

				SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [Principal_Aggregate_Cost] = [Gross_Price_perShare]*[Quantity_Face_Value]
                where Client_ID='''+@ClientId+''' AND
                isnull([Principal_Aggregate_Cost],0)=0 and 
				isnull([Quantity_Face_Value],0)<>0 and 
				isnull([Gross_Price_perShare],0)<>0 '

				EXEC sp_executesql @SQL

			END
			
	END

	BEGIN
		-- 26. Calculate [Gross_Price_perShare]

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' AND 
						 ISNULL([Principal_Aggregate_Cost],0)=0 and 
                         ISNULL([Quantity_Face_Value],0)<>0 and 
                         ISNULL([Gross_Price_perShare],0)<>0)'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
	
			BEGIN

				SET @SQL= 	'UPDATE '+@TranTableName+'
				SET [Gross_Price_perShare] = [Principal_Aggregate_Cost]/[Quantity_Face_Value]
                where Client_ID='''+@ClientId+''' AND
                isnull([Principal_Aggregate_Cost],0)<>0 and 
				isnull([Quantity_Face_Value],0)<>0 and 
				isnull([Gross_Price_perShare],0)=0  '

				EXEC sp_executesql @SQL

			END
			
	END

	BEGIN
		-- 27. CHECK Duplicate Transaction_Id 

		SET @SQL = 'SET @Count = (SELECT COUNT(*) FROM ' + @TranTableName + ' t1
					WHERE Client_ID = ''' + @ClientId + ''' AND isnull([ReMapped_Transaction_Type],'''') <> ''X'' 
					AND EXISTS (
					SELECT 1
					FROM ' + @TranTableName + ' t2
					WHERE t1.[Transaction_Id] = t2.[Transaction_Id]
					AND t1.Client_ID = t2.Client_ID
					AND t2.Client_ID = ''' + @ClientId + '''
					HAVING COUNT(t2.[Transaction_Id]) > 1 ))'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Duplicate_TranId] = 1
				WHERE IssueID = @IssueID

			END

	END

	BEGIN
		-- 28. CHECK Account Reconciliation 

		SET @SQL= 'SET @Count = (SELECT COUNT(*)
						 FROM '+@TranTableName+'
						 WHERE Client_ID = '''+@ClientId+''' and [Account_Number] not in 
						 (select distinct isnull([Account_Number],'''') from '+@AccTableName+' where Client_ID='''+@ClientId+''' ))'
						

		EXEC sp_executesql @SQL , @ParmDefinition, @Count = @Count OUTPUT
	
		
		IF(@Count>0)
			BEGIN

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Acc_Recon] = 1
				WHERE IssueID = @IssueID

			END
			
	END

	BEGIN
		-- 29. CHECK Duplicate rows in Trade


		SET @SQL= ';with cte as
                    (
						select row_number() over( partition by FileName,RowNum order by 
						FileName,RowNum) as rw
						FROM '+@TranTableName+'
						WHERE Client_ID = '''+@ClientId+''' 
					)
                    select @Count = COUNT(*)
                    from cte
                    where rw>1'

		EXEC sp_executesql @SQL, @ParmDefinition, @Count = @Count OUTPUT

		IF(@Count>0)
			BEGIN

				SET @SQL= ';with cte as
							(
								select row_number() over( partition by FileName,RowNum order by 
								FileName,RowNum) as rw
								FROM '+@TranTableName+'
								WHERE Client_ID = '''+@ClientId+''' 
							)
							DELETE
							from cte
							where rw>1'

				EXEC sp_executesql @SQL

				UPDATE [dbo].[Postload_QA_Details]
				SET [T_Isdup_row_deleted] = 1
				WHERE IssueID = @IssueID

			END
			
	END
	
	
END
