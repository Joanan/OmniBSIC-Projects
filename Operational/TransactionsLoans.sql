--------------------------------------------------------------------------------------------------------------------
-- USLsp_MIS_depositsportfolioDetailreportKP        
-- Version     Author             Date          Changes        
-- v1.0        BankUser             07-03-2016    Initial version    
--             BankUser            01.06.2016    Review
--             BankUser            05.06.2016    Review join(left) to users table and added accounts with status NEW  
--             BankUser    07.15.2016    c.ContractDate as DATE_EST,a.LastTranDate As LAST_USED,cas.DescrLocal As [STATUS],dbo.f_cus_GetCustomerContactPhone(cl.ClientId,1) AS PHONEnumber,SMS
--------------------------------------------------------------------------------------------------------------------  


SELECT 
      c.ContractNumber,
	  la.PaymentsContractNumber as FundingAccount,
	  cl.FullnameEng
	  	 ,bp.BPId
	 --,sct.DescrLocal as Module
	 --,c.CreatorId as UserRef
	 
	 ,bp.BPTypeCode

	 ,vlp.BPAmount
	 ,vlp.Currency
	 ,case when vlp.RepaymentTypePartDescription='Additional comm interest diff' then 'Interest' else vlp.RepaymentTypePartDescription end as RepaymentTypePartDescription
	 
	 ,vlp.ValueDate
	 ,bp.Created as TradeDate

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
    inner join vContractComponents vcc on vcc.ContractNumber=c.ContractNumber
	inner join vLoanRepayments vlp on vlp.ContractNumber=la.LoanapplicationId
	inner join businessprocesses bp on bp.BPId=vlp.BPId
	--inner join transactions t on t.BPId=bp.BPId
	inner join clients cl on cl.clientid=la.ClientId
	
	  where c.ContractNumber  not in (
	  select ContractNumber from CustomerContractRelations where 
		 ClientId  IN (20041129,4001025))
		 and acp.AccountContractProductId not in (7185,7184)
		 and (c.ContractStatusId in (1,2,3) or c.CloseDate>'2016-12-31')
		 and vlp.BPAmount<>0
		 and c.ContractDate<='2016-12-31' 
		 and (bp.Created  >='2016-10-01' and bp.Created <='2016-12-31')

		 and la.LoanapplicationId='09001906'
		 

	