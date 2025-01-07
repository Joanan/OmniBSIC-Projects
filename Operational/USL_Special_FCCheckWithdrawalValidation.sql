--------------------------------------------------------------------------------------------------------------------------------------------    
/*      
 <info>      
 <name>[USL_Special_GomoaCallCheckWithdrawalValidation]</name>      
 <desc>      
   Stored Procedure to validate and check if withdrawals reduces balance less
   than 100 of FC      
----------------------------------------------------------------------      
-- Version  Author          Date       Changes      
-- 1.0      BankUser          07.09.16   Initial Version       
----------------------------------------------------------------------      
 </info>      
*/      
sp_helptext2 USL_Special_FCCheckWithdrawalValidation
ALTER PROCEDURE [dbo].[USL_Special_FCCheckWithdrawalValidation]         
@BpID INT          
AS       
BEGIN       
DECLARE        
   @ErrOR                         dbo.TLongInfo_U,          
   @Amount                        INT,
   @AccountNumber                 nvarchar(MAX), 
   @Balance                       money,
   @Currency                      nvarchar(3),
   @accountcontractproductid      INT 
SET @Amount =  (SELECT BP.Amount FROM BusinessProcesses BP WHERE BP.BPId = @BpID)      
SET @AccountNumber = (SELECT BP.RelatedContractNumber FROM BusinessProcesses BP WHERE BP.BPId = @BpID)  
SET @Balance = (SELECT dbo.accounts.BalanceAvailable  FROM accounts WHERE dbo.accounts.AccountNum = @AccountNumber)
SET @Currency = ( SELECT dbo.accounts.Currency FROM accounts WHERE dbo.accounts.AccountNum = @AccountNumber)  
SET @accountcontractproductid = ( SELECT c.AccountContractProductId FROM dbo.Contracts c WHERE c.ContractNumber = @AccountNumber)                           
IF (@Balance < 100 AND @accountcontractproductid IN (
select AccountContractProductId from AccountContractProducts where Currency !='GHS' and ContractTypeID in (3,4) and ShortNameLocal like '%FEA On-Shore%'
 --and @AccountNumber<>'1003190115001'
) AND @Currency != 'GHS') OR (@Balance < 200 AND @accountcontractproductid IN(
select AccountContractProductId from AccountContractProducts where Currency !='GHS' and ContractTypeID in (3,4) and ShortNameLocal like '%FCA Off-Shore%'
) AND @Currency != 'GHS' )
BEGIN 
	GOTO AccountHasFundsReseved   
END
ELSE
	RETURN       
  --/////////////////////////////////////////          
 --Section of Errors:          
 --/////////////////////////////////////////          
  AccountHasFundsReseved:            
 SELECT @ErrOR='NOT ALLOWED: BALANCE AFTER WITHDRAWAL LESS THAN FLOAT LIMIT'           
 RAISERROR (@ErrOR, 16, 1)      
 END            
 --select AccountContractProductId,FullNameLocal from AccountContractProducts where Currency !='GHS' and ContractTypeID in (3,4) and ShortNameLocal like '%FCA%'