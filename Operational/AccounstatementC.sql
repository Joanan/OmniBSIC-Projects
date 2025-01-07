DECLARE @Balance money,
        @OVDContract TName_U,
		@OVDLimit   money,
		@OVDOverdue  money,
		@OVDAccrue   money,
		@Penalty     money,
		@TechOVD     money,
		@OVDOUsedAmount money ,
	@ContractNumber TName_U,      
	@StartDate DATETIME,      
	@EndDate DATETIME,
	@ShowCancelledTrans BIT = 0
	SET @ContractNumber ='1126080233300'      
    SET @StartDate = '20160102'      
    SET   @EndDate = '20161216' 
	SET @StartDate = (SELECT CASE WHEN @StartDate <= '2013-10-11' THEN '2013-10-11' ELSE @StartDate END)
	
DECLARE @Date date
SELECT @Date = dbo.f_sys_GetActualDate()
DECLARE @ClientId int
SET @Balance = (select dbo.f_acc_GetAccountBalance2(a2.AccountId, @StartDate )  FROM Accounts a2 where a2.AccountNum =  @ContractNumber)
SELECT @OVDContract = vcc.ContractNumber 
		FROM dbo.vContractComponents vcc
		JOIN contracts c ON c.ContractNumber = vcc.ContractNumber
		JOIN dbo.AccountContractProducts acp ON acp.AccountContractProductId = c.AccountContractProductId
		WHERE vcc.ContractTypeId IN (43,44) AND vcc.ServiceComponentTypeID = 1 AND vcc.ContractServiceId = 1 
		AND vcc.AccountNum  = @ContractNumber AND c.ContractStatusId = 2 
 IF @OVDContract  IS NOT NULL 
  BEGIN 
		  SELECT @OVDLimit = c.ContractValue from  contracts c 
				 WHERE c.ContractNumber = @OVDContract
		  SELECT @OVDOverdue = abs (Balance) from  dbo.vContractComponents vcc1
				 WHERE vcc1.ContractNumber = @OVDContract AND vcc1.ServiceComponentTypeID = 9 AND vcc1.ContractServiceId = 1 
		  SELECT @OVDAccrue = abs (Balance) from  dbo.vContractComponents vcc2
				 WHERE vcc2.ContractNumber = @OVDContract AND vcc2.ServiceComponentTypeID =3 AND vcc2.ContractServiceId = 3 
		  SELECT @Penalty = ISNULL(abs (AccruedPenalties),0) from  dbo.LoanContractParameters lcp
				 WHERE lcp.ContractNumber = @OVDContract 
		
		  SELECT @OVDOUsedAmount = abs (Balance) from  dbo.vContractComponents vcc1
				 WHERE vcc1.ContractNumber = @OVDContract AND vcc1.ServiceComponentTypeID = 1 AND vcc1.ContractServiceId = 1 
				 AND vcc1.Balance < 0 
  END
		  SELECT @TechOVD = ISNULL(abs (Balance),0) from  dbo.vContractComponents vcc3
				 WHERE vcc3.ContractNumber = @OVDContract AND vcc3.ServiceComponentTypeID =1 AND vcc3.ContractServiceId = 158
SELECT TOP 1 @ClientId = ccr.ClientId 
		FROM CustomerContractRelations AS ccr 
		WHERE ccr.ContractNumber = @ContractNumber
		AND ccr.CustomerContractRelationTypeId = 1
-----------------Checking staff account --------------------------------------------------------
DECLARE @IsStaff int
SELECT @IsStaff = ( SELECT ISNULL(pc.Is_Employee,0) FROM dbo.PrivateClients pc
		INNER JOIN dbo.CustomerContractRelations ccr ON ccr.ClientId = pc.ClientId
		AND ccr.CustomerContractRelationTypeId = 1 and ccr.ClientId= (select min(ClientId) from CustomerContractRelations where ContractNumber=ccr.contractnumber)
		WHERE ccr.ContractNumber = @ContractNumber) 
		DECLARE @CurrentUserId int
SELECT @CurrentUserId = dbo.f_sys_GetCurrentUser()
IF ( @IsStaff = 1)
BEGIN
	DECLARE @CurrentUserRoleAllowed int = 0
	DECLARE @CurrentUserRoleAllowed4ReverseTrans int = 0
SELECT @CurrentUserRoleAllowed = COUNT (*) 
		FROM UsersRoles AS ur 
		WHERE ur.UserId = @CurrentUserId
		AND ur.RoleId IN (525,500)
DECLARE @AccUserId int
SELECT @AccUserId = ISNULL(( SELECT ISNULL(u.UserId,0) FROM  dbo.CustomerContractRelations ccr 
JOIN dbo.Users u ON ccr.ClientId = u.ClientId
WHERE ccr.ContractNumber = @ContractNumber) ,0)
IF ( @CurrentUserId <> @AccUserId AND @CurrentUserRoleAllowed = 0)
BEGIN
RETURN
END
END
--Roles allowed to see cancelled tranasctions
SELECT @CurrentUserRoleAllowed4ReverseTrans = COUNT (*) 
		FROM UsersRoles AS ur 
		WHERE ur.UserId = @CurrentUserId
		AND ur.RoleId IN (7)
SELECT DISTINCT
		bp.BPId
		,T.RegistrationDate AS DateTransaction 
		,		CASE WHEN bp.BPTypeCode = 'MIGRATE_BALANCES' THEN 'Transaction Reversal' ELSE BPT.DescrLocal	EnD	AS TransacationsType  									
		,
		
		case when bp.BPTypeCode = 'FX_TRANS_IA' then (select ReasonText from businessprocessreasons where bpid=bp.bpid and 
		OrderReasonTypeID=2) else 
		ISNULL(TransactionReason, bpt.DescrLocal )+ CASE WHEN ISNULL(TransactionReason,'')='' THEN BPT.DescrLocal ELSE '' END+
		
		+ CASE WHEN ISNULL (ch.Number, '') = '' THEN '' ELSE ' No.'+ch.Number END END
		AS TransacationReason             
		,TT.DescrLocal AS Transacations       
		,case when bp.ValueDate='2000-01-01' then bp.RefValueDate  else bp.ValueDate end  AS ValueDate      
		--,CASE WHEN e.EntryType IN (-196,-57,-55,50,56,112,195,196,113,57,55,-56,-50,-195) THEN e.Value ELSE  0 END      AS  Commission 
		--,CASE WHEN e.EntryType IN (-508,-506,-504,-502,501,503,505,507,-507,-505,-503,-501,502,504,506,508) THEN e.Value ELSE  0 END    AS VAT 
		,CASE WHEN et.BasicEntryType = 'C'  THEN e.Value ELSE  0 END         AS CreditAmount         
		,CASE WHEN et.BasicEntryType = 'D'  THEN e.Value ELSE  0 END         AS DebitAmount 
		--,CASE WHEN e.EntryType IN (-601,-511,-509,-401,-301,-211,-209,-208,-205,-204,-160,
		--                          -140,-120,-90,-70,-60,-40,-1,2,30,65,110,80,130,150,170,190,196,
		--                           206,207,210,212,302,402,602,512,510)  THEN e.Value ELSE  0 END         AS CreditAmount         
		--,CASE WHEN e.EntryType IN (-602,-512,-510,-402,-302,-212,-210,-207,-206,-203,-196,-196,-170,-150,-130,
		--                          -110,-80,-65,-30,-2,1,40,60,70,90,120,140,160,180,205,208,
		--						           209,211,301,401,509,511,601)  THEN e.Value ELSE  0 END         AS DebitAmount    
		--	--CASE WHEN et.BasicEntryType = 'D' AND  cscd.ServiceComponentTypeID != 1  THEN e.Value ELSE '' END AS CommissionAccrue,     
		,e.OutBalance													AS Balance      
		,case when (select count(*) from CustomerContractRelations where ContractNumber= con.ContractNumber and CustomerContractRelationTypeId =1)=2
		then con.description else c.FullnameLocal end    AS clientName 
		
		
		     
		,aa.StreetAddress                                               AS Addresses      
		,b.NameLocal                                                    AS branch      
		--dbo.f_acc_GetAccountBalance2(a.AccountId, @StartDate )           AS Currentbalance, 
		,@Balance      AS Currentbalance 
		,ISNULL(( dbo.f_acc_GetAvailableAccountBalance(dbo.f_acc_GetAccount(con.ContractNumber, 1,1), @EndDate)),0) AS AvailBal
		,dbo.f_con_GetFundsReservationByDate(@ContractNumber,10,@EndDate) AS UnclearedEffect
		--,frl.oldBalance
		--,frl.newBalance
		,ccr.ContractNumber   AS AccountNumber      
		,e.EntryNum
		,acp.ShortNameLocal
		,REPLACE(csct.DescrLocal,'accounts','Account')  AS ContractType
		,a.Currency
		,ISNULL((dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(con.ContractNumber, 1,1), @EndDate)),0) AS CurrentBal
		,DATEDIFF(M,CONVERT(date,@StartDate),CONVERT(date,@EndDate) ) AS Period
		,ccr.ClientId 
		,t.ValueDate AS TransValDate 
		,@OVDContract    AS ODContract
		,@OVDLimit       AS ODLimit
		,ISNULL(@OVDOverdue,0)     AS ODOverdue
		,ISNULL(@OVDAccrue,0)      AS ODAccrue
		,ISNULL(@Penalty,0)        AS ODPenalty
		,ISNULL(@TechOVD,0)        AS NOTAlllowedOD
		,a.balance                AS  ActualyBal
		,ISNULL(@OVDOUsedAmount,0)        AS OVDOUsedAmount
		INTO #Output
		FROM Accounts a (NOLOCK)     
		INNER JOIN Entries e (NOLOCK) ON e.AccountId = a.AccountId      
		INNER JOIN Transactions t (NOLOCK) ON t.TransactionId = e.TransactionId      
		INNER JOIN BusinessProcesses bp (NOLOCK) ON bp.BPId = t.BPId
		LEFT OUTER JOIN BPCheques bpc (NOLOCK)
					ON bpc.BPId = bp.BPId
				LEFT OUTER JOIN cheques ch (NOLOCK)
					ON ch.ChequeId = bpc.ChequeId
				LEFT OUTER JOIN BusinessProcessReasons br (NOLOCK) 
					ON bp.BPId = br.BPId AND br.OrderReasonTypeID=1   
		INNER JOIN BusinessProcessesTypes as BPT (NOLOCK)               
				ON BP.BPTypeCode = BPT.BPTypeCode 
		INNER JOIN TransactionTypes tt (NOLOCK) ON tt.TransactionType = t.TransactionType      
			LEFT  JOIN Cls_EntryTypes et (NOLOCK ) ON et.EntryType = e.EntryType      
			LEFT  JOIN Branches b (NOLOCK) ON b.BranchId = a.BranchId 
		INNER JOIN contracts con ON a.AccountNum = con.ContractNumber
		INNER JOIN dbo.AccountContractProducts acp ON acp.AccountContractProductId = con.AccountContractProductId
		INNER JOIN dbo.ContractTypes ct ON ct.ContractTypeID = acp.ContractTypeID    
		INNER JOIN dbo.Cls_SystemContractTypes csct ON csct.SystemContractTypeID = ct.SystemContractTypeID 
		INNER JOIN CustomerContractRelations ccr (NOLOCK) ON ccr.ContractNumber = a.AccountNum      
			AND ccr.CustomerContractRelationTypeId = 1      
		INNER JOIN Clients c (NOLOCK) ON c.ClientId = ccr.ClientId      
			LEFT JOIN Addresses aa (NOLOCK) ON aa.ClientId = c.ClientId     
			LEFT JOIN ContractComponents CC (NOLOCK) ON CC.ContractNumber = ccr.ContractNumber    
			LEFT JOIN ContractServiceComponentsDefinition CSCD (NOLOCK) ON     
		 CC.ServiceComponentDefinitionID = CSCD.ServiceComponentDefinitionID     
		WHERE  et.BasicEntryType NOT IN ('A') AND a.AccountNum = @ContractNumber      
		AND (case when bp.ValueDate='2000-01-01' then bp.RefValueDate  else bp.ValueDate end BETWEEN  @StartDate AND @EndDate) 
		--AND (bp.ValueDate BETWEEN  @StartDate AND @EndDate) 
		
		 AND bp.BPTypeCode NOT IN ('OD_ASSET_EXTRACTION','OD_REVERSE_ASSET_EXTRACTION')  
		 AND (bp.BPStatusId !=9  OR (@CurrentUserRoleAllowed4ReverseTrans > 0 AND @ShowCancelledTrans = 1) )
		 --AND t.BPId = 6393275
		ORDER BY  e.EntryNum ,t.ValueDate     
--DROP TABLE #Addresses
;WITH Clt AS
		(
		   SELECT *,
				 ROW_NUMBER() OVER (PARTITION BY ContractNumber ORDER BY CustomerContractRelationId ASC ) AS rn
		   FROM CustomerContractRelations    
		   WHERE ContractNumber = @ContractNumber AND CustomerContractRelationTypeId = 1
		)
DELETE FROM #Output WHERE #Output.ClientId IN (SELECT c.ClientId FROM Clt AS c WHERE c.rn >1 AND c.ClientId != #Output.ClientId) 
DECLARE @address varchar( max)
;WITH CAdd AS
		(
		   SELECT ad.StreetAddress,
				 ROW_NUMBER() OVER (PARTITION BY ad.ClientId ORDER BY ad.AddressTypeId DESC) AS rn
		   FROM Addresses ad   
		   INNER JOIN #Output AS o ON o.ClientId = ad.ClientId
		)
SELECT @address=c.StreetAddress FROM CAdd AS c WHERE c.rn =1
DELETE FROM #Output WHERE #Output.Addresses  != @address
SELECT * FROM #Output ORDER BY dbo.#Output.EntryNum