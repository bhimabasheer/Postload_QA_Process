USE [Data_Load]
GO
/****** Object:  StoredProcedure [dbo].[PostLoad_ReportGen]    Script Date: 30-11-2023 15:45:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[PostLoad_ReportGen]
    @IssueID INT,
	@ReportId INT
AS
SET NOCOUNT ON -------

/***

AUTHOR : BEEMA & TONCY
CREATED DATE : 11/27/2023
MODIFIED USER : 
MODIFIED DATE : 11/27/2023

TO RUN THIS PROCEDURE PLEASE FOLLOW THIS

EXEC PostLoad_ReportGen @IssueID = 3 , @ReportId = 1

@IssueID :-  is the IssueID from  the table Postload_QA_Details which we need to take reports

@ReportId :-  Please check below for the ID's

				1 . Account Number NUll in Account
				2 . Account Number Exponential in Account
				3 . Multiple Account Name for same Account Number in Account
				4 . Account Number NUll in Balance
				5 . Account Number Exponential in Balance
				6 . Cusip Exponential in Balance
				7 . Isin Exponential in Balance
				8 . Sedol Exponential in Balance
				9 . Ticker Exponential in Balance
				10 . As Of Data NULL in Balance
				11 . Blank Security in Balance
				12 . Account Reconciliation in Balance
				13 . Account Number NUll in Trade
				14 . Account Number Exponential in Trade
				15 . Cusip Exponential in Trade
				16 . Isin Exponential in Trade
				17 . Sedol Exponential in Trade
				18 . Ticker Exponential in Trade
				19 . Trade Date NULL in Trade
				20 . Blank Security in Trade
				21 . Transaction Type NULL in Trade
				22 . ReMapped Transaction Type NULL in Trade
				23 . Account Reconciliation in Trade
				24 . Duplicate Transaction ID in Trade 
			

***/

BEGIN

    DECLARE @AccTableName NVARCHAR(100), @BalTableName NVARCHAR(100),
			@TranTableName NVARCHAR(100), @ParmDefinition nvarchar(500),@Query NVARCHAR(MAX), @ClientId NVARCHAR(20),
			@FilerCode NVARCHAR(20), @A_Acc_Num_Null BIT, @A_Acc_Num_Exp BIT,@Mul_Acc_Name BIT, @B_Acc_Num_Null BIT, @B_Acc_Num_Exp BIT, @B_CUSIP_Exp BIT, @B_ISIN_Exp BIT,@B_SEDOL_Exp BIT, @B_TICKER_Exp BIT, 
			@B_AsofDate_Null BIT, @B_Blank_Security BIT, @B_Acc_Recon BIT,  @T_Acc_Num_Null BIT, @T_Acc_Num_Exp BIT,
			@T_CUSIP_Exp BIT, @T_ISIN_Exp BIT,@T_SEDOL_Exp BIT, @T_TICKER_Exp BIT, @T_Trade_Date_Null BIT, @T_Blank_Security BIT, @T_Tran_Type_Null BIT, @T_Remapped_Trantype_Null BIT , @T_Acc_Recon BIT,
			@T_Duplicate_TranId BIT 

	SET @A_Acc_Num_Null = (SELECT ISNULL(A_Acc_Num_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @A_Acc_Num_Exp  = (SELECT ISNULL(A_Acc_Num_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @Mul_Acc_Name  = (SELECT ISNULL(Mul_Acc_Name,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_Acc_Num_Null   = (SELECT ISNULL(B_Acc_Num_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_Acc_Num_Exp   = (SELECT ISNULL(B_Acc_Num_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_CUSIP_Exp = (SELECT ISNULL(B_CUSIP_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_ISIN_Exp  = (SELECT ISNULL(B_ISIN_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_SEDOL_Exp   = (SELECT ISNULL(B_SEDOL_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_TICKER_Exp   = (SELECT ISNULL(B_TICKER_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_AsofDate_Null   = (SELECT ISNULL(B_AsofDate_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @B_Blank_Security  = (SELECT ISNULL(B_Blank_Security,0) FROM Postload_QA_Details WHERE IssueID = @IssueID) 
	SET @B_Acc_Recon   = (SELECT ISNULL(B_Acc_Recon,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Acc_Num_Null   = (SELECT ISNULL(T_Acc_Num_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Acc_Num_Exp   = (SELECT ISNULL(T_Acc_Num_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_CUSIP_Exp   = (SELECT ISNULL(T_CUSIP_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_ISIN_Exp   = (SELECT ISNULL(T_ISIN_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_SEDOL_Exp   = (SELECT ISNULL(T_SEDOL_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_TICKER_Exp   = (SELECT ISNULL(T_TICKER_Exp,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Trade_Date_Null   = (SELECT ISNULL(T_Trade_Date_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Blank_Security   = (SELECT ISNULL(T_Blank_Security,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Tran_Type_Null = (SELECT ISNULL(T_Tran_Type_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Remapped_Trantype_Null   = (SELECT ISNULL(T_Remapped_Trantype_Null,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Acc_Recon   = (SELECT ISNULL(T_Acc_Recon,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	SET @T_Duplicate_TranId   = (SELECT ISNULL(T_Duplicate_TranId,0) FROM Postload_QA_Details WHERE IssueID = @IssueID)
	


	SET @ClientId = (SELECT ClientID FROM [Postload_QA_Details] WHERE IssueID = @IssueID)
	SET @FilerCode = (SELECT FilerID FROM [Postload_QA_Details] WHERE IssueID = @IssueID)

	SET @AccTableName = 'Accounts_Stg_'+@ClientId+'_'+@FilerCode
	SET @BalTableName = 'Balance_Stg_'+@ClientId+'_'+@FilerCode
	SET @TranTableName = 'Trade_Stg_'+@ClientId+'_'+@FilerCode
	SET @ParmDefinition = '@Count INT OUTPUT'

	BEGIN
		--CHECK ACCOUNT NUMBER NULL IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@A_Acc_Num_Null=1 and @ReportId = 1)

		BEGIN

			SET @Query = 'SELECT * FROM '+@AccTableName+' WHERE ISNULL([Account Number],'''')='''''

			EXEC sp_executesql @Query

		END

		--CHECK ACCOUNT NUMBER EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@A_Acc_Num_Exp=1 and @ReportId = 2)

		BEGIN

			SET @Query = 'SELECT * FROM '+@AccTableName+' WHERE ISNULL([Account Number],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK  MULTIPLE ACCOUNT NAME FOR SAME ACCOUNT NUMBER IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@Mul_Acc_Name=1 and @ReportId = 3)

		BEGIN

			SET @Query = ';with cte as
                    (
						SELECT [Account Number],[Account Name],Isdelete , COUNT(*) OVER (PARTITION BY [Account Number]) AS rw
						FROM '+@AccTableName+'
						WHERE ClientID = '''+@ClientId+''' AND isnull(Isdelete,0)<>1
					)
                    select *
                    from cte
                    where rw>1 '

			EXEC sp_executesql @Query

		END

		--CHECK ACCOUNT NUMBER EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_Acc_Num_Null=1 and @ReportId = 4)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([Account Number],'''') = '''''

			EXEC sp_executesql @Query

		END

		--CHECK CUSIP EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_Acc_Num_Exp=1 and @ReportId = 5)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([Account Number],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

	IF (@B_CUSIP_Exp=1 and @ReportId = 6)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([Security Identifier Number - CUSIP],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK ISIN EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_ISIN_Exp=1 and @ReportId = 7)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([Security Identifier Number - ISIN],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK SEDOL EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_SEDOL_Exp=1 and @ReportId = 8)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([Security Identifier Number - SEDOL],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END


		--CHECK TICKER EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_TICKER_Exp=1 and @ReportId = 9)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL(TICKER,'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK AS OF DATE NULL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_AsofDate_Null=1 and @ReportId = 10)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([As of Date (Year-End or Month-End)],'''')='''''

			EXEC sp_executesql @Query

		END

		--CHECK BLANK SECURITY  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_Blank_Security=1 and @ReportId = 11)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE ISNULL([Security Identifier Number - CUSIP],'''')='''' AND 
								ISNULL([Security Identifier Number - ISIN],'''')='''' AND ISNULL([Security Identifier Number - SEDOL],'''')=''''	
								AND ISNULL(TICKER,'''')='''''
			

			EXEC sp_executesql @Query

		END

		--CHECK ACCOUNT RECONCILATION IN BALANCE  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@B_Acc_Recon=1 and @ReportId = 12)

		BEGIN

			SET @Query = 'SELECT * FROM '+@BalTableName+' WHERE [Account Number] not in (select distinct [Account Number] FROM '+@AccTableName+'
						WHERE ClientID = '''+@ClientId+''')'

			EXEC sp_executesql @Query

		END

		--CHECK ACCOUNT NUMBER NULL IN TRADE  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_Acc_Num_Null=1 and @ReportId = 13)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Account Number],'''') = '''''

			EXEC sp_executesql @Query

		END

		--CHECK ACCOUNT NUMBER EXPONENTIAL IN TRADE  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_Acc_Num_Exp=1 and @ReportId = 14)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Account Number],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK CUSIP EXPONENTIAL IN TRADE  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_CUSIP_Exp=1 and @ReportId = 15)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Security Identifier Number - CUSIP],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK ISIN EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_ISIN_Exp=1 and @ReportId = 16)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Security Identifier Number - ISIN],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK SEDOL EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_SEDOL_Exp=1 and @ReportId = 17)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Security Identifier Number - SEDOL],'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END


		--CHECK TICKER EXPONENTIAL  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_TICKER_Exp=1 and @ReportId = 18)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL(TICKER,'''') LIKE ''%E+%'''

			EXEC sp_executesql @Query

		END

		--CHECK TRADE DATE NULL IN TRADE  IF EXIST THEN SELECT THE CORESPONDING DATA

	IF (@T_Trade_Date_Null=1 and @ReportId = 19)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Trade Date],'''') ='''' AND ISNULL([ReMapped Transaction Type],'''') <>''X'''

			EXEC sp_executesql @Query

		END

		-- CHECK BLANK SECURITY IN TRADE IF EXIST THEN SELECT THE CORRESPONDING DATA

	IF (@T_Blank_Security=1 and @ReportId = 20)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Security Identifier Number - CUSIP],'''')='''' AND 
								ISNULL([Security Identifier Number - ISIN],'''')='''' AND ISNULL([Security Identifier Number - SEDOL],'''')=''''	
								AND ISNULL(TICKER,'''')='''' AND ISNULL([ReMapped Transaction Type],'''') <>''X'''
			

			EXEC sp_executesql @Query

		END

		-- CHECK  TRANSACTION TYPE NULL IN TRADE IF EXIST THEN SELECT THE CORRESPONDING DATA

	IF (@T_Tran_Type_Null=1 and @ReportId = 21)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([Transaction Type],'''') ='''' AND ISNULL([ReMapped Transaction Type],'''') <>''X'''

			EXEC sp_executesql @Query

		END

		-- CHECK  REMAPPED TRANSACTION TYPE NULL IN TRADE IF EXIST THEN SELECT THE CORRESPONDING DATA

	IF (@T_Remapped_Trantype_Null=1 and @ReportId = 22)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE ISNULL([ReMapped Transaction Type],'''') ='''''

			EXEC sp_executesql @Query

		END

		-- CHECK  ACCOUNT RECONCILIATION IN TRADE IF EXIST THEN SELECT THE CORRESPONDING DATA

	IF (@T_Acc_Recon=1 and @ReportId = 23)

		BEGIN

			SET @Query = 'SELECT * FROM '+@TranTableName+' WHERE [Account Number] not in (select distinct [Account Number] FROM '+@AccTableName+'
						WHERE ClientID = '''+@ClientId+''')'

			EXEC sp_executesql @Query

		END

		-- CHECK  DUPLICATE TRANSACTION ID IN TRADE IF EXIST THEN SELECT THE CORRESPONDING DATA

	IF (@T_Duplicate_TranId=1 and @ReportId = 24)

		BEGIN

			SET @Query = ';with cte as (
			select *, row_number() over( partition by [Transaction Id] order by [Transaction Id] )as rw
			from '+@TranTableName+' where ClientID ='''+@ClientId+''' and [ReMapped Transaction Type] <>''X''
			and [Transaction Id] in (select distinct [Transaction Id] from '+@TranTableName+' where ClientID = '''+@ClientId+'''
			group by [Transaction Id] having COUNT([Transaction Id]) > 1) 

			)select *
			from cte
			where  [ReMapped Transaction Type] <>''X'' and rw between 1 and 3 order by [Transaction Id] '



			EXEC sp_executesql @Query

		END

	


	END
		

END


