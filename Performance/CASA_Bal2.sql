   ----CONVERT(varchar(10), dbo.f_sys_GetCurrentDate(), 104) as reportdate,
DECLARE @end_of_month date
SET @end_of_month ='2016-01-01'
SELECT DISTINCT
        contracts.ContractNumber as 'Contract Reference Number',
		contracts.ContractNumber as 'Account Number',
		cl.FullnameLocal  AS ClientName ,
		Branches.NameEng [Branch],
		contracts.ContractTerm  as  ProductTerm,
		contracts.AccountContractProductId  as  ProductID,
		'GHS' as Currency,
        ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(contracts.ContractNumber, 1,1), @end_of_month), 0) AS BalanceLCY
		,contracts.CloseDate
		,contracts.ContractStatusId
			
INTO #clients	
FROM contracts 
	
	JOIN ContractComponents (nolock) 
	ON ContractComponents.ContractNumber = contracts.ContractNumber
	INNER JOIN AccountContractProducts acp (NOLOCK)
			ON acp.AccountContractProductId = contracts.AccountContractProductId
 	JOIN dbo.ContractTypes ct (nolock) 
	ON ct.ContractTypeID = acp.ContractTypeID
	JOIN dbo.Accounts (nolock) 
	ON dbo.ContractComponents.AccountId = Accounts.AccountId
    JOIN dbo.CustomerContractRelations ccr (nolock) 
    ON ccr.ContractNumber = dbo.Contracts.ContractNumber 
	and ccr.CustomerContractRelationId=(select min(CustomerContractRelationId) from CustomerContractRelations where ContractNumber = dbo.Contracts.ContractNumber and CustomerContractRelationTypeId=1)
    JOIN Branches (nolock) 
    ON contracts.BranchId=Branches.BranchId
	inner join Clients cl on cl.ClientId=ccr.ClientId
	--inner  join vContractComponents  vcc on vcc.ContractNumber=contracts.ContractNumber and vcc.ContractService='TDA CAPITAL PAYMENT'
	--and ServiceComponentType='CONNECTED ACCOUNT'
	inner join users u on u.UserId=contracts.CreatorId

WHERE 
     --acs.ContractServiceCode = 'PRINCIPAL'
	 SystemContractTypeId in (3,30)

	 --select * from Cls_SystemContractTypes where contractnumber=''
  --   --AND Contracts.ContractStatusId in (1,2)----New,active,prepared for closure
	 AND (Contracts.ContractStatusId in (1,2,3) or contracts.CloseDate>@end_of_month)
     AND ccr.CustomerContractRelationTypeId=1
	 
      AND contracts.AccountContractProductId NOT IN (7185,7184,7187,7186)



	 
SELECT sum(BalanceLCY) FROM #clients c where c.BalanceLCY>0 
--where c.BalanceLCY<>0		
SELECT * FROM #clients c 
where c.BalanceLCY>0 
--and c.[Account Number]='1126020846200'
DROP TABLE #clients	



