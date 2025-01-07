
SELECT 
      c.ContractNumber,
	  la.LoanApplicationId,
	  la.PaymentsContractNumber as FundingAccount,
     Branches.NameLocal as Branch,
	 acp.FullNameLocal as Product
	 --,acp.AccountContractProductId
	 ,sct.DescrLocal as Module
	 ,c.CreatorId as UserRef
	 ,'GHS' as Currency
	 ,c.contractValue as ContractAmount
	 ,c.RegDate as OpeningDate
	 ,c.ContractDate as ValueDate
	 ,c.MaturityDate MaturityDate
	 --,vcc.AccountNum
	 --,vcc2.AccountNum asAcount2
	 --,vcc3.AccountNum asAcount3
	 
	 --,ABS((SELECT ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(c.ContractNumber,1,9), '2016-12-31'), 0))) AS Prin_Arrears, -------------ADDED FOR UNION SL 
     --ABS((SELECT ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(c.ContractNumber,11,9), '2016-12-31'), 0))) AS Int_Arrears -------------ADDED FOR UNION SL 
    --(SELECT dbo.f_mis_rep_OustandingLoansAmount(c.ContractNumber, 'GHS', GETDATE())) as Oustansding_Bal -------------ADDED FOR UNION SL 
	,CONVERT(NUMERIC(15,2),dbo.f_acc_GetContractBalanceOndate(la.ContractNumber,'2016-12-31','PRINCIPAL_PRINCIPAL')) AS OutstandingPrincipal  
    --,lcp.AccruedPenalties AS Penalties
	,(ABS((SELECT ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(c.ContractNumber,1,9), '2016-12-31'), 0))) + -------------ADDED FOR UNION SL 
    ABS((SELECT ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(c.ContractNumber,11,9), '2016-12-31'), 0))) + -------------ADDED FOR UNION SL 
    --(SELECT dbo.f_mis_rep_OustandingLoansAmount(c.ContractNumber, 'GHS', GETDATE())) as Oustansding_Bal -------------ADDED FOR UNION SL 
	 CONVERT(NUMERIC(15,2),dbo.f_acc_GetContractBalanceOndate(la.ContractNumber,'2016-12-31','PRINCIPAL_PRINCIPAL')) +  
    lcp.AccruedPenalties) AS TotalOut,
	ABS((SELECT ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(c.ContractNumber,1,9), '2016-12-31'), 0))) as OverDuePrinc,
    ABS((SELECT ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(c.ContractNumber,11,9), '2016-12-31'), 0)))as OverDueIntere,  -------------ADDED FOR UNION SL 
    --(SELECT dbo.f_mis_rep_OustandingLoansAmount(c.ContractNumber, 'GHS', GETDATE())) as Oustansding_Bal -------------ADDED FOR UNION SL 
	 CONVERT(NUMERIC(15,2),dbo.f_acc_GetContractBalanceOndate(la.ContractNumber,'2016-12-31','PRINCIPAL_PRINCIPAL')) as PrincipalBalance,  
     CONVERT(NUMERIC(15,2),lcp.AccruedPenalties) as PenaltiesOutstanding
    --,c.MaturityDate
    --,abs((select dbo.f_acc_GetAccountBalance( dbo.f_acc_GetAccount(la.ContractNumber, 11, 3), dbo.f_sys_GetActualDate())) +
    --(select dbo.f_acc_GetAccountBalance( dbo.f_acc_GetAccount(la.ContractNumber, 3, 3), dbo.f_sys_GetActualDate()))) AS accInterest

  FROM
        Contracts c WITH (NOLOCK) 
	join Branches on c.BranchId = Branches.BranchId
    JOIN LoanApplications la WITH (NOLOCK) ON c.ContractNumber = la.LoanapplicationId 
	INNER JOIN Cls_LoanApplicationStatuses las on las.ApplicationStatusID=la.ApplicationStatusID
    JOIN AccountContractProducts acp WITH (NOLOCK) ON acp.AccountContractProductId = c.AccountContractProductId 
    JOIN ContractTypes ct WITH (NOLOCK) ON acp.ContractTypeID = ct.ContractTypeID and   ct.SystemContractTypeID IN (1,12,13)
	JOIN Cls_SystemContractTypes sct WITH (NOLOCK) ON sct.SystemContractTypeID = ct.SystemContractTypeID
    AND acp.AccountContractProductId NOT IN ('')
	inner join Cls_ContractStatuses clc on clc.ContractStatusId=c.ContractStatusId

	inner join Clients cl  
    on la.ClientId = cl.ClientId   
    inner join LoanContractParameters lcp on lcp.ContractNumber = la.LoanApplicationId

 --   left outer join vContractComponents vcc on vcc.ContractNumber=c.ContractNumber and ServiceComponentType='OVERDUE' and 
	--ContractService='PRINCIPAL ACCOUNT'
	--left outer join vContractComponents vcc2 on vcc2.ContractNumber=c.ContractNumber and vcc2.ServiceComponentType='OVERDUE' and 
	--vcc2.ContractService like '%Interest%'
	--left outer join vContractComponents vcc3 on vcc3.ContractNumber=c.ContractNumber and vcc3.ServiceComponentType='OVERDUE' and 
	--vcc3.ContractService = 'Commission'
	  where c.ContractNumber  not in (
	  select ContractNumber from CustomerContractRelations where 
		 ClientId  IN (20041129,4001025))
		 and acp.AccountContractProductId not in (7185,7184)

		 and c.ContractDate<='2016-12-31' 
		 and (c.ContractStatusId in (1,2,3) or c.CloseDate>'2016-12-31')

		 

	