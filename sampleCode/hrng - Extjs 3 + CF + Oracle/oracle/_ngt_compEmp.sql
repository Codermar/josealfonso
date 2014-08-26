
/*
  ng_compEmp
  Saves cycle information for comp employees
  drop table hr_compEmp cascade constraints;
  drop type ngt_compEmp force;

*/


CREATE or replace TYPE ngt_compEmp AS OBJECT (
   cached int
  ,EID number
  ,cycleID number
  ,managerID number
  ,careerBand varchar2(5 byte)
  ,PAID varchar2(6 byte)
  ,CAID VARCHAR2(6 BYTE)
  ,compLevelID number
  ,payScaleLevel number
  ,EmploymentGroup varchar(50 byte)
  ,EmploymentPayType varchar(50 byte) 
  ,jobCode varchar2(50 byte)  
  ,mrhiredate date
  ,FTsalary number
  ,yearlyPayPeriods int
  ,percentTimeWorked float
  ,salCurrency VARCHAR2(3 BYTE)
  ,currencyUSD float
  ,compensationGroup varchar2(50 byte) 
  ,ICPTargetPercent float
  ,ICPIndivModifier float
  ,ICPSalary number
  ,orgUnitCode VARCHAR2(15 BYTE) 
  ,EmploymentLocation varchar2(75 byte)
  ,employmentCountry VARCHAR2(50 BYTE)
  ,contributionCalibration varchar2(25 byte)
  ,potentialCalibration varchar2(25 byte)
  ,contributionCalibrationprev varchar2(25 byte)
  ,potentialCalibrationprev varchar2(25 byte)
  ,UnvestedSharesValue number
  ,directReports number
  ,totalReports number
  
  ,BridgedServiceDate date
  ,InJobDate date
  ,LastLOA date
  ,LastIncreaseDate date
  ,LastIncreasePercent float
  ,CostCenterCode varchar2(15 byte)
  ,CompGlobalRegion varchar2(50 byte)
  
  ,isEligibilityUpdatable int
  ,isRecordUpdatable int
  ,forceLoad int
  ,eligibility ngt_eligibility
  
 
  ,constructor function ngt_compEmp (
       cached int default 0
      ,EID number default 0
      ,cycleID number default 0
      ,managerID number default 0
      ,careerBand varchar2 default null
      ,PAID varchar2 default null
      ,CAID VARCHAR2 default null
      ,compLevelID number  default null
      ,payScaleLevel number default null
      ,EmploymentGroup varchar default null
      ,EmploymentPayType varchar default null
      ,jobCode varchar2 default null  
      ,mrhiredate date default null
      ,FTsalary number default 0
      ,yearlyPayPeriods int default null
      ,percentTimeWorked float default 0
      ,salCurrency VARCHAR2 default null
      ,currencyUSD float default null
      ,compensationGroup varchar2 default null 
      ,ICPTargetPercent float default null
      ,ICPIndivModifier float default null
      ,ICPSalary number default null
      ,orgUnitCode VARCHAR2 default null 
      ,EmploymentLocation varchar2 default null
      ,employmentCountry VARCHAR2 default null
      ,contributionCalibration varchar2 default null
      ,potentialCalibration varchar2 default null
      ,contributionCalibrationprev varchar2 default null
      ,potentialCalibrationprev varchar2 default null
      ,UnvestedSharesValue number default 0
      ,directReports number default 0
      ,totalReports number default 0
      
      ,BridgedServiceDate date default null
      ,InJobDate date default null
      ,LastLOA date default null
      ,LastIncreaseDate date default null
      ,LastIncreasePercent float default null
      ,CostCenterCode varchar2 default null
      ,CompGlobalRegion varchar2 default null
  
      ,isEligibilityUpdatable int default 1
      ,isRecordUpdatable int default 1
      ,forceLoad int default 0
      ,eligibility ngt_eligibility default null
     
      
  )return self as result
  
  ,member function get return ngt_compEmp
  ,member function setFromTables return ngt_compEmp
  ,member function isCached return boolean
  ,member function print return varchar2
  ,member function getEmpRef(p_EID number, p_CycleID number) return ref ngt_compEmp
  ,member procedure save

  
  
  )
   NOT FINAL;
/

-- persist the objects
create table hr_compEmp of ngt_compEmp (
     constraint hr_compEmp_pk primary key (cycleID,EID)
    ,constraint hr_compEmp_eid foreign key (eid) references hr_employees
    ,constraint hr_compEmp_cycleid foreign key (cycleid) references hr_fy_cycles
    ,constraint hr_compEmp_NewJobCode foreign key (jobCode) references hr_jobs
    );
/

