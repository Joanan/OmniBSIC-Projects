
select g.ClientId,sum(g.Value) as TotalTurnover,Count(g.Value) as CountTotalTurnover,sum(g.Debit) as DebitTurnover
,Sum(g.CDebit)  as CountDebitTurnover
, sum(g.Credit) as CreditTurnover, 
Sum(g.CCredit)  as CountCreditTurnover 
,min(g.created) as FromDate
,max(g.created) as ToDate
from 
(SELECT c.Description,bpt.DescrLocal,bp.BPTypeCode,t.TransactionReason, e.Account,et.BasicEntryType,
 case when et.BasicEntryType='D' then -e.Value else e.Value end as 'Value'
 ,case when et.BasicEntryType='D' then e.Value else 0 end as 'Debit'
 ,case when et.BasicEntryType='C' then e.Value else 0 end as 'Credit'
  ,case when et.BasicEntryType='D' then 1 else 0 end as 'CDebit'
 ,case when et.BasicEntryType='C' then 1 else 0 end as 'CCredit'
  , e.Currency,e.Created,bp.BPId, bp.CreatorId,bp.ConfirmingUserId,ccr.ClientId
FROM Transactions t JOIN Entries e ON t.TransactionId = e.TransactionId
join accounts acc on e.accountid=acc.accountid
join Cls_EntryTypes et
on et.EntryType = e.EntryType
inner join BusinessProcesses bp
on bp.bpid=t.BPId
inner join contracts c
on c.ContractNumber=acc.AccountNum
inner join BusinessProcessesTypes bpt on bpt.BPTypeCode=bp.BPTypeCode
inner join AccountContractProducts acp on  acp.AccountContractProductId=c.AccountContractProductId
 and c.AccountContractProductId not in (7185,7184,7187,7186)
inner join ContractTypes ct on acp.ContractTypeID=ct.ContractTypeID and SystemContractTypeID in (3,30)
inner join CustomerContractRelations ccr on ccr.ContractNumber=c.ContractNumber and ccr.CustomerContractRelationTypeId=1
and ccr.CustomerContractRelationId=(select max(CustomerContractRelationId) from CustomerContractRelations where ContractNumber=c.ContractNumber and ccr.CustomerContractRelationTypeId=1)
WHERE 
-- e.Account IN ('0110070217701'
--) and 
e.Created between '2017-01-01' and '2017-02-01'

) g group by g.ClientId


--EXEC USLsp_MIS_loanportfolioreport @Reportdate = '2017-01-31'

--select * from LoanApplications
--01006922 526068 01000474.115 655799

--select * from AccountBalances where accountid=526068 order by ValueDate desc

--select * from AccountBalances where accountid=655799 order by ValueDate desc

--select * from entries where AccountId in ('655799','526068') order by created desc

--select * from entries where AccountId in ('526068') order by created desc

--select * from Entries where TransactionId='1738777'


--,'655799'




--select * from vContractComponents where ContractNumber='01006922'
