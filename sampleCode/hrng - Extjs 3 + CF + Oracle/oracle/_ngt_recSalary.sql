

--  drop table hr_compOrg cascade constraints;
--  drop type ngt_compOrg;

create or replace type ngt_recSalary as object (
   cached int
  ,EID number
  ,cycleID number
  ,compEmp ref ngt_compEmp
  ,jobMarketData ref ngt_jobMarketData
  ,MeritPAMod ref ngt_compCycleMod
  ,ContributionCalibration varchar2(25 byte) -- for reference in my print 
  ,PercThruRangeCurr float
  ,matrixModifier number
  ,Merit number
  ,MeritPerc float
  ,LumpSum number
  ,LumpSumPec float
    
  ,constructor function ngt_recSalary (
       cached int default 0
      ,EID number
      ,cycleID number default 0
      ,ContributionCalibration varchar2 default 'Not calibrated'
      ,PercThruRangeCurr float default 0
      ,Merit number default 0
      ,MeritPerc float default 0
      ,LumpSum number default 0
      ,LumpSumPec float default 0
      
  )return self as result
  ,member function recalc return ngt_recSalary
  ,member function isCached return boolean
  ,member function print return varchar2
  
)NOT FINAL;
/



