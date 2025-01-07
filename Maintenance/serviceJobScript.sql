SELECT sj.ServiceJobID, sjsd.ServiceJobScheduleID, sj.Description, sj.Title, sjl.StartTime, sjil.Info, sjil.ServiceJobItemLogID, sjirl.Info
FROM dbo.ServiceJobLog sjl (NOLOCK)
 INNER JOIN dbo.ServiceJobItemRelationLog sjirl (NOLOCK)
  ON sjl.ServiceJobLogId = sjirl.ServiceJobLogId
 INNER JOIN dbo.ServiceJobItemLog sjil (NOLOCK)
  ON sjil.ServiceJobItemRelationLogid = sjirl.ServiceJobItemRelationLogid
 INNER JOIN (
   SELECT DISTINCT serviceJobScheduleID 
   FROM dbo.ServiceJobSchedulesDependencies sjsd (NOLOCK)
    ) sjsd
  ON sjsd.serviceJobScheduleID = sjl.serviceJobScheduleID
 INNER JOIN ServiceJobs sj (NOLOCK)
  ON sj.ServiceJobID = sjl.ServiceJobID
WHERE   sjl.StartTime  >=  '2017-02-16' and sjl.StartTime  <=  '2017-02-17'
--and sj.ServiceJobId='26'
ORDER BY sjl.StartTime ASC



/**
select bpt.descrlocal,c.* from CommissionsDefinition c
inner join BusinessProcessesTypes bpt on bpt.BPTypeCode =c.BPTypeCode
5 desc
select * from BusinessProcesses where created >'2016-10-10' order by created desc
select * from Calendar where IsDayOpened=1
11944
08001939
select * from users where namelocal like '%shant%'
select * from Roles where RoleId='2'
select * from UsersRoles where UserId='10386''10693'
10211
10284
select * from MenuItems where bptype

select * from MenuItemsSecurityRestrictions where MenuItemId =600600986 and RoleId =2

select * from MenuItems where Description like '%Correction%'

select * from businessprocesses where created>'2016-09-26'

--insert into MenuItemsSecurityRestrictions values('600600986',1,509,SYSDATETIME(),0)

select * from Transactions where bpid='10035801'

select * from Entries where TransactionId='4440962'

select * from Cls_LocalDefinedClientTypes

select * from AllowedLocalDefinedClientTypes

select * from UsersRoles where UserId ='10708'
select * from MenuItems where Description like '%pending%'

600600986

select * from Roles where roleid=9

select * from users where Login = 'l.addo'




--update UsersRoles set RoleId ='502' where  UserId='10693'


--update Calendar set IsDayOpened =1 where BranchCalendarId =11948

select * from RateValues where AccountContractProductID =8921

select * from RateValues where AccountContractRateDefinitionID=8921
--update RateValues set RateValue =2.5000 where AccountContractRateDefinitionID=8921

6660


select * from AccountContractRatesDefinitions where AccountContractProductId=7326 and ContractRateTypeId=6
select * from Cls_ContractRateTypes

select * from Calendar where CalendarDate ='2016-09-30'

select * from Calendar where IsDayOpened=1
update Calendar set IsDayOpened =0 where BranchCalendarId =11956
update Calendar set IsDayClosed =0 where BranchCalendarId =11958
update Calendar set IsDayOpened =0 where BranchCalendarId =11956

exec dbo.qp_loa_AccountContractProducts_Search @ContractTypeID=43,@BranchID=0,@ISO=NULL,@AllowExpressProcessing=0,@ClientTypeID=1,@IsSelectable=NULL,@LocalDefinedClientTypeID=NULL


select * from AccountContractRatesDefinitions where ContractRateTypeId=4 and AccountContractProductId in (8321,7192,7197)

select * from AccountProductsOpeningParameters where AccountContractProductId in (8321,7192,7197)

select * from OpeningParameters
sp_helptext2 qp_loa_AccountContractProducts_Search

select * from AccountProductsLoanParameters where  AccountContractProductId in (8321,7192,7197)

select * from AccountContractProducts where ContractTypeID=43 and branchid

update AccountContractProducts set DaysInYearRule=0 where AccountContractProductId=8321
select * from clients where Code='0702665'

select * from Cls_ClientTypes



select * from vContractComponents where ServiceComponentDefinitionID =27

select * from contracts where contractnumber in (
select ContractNumber from vContractComponents where ServiceComponentDefinitionID in (27,28)
) and BranchId in (3)

select * from AccountBalances where AccountId in (select accountid from accounts where AccountNum='11000300027936.27')
and ValueDate='2016-08-31'
select * from BusinessProcesses order by created desc
select * from entries where transaction in (select * from transactions where bpid in ())

select  * from Calendar where BranchCalendarId =11944

select * from accounts where AccountNum ='0110013605500'

select * from contracts where contractnumber='0110013605500'

select * from branches where BranchId=1

select * from BusinessProcessesTypes

--select * from terminals where TerminalId=50066
--update terminals set branchid=07 where TerminalId=50066
12003

select * from terminals where terminal

select * from Branches

select 


exec dbo.qp_int_ServiceJobItemRelations_Search @ServiceJobItemRelationId=NULL,@ServiceJobId=26,@ServiceJobItemId=NULL,@ExecutionOrder=default,@IsMandatory=default

exec qp_loa_Get_ActualListOfArrearsStatuses @ReportDate='2016-08-31 00:00:00',@BranchList='4',@CalculatePenalties=1

select * from ServiceJobSchedulesDependencies

select * from ServiceJobSchedules

select * from ApplicationServers where 

update ApplicationServers set IP='USL-AS-00,997'

sp_helptext2 qp_loa_Get_LoanScheduledRepaymensData

exec dbo.qp_int_ServiceJobScheduleBranches_SelAll @where_clause=N'ServiceJobScheduleID = 802'

select * from ServiceJobSchedulesDependencies

--update ServiceJobSchedulesDependencies set DependencyType=0 where DependencyType=1
select * from contracts where contractnumber='01005944'

select * from vContractComponents where contractnumber='01005944'

select * from businessprocesses where created >'2016-09-30'

--Stickers
select cat.ContractStickerTypeId[stickertypeId],cat.DescrLocal[StickerName],car.DescrLocal[RestrictionType] from Cls_ContractStickersTypes cat
inner join Cls_AccountTransactionRestrictionTypes car
on car.RestrictionTypeId=cat.RestrictionTypeId
 where cat.IsActive=1
 --StickerManagementRestriction


select * from Cls_AccountTransactionRestrictionTypes

sp_help Cls_ContractStickersTypes

select 

select * from stickersmanagementrestrictions

5085
5084

select * from AccountContractProducts where 

select * from Contracts where AccountContractProductId in (5085,5084) and ContractStatusId =2

183**/
