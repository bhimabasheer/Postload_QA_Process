create table Postload_QA_Details(

IssueID int identity(1,1),
FilerID varchar (100) NULL,  
ClientID varchar (15)  NULL,
Closed_Acc bit  NULL,
Filing_Mailing bit  NULL,
A_Acc_Num_Exp bit  NULL,
A_Acc_Num_Null bit  NULL,


B_CUSIP_Exp bit  NULL,
B_ISIN_Exp bit  NULL,
B_TICKER_Exp bit  NULL,   
B_SEDOL_Exp bit  NULL,

B_Acc_Num_Null bit  NULL,
B_Acc_Num_Exp bit  NULL,
B_AsofDate_Null bit  NULL,
B_Blank_Security bit  NULL,
B_Acc_Recon bit  NULL,

T_CUSIP_Exp bit  NULL,
T_ISIN_Exp bit  NULL,
T_TICKER_Exp bit  NULL,
T_SEDOL_Exp bit  NULL,
T_Acc_Num_Null bit  NULL,
T_Acc_Num_Exp bit  NULL,
T_Trade_Date_Null bit  NULL,
T_Blank_Security bit  NULL,
T_Acc_Recon bit  NULL,
T_Duplicate_TranId bit  NULL,
T_Remapped_Trantype_Null bit  NULL,
T_Tran_Type_Null bit  NULL,

Created_Date  datetime Default getdate() NOT NULL,
Created_User   Varchar (255) default CURRENT_USER NOT NULL,

Modified_Date  datetime   NULL,
Modified_User   Varchar (255)  NULL ,

PRIMARY KEY (IssueID)

)








EXEC Get_postload_QA @ClientId = 'n5a' , @FilerCode = 'BR'

select * from  Postload_QA_Details where clientid='n5a'



declare @Count Int
;with cte as
              (
                select row_number() over( partition by FileName,RowNum order by 
                FileName,RowNum) as rw
				FROM [dbo].[Accounts_Stg_n5a_BR]
				WHERE Client_ID = 'n5a' 
			  )
              select @Count = COUNT(*)
                from cte
                where rw>1
print @Count




