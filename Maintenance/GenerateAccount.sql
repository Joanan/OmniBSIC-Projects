/*      
 <info>      
 <name>[f_int_GenerateAccountNumber]</name>      
 <desc>Account and Contract number generating function      
</desc>      
----------------------------------------------------------------------      
-- Version  Author     Date     Changes      
-- 1.0      BankUser   10.04.06  Initial Version       
-- 1.1      BankUser         28.11.06  Added opening accounts with DivisionTypeId = 5 (by Client)       
-- 1.2      BankUser         05.12.06  Currency code is added now to  LC accounts as well      
-- 1.3      BankUser         28.03.07  ClientId type  changed from int to bigint      
-- 1.4      BankUser            16.08.07  Bug fixing. @BankCode should be taken from GlobalParameters      
-- 1.5      BankUser            23.08.07  Added @CanMakeExternalTF parameter      
--			BankUser            2014.07.30 Use ClientID instead of Client Code in deriving Residence StatusID  
--			BankUser			2015.04.28 Fix timeout error during second Account Generation for Same Client
--			BankUser			2015.05.07 Reduce Amount Number from 15 to 13
--			BankUser			2016.11.18 Change Logic for Fixed Deposit Accounts Generation (Increased Counter to 9999)
--			BankUser			2016.11.28 Fixed Bonus SA not creating
--			BankUser			2016.12.01 Fix For Nostro Accounts Opening
--------------------------------------------------------------------------------------------------------------------------      
 </info>      
*/      
ALTER FUNCTION f_int_GenerateAccountNumber       
( @AccountType TINYINT      
 -- 1 - Customer account per contract      
 -- 2 - Bank contract      
 -- 3 - Cashbox      
 -- 4 - Inter-branch      
 -- 5 - FX positions      
 -- 6 - Customer account per client      
 , @GeneralLedgerCode CHAR(6)      
 , @ClientID BIGINT      
 , @Currency INT      
 , @BranchID INT      
 , @ContractType INT      
 , @ComponentType INT      
 , @CashTerminal INT      
 , @BranchID_to INT      
 , @Currency_to INT      
 , @ContractServiceComponentDefinitionID INT = 0      
 , @CanMakeExternalTF BIT = 0      
)      
RETURNS dbo.TName_U      
AS      
BEGIN      
 DECLARE      
   @Account    dbo.TName_U      
 , @AccountLeft   dbo.TName      
 , @AccountRight   dbo.TName      
 , @BankCode    VARCHAR(10)      
 , @ClientCode   dbo.TCode      
 , @BANKPREFIX   VARCHAR(10)      
 , @CountryId   INT      
 , @InternalCurrencyCode CHAR(3)      
 , @Counter    INT      
 , @BranchCode   VARCHAR(10)      
 , @key     VARCHAR(2)      
 , @AccountMask   dbo.TName      
 , @SystemContractTypeId INT      
 , @ContractServiceId INT      
 , @ServiceComponentTypeId INT      
 , @AccountByClient  INT      
 , @ClientsFirstAccount dbo.TName_U      
 , @ClientCodeOld  dbo.TCode      
 --SELECT @BankCode = BankCode FROM dbo.Branches (NOLOCK) WHERE BranchId = @BranchID      
 SELECT @SystemContractTypeId = ct.SystemContractTypeID,      
     @ContractServiceId = cscd.ContractServiceID,      
     @ServiceComponentTypeId = cscd.ServiceComponentTypeID      
 FROM dbo.ContractServiceComponentsDefinition cscd       
      INNER JOIN dbo.ContractTypes ct ON ct.ContractTypeID = cscd.ContractTypeID      
    WHERE cscd.ServiceComponentDefinitionID = @ContractServiceComponentDefinitionID       
 SELECT @BankCode = CONVERT(VARCHAR(8),dbo.f_int_GetParameterValue('BANKCODE'))      
 SELECT @CountryId = CONVERT(INT,dbo.f_int_GetParameterValue('COUNTRY_ID'))      
 SELECT @BANKPREFIX = CONVERT(VARCHAR(10),dbo.f_int_GetParameterValue('BANKPREFIX'))      
 SELECT @ClientCode = Code, @ClientCodeOld=Code       
 FROM dbo.Clients (NOLOCK)      
 WHERE ClientId = @ClientId      
 SELECT  @ClientCode =  REPLACE(dbo.f_migr_EliminateLiterals (@ClientCode),'.','')      
    /* Values by country */      
 IF @CountryId = 51 -- If generating account for armenia      
 BEGIN      
  SELECT @InternalCurrencyCode = LTRIM(InternalCode)      
  FROM dbo.Currencies (NOLOCK)      
  WHERE ISONum = @Currency      
  SET @AccountRight = '-' + RIGHT('0000000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)      
  SET @AccountRight = @AccountRight + LEFT(@InternalCurrencyCode, 1)      
  IF @ContractServiceComponentDefinitionID = 0 SET @ContractServiceComponentDefinitionID = 'Invalid CSCD ID'      
 END      
 IF @CountryId = 276 -- If generating account for Germany      
 BEGIN      
  SELECT @InternalCurrencyCode = LTRIM(InternalCode)      
  FROM dbo.Currencies (NOLOCK)      
  WHERE ISONum = @Currency      
  SET @AccountRight = '.' + RIGHT('0000000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)      
  SET @AccountRight = @AccountRight + LEFT(@InternalCurrencyCode, 1)      
  IF @ContractServiceComponentDefinitionID = 0 SET @ContractServiceComponentDefinitionID = 'Invalid CSCD ID'      
 END      
 IF @CountryId = 268 -- If generating account for Georgia      
 BEGIN      
  SELECT @InternalCurrencyCode = LTRIM(ISO)      
  FROM dbo.Currencies (NOLOCK)      
  WHERE ISONum = @Currency      
  SET @AccountRight = RIGHT('0000000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 5)      
  SET @AccountRight = @AccountRight + LEFT(@InternalCurrencyCode, 3)      
  IF @ContractServiceComponentDefinitionID = 0 SET @ContractServiceComponentDefinitionID = 'Invalid CSCD ID'      
 END      
 IF @CountryId = 498 -- If generating account for Moldova      
 BEGIN      
  SELECT @InternalCurrencyCode = LTRIM(ISO)      
  FROM dbo.Currencies (NOLOCK)      
  WHERE ISONum = @Currency      
  SET @AccountRight = RIGHT('0000000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 5)      
  SET @AccountRight = @AccountRight + LEFT(@InternalCurrencyCode, 3)      
  IF @ContractServiceComponentDefinitionID = 0 SET @ContractServiceComponentDefinitionID = 'Invalid CSCD ID'      
 END      
 IF @CountryId = 68 -- If generating account for Bolivia      
  OR @CountryId= 218 --If Generating Account For Ecuador        
 BEGIN      
  SELECT @InternalCurrencyCode = LTRIM(InternalCode)      
  FROM dbo.Currencies (NOLOCK)      
  WHERE ISONum = @Currency      
 END      
 /* Account per Contract or Account per Client */       
 IF @AccountType in (1,6 )-- Customer per contract or customer per client      
 BEGIN      
  IF @CountryId = 417 -- If generating account for Kyrgyzstan      
  BEGIN        
   SELECT @InternalCurrencyCode = LTRIM(InternalCode)      
   FROM dbo.Currencies (NOLOCK)      
   WHERE ISONum = @Currency         
   SELECT @BranchCode = BankCode       
   FROM dbo.Branches (NOLOCK)      
   WHERE BranchId = @BranchId      
   SELECT @Counter=COUNT(ContractComponents.AccountId)+1      
     FROM dbo.Clients (NOLOCK)      
     INNER JOIN dbo.CustomerContractRelations (NOLOCK) ON CustomerContractRelations.ClientId = Clients.ClientId      
     INNER JOIN dbo.Contracts (NOLOCK) ON Contracts.ContractNumber = CustomerContractRelations.ContractNumber      
     INNER JOIN dbo.ContractComponents  (NOLOCK) ON ContractComponents.ContractNumber = Contracts.ContractNumber      
     inner join dbo.Accounts a (nolock) on a.accountID = contractComponents.accountID      
     WHERE       
     Clients.ClientId=@clientID AND       
     ContractComponents.ServiceComponentDefinitionID=@ContractServiceComponentDefinitionID      
     and a.currency = @InternalCurrencyCode      
   SET @AccountRight = RIGHT('000000' + CAST(@ClientCode AS VARCHAR(20)), 6)+ RIGHT('00' + CAST(@Counter AS VARCHAR(20)), 2)      
   SET @AccountRight = @AccountRight + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)      
   SET @AccountRight = RIGHT('000' + @BranchCode, 3) + @AccountRight       
   SET @Key =  RIGHT('00'+cast((cast(@AccountRight AS bigint) % 97) AS VARCHAR(2)),2)         
   IF @Key='00'  SET @Key='97'       
   SET @Account=@AccountRight+@Key+'.'+RIGHT('000' + CAST(@Currency AS VARCHAR(20)), 3)      
  END      
  IF @CountryId = 804 -- If generating account for ukraine      
  BEGIN      
   /*if CHARINDEX('.',@ClientCodeOld)=0      
    SET @AccountRight = RIGHT('000009' + CAST(@ClientCode AS VARCHAR(20)), 7)      
   else*/      
    SET @AccountRight = RIGHT('000000' + CAST(@ClientCode AS VARCHAR(20)), 7)      
   SET @AccountRight = @AccountRight + '.' + CAST(@Currency AS VARCHAR(20))      
   IF @AccountType = 1       
    -- Michael: this construction should work much faster then that , which is below      
    /*select @AccountByClient = MAX(SUBSTRING(AccountNum, 6, 2)) + 1 from dbo.CustomerContractRelations ccr (NOLOCK)      
    inner join contractcomponents ccp (NOLOCK) on ccr.ContractNumber=ccp.ContractNumber      
    inner join accounts acc (NOLOCK) on acc.Accountid=ccp.AccountId      
    inner join currencies cur (NOLOCK) on acc.Currency=cur.ISO      
    where ccr.clientid=@ClientId and ccr.CustomerContractRelationTypeId=1/*owner*/ /*and ccr.IsActive=1  IsActive should not be inside of query to support old owners */      
    and substring(acc.Accountnum,1,4)=@GeneralLedgerCode and cur.ISONum=@Currency      
    */      
    SELECT @AccountByClient = MAX(SUBSTRING(AccountNum, 6, 2)) + 1       
    FROM dbo.Accounts (NOLOCK)       
    WHERE AccountNum LIKE @GeneralLedgerCode + '___' + @AccountRight      
   ELSE  -- @AccountType = 6       
    SELECT @AccountByClient =1 --one account per client in each currency      
    SET @AccountByClient = @AccountByClient % 100      
    if charindex('.',@ClientCodeOld)>0 and isnumeric(substring(@ClientCodeOld,1,1))=0  and substring(@ClientCodeOld,1,1)='F'      
     SET @AccountRight = RIGHT('0' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(2)), 2) + @AccountRight      
    else if charindex('.',@ClientCodeOld)>0 and isnumeric(substring(@ClientCodeOld,1,1))=0  and substring(@ClientCodeOld,1,1)='U'      
     SET @AccountRight = RIGHT('3' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(2)), 2) + @AccountRight      
    else if charindex('.',@ClientCodeOld)>0 and isnumeric(substring(@ClientCodeOld,1,1))=0  and substring(@ClientCodeOld,1,1)='P'      
     SET @AccountRight = RIGHT('4' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(2)), 2) + @AccountRight      
    else if charindex('.',@ClientCodeOld)>0 and isnumeric(substring(@ClientCodeOld,1,1))=0  and substring(@ClientCodeOld,1,1)='B'      
     SET @AccountRight = RIGHT('5' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(2)), 2) + @AccountRight      
    else if charindex('.',@ClientCodeOld)>0 and isnumeric(substring(@ClientCodeOld,1,1))=0 -- Is card      
     SET @AccountRight = RIGHT('1' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(2)), 2) + @AccountRight      
    else  -- New      
     SET @AccountRight = RIGHT('2' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(2)), 2) + @AccountRight      
    SET @Account = @GeneralLedgerCode + dbo.f_int_GenerateAccountKey(@GeneralLedgerCode, @AccountRight, @BankCode) + @AccountRight      
  END      
  IF @CountryId = 807 -- If generating account for MACEDONIA      
  BEGIN      
   IF @AccountType = 1       
   BEGIN          
    DECLARE @CheckIfLoan INT      
    SELECT @CheckIfLoan=0      
    SELECT @CheckIfLoan=Count(*) FROM dbo.ContractTypes      
    WHERE @ContractType=ContractTypeID AND SystemContractTypeID IN (1, 13)      
    IF @CheckIfLoan=0      
    BEGIN      
     SELECT @InternalCurrencyCode = LTRIM(InternalCode)      
     FROM dbo.Currencies (NOLOCK)      
     WHERE ISONum = @Currency         
 SET @AccountRight = @BankCode      
     SET @AccountRight = @AccountRight + LEFT(RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2),1)      
     SET @AccountRight = @AccountRight + RIGHT('000000' + CAST(@ClientCode AS VARCHAR(20)), 6)      
     DECLARE @tempCounter int      
     DECLARE @TempAccounts TABLE (      
      [AccountNum] VARCHAR(30) NULL      
      )      
     INSERT  @TempAccounts(AccountNum) SELECT ContractNumber from dbo.Contracts where ContractNumber like @AccountRight + '%'      
     SET @Counter=-1      
     SET @tempCounter=-1000      
     WHILE @tempCounter<>0      
     BEGIN      
      SET @Counter=@Counter+1      
      select @tempCounter=count(accountnum) from @TempAccounts where substring(accountnum,0,13) = @AccountRight+RIGHT('00'+cast(@Counter as VARCHAR(2)),2)      
     END      
     SET @AccountRight = @AccountRight + RIGHT('00' + CAST(@Counter AS VARCHAR(20)), 2)      
     SET @AccountRight = @AccountRight + LEFT(@InternalCurrencyCode, 1)      
     SET @Key=RIGHT('00'+cast(98 - (CAST(@AccountRight + '00' AS DECIMAL) - (FLOOR(CAST(@AccountRight + '00' AS DECIMAL)/97)*97)) AS VARCHAR(2)),2)      
     SET @AccountRight = @AccountRight + @Key      
     SET @Account = @AccountRight         
    END      
    ELSE      
    BEGIN      
     SELECT @Account=RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) + RIGHT('000000' + cast(ISNULL(MAX(cast(SUBSTRING(ContractNumber,3,6) AS INT))+1,1) AS VARCHAR(6)),6)      
     FROM dbo.Contracts c      
     INNER JOIN dbo.AccountContractProducts acp ON acp.AccountContractProductId = c.AccountContractProductId      
     INNER JOIN dbo.ContractTypes ct ON acp.ContractTypeID=ct.ContractTypeID      
     WHERE ct.SystemContractTypeID=1 AND c.BranchId=@BranchID      
       AND CHARINDEX('.', c.ContractNUmber) = 0      
    END      
   END       
   ELSE -- @AccountType = 6       
   BEGIN         
    SET @Account = @BankCode      
    SET @Account = @Account + RIGHT('00000000' + CAST(@ClientCode AS VARCHAR(20)), 8)      
    SET @Account = @Account + CAST(@Currency AS VARCHAR(3)) + '0'      
    SET @Account = @Account + '.' + CAST(@ContractServiceComponentDefinitionID AS varchar)      
   END    
  END    
  IF @CountryId = 900 -- If generating account for GHANA        
        BEGIN        
            DECLARE @check_digitsGHA INT        
                IF @AccountType = 1         
                BEGIN            
                --DECLARE @CheckIfLoan INT        
                SELECT @CheckIfLoan=0        
                SELECT @CheckIfLoan=Count(*) FROM ContractTypes        
                WHERE @ContractType=ContractTypeID AND SystemContractTypeID IN (1, 12, 13, 22, 37, 33, 34) -- + L/G, L/C        
                    IF @CheckIfLoan=0        
                    BEGIN        
                        IF @ContractType<>176 -- if not debit card        
                        BEGIN             
                            SELECT @InternalCurrencyCode = LTRIM(InternalCode)        
                            FROM dbo.Currencies (NOLOCK)        
                            WHERE ISONum = @Currency           
                            RangeFilledGHA:        
                            IF @Counter=99        
                            BEGIN        
                                SELECT @Counter=-1        
                                SELECT @ClientCode=CAST(CAST(@ClientCode AS INT)+1 AS VARCHAR(20))        
                            END        
                           SET @AccountRight = RIGHT('00' + CAST(@InternalCurrencyCode AS VARCHAR(2)), 2)
                           SET @AccountRight = @AccountRight + RIGHT('000' + CAST(@ContractType AS VARCHAR(3)), 3) 
						   SET @AccountRight = @AccountRight + RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)        
                           SET @AccountRight = @AccountRight + RIGHT('000000' + CAST(@ClientCode AS VARCHAR(20)), 6)        
                           --DECLARE @tempCounter int        
                            DECLARE @TempAccountsGHA TABLE (        
                            [AccountNum] varchar(30) NULL        
             )        
                            INSERT  @TempAccountsGHA(AccountNum) SELECT AccountNum from Accounts where AccountNum like @AccountRight + '%'        
                            SET @Counter=-1        
                            SET @tempCounter=-1000        
                            FindNextEmptyNumberGHA:        
                            WHILE @tempCounter<>0        
                            BEGIN        
                                SET @Counter=@Counter+1        
                                select @tempCounter=count(accountnum) from @TempAccountsGHA where substring(accountnum,1,10) = @AccountRight+RIGHT('00'+cast(@Counter as varchar(2)),2)                   
                                IF @tempCounter<>0 AND @Counter=99  GOTO RangeFilledGHA                   
                            END        
                            --remember for in case if we return back to find because in contract this number exists        
                            DECLARE @remAccountPart TName_U        
                            SET @remAccountPart=@AccountRight        
                            SET @AccountRight = RTRIM(@AccountRight) + RIGHT('00' + CAST(@Counter AS VARCHAR(20)), 2)        
                            -- Check digit        
                            SET @check_digitsGHA= 98 - (CAST(@AccountRight+'00' AS BIGINT) - (CAST(@AccountRight+'00' AS BIGINT)/97)*97)        
                            --      SET @Account = @AccountRight + '0' + RIGHT('00' + cast(@check_digitsGHA as varchar(2)),2)        
                            SET @Account = @AccountRight + RIGHT('00' + cast(@check_digitsGHA as varchar(2)),2)        
                            ---- SET @AccountRight = @AccountRight + LEFT(@InternalCurrencyCode, 1) --- temporal Union        
                            DECLARE @tempCountContracts int        
                            SET @tempCountContracts=0        
                            SELECT @tempCountContracts=Count(*) FROM contracts WHERE ContractNumber=@Account        
                            IF @tempCountContracts>0         
                            BEGIN        
                                SELECT @tempCounter=-1000        
                                SET @AccountRight=@remAccountPart        
                                GOTO FindNextEmptyNumberGHA        
                            END        
                        END         
                        ELSE        
                        BEGIN        
                        -- FOR Debit Card        
                            SELECT @Account= RIGHT('00' + CAST(@InternalCurrencyCode AS VARCHAR(2)), 2) + '99'+ RIGHT('000000' + cast(ISNULL(MAX(cast(SUBSTRING(c.ContractNumber,5,6) AS INT))+1,1) AS varchar(6)),6)  -- TEMPORARY        
                            FROM Contracts c INNER JOIN AccountContractProducts acp ON acp.AccountContractProductId = c.AccountContractProductId               
                            WHERE acp.ContractTypeID=176 AND c.ContractNumber LIKE RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)+'________' --c.BranchId=@BranchID        
                            AND CHARINDEX('.', c.ContractNUmber) = 0        
                            AND CHARINDEX('-', c.ContractNUmber) = 0         
                        END        
                    END        
                    ELSE        
                    BEGIN        
                    -- IT IS USED ONLY BY THE JOBS (otherwise it is generated in con_Contracts_InsUpd)        
                        SELECT @Account = RIGHT('00' + CAST(@BranchID AS NVARCHAR(2)), 2)         
                        + RIGHT('000000' + CAST(ISNULL(MAX(CAST(SUBSTRING(a.AccountNum, 3, 6) AS INT)) + 1, 1) AS NVARCHAR(6)),6)         
                        FROM Accounts (NOLOCK) a         
                        WHERE a.AccountNum LIKE RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) + '______.' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4))                 
                    END        
                END         
                ELSE -- @AccountType = 6         
                BEGIN           
                    SET @Account = @BankCode        
                    SET @Account = @Account + RIGHT('00000000' + CAST(@ClientCode AS VARCHAR(20)), 8)        
                    SET @Account = @Account + CAST(@Currency AS VARCHAR(3)) + '0'        
                    SET @Account = @Account + '.' + CAST(@ContractServiceComponentDefinitionID AS varchar)        
                END        
        END        
  IF @CountryId = 180 -- If generating account for CONGO        
        BEGIN        
            DECLARE @check_digitsCOD INT    
            DECLARE @resident INT    
                IF @AccountType = 1         
                BEGIN            
                --DECLARE @CheckIfLoan INT        
                SELECT @CheckIfLoan=0    
                SELECT @resident=LTRIM(RTRIM(ResidenceStatusId)) FROM Clients WHERE ClientId = @ClientID       
                SELECT @CheckIfLoan=Count(*) FROM ContractTypes        
                WHERE @ContractType=ContractTypeID AND SystemContractTypeID IN (1, 12, 13, 22, 37, 33, 34) -- + L/G, L/C        
                    IF @CheckIfLoan=0        
                    BEGIN        
                        IF @ContractType <> 176 -- if not debit card        
                        BEGIN             
                            SELECT @InternalCurrencyCode = LTRIM(InternalCode)        
                            FROM dbo.Currencies (NOLOCK)        
                            WHERE ISONum = @Currency           
                            RangeFilledCOD:        
                            IF @Counter=99        
                            BEGIN        
                                SELECT @Counter=-1        
                                SELECT @ClientCode=CAST(CAST(@ClientCode AS INT)+1 AS VARCHAR(20))        
                            END        
						   --SET @AccountRight = '11' + RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)    
                           SET @AccountRight = RIGHT('0000' + CAST(@BankCode AS VARCHAR(4)),4)                 
                           SET @AccountRight = @AccountRight + RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)        
                           SET @AccountRight = @AccountRight + RIGHT('000000' + CAST(@ClientCode AS VARCHAR(20)), 6)        
                           SET @AccountRight = @AccountRight + RIGHT('1' + CAST(@resident AS VARCHAR(1)),1)    
                           SET @AccountRight = @AccountRight + RIGHT('0' + CAST(@InternalCurrencyCode AS VARCHAR(1)),1)    
                           --DECLARE @tempCounter int        
                            DECLARE @TempAccountsCOD TABLE (        
                            [AccountNum] varchar(30) NULL        
                            )        
                            INSERT  @TempAccountsCOD(AccountNum) SELECT AccountNum from Accounts where AccountNum like @AccountRight + '%'        
                            SET @Counter=-1        
                         SET @tempCounter=-1000        
                            FindNextEmptyNumberCOD:        
                            WHILE @tempCounter<>0        
                            BEGIN        
                                SET @Counter=@Counter+1        
                                select @tempCounter=count(accountnum) from @TempAccountsCOD where substring(accountnum,1,13) = @AccountRight+RIGHT('00'+cast(@Counter as varchar(2)),2)                   
                                IF @tempCounter<>0 AND @Counter=99  GOTO RangeFilledCOD                   
                            END        
                            --remember for in case if we return back to find because in contract this number exists        
                            --DECLARE @remAccountPart TName_U        
                            SET @remAccountPart=@AccountRight        
                            SET @AccountRight = RTRIM(@AccountRight) + RIGHT('00' + CAST(@Counter AS VARCHAR(20)), 2)        
                            -- Check digit        
                            SET @check_digitsCOD= 98 - (CAST(@AccountRight+'00' AS BIGINT) - (CAST(@AccountRight+'00' AS BIGINT)/97)*97)        
                            SET @Account = @AccountRight --- + RIGHT('00' + cast(@check_digitsCOD as varchar(2)),2)        
                            --DECLARE @tempCountContracts int        
                            SET @tempCountContracts=0        
                            SELECT @tempCountContracts=Count(*) FROM contracts WHERE ContractNumber=@Account        
                            IF @tempCountContracts>0         
                            BEGIN        
                                SELECT @tempCounter=-1000        
                                SET @AccountRight=@remAccountPart        
                                GOTO FindNextEmptyNumberCOD        
                            END        
                        END         
                        ELSE        
                        BEGIN        
                        -- FOR Debit Card        
                            SELECT @Account= RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) + '99'+ RIGHT('000000' + cast(ISNULL(MAX(cast(SUBSTRING(c.ContractNumber,5,6) AS INT))+1,1) AS varchar(6)),6)  -- TEMPORARY        
                            FROM Contracts c INNER JOIN AccountContractProducts acp ON acp.AccountContractProductId = c.AccountContractProductId               
                            WHERE acp.ContractTypeID=176 AND c.ContractNumber LIKE RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)+'________' --c.BranchId=@BranchID        
                            AND CHARINDEX('.', c.ContractNUmber) = 0        
                            AND CHARINDEX('-', c.ContractNUmber) = 0         
                        END        
                    END        
                    ELSE        
                    BEGIN        
                    -- IT IS USED ONLY BY THE JOBS (otherwise it is generated in con_Contracts_InsUpd)        
                        SELECT @Account = RIGHT('00' + CAST(@BranchID AS NVARCHAR(2)), 2)         
                        + RIGHT('000000' + CAST(ISNULL(MAX(CAST(SUBSTRING(a.AccountNum, 3, 6) AS INT)) + 1, 1) AS NVARCHAR(6)),6)         
                        FROM Accounts (NOLOCK) a         
                        WHERE a.AccountNum LIKE RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) + '______.' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4))                 
                    END        
                END         
                ELSE -- @AccountType = 6         
                BEGIN           
                    SET @Account = @BankCode       
                    SET @Account = @Account + RIGHT('00000000' + CAST(@ClientCode AS VARCHAR(20)), 8)        
                    SET @AccountRight = @AccountRight + RIGHT('1' + CAST(@resident AS VARCHAR(1)),1)    
                    SET @AccountRight = @AccountRight + RIGHT('1' + CAST(@InternalCurrencyCode AS VARCHAR(1)),1)    
                    SET @Account = @Account + '.' + CAST(@ContractServiceComponentDefinitionID AS varchar)        
                END        
        END      
  IF @CountryId = 288 ---- If generating account for OminBank - GHANA        
        BEGIN        
            DECLARE @check_digitsUNSL INT        
                IF @AccountType = 1         
                BEGIN            
                --DECLARE @CheckIfLoan INT        
                SELECT @CheckIfLoan = 0        
                SELECT @CheckIfLoan = Count(*) FROM ContractTypes        
                WHERE @ContractType = ContractTypeID AND SystemContractTypeID IN (1, 12, 13, 22, 37, 33, 34) -- + L/G, L/C        
                    IF @CheckIfLoan=0        
                    BEGIN        
                        IF @ContractType<>176 -- if not debit card        
                        BEGIN             
							IF @ContractType IN (5,6,11)
							BEGIN
								SELECT @InternalCurrencyCode = LTRIM(InternalCode) FROM dbo.Currencies (NOLOCK)	WHERE ISONum = @Currency           
								
								RangeFilledUNSLFDs:        
								IF @Counter = 9999        
								
								BEGIN        
									SELECT @Counter = -1        
									SELECT @ClientCode = CAST(CAST(@ClientCode AS INT) + 1 AS VARCHAR(20))        
								END
								BEGIN   
								   SET @AccountRight = '1' ---- RIGHT('00' + CAST(@InternalCurrencyCode AS VARCHAR(2)), 2)
								   SET @AccountRight = @AccountRight + RIGHT('0' + CAST(@ContractType AS VARCHAR(3)), 1) 
								   SET @AccountRight = @AccountRight + RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)        
								   SET @AccountRight = @AccountRight + RIGHT('00000' + CAST(@ClientCode AS VARCHAR(20)), 5)   						   						          
								                
									DECLARE @TempAccountsUNSLFDs TABLE (
									[AccountNum] VARCHAR(30) NULL
									)        
									INSERT  @TempAccountsUNSLFDs(AccountNum) SELECT AccountNum FROM Accounts WHERE AccountNum LIKE @AccountRight + '%'        
									SET @Counter = -1        
									SET @tempCounter = -1000        
									
									FindNextEmptyNumberUNSLFDs:        
									WHILE @tempCounter <> 0        
									BEGIN        
										SET @Counter = @Counter + 1        
										SELECT @tempCounter = COUNT(accountnum) FROM @TempAccountsUNSLFDs WHERE SUBSTRING(accountnum,1,9) = @AccountRight + RIGHT('0000'+ CAST(@Counter AS VARCHAR(4)),4)                   
										IF @tempCounter <> 0 AND @Counter = 9999  GOTO RangeFilledUNSLFDs                   
									END        
									--remember for in case if we return back to find because in contract this number exists        
									--- DECLARE @remAccountPart TName_U        
									SET @remAccountPart = @AccountRight        
									SET @AccountRight = RTRIM(@AccountRight) + RIGHT('0000' + CAST(@Counter AS VARCHAR(20)), 4)        
									-- Check digit        
									SET @check_digitsUNSL= 98 - (CAST(@AccountRight+'00' AS BIGINT) - (CAST(@AccountRight+'00' AS BIGINT)/97)*97)        
									SET @Account = @AccountRight
									         
									---DECLARE @tempCountContracts int        
									SET @tempCountContracts = 0        
									SELECT @tempCountContracts = COUNT(*) FROM Contracts WHERE ContractNumber = @Account        
									IF @tempCountContracts > 0         
									BEGIN        
										SELECT @tempCounter=-1000        
										SET @AccountRight = @remAccountPart        
										GOTO FindNextEmptyNumberUNSLFDs        
									END
								END      
							END	
									   
							IF @ContractType IN (3,4,215,345,126,341,344,425,523,46,47,48)
							BEGIN
								SELECT @InternalCurrencyCode = LTRIM(InternalCode)        
								FROM dbo.Currencies (NOLOCK)        
								WHERE ISONum = @Currency           
								
								RangeFilledUNSL:        
								IF @Counter=99        
								
								BEGIN        
									SELECT @Counter=-1        
									SELECT @ClientCode = CAST(CAST(@ClientCode AS INT) + 1 AS VARCHAR(20))        
								END
								BEGIN   
								   SET @AccountRight = '1' ---- RIGHT('00' + CAST(@InternalCurrencyCode AS VARCHAR(2)), 2)
								   SET @AccountRight = @AccountRight + RIGHT('000' + CAST(@ContractType AS VARCHAR(3)), 3) 
								   SET @AccountRight = @AccountRight + RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)        
								   SET @AccountRight = @AccountRight + RIGHT('00000' + CAST(@ClientCode AS VARCHAR(20)), 5)   						   						          
								   --DECLARE @tempCounter int             
									DECLARE @TempAccountsUNSL TABLE (
									[AccountNum] varchar(30) NULL
									)        
									INSERT  @TempAccountsUNSL(AccountNum) SELECT AccountNum from Accounts where AccountNum LIKE @AccountRight + '%'        
									SET @Counter=-1        
									SET @tempCounter=-1000        
									FindNextEmptyNumberUNSL:        
									WHILE @tempCounter<>0        
									BEGIN        
										SET @Counter=@Counter+1        
										select @tempCounter=count(accountnum) from @TempAccountsUNSL where substring(accountnum,1,11) = @AccountRight+RIGHT('00'+cast(@Counter as varchar(2)),2)                   
										IF @tempCounter<>0 AND @Counter=99  GOTO RangeFilledUNSL                   
									END        
									--remember for in case if we return back to find because in contract this number exists        
									--- DECLARE @remAccountPart TName_U        
									SET @remAccountPart=@AccountRight        
									SET @AccountRight = RTRIM(@AccountRight) + RIGHT('00' + CAST(@Counter AS VARCHAR(20)), 2)        
									-- Check digit        
									SET @check_digitsUNSL= 98 - (CAST(@AccountRight+'00' AS BIGINT) - (CAST(@AccountRight+'00' AS BIGINT)/97)*97)        
									SET @Account = @AccountRight         
									---DECLARE @tempCountContracts int        
									SET @tempCountContracts = 0        
									SELECT @tempCountContracts=Count(*) FROM contracts WHERE ContractNumber=@Account        
									IF @tempCountContracts > 0         
									BEGIN        
										SELECT @tempCounter=-1000        
										SET @AccountRight=@remAccountPart        
										GOTO FindNextEmptyNumberUNSL        
									END
								END
							END
                        END
                        ELSE        
                        BEGIN        
                        -- FOR Debit Card        
                            SELECT @Account= RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) + '99'+ RIGHT('000000' + cast(ISNULL(MAX(cast(SUBSTRING(c.ContractNumber,5,6) AS INT))+1,1) AS varchar(6)),6)  -- TEMPORARY        
                            FROM Contracts c INNER JOIN AccountContractProducts acp ON acp.AccountContractProductId = c.AccountContractProductId               
                            WHERE acp.ContractTypeID=176 AND c.ContractNumber LIKE RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2)+'________' --c.BranchId=@BranchID        
                            AND CHARINDEX('.', c.ContractNUmber) = 0        
                            AND CHARINDEX('-', c.ContractNUmber) = 0         
                        END        
                    END        
                    ELSE        
                    BEGIN        
                    -- IT IS USED ONLY BY THE JOBS (otherwise it is generated in con_Contracts_InsUpd)        
                        SELECT @Account = RIGHT('00' + CAST(@BranchID AS NVARCHAR(2)), 2)         
                        + RIGHT('000000' + CAST(ISNULL(MAX(CAST(SUBSTRING(a.AccountNum, 3, 6) AS INT)) + 1, 1) AS NVARCHAR(6)),6)         
                        FROM Accounts (NOLOCK) a         
                        WHERE a.AccountNum LIKE RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) + '______.' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4))                 
                    END        
                END         
                ELSE -- @AccountType = 6         
                BEGIN           
                    SET @Account = @BankCode        
                    SET @Account = @Account + RIGHT('0000000' + CAST(@ClientCode AS VARCHAR(20)), 7)        
                    SET @Account = @Account + CAST(@Currency AS VARCHAR(3)) + '0'        
                    SET @Account = @Account + '.' + CAST(@ContractServiceComponentDefinitionID AS varchar)        
                END        
        END        
  IF @CountryId = 51 -- If generating account for armenia      
  BEGIN      
   IF ISNULL(@CanMakeExternalTF, 0) = 1       
   BEGIN      
    SET @AccountLeft = LEFT(@BANKPREFIX, 3)      
    SET @AccountLeft = @AccountLeft + RIGHT('0000000' + CAST(@BranchID AS VARCHAR(20)), 2)      
    SELECT @AccountByClient = MAX(SUBSTRING(AccountNum, 6, 6))       
    FROM dbo.Accounts (NOLOCK)       
    WHERE AccountNum LIKE @AccountLeft + '_______-____'      
    SET @AccountByClient = @AccountByClient + 1      
    IF @AccountByClient IS NULL SET @AccountByClient = 0      
    SET @AccountLeft = @AccountLeft + RIGHT('000000' + CAST(@AccountByClient AS VARCHAR(20)), 6)      
    SET @Account = @AccountLeft + dbo.f_int_GenerateAccountKey('', @AccountLeft, '') + @AccountRight      
    IF @AccountType = 6      
    BEGIN      
     SELECT @ClientsFirstAccount = MIN(ContractNumber)      
     FROM dbo.CustomerContractRelations (NOLOCK)       
     WHERE ContractNumber LIKE @AccountLeft + '_______' + @AccountRight      
      AND CustomerContractRelationTypeId = 1 AND IsActive = 1 AND ClientId = @ClientID      
     SET @Account = ISNULL(@ClientsFirstAccount, @Account)      
    END      
   END      
   IF ISNULL(@CanMakeExternalTF, 0) = 0       
   BEGIN      
    SET @AccountLeft = 'C00'      
    SET @AccountLeft = @AccountLeft + RIGHT('0000000' + CAST(@BranchID AS VARCHAR(20)), 2)      
    SET @AccountLeft = @AccountLeft + RIGHT('0000000' + CAST(@ClientID AS VARCHAR(20)), 5)      
    IF @AccountType = 1      
    BEGIN      
     SELECT @AccountByClient = MAX(SUBSTRING(AccountNum, 11, 2))       
     FROM dbo.Accounts (NOLOCK)       
     WHERE AccountNum LIKE @AccountLeft + '__' + @AccountRight      
     SET @AccountByClient = @AccountByClient + 1      
     IF @AccountByClient IS NULL SET @AccountByClient = 0      
    END      
    ELSE  -- @AccountType = 6       
     SELECT @AccountByClient = 0 --one account per client in each currency      
    SET @AccountByClient = @AccountByClient % 100      
    SET @AccountLeft = @AccountLeft + RIGHT('0000000' + CAST(@AccountByClient AS VARCHAR(20)), 2)      
    SET @Account = @AccountLeft + @AccountRight      
   END      
  END      
        DECLARE @tExistingAccounts TABLE (tAccountNum VARCHAR(30), tAccountStatusID INT)      
        DECLARE @MaxValue NVARCHAR(30)      
        DECLARE @MaxValuePrincipal NVARCHAR(30)      
  IF @CountryId = 268 -- If generating account for Georgia      
  BEGIN      
   -- For Georgia, @ContractType contains externalproductid (necessary for account numberings)      
   IF @AccountType IN (1, 6) -- Unique by Contract/Client      
   BEGIN      
    IF (@ContractType = 175)      
        SET @ContractType = 2      
    SET @AccountLeft =       
     'GE__PC___' +       
     LEFT(@GeneralLedgerCode, 2) +       
     CASE @AccountType WHEN 1 THEN RIGHT('000' + CAST(ISNULL(@ContractType, 0) AS VARCHAR(20)), 3) ELSE '001' END       
    SET @AccountRight = CASE @AccountType WHEN 1 THEN '___' ELSE @InternalCurrencyCode END      
    -- If account is by client or is principal/principal      
    IF @AccountType = 6 OR (@ContractServiceId = 1 AND @ServiceComponentTypeId = 1)      
    BEGIN      
     INSERT INTO @tExistingAccounts (tAccountNum,tAccountStatusID)      
     SELECT CASE @AccountType       
      WHEN 1 THEN LEFT(AccountNum, 22) + @InternalCurrencyCode      
      ELSE AccountNum END,      
      AccountStatusID      
     FROM dbo.CustomerContractRelations ccr (NOLOCK)      
      INNER JOIN dbo.ContractComponents cc (NOLOCK)      
       ON ccr.ContractNumber = cc.ContractNumber      
        INNER JOIN dbo.ContractServiceComponentsDefinition cscd       
           ON cscd.ServiceComponentDefinitionID = cc.ServiceComponentDefinitionID                    
          INNER JOIN dbo.ContractTypes ct       
             ON ct.ContractTypeId = cscd.ContractTypeID      
            INNER JOIN dbo.Accounts a (NOLOCK)      
         ON a.AccountId = cc.AccountId      
     WHERE ccr.IsActive = 1       
      AND ccr.CustomerContractRelationTypeId = 1       
      AND ccr.ClientId = @ClientId       
      AND a.AccountNum LIKE @AccountLeft + '________' + @AccountRight      
      AND ct.SystemContractTypeID = @SystemContractTypeId      
      AND cscd.ContractServiceID = @ContractServiceId      
      AND cscd.ServiceComponentTypeID = @ServiceComponentTypeId      
     IF @AccountType = 1 DELETE FROM @tExistingAccounts      
     FROM @tExistingAccounts ea INNER JOIN dbo.Accounts a (NOLOCK)      
      ON tAccountNum = AccountNum       
    END      
    SET @Account = NULL          
                SELECT TOP 1 @Account = tAccountNum FROM @tExistingAccounts WHERE tAccountStatusID IN (0,1) ORDER BY SUBSTRING(tAccountNum, 7, 16) DESC      
    IF @Account IS NULL -- We must generate new account number      
    BEGIN      
     SET @AccountLeft =       
      'GE__PC' +       
      RIGHT('000' + CAST(ISNULL(@BranchID, 0) AS VARCHAR(20)), 3) +       
      LEFT(@GeneralLedgerCode, 2) +       
      CASE @AccountType WHEN 1 THEN RIGHT('000' + CAST(ISNULL(@ContractType, 0) AS VARCHAR(20)), 3) ELSE '001' END       
     SET @AccountRight = '___'      
     SET @AccountMask = @AccountLeft + '________' + @AccountRight      
     SELECT TOP 1 @MaxValue = MAX(SUBSTRING(AccountNum, 15, 8))       
     FROM dbo.Accounts (NOLOCK)       
     WHERE AccountNum LIKE @AccountMask      
     IF @MaxValue IS NULL SET @AccountByClient = 1      
     ELSE SET @AccountByClient = CAST(@MaxValue AS INT) + 1      
     SET @Account =       
      'GE00PC' +       
      RIGHT('000' + CAST(ISNULL(@BranchID, 0) AS VARCHAR(20)), 3) +       
      LEFT(@GeneralLedgerCode, 2) +       
      CASE @AccountType WHEN 1 THEN RIGHT('000' + CAST(ISNULL(@ContractType, 0) AS VARCHAR(20)), 3) ELSE '001' END +       
      RIGHT('00000000' + CAST(@AccountByClient AS VARCHAR(20)), 8) + @InternalCurrencyCode      
     SET @key = dbo.f_int_GenerateIBANKey(LEFT(@Account, 22))      
     SET @Account = 'GE' + RIGHT('0' + CAST(@key AS VARCHAR(2)), 2) + SUBSTRING(@Account, 5, 22)      
     IF LEN(@Account) <> 25 SET @ContractServiceComponentDefinitionID = @Account      
    END      
   END      
  END      
  IF @CountryId = 498 -- If generating account for Moldova      
  BEGIN      
   SET @AccountLeft = LEFT(@GeneralLedgerCode, 4) +       
   RIGHT('000000' + CAST(@ClientID AS VARCHAR(6)),6)+      
   '___' +      
   RIGHT('000' + CAST(@Currency AS VARCHAR(3)), 3)       
   IF @AccountType = 6 -- By Client      
   BEGIN      
    SELECT TOP 1 @Account = a.AccountNum      
    FROM dbo.CustomerContractRelations ccr (NOLOCK)      
    INNER JOIN dbo.ContractComponents cc (NOLOCK)      
     ON ccr.ContractNumber = cc.ContractNumber      
      INNER JOIN dbo.ContractServiceComponentsDefinition cscd (NOLOCK)      
         ON cscd.ServiceComponentDefinitionID = cc.ServiceComponentDefinitionID                    
        INNER JOIN dbo.ContractTypes ct (NOLOCK)      
           ON ct.ContractTypeId = cscd.ContractTypeID      
          INNER JOIN dbo.Accounts a (NOLOCK)      
       ON a.AccountId = cc.AccountId      
    WHERE ccr.IsActive = 1       
     AND ccr.CustomerContractRelationTypeId = 1       
     AND ccr.ClientId = @ClientId       
     AND a.AccountNum LIKE @AccountLeft      
     AND ct.SystemContractTypeID = @SystemContractTypeId      
    ORDER BY SUBSTRING(AccountNum, 12, 2)      
   END      
   IF @Account IS NULL --Generate new account number      
   BEGIN      
    SELECT TOP 1 @MaxValue = MAX(SUBSTRING(AccountNum, 12, 2))       
    FROM dbo.Accounts (NOLOCK)      
    WHERE AccountNum LIKE @AccountLeft      
    /*            
    SELECT TOP 1 @MaxValuePrincipal = MAX(SUBSTRING(AccountNum, 12, 2))       
    FROM dbo.Accounts (NOLOCK)      
      INNER JOIN dbo.ContractComponents cc (NOLOCK) ON cc.AccountId = dbo.Accounts.AccountId      
      inner JOIN dbo.ContractServiceComponentsDefinition (NOLOCK) cscd ON cscd.ServiceComponentDefinitionID = cc.ServiceComponentDefinitionID      
      INNER JOIN dbo.ContractTypes ct (NOLOCK) ON ct.ContractTypeID = cscd.ContractTypeID       
    WHERE AccountNum LIKE @AccountLeft      
       AND ct.SystemContractTypeID = @SystemContractTypeId      
       AND cscd.ContractServiceID = 1 AND cscd.ServiceComponentTypeID = 1      
    */      
    IF @MaxValue IS NULL       
     SET @AccountByClient = 1      
    ELSE      
      SET @AccountByClient = CAST(@MaxValue AS INT) + 1       
    SET @Account =       
     LEFT(@GeneralLedgerCode, 4) +       
     RIGHT('000000' + CAST(@ClientID AS VARCHAR(6)),6)+ '0' +      
     RIGHT('00' + CAST(@AccountByClient AS VARCHAR(2)), 2)+      
     RIGHT('000' + CAST(@Currency AS VARCHAR(3)), 3)      
   END      
  END      
  IF @CountryId = 68 -- If generating account for Bolivia      
   OR @CountryId =218 -- If generating account for Ecuador        
  BEGIN      
   DECLARE @InternalSystemContractTypeCode CHAR(1)      
   --DECLARE @SystemContractTypeId INT      
   IF @AccountType = 1       
   BEGIN          
    --DECLARE @CheckIfLoan INT          
    SELECT @CheckIfLoan = 0      
    SELECT @CheckIfLoan = COUNT(*)       
    FROM ContractTypes      
    WHERE @ContractType = ContractTypeID       
     AND SystemContractTypeID IN (1, 12, 13, 22, 37, 33, 34) -- + L/G, L/C      
    IF @CheckIfLoan = 0      
    BEGIN                            
     -- Get internal Code for the current ContractType        
     SELECT       
      @InternalSystemContractTypeCode = csct.InternalCode      
      , @SystemContractTypeId = csct.SystemContractTypeID        
     FROM dbo.ContractTypes ct WITH (NOLOCK)        
     INNER JOIN Cls_SystemContractTypes csct WITH (NOLOCK) ON csct.SystemContractTypeID = ct.SystemContractTypeID        
     WHERE ContractTypeID = @ContractType        
     -- All Customer Contracts (Current Acc, TDA, Saving Acc, etc.)        
     -- Structure: BBB-PP-$$-NNNNNN-K        
     SET @AccountLeft = RIGHT('000' + CAST(@BranchID AS VARCHAR(3)), 3) -- BBB: Branch        
     SET @AccountLeft = @AccountLeft + RIGHT('00' + CAST(@InternalSystemContractTypeCode AS NVARCHAR(1)), 2) -- PP: 2 characters from ContractType, InternalCode        
     SET @AccountLeft = @AccountLeft + RIGHT('00' + CAST(RTRIM(LTRIM(@InternalCurrencyCode)) AS NVARCHAR(2)), 2) -- $$: 2 characters for Currency                    
     RangeFilledBOL:      
     IF @Counter=999999      
     BEGIN      
      SELECT @Counter = -1            
      SELECT @ClientCode = CAST(CAST(@ClientCode AS INT)+1 AS VARCHAR(20))      
     END      
     DECLARE @TempAccountsBOL TABLE (      
      [AccountNum] NVARCHAR(30) PRIMARY KEY --NULL          
      )      
     INSERT  @TempAccountsBOL(AccountNum)       
     SELECT AccountNum       
     FROM Accounts      
     WHERE AccountNum LIKE @AccountLeft + '%'      
     --DECLARE @remAccountPart TName_U      
     SET @remAccountPart = @AccountLeft      
     SET @Counter = -1      
     SET @tempCounter = 0      
     --WHILE @tempCounter<>0      
     --BEGIN      
     -- SET @Counter=@Counter+1      
     -- select @tempCounter=count(accountnum) from @TempAccountsBOL where substring(accountnum,1, 13) = @AccountLeft+RIGHT('000000'+cast(@Counter as varchar(6)), 6)                 
     -- IF @tempCounter<>0 AND @Counter=999999  GOTO RangeFilledBOL                 
     --END      
     SELECT @Counter = ISNULL(MAX(CONVERT(NUMERIC, SUBSTRING(accountnum, 8, 6))),0) + 1       
     FROM @TempAccountsBOL       
     WHERE LEFT(AccountNum, 7) = @AccountLeft      
     FindNextEmptyNumberBOL:      
     SET  @Counter = @Counter + @tempCounter      
     IF @Counter=999999  GOTO RangeFilledBOL           
     -- (Branch + ContractType + CurrencyInternalCode) + Counter: where counter are 6 characters NNNNNN.        
     SET @AccountLeft = @AccountLeft + RIGHT('000000' + CAST(ISNULL(@Counter, 1) AS NVARCHAR(6)), 6)        
     -- Check Digit        
     SET @AccountLeft = @AccountLeft + dbo.f_int_GenerateAccountKey('', @AccountLeft, '')       
     SELECT @Account = @AccountLeft      
     --DECLARE @tempCountContracts INT      
     SET @tempCountContracts = 0      
     SELECT @tempCountContracts = COUNT(*)       
     FROM contracts       
     WHERE ContractNumber = @Account      
     IF @tempCountContracts > 0       
     BEGIN      
      SELECT @tempCounter = @tempCounter + 1      
      SET @AccountLeft = @remAccountPart      
      GOTO FindNextEmptyNumberBOL      
     END           
    END      
    ELSE      
    BEGIN      
        -- IT IS USED ONLY BY THE JOBS (otherwise it is generated in qp_con_Contracts_InsUpd)      
     -- Structure: BBB-S-$$-LLLLLLLL.CSCD      
     SELECT @Account=RIGHT('000' + CAST(@BranchID AS VARCHAR(3)), 3)       
      + 'S'       
      + RIGHT('00' + CAST(RTRIM(LTRIM(@InternalCurrencyCode)) AS NVARCHAR(2)), 2)        
      + RIGHT('00000000' + CAST(ISNULL(MAX(CAST(SUBSTRING(a.AccountNum, 7, 8) AS INT)) + 1, 1) AS VARCHAR(8)), 8)       
      + '.'       
      + RIGHT('0000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4)), 4)       
     FROM Accounts a      
     WHERE a.AccountNum LIKE RIGHT('000' + CAST(@BranchID AS VARCHAR(3)), 3)       
      + 'S'       
      + RIGHT('00' + CAST(RTRIM(LTRIM(@InternalCurrencyCode)) AS NVARCHAR(2)), 2)       
      + '________.'       
      + RIGHT('0000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4)), 4)                     
    END      
   END       
   ELSE -- @AccountType = 6       
   BEGIN      
    -- All Customer Accounts      
    -- Structure: BBB-C-$$-NNNNNNNN      
    SELECT @Account = RIGHT('000' + CAST(@BranchID AS VARCHAR(3)), 3)      
    SELECT @Account = @Account + 'C'       
    SELECT @Account = @Account + RIGHT('0000000' + CAST(@ClientCode AS VARCHAR(7)), 7)      
    SELECT @Account = @Account + dbo.f_int_GenerateAccountKey('', @AccountLeft, '')      
    SELECT @Account = @Account + '.' + RIGHT('0000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4)), 4)      
   END      
  END      
    END      
 IF @CountryId = 276 -- If generating account for Germany      
 BEGIN      
   -- Build the Account Number structure      
   SET @AccountLeft = RIGHT('000000' + CAST(@ClientCode AS VARCHAR(20)), 6)      
   --SELECT @AccountByClient = MAX(SUBSTRING(AccountNum, 7, 3))      
   --FROM dbo.Accounts (NOLOCK)       
   --WHERE AccountNum LIKE @AccountLeft + '____.____'      
   SELECT @AccountByClient = MAX(SUBSTRING(ContractNumber, 7, 3))      
   FROM dbo.CustomerContractRelations (NOLOCK)       
   WHERE ContractNumber LIKE @AccountLeft + '____.____'      
    AND CustomerContractRelationTypeId = 1 AND IsActive = 1 AND ClientId = @ClientID      
   -- Set/increase the counter      
   SET @AccountByClient = @AccountByClient + 1      
   IF @AccountByClient IS NULL SET @AccountByClient = 0      
            -- Client Code + Counter      
   SET @AccountLeft = @AccountLeft + RIGHT('000' + CAST(ISNULL(@AccountByClient, 1) AS VARCHAR(3)), 3)      
   -- Check Digit      
   SET @AccountLeft = @AccountLeft + dbo.f_int_GenerateAccountKey('', @AccountLeft, '')      
   -- Set the Account value      
   SET @Account = @AccountLeft + @AccountRight      
            -- In case it is one account per Client      
   IF @AccountType = 6      
   BEGIN     
    SELECT @ClientsFirstAccount = MIN(ContractNumber)      
    FROM dbo.CustomerContractRelations (NOLOCK)       
    WHERE ContractNumber LIKE @AccountLeft + '____' + @AccountRight      
     AND CustomerContractRelationTypeId = 1 AND IsActive = 1 AND ClientId = @ClientID      
    SET @Account = ISNULL(@ClientsFirstAccount, @Account)      
   END      
 END      
    /* Bank Contract */        
 IF @AccountType = 2 -- Bank contract      
 BEGIN      
  IF @CountryId = 417 -- If generating account for Kyrgyzstan      
  BEGIN      
   SELECT @BranchCode = BankCode       
   FROM dbo.Branches (NOLOCK)      
   WHERE BranchId = @BranchId      
   SET @AccountRight = RIGHT('0000' + CAST(@BranchID AS VARCHAR(20)), 4)      
   SET @AccountRight = RIGHT('000' + @BranchCode, 3)+'0000'+@AccountRight + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)      
   SET @Key =  RIGHT('00'+cast((cast(@AccountRight AS bigint) % 97) AS VARCHAR(2)),2)         
   IF @Key='00'  SET @Key='97'       
   SET @Account=@AccountRight+@Key+'.'+RIGHT('000' + CAST(@Currency AS VARCHAR(20)), 3)      
  END      
  IF @CountryId = 804 -- If generating account for ukraine      
  BEGIN      
   SET @AccountRight = RIGHT('0000' + CAST(@BranchID AS VARCHAR(20)), 4) + RIGHT('00000' + CAST(@ComponentType AS VARCHAR(20)), 5)      
   SET @AccountRight = @AccountRight + '.' + CAST(@Currency AS VARCHAR(20))      
   SET @Account = @GeneralLedgerCode + dbo.f_int_GenerateAccountKey(@GeneralLedgerCode, @AccountRight, @BankCode) + @AccountRight      
  END      
  IF @CountryId = 807 -- If generating account for MACEDONIA      
  BEGIN      
   SELECT @BranchCode = BankCode       
   FROM dbo.Branches (NOLOCK)      
   WHERE BranchId = @BranchId      
    SELECT @InternalCurrencyCode = LTRIM(InternalCode)      
    FROM dbo.Currencies (NOLOCK)      
    WHERE ISONum = @Currency         
   SET @AccountRight = RIGHT('0000' + CAST(@BranchID AS VARCHAR(20)), 4)      
   SET @AccountRight = RIGHT('000' + @BranchCode, 3) + '09' + LEFT(@InternalCurrencyCode, 1) +@AccountRight + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)      
   SET @AccountRight = @AccountRight + RIGHT('00'+cast(98 - (CAST(@AccountRight + '00' AS DECIMAL) - (FLOOR(CAST(@AccountRight + '00' AS DECIMAL)/97)*97)) AS varchar(2)),2)    
   SET @Account=@AccountRight+'.'+cast(@ContractServiceComponentDefinitionID as varchar(10))    
  END    
  IF @CountryId = 900 -- If generating account for GHANA        
        BEGIN        
            SELECT @BranchCode = BankCode         
            FROM Branches (NOLOCK)        
            WHERE BranchId = @BranchId        
            SELECT @InternalCurrencyCode = LTRIM(InternalCode)        
            FROM dbo.Currencies (NOLOCK)        
            WHERE ISONum = @Currency           
            SET @AccountRight = RIGHT('0000' + CAST(@BranchID AS VARCHAR(20)), 4)        
            SET @AccountRight = RIGHT('000' + @BranchCode, 3) + '09' + LEFT(@InternalCurrencyCode, 1) + @AccountRight + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)        
            SET @AccountRight = @AccountRight + RIGHT('00'+cast(98 - (CAST(@AccountRight + '00' AS DECIMAL) - (FLOOR(CAST(@AccountRight + '00' AS DECIMAL)/97)*97)) AS varchar(2)),2)        
            SET @Account=@AccountRight+'.'+cast(@ContractServiceComponentDefinitionID as varchar(10))        
        END     
  IF @CountryId = 180 -- If generating account for CONGO        
        BEGIN        
            SELECT @BranchCode = BankCode         
            FROM Branches (NOLOCK)        
            WHERE BranchId = @BranchId        
            SELECT @InternalCurrencyCode = LTRIM(InternalCode)        
            FROM dbo.Currencies (NOLOCK)        
            WHERE ISONum = @Currency           
            SET @AccountRight = RIGHT('0000' + CAST(@BranchID AS VARCHAR(20)), 4)        
            SET @AccountRight = RIGHT('000' + @BranchCode, 3) + '09' + LEFT(@InternalCurrencyCode, 1) +@AccountRight + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)        
            SET @AccountRight = @AccountRight + RIGHT('00'+cast(98 - (CAST(@AccountRight + '00' AS DECIMAL) - (FLOOR(CAST(@AccountRight + '00' AS DECIMAL)/97)*97)) AS varchar(2)),2)        
            SET @Account=@AccountRight+'.'+cast(@ContractServiceComponentDefinitionID as varchar(10))        
        END     
  IF @CountryId = 288 -- If generating account for Ghana        
        BEGIN        
            SELECT @BranchCode = BankCode         
            FROM Branches (NOLOCK)        
            WHERE BranchId = @BranchId        
            SELECT @InternalCurrencyCode = LTRIM(InternalCode)        
            FROM dbo.Currencies (NOLOCK)        
            WHERE ISONum = @Currency           
            SET @AccountRight = RIGHT('0000' + CAST(@BranchID AS VARCHAR(20)), 4)        
            SET @AccountRight = RIGHT('000' + @BranchCode, 3) + '09' + LEFT(@InternalCurrencyCode, 1) +@AccountRight + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)        
            SET @AccountRight = @AccountRight + RIGHT('00'+cast(98 - (CAST(@AccountRight + '00' AS DECIMAL) - (FLOOR(CAST(@AccountRight + '00' AS DECIMAL)/97)*97)) AS varchar(2)),2)        
            SET @Account=@AccountRight+'.'+cast(@ContractServiceComponentDefinitionID as varchar(10))        
        END 
IF @CountryId = 51 -- If generating account for armenia    
  BEGIN      
   SET @AccountLeft = 'B00'      
   SET @AccountLeft = @AccountLeft + RIGHT('0000000' + CAST(@BranchID AS VARCHAR(20)), 2)      
   SET @AccountLeft = @AccountLeft + '0000000'      
   SET @Account = @AccountLeft + @AccountRight      
  END      
  IF @CountryId = 268 -- If generating account for Georgia      
  BEGIN      
   SET @AccountLeft = @GeneralLedgerCode + '01' + RIGHT('0000000' + CAST(@BranchID AS VARCHAR(20)), 2)      
   SET @Account = 'GE00PC9' + @AccountLeft + @AccountRight      
   SET @key = dbo.f_int_GenerateIBANKey(LEFT(@Account, 22))      
   SET @Account = 'GE' + RIGHT('0' + CAST(@key AS VARCHAR(2)), 2) + SUBSTRING(@Account, 5, 22)      
   IF LEN(@Account) <> 25 SET @ContractServiceComponentDefinitionID = @Account      
  END      
  IF @CountryId = 498 -- If generating account for Moldova      
  BEGIN      
   SET @Account =       
   LEFT(@GeneralLedgerCode, 4) +       
   '000' +      
   RIGHT('0000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(4)), 4)+      
   RIGHT('00' + CAST(@BranchID AS VARCHAR(2)), 2) +      
   RIGHT('000' + CAST(@Currency AS VARCHAR(3)), 3)         
  END      
  IF @CountryId = 276 -- If generating account for Germany      
  BEGIN      
   -- Build the Account Number structure      
   SET @AccountLeft = '9'      
   SET @AccountLeft = @AccountLeft + RIGHT('00' + CAST(@BranchID AS VARCHAR(20)), 2)      
   SET @AccountLeft = @AccountLeft + RIGHT('000' + CAST(@ContractServiceComponentDefinitionID AS VARCHAR(20)), 3)      
   SET @AccountLeft = @AccountLeft + LEFT(@InternalCurrencyCode, 1)      
   SET @AccountLeft = @AccountLeft + '00'      
   SET @AccountLeft = @AccountLeft + dbo.f_int_GenerateAccountKey('', @AccountLeft, '')      
   -- Set the Account value      
   SET @Account = @AccountLeft + @AccountRight      
  END      
  IF @CountryId = 68 -- If generating account for Bolivia      
   OR @CountryId =218 -- If generating account for Ecuador        
  BEGIN      
   -- Build the Account Number structure        
   -- Bank/Branch: Internal Bank Contracts that are opened for Branch.         
   -- i.e. income/expense, transitory acc, off-balance        
   -- Structure: BBB-B-$$-000-CSCD-K        
   SELECT @AccountLeft = RIGHT('000' + CAST(@BranchID AS NVARCHAR(3)), 3) -- B: 3 character BranchId        
   SELECT @AccountLeft = @AccountLeft + 'B' -- B: 1 character literal 'B' for Branch/Bank.        
   SELECT @AccountLeft = @AccountLeft + RIGHT('00' + CAST(RTRIM(LTRIM(@InternalCurrencyCode)) AS NVARCHAR(2)), 2) -- $$: 2 character currency        
   SELECT @AccountLeft = @AccountLeft + '000' -- 0: Zero Filled        
   SELECT @AccountLeft = @AccountLeft + RIGHT('0000' + CAST(@ContractServiceComponentDefinitionID AS NVARCHAR(4)), 4) -- CSCD: ContractServiceComponentDefinitionID        
   SELECT @AccountLeft = @AccountLeft + dbo.f_int_GenerateAccountKey('', @AccountLeft, '')             
   -- Set the Account value        
   SET @Account = @AccountLeft         
  END      
 END      
 RETURN @Account      
END  