------------------------------------------------------------------------
-- USLsp_MIS_AccountOpened        
-- Version     Author             Date          Changes        
-- v1.0        BankUser             07-03-2016    Initial version    
--             BankUser              01.02.2017    Update into sp   
------------------------------------------------------------------------  
CREATE PROC  dbo.USLsp_MIS_AccountOpened
(
@Reportdate DATE
)
As
BEGIN


select AC.ACCOUNTNUM as ACC_NUMBER,c.clientid as CLIENTID,con.ContractDate as DATE_EST,c.FullnameEng AS CUSTOMER_NAME,U.email AS OFFICER_CODE,
isnull(sum(ISNULL(dbo.f_acc_GetAccountBalance(dbo.f_acc_GetAccount(Ac.AccountNum, 1,1), @Reportdate), 0)),0) AS BAL,ac.LastTranDate As LAST_USED,C.BranchId as BRANCH,acp.ShortNameLocal AS TYPE_0F_ACCT,cls.DescrLocal As STATUS
FROM CLIENTs C
INNER JOIN CustomerContractRelations ccr on c.CLIENTID=Ccr.clientid
INNER JOIN Contracts con on ccr.Contractnumber=con.Contractnumber
INNER JOIN ACCOUNTS AC ON CON.CONTRACTNUMBER=AC.ACCOUNTNUM
INNER JOIN Cls_AccountStatuses CLS on AC.AccountStatusID=CLS.AccountStatusID
INNER JOIN AccountContractProducts acp on con.AccountContractProductId=acp.AccountContractProductId
INNER JOIN ContractTypes ct on acp.ContractTypeID=ct.ContractTypeID
INNER JOIN CLS_SYSTEMCONTRACTTYPES SC ON CT.SystemContractTypeID=SC.SystemContractTypeID
INNER JOIN Users u on C.AdvisorId=U.useriD
WHERE con.ContractStatusId in (1,2,3,4,5) AND ccr.CustomerContractRelationTypeId=1 and con.ContractDate<=@Reportdate
AND c.FullnameEng not like '%tengkorang bismark%'
AND ct.SystemContractTypeID in (2,3,30)
GROUP BY AC.AccountNum,AC.DateOpen ,C.FullnameEng, acp.FullNameEng,u.EMail,ac.BranchId,ac.LastTranDate,cls.DescrEng,c.ClientId,con.ContractDate,c.BranchId,acp.ShortNameLocal,cls.DescrLocal
ORDER BY bal asc

END
--- EXEC USLsp_MIS_AccountOpened @Reportdate = '2016-12-31'