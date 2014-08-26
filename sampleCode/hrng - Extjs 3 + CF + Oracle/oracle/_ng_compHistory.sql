set define off;
create or replace PACKAGE ng_compHistory IS

PROCEDURE getCompHistory(
     p_CurSalHistory IN OUT Globals.genRefCursor
    ,p_ICPHistory IN OUT Globals.genRefCursor
    ,p_LTIHistory IN OUT Globals.genRefCursor
    ,p_OtherPaymts IN OUT Globals.genRefCursor
    ,p_EmployeeID NUMBER
    ,p_CycleID NUMBER);

END ng_compHistory;
 
/
create or replace PACKAGE BODY  ng_compHistory IS

PROCEDURE  getCompHistory(
     p_CurSalHistory IN OUT Globals.genRefCursor
    ,p_ICPHistory IN OUT Globals.genRefCursor
    ,p_LTIHistory IN OUT Globals.genRefCursor
    ,p_OtherPaymts IN OUT Globals.genRefCursor
    ,p_EmployeeID NUMBER
    ,p_CycleID NUMBER) IS
BEGIN


OPEN p_CurSalHistory FOR
SELECT
 sh.EMP_IDFK EmployeeID,
 sh.FY_CYCLE_IDFK CycleID,
 sh.JOB_CODE JobCode,
 sh.JOB_TITLE JobTitle,
 sh.GRADE careerband,
 sh.EFFECTIVE_DATE EffectiveDate,
 sh.ANNUAL_SALARY AnnualSalary,
 sh.INC_PERCENT increasepercent
FROM HR_SAL_HISTORY sh
WHERE sh.EMP_IDFK = p_EmployeeID
AND sh.FY_CYCLE_IDFK = p_CycleID
ORDER BY sh.EFFECTIVE_DATE DESC;


open p_ICPHistory for 
  SELECT
    EMP_IDFK EmployeeID
  ,FY_CYCLE_IDFK CycleID
  ,BONUS_TYPE BonusType
  ,AWARD_AMT annualsalary
  ,CURRENCY Currency
  ,EFFECTIVE_DATE EffectiveDate
  ,INDIV_MOD INDIVMOD
  FROM HR_ICP_HISTORY o
  WHERE o.EMP_IDFK = p_EmployeeID
  AND o.FY_CYCLE_IDFK = p_CycleID
  ORDER BY o.EFFECTIVE_DATE DESC;
  
  open p_LTIHistory for 
    SELECT
      EMP_IDFK EmployeeID
    ,FY_CYCLE_IDFK CycleID
    ,GRANT_DATE GrantDate
    ,EQUITY_TYPE EquityType
    ,GRANT_PRICE GrantPrice
    ,SHARES_GRANTED SharesGranted
    ,SHARES_VESTED SHARESVESTED
    ,SHARES_UNVESTED SharesUnvested
    ,VALUE_UNVESTED ValueUnvested
    FROM HR_LTI_HISTORY o
    WHERE o.EMP_IDFK = p_EmployeeID
  AND o.FY_CYCLE_IDFK = p_CycleID
  ORDER BY o.GRANT_DATE DESC;
  
  
OPEN p_OtherPaymts FOR
  SELECT
   o.EMP_IDFK EmployeeID,
   o.FY_CYCLE_IDFK CycleID,
   o.ADDITIONAL_PAYMENT_DESC BonusType,
      o.EFFECTIVE_DATE EffectiveDate,
   o.AMOUNT Amount,
   o.INDIV_MODIFIER IndivModifier
  FROM HR_SAL_HISTORY_OTHERPMTS o
  WHERE o.EMP_IDFK = p_EmployeeID
  AND o.FY_CYCLE_IDFK = p_CycleID
  ORDER BY o.EFFECTIVE_DATE DESC;

/*
OPEN p_CurSalesPerf FOR
SELECT
 p.EMP_IDFK EmployeeID,
 p.FY_CYCLE_IDFK CycleID,
 p.FY_DESC FYDescription,
    p.RESULT Result
FROM HR_SAL_HISTORY_SALESPERF p
WHERE p.EMP_IDFK = p_EmployeeID
AND p.FY_CYCLE_IDFK = p_CycleID;


OPEN p_CurOT FOR
SELECT
    ot.EMP_IDFK EmployeeID,
    ot.FY_CYCLE_IDFK CycleID,
    ot.EFFECTIVE_DATES EffectiveDates,
       ot.AMOUNT
FROM HR_SAL_HISTORY_OT ot
WHERE ot.EMP_IDFK = p_EmployeeID
AND ot.FY_CYCLE_IDFK = p_CycleID;
*/

END getCompHistory;


END ng_compHistory;
/
