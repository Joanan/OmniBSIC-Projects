/**select (select NameLocal from branches where branchid=mi.branchid)[Bran], * from MIS_DepositsportfolioDetails mi where mi.Balance_Date='2017-11-17'

SELECT ExchangeRate_OID, LastChange, ValidFromTime, ValidToTime, FactorCurrency1, FactorCurrency2Exp, Type, CreatedAtTime, Currency1_OID, Currency2_OID FROM IPC.VExchangeRate  WHERE Type = 'DailyBase'
 AND Currency1_OID = 12027 AND (ValidToTime IS NULL OR ValidToTime > '2017-07-08 00:00:00') AND ValidFromTime < '2017-12-06 00:00:00'

 select * from  IPC.VExchangeRate order by validfromtime desc

 select * from IPC.VSysOid
**/
--UPDATE IPC.VSysOid SET CurrVal = 128117686 WHERE LastChange = 0x00000000093E217E

--EUR
INSERT INTO IPC.VExchangeRate(
    ExchangeRate_OID,ValidFromTime,ValidToTime,
    FactorCurrency1,FactorCurrency2Exp,
    Type,CreatedAtTime,Currency1_OID,Currency2_OID
)VALUES(
     (select currVal from IPC.VSysOid),'2017-11-30 23:55:00.000',NULL,
    5.2572,0,
    'DailyBase',GETDATE(),12027,1143
)

UPDATE IPC.VSysOid SET CurrVal = ((select max(ExchangeRate_OID) from IPC.VExchangeRate)+1)

UPDATE  IPC.VExchangeRate
SET     ValidToTime = (select max(ValidFromTime) from IPC.VExchangeRate where Currency2_OID=1143 and ValidToTime is NULL)
WHERE   ExchangeRate_OID = (select min(ExchangeRate_OID) from IPC.VExchangeRate where Currency2_OID=1143 and ValidToTime is NULL)



--GBP
INSERT INTO IPC.VExchangeRate(
    ExchangeRate_OID,ValidFromTime,ValidToTime,
    FactorCurrency1,FactorCurrency2Exp,
    Type,CreatedAtTime,Currency1_OID,Currency2_OID
)VALUES(
     (select currVal from IPC.VSysOid),'2017-11-30 23:55:00.000',NULL,
    5.9638,0,
    'DailyBase',GETDATE(),12027,12020
)

UPDATE IPC.VSysOid SET CurrVal = ((select max(ExchangeRate_OID) from IPC.VExchangeRate)+1)

UPDATE  IPC.VExchangeRate
SET     ValidToTime = (select max(ValidFromTime) from IPC.VExchangeRate where Currency2_OID=12020 and ValidToTime is NULL)
WHERE   ExchangeRate_OID = (select min(ExchangeRate_OID) from IPC.VExchangeRate where Currency2_OID=12020 and ValidToTime is NULL)


--USD
INSERT INTO IPC.VExchangeRate(
    ExchangeRate_OID,ValidFromTime,ValidToTime,
    FactorCurrency1,FactorCurrency2Exp,
    Type,CreatedAtTime,Currency1_OID,Currency2_OID
)VALUES(
     (select currVal from IPC.VSysOid),'2017-11-30 23:55:00.000',NULL,
   4.4122,0,
    'DailyBase',GETDATE(),12027,1142
)

UPDATE IPC.VSysOid SET CurrVal = ((select max(ExchangeRate_OID) from IPC.VExchangeRate)+1)

UPDATE  IPC.VExchangeRate
SET     ValidToTime = (select max(ValidFromTime) from IPC.VExchangeRate where Currency2_OID=1142 and ValidToTime is NULL)
WHERE   ExchangeRate_OID = (select min(ExchangeRate_OID) from IPC.VExchangeRate where Currency2_OID=1142 and ValidToTime is NULL)

