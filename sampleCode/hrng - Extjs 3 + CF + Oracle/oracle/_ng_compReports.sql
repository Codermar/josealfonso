set define off;
create or replace package ng_compReports AS
/*
  Package: ng_compReports
  Description: Reports for hrtools NG
  Author: Jose Alfonso
  
*/
TYPE genRefCursor IS REF CURSOR;

PROCEDURE getSPExceptions ( 
   p_BelowRangeMin IN OUT genRefCursor
  ,p_AboveRangeMax in out genRefCursor 
  ,p_Above3xMerit in out genRefCursor
  ,p_EligBlankMerit in out genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getICPExceptions ( 
   p_ICPOutsideRange IN OUT genRefCursor
  ,p_EligBlankICP IN OUT genRefCursor 
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);
  
PROCEDURE getLTIExceptions ( 
   p_ltiExceptions IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getDataDownload ( 
   p_org IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_OrgType INTEGER
  ,p_Countries VARCHAR2 DEFAULT NULL
  ,p_showLTIInfo int default 1);

PROCEDURE ratingAnalysisSalICP (
      p_Merit IN OUT Globals.genRefCursor,
      p_Salary IN OUT Globals.genRefCursor,
      p_ICP IN OUT Globals.genRefCursor,
      p_ManagerID NUMBER,
      p_CycleID   NUMBER,
      p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE salaryIcreaseAnalysis (
      p_Data IN OUT Globals.genRefCursor,
      p_ManagerID NUMBER,
      p_CycleID   NUMBER,
      p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE IncreaseAvgByCal ( 
   p_data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);


PROCEDURE salicpPosInRange(
   p_data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE EmpMarketRangePositioning(
     p_cursor IN OUT Globals.genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getRatingChart(
     p_cursor IN OUT genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getICPIndModByCal(
     p_cursor IN OUT genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getLTIIndModByCal(
     p_LTIAvgByCal IN OUT genRefCursor
    ,p_LTIAvgAsPct in out genRefCursor
    ,p_LTIAvgByCal912 IN OUT genRefCursor
    ,p_LTIAvgAsPct912 in out genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2);

procedure getCompLetters (
         p_Letters in OUT genRefCursor
        ,p_EmployeeIDList VARCHAR2 default null
        ,p_CycleID number
        ,p_Countries VARCHAR2 DEFAULT NULL);



procedure putTotalReports(p_ManagerID NUMBER,p_CycleID   NUMBER);


function geteffdate return date;

function getSAPEmpType(p_EmpType varchar2) return VARCHAR2;



  const_effdate CONSTANT date := '01-APR-' || TO_CHAR(SYSDATE, 'YY');


END ng_compReports;
/




create or replace package body ng_compReports AS


PROCEDURE getSPExceptions ( 
   p_BelowRangeMin IN OUT genRefCursor
  ,p_AboveRangeMax in out genRefCursor 
  ,p_Above3xMerit in out genRefCursor
  ,p_EligBlankMerit in out genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is
  
  v_sql varchar2(4000);

begin
  
  -- put the org into the temp table
  putTotalReports(p_ManagerID,p_CycleID);
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  -- 
  v_sql := 
      'select o.* from ('
      || '  select' 
      || '         d.eid employeeid'
      || '        ,d.empname employeeName'
      || '        ,d.managerid '
      || '        ,d.manager.empname managername'    
      || '        ,d.compEmp.orgUnitCode orgUnitCode'
      || '        ,j.job_title jobTitle'
      || '        ,j.job_grade careerBand'
      || '        ,d.compEmp.employmentCountry employmentCountry'
      || '        ,d.compEmp.FTsalary FTsalary'
      || '        ,d.compEmp.eligibility.isSalaryEligible salaryeligible'
      || '        ,d.recSalary.Merit      recmeritinc'
      || '        ,d.recSalary.MeritPerc  RecMeritIncPerc'
      || '        ,d.compInput.MeritAmt meritamt'
      || '        ,decode(d.compEmp.eligibility.isSalaryEligible,0,nvl(d.compEmp.FTSalary,0) '
      || '          ,decode(nvl(d.compInput.LumpSumAmt,0),0'
      || '            ,NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0)'
      || '            ,nvl(d.compEmp.FTSalary,0) ) '
      || '        ) newftsalary'
      || '        ,NVL(d.compInput.MeritPerc,0) + NVL(d.compInput.LumpSumPerc,0) + NVL(d.compInput.AdjustmentPerc,0) + NVL(d.compInput.PromotionPerc,0) as TotalIncreasePercent '          
      || '        ,NVL(d.compInput.MeritPerc,0) meritperc'
      || '        ,nvl(d.recSalary.PercThruRangeCurr,0) * 100  percentthrurangecurr'
      || '        ,d.compEmp.contributionCalibration contribution'
      || '        ,d.compEmp.potentialCalibration   potential'        
      || '        ,d.recSalary.JobMarketData.highFTE  highFTE'
      || '        ,d.recSalary.JobMarketData.LowFTE   LowFTE'       
      || '        ,treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).MeritPercModifier MeritPercModifier'
      || '  from tmp_emp_org t'
      || '      ,hr_compOrg d, hr_jobs j'
      || '  where t.eid = d.eid'
      || '  and d.compEmp.JobCode = j.job_code(+)'
      || ') o WHERE 0=0'
  ;
  
  -- 'Employees with SALARY BELOW RANGE MINIMUM (if market data available)'
  open p_BelowRangeMin for v_sql || 'AND o.newftsalary < o.LowFTE';
  -- 'Employees with NEW SALARY ABOVE RANGE MAXIMUM (if market data available)'
  open p_AboveRangeMax for v_sql || 'AND o.newftsalary > o.highFTE'; 
   --  Employees with Merit Increase % that is GREATER THAN 3x MERIT BUDGET %
  open p_Above3xMerit for v_sql || 'AND o.MeritPercModifier * 3 < o.meritperc';
  -- 'Eligible EEs with BLANK Merit Increase Field'
  open p_EligBlankMerit for v_sql || 'AND o.salaryeligible = 1 and o.meritamt is null';
  
end getSPExceptions;

PROCEDURE getICPExceptions ( 
   p_ICPOutsideRange IN OUT genRefCursor
  ,p_EligBlankICP IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is

  v_sql varchar2(4000);

begin
  
  -- put the org into the temp table
  putTotalReports(p_ManagerID,p_CycleID);
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  -- 
  v_sql := 
      'select o.* from ('
      || '  select' 
      || '         d.eid employeeid'
      || '        ,d.empname employeeName'
      || '        ,d.managerid '
      || '        ,d.manager.empname managername'    
      || '        ,d.compEmp.orgUnitCode orgUnitCode'
      || '        ,j.job_title jobTitle'
      || '        ,j.job_grade careerBand'
      || '        ,d.compEmp.eligibility.isICPEligible icpeligible'
      || '        ,d.compEmp.employmentCountry employmentCountry'
      || '        ,d.compEmp.contributionCalibration contribution'
      || '        ,d.compEmp.ICPTargetPercent * 100 ICPTargetPercent'
      || '        ,d.recICP.ICPPerc * 100   as icprecommendedincperc'
      || '        ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPCompanyMod  icpcompanymodifier '
      || '        ,d.compInput.ICPAward icpamount'
      || '        ,d.compInput.ICPIndivModifier icpindivmodifiernew '
      || '        ,floor(nvl(d.recICP.ICPPerc * 100,0) - (nvl(d.recICP.ICPPerc * 100,0) * 10 / 100)) minModifier'
      || '        ,round((nvl(d.recICP.ICPPerc * 100,0) * 10 / 100) + nvl(d.recICP.ICPPerc * 100,0),0) maxModifier '
      || '        ,d.compEmp.icpsalary icpsalary'
      || '        ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPIndivMod    icpindivmodifier ' 
      || '        ,d.compInput.ICPOutsideRangeJust as icpoutsiderangejust'
      || '  from tmp_emp_org t'
      || '      ,hr_compOrg d, hr_jobs j'
      || '  where t.eid = d.eid'
      || '  and d.compEmp.JobCode = j.job_code(+)'
      || ') o WHERE 0=0'
  ;
  
  -- 'Employees outside the range'
  open p_ICPOutsideRange for v_sql || 'and o.icpindivmodifiernew is not null and o.icpindivmodifiernew not between o.minModifier and o.maxModifier';

  open p_EligBlankICP for v_sql || 'and o.icpeligible = 1 and o.icpindivmodifiernew is null';
  
end getICPExceptions;

PROCEDURE getLTIExceptions ( 
   p_ltiExceptions IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is

  v_sql varchar2(4000);

begin
  
  -- put the org into the temp table
  putTotalReports(p_ManagerID,p_CycleID);
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  -- 
  v_sql := 
      'select o.* from ('
      || '  select' 
      || '         d.eid employeeid'
      || '        ,d.empname employeeName'
      || '        ,d.managerid '
      || '        ,d.manager.empname managername'    
      || '        ,d.compEmp.orgUnitCode orgUnitCode'
      || '        ,j.job_title jobTitle'
      || '        ,j.job_grade careerBand'
      || '        ,d.compEmp.employmentCountry employmentCountry'
      || '        ,d.compEmp.potentialCalibration potential'
      || '        ,d.recLTI.LTIGuidelines.ParticRate'       
      || '        ,d.compInput.LTIGrantAmt grantamt'
      || '        ,d.compInput.LTGrantModifier as ltimodifier'
      || '        ,nvl(d.recLTI.LTIPerc * 100,0)   as ltirecommendedperc'
      || '        ,round(nvl(d.recLTI.LTIPerc * 100,0) - (nvl(d.recLTI.LTIPerc * 100,0) * 6 / 100),1) minModifier'
      || '        ,round((nvl(d.recLTI.LTIPerc * 100,0) * 6 / 100) + nvl(d.recLTI.LTIPerc * 100,0),1) maxModifier'
      || '        ,d.compInput.LTIGrantOutSideRangeJust as LTIGrantOutSideRangeJust '
      || '        ,decode(nvl(d.compEmp.FTSalary,0),0,null, d.compEmp.UnvestedSharesValue / (d.getNewSalary() * d.compEmp.CurrencyUSD) * 100) unvestedamountaspercentofbase'        
      || '  from tmp_emp_org t'
      || '      ,hr_compOrg d, hr_jobs j'
      || '  where t.eid = d.eid'
      || '  and d.compEmp.JobCode = j.job_code(+)'
      || ') o WHERE 0=0'
  ;

  -- 'Employees outside the range'
  open p_ltiExceptions for v_sql || 'and o.ltimodifier not between o.minModifier and o.maxModifier';
  
end getLTIExceptions;


PROCEDURE getDataDownload ( 
   p_org IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_OrgType INTEGER
  ,p_Countries VARCHAR2 DEFAULT NULL
  ,p_showLTIInfo int default 1) is

  orgCursor  SYS_REFCURSOR;
  EmpRecord ng_org.EmpCompOrgRecord;
  
begin

  delete from tmp_emp_org;
  -- Get The org and place it in a temp table to be used as the base table
      orgCursor := ng_org.getCompOrg(p_ManagerID,p_CycleID,p_OrgType);
      
      LOOP
          FETCH orgCursor INTO EmpRecord;
          EXIT WHEN orgCursor%NOTFOUND;
          -- DBMS_OUTPUT.put_line ('EID: ' || EmpRecord.eid); 
          -- TODO: Using tmp_org for testing only. It's a regular table, eventually, we would use a temp table or a plsql table.
          insert into tmp_emp_org (eid) values(EmpRecord.eid);
      END LOOP;
      
      
  OPEN p_org FOR 
    select y.*
    -- DD specific/calculated
    ,y.MeritBudgeted * y.CurrencyUSD MeritBudgetedUSD
    ,y.PABudgeted * y.CurrencyUSD PABudgetedUSD
    ,y.LTIBudgeted * y.CurrencyUSD LTIBudgetedUSD
    ,y.ICPBudgeted * y.CurrencyUSD  ICPBudgetedUSD
    
    -- TODO: monthly salary should move to inner query when I add YearlyPayPeriods field
    ,(nvl(y.FTSalary,0) * NVL(y.percentTimeWorked,100) / 100) / DECODE(y.YearlyPayPeriods,NULL,12,0,12,y.YearlyPayPeriods)  MonthlySalary
    ,(nvl(y.FTSalary,0) * NVL(y.percentTimeWorked,100) / 100) / DECODE(y.YearlyPayPeriods,NULL,12,0,12,y.YearlyPayPeriods)  * y.CurrencyUSD monthlySalaryUSD
    ,(nvl(y.newftsalary,0) * NVL(y.percentTimeWorked,100) / 100) / DECODE(y.YearlyPayPeriods,NULL,12,0,12,y.YearlyPayPeriods)  monthlySalaryNew
    ,((nvl(y.newftsalary,0) * NVL(y.percentTimeWorked,100) / 100) / DECODE(y.YearlyPayPeriods,NULL,12,0,12,y.YearlyPayPeriods)  * y.CurrencyUSD) monthlySalaryNewUSD
    ,nvl(y.FTSalary,0) * y.CurrencyUSD ftSalaryUSD
    ,y.AnnualSalary * y.CurrencyUSD AnnualSalaryUSD
    ,y.meritamt * y.CurrencyUSD meritamtUSD
    ,y.LumpSumAmt * y.CurrencyUSD LumpSumAmtUSD
    ,y.PromotionAmt * y.CurrencyUSD PromotionAmtUSD
    ,y.AdjustmentAmt * y.CurrencyUSD AdjustmentAmtUSD
    ,y.totalamtinc * y.CurrencyUSD  totalamtincUSD
    ,y.grantamt * y.CurrencyUSD  grantamtUSD
    ,y.newftsalary * y.CurrencyUSD newftsalaryUSD
    ,y.AnnualSalaryNew * y.CurrencyUSD AnnualSalaryNewUSD
    ,y.ICPAmount * y.CurrencyUSD ICPAmountUSD
    ,round(y.recmeritincperc,1) * (100 - y.salaryincwarningthreshold) / 100 meritMinRec
    ,round(y.recmeritincperc,1) * (100 + y.salaryincwarningthreshold) / 100 meritMaxRec
    
    ,floor(y.icprecommendedincperc * (100 - y.icpincwarningthreshold) / 100) icpMinRec
		,round(y.icprecommendedincperc * (100 + y.icpincwarningthreshold) / 100,0) icpMaxRec
    
    ,round(y.ltirecommendedperc,1) * (100 - y.ltiincwarningthreshold) / 100 ltiMinRec
    ,round(y.ltirecommendedperc,1) * (100 + y.ltiincwarningthreshold) / 100 ltiMaxRec
   
    -- sap report fields
    ,CASE
      WHEN NVL(y.MeritAmt,0) > 0 AND y.sapAdjAmt > 0  AND y.sapPromAmt > 0 THEN 'AX'
      WHEN y.sapAdjAmt > 0 AND NVL(y.MeritAmt,0) > 0 THEN 'AM'
      WHEN NVL(y.MeritAmt,0) > 0 AND y.sapPromAmt > 0 THEN 'MP'
      WHEN NVL(y.MeritAmt,0) > 0 THEN 'M'
      WHEN y.sapAdjAmt > 0 AND y.sapPromAmt > 0 THEN 'AP'
      WHEN y.sapAdjAmt > 0 THEN 'A'
      WHEN y.sapPromAmt > 0 THEN 'P'
      ELSE NULL END as SAPreasonJobCodeChange
      
    ,ng_compReports.getSAPEmpType(y.EmploymentPayType) as SAPSalaryGroup

    ,null AS SAPNextIncreaseDate
    ,(NVL(y.MeritAmt,0) + y.sapAdjAmt  + y.sapPromAmt )
        * (NVL(y.percentTimeWorked,100) / 100) as SAPTotalIncreaseAmount
    ,CASE
        WHEN y.EmploymentCountry = 'USA' THEN y.SAPAnnualSalaryNew/26
        when y.EmploymentCountry in('Brazil', 'China', 'France', 'Mexico', 'Singapore', 'South Korea', 'Taiwan', 'Thailand') then y.SAPAnnualSalaryNew/13
        WHEN y.EmploymentCountry in('Austria', 'Italy', 'Portugal', 'Spain') THEN y.SAPAnnualSalaryNew/14
        when y.EmploymentCountry = 'Hong Kong'then y.SAPAnnualSalaryNew/12
        when y.EmploymentCountry = 'Japan' then y.SAPAnnualSalaryNew/18
        WHEN y.EmploymentCountry = 'Canada' THEN y.SAPAnnualSalaryNew/24
        WHEN y.EmploymentCountry = 'Netherlands' THEN y.SAPAnnualSalaryNew/14.04
        WHEN y.EmploymentCountry = 'Switzerland' THEN y.SAPAnnualSalaryNew/13.5
        WHEN y.EmploymentCountry = 'Belgium' THEN y.SAPAnnualSalaryNew/13.92
        ELSE (y.SAPAnnualSalaryNew / DECODE(y.YearlyPayPeriods,NULL,12,0,12,y.YearlyPayPeriods))
		END AS SAPMonthlySalary
    
  from (  
  select   
         o.eid EmployeeID
        
        
        ,decode(nvl(to_char(d.compInput.AdjEffectiveDate,'DD-MON-YY'),ng_compReports.geteffdate), ng_compReports.geteffdate, NVL(d.compInput.AdjustmentAmt,0), 0) sapAdjAmt
        ,decode(nvl(to_char(d.compInput.PromotionEffectiveDate,'DD-MON-YY'),ng_compReports.geteffdate), ng_compReports.geteffdate, NVL(d.compInput.PromotionAmt,0), 0) sapPromAmt
  
        ,(decode(d.compEmp.eligibility.isSalaryEligible,0,nvl(d.compEmp.FTSalary,0) 
          ,decode(nvl(d.compInput.LumpSumAmt,0),0
            ,NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) 
                + decode(nvl(to_char(d.compInput.AdjEffectiveDate,'DD-MON-YY'),ng_compReports.geteffdate), ng_compReports.geteffdate, NVL(d.compInput.AdjustmentAmt,0), 0)
                + decode(nvl(to_char(d.compInput.PromotionEffectiveDate,'DD-MON-YY'),ng_compReports.geteffdate), ng_compReports.geteffdate, NVL(d.compInput.PromotionAmt,0), 0)
          ,nvl(d.compEmp.FTSalary,0) ) 
        ) * NVL(d.compEmp.percentTimeWorked,100) ) SAPAnnualSalaryNew
        
         -- DD Specific fields
        ,e.last_name LastName
        ,e.known_as KnownAs
        ,e.first_name FirstName
        ,e.current_status empStatus        
        ,d.compEmp.orgUnitCode orgUnitCode
        ,ou.ORG_UNIT_LONGTEXT orgUnitLongText
        ,d.compEmp.CompensationGroup CompensationGroup
        ,d.compEmp.PAID PAID
        ,pa.personnel_area_name PAText
        -- these will be in compEmp
        ,d.compEmp.BridgedServiceDate BridgedServiceDate
        ,d.compEmp.InJobDate InJobDate
        ,d.compEmp.LastLOA LastLOA
        ,d.compEmp.LastIncreaseDate LastIncreaseDate
        ,d.compEmp.LastIncreasePercent LastIncreasePercent
        ,d.compEmp.CostCenterCode CostCenterCode
        ,d.compEmp.CompGlobalRegion CompGlobalRegion
        
        -- placeholder until I add the field
        ,d.compEmp.yearlyPayPeriods yearlyPayPeriods
 
        ,d.compEmp.Eligibility.GeneratesSalary GeneratesSalary
        ,d.compEmp.Eligibility.GeneratesICP GeneratesICP
        ,d.compEmp.Eligibility.GeneratesLTI GeneratesLTI
        ,decode(d.compEmp.Eligibility.GeneratesSalary,0,0,
          NVL((d.compEmp.FTSalary * treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).MeritPercModifier)  / 100,0)
        ) MeritBudgeted
        ,decode(d.compEmp.Eligibility.GeneratesSalary,0,0,
          NVL((d.compEmp.FTSalary  * treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).PAPercModifier) / 100, 0)
        ) PABudgeted
        
        ,decode(d.compEmp.Eligibility.GeneratesICP,0,0,      
          (treat(deref(d.recICP.icpMod) as ngt_icpMod).ICPCompanyMod * treat(deref(d.recICP.icpMod) as ngt_icpMod).ICPIndivMod) /100 -- icp funding level
          * ((d.compEmp.ICPSalary * d.compEmp.ICPTargetPercent /100) )
        ) ICPBudgeted
        
        ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,
          d.recLTI.LTIGuidelines.TargetGrant * d.recLTI.LTIGuidelines.ParticRate / 100
        ) LTIBudgeted
        -- end DD specific
        
        
        ,d.empname EmployeeName
        ,d.managerid 
        ,d.manager.empname managername
        ,d.cycleid
        ,d.compEmp.DirectReports DirectReports
        ,d.compEmp.TotalReports TotalReports
        ,0 as isModified -- placeholder for grid
        ,d.compEmp.eligibility.isSalaryEligible SalaryEligible
     
        ,nvl(d.compEmp.FTSalary,0) FTSalary
        ,(NVL(d.compEmp.FTSalary,0) * NVL(d.compEmp.percentTimeWorked,100) ) AnnualSalary
        ,(d.getNewSalary() * NVL(d.compEmp.percentTimeWorked,100) ) AnnualSalaryNew
        
        
        ,(d.compEmp.percentTimeWorked * 100) percenttimeworked
        ,d.compEmp.EmploymentGroup EmploymentGroup
        ,d.compEmp.EmploymentPayType EmploymentPayType
        ,d.compEmp.CurrencyUSD CurrencyUSD
        ,d.compEmp.SalCurrency SalCurrency
         
        ,decode(d.compEmp.eligibility.isSalaryEligible,0,nvl(d.compEmp.FTSalary,0) -- default current
          ,d.getNewSalary()
        ) newftsalary

        ,d.compInput.MeritAmt meritamt
        ,d.compInput.MeritPerc meritperc
        ,d.compInput.MeritOutsideRangeJust MeritOutsideRangeJust

        ,d.compInput.AdjustmentAmt adjustmentamt
        ,d.compInput.AdjustmentPerc adjustmentperc
        ,to_char(d.compInput.AdjEffectiveDate,'MON-YYYY') adjusteffectivedate
        ,d.compInput.AdjustmentReason AdjustmentReason
        ,d.compInput.AdjustmentOutsideRangeJust AdjustmentOutsideRangeJust
        
        ,d.compInput.PromotionAmt promotionamt
        ,d.compInput.PromotionPerc promotionpercent
        ,to_char(d.compInput.PromotionEffectiveDate,'MON-YYYY') PromotionEffectiveDate
        ,d.compInput.PromotionOutsideRangeJust PromotionOutsideRangeJust
        
        -- percentthrurangecurr > 100 nvl(d.recSalary.PercThruRangeCurr,0) * 100
        
        ,case when nvl(d.recSalary.PercThruRangeCurr,0) * 100 > 100 then  d.recSalary.LumpSum else null end as lumpsumrecommendedinc
       -- ,d.recSalary.LumpSum lumpsumrecommendedinc
        --,d.recSalary.LumpSumPec lumpsumrecommendedperc
        ,case when nvl(d.recSalary.PercThruRangeCurr,0) * 100 > 100 then  d.recSalary.LumpSumPec else null end as lumpsumrecommendedperc
        
        ,d.compInput.LumpSumAmt lumpsumamt
        ,d.compInput.LumpSumPerc lumpsumperc
        ,d.compInput.LumpSumOutsideRangeJust as LumpSumOutsideRangeJust    
        
        ,NVL(d.compInput.MeritPerc,0) + NVL(d.compInput.LumpSumPerc,0) + NVL(d.compInput.AdjustmentPerc,0) + NVL(d.compInput.PromotionPerc,0) as totalpercinc -- total for worksheet
        ,NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.LumpSumAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0) as totalamtinc
        
        ,d.compEmp.caid caid
        ,d.compEmp.JobCode JobCode
        ,j.job_title jobTitle
        ,j.job_level joblevel
        ,j.job_grade careerBand
        ,j.job_family jobfamily
        ,j.job_func_area jobfunctarea
        
        -- TODO: this does not seem right!
        ,j.job_level CompLevelID
        
        ,DECODE(j.JOB_EXEMPT, 'Y', 'Exempt', 'EX', 'Exempt' ,'N', 'Non-Exempt', 'NEX','Non-Exempt', NULL) jobexempt
        
        ,d.compInput.newjobjustification newjobjustification
        ,d.compInput.NewJobCode newjobcode    
        
        ,d.compInput.NewJobInfo.JobTitle NewJobTitle
        ,d.compInput.NewJobInfo.CareerBand NewCareerBand
        ,d.compInput.NewJobInfo.JobExempt JobExemptNew
        ,d.compInput.NewJobInfo.lowFTE lowftenew 
        ,d.compInput.NewJobInfo.highFTE highftenew    
        ,case when d.compInput.NewJobCode is null then (d.compEmp.ICPTargetPercent * 100) when d.compEmp.ICPTargetPercent > d.compInput.NewJobInfo.ICPTargetPercent then d.compEmp.ICPTargetPercent else d.compInput.NewJobInfo.ICPTargetPercent end as icptargetpercnew
        
        ,d.compEmp.employmentlocation employmentlocation
        ,d.compEmp.employmentCountry EmploymentCountry
        ,d.compEmp.mrhiredate mrhiredate

        ,decode(d.compEmp.eligibility.isSalaryEligible,0,'true','false') hidesalaryinput
        ,decode(d.compEmp.eligibility.isICPEligible,0,'true','false') hideicpinput
        ,decode(d.compEmp.eligibility.isLTIEligible,0,'true','false') hideltiinput
        
        /* Goals and dialogs TODO: */
        ,'Not defined...' as goalProgress

        ,Nvl(d.compEmp.contributionCalibrationprev,'N/A') as contributionprev 
        ,nvl(d.compEmp.potentialCalibrationprev,'N/A') as potentialprev 
        ,EXTRACT( YEAR FROM sysdate) - 1 calibrationyearprev
        ,d.compEmp.contributionCalibration contribution
        ,d.compEmp.potentialCalibration   potential
        ,EXTRACT( YEAR FROM sysdate)      calibrationyear
        
        /* Recommended values */
        ,d.recSalary.JobMarketData.highFTE  highFTE
        ,d.recSalary.JobMarketData.LowFTE   LowFTE
        --,round(d.recSalary.Merit,0)      recmeritinc
        --,round(d.recSalary.MeritPerc,1)  RecMeritIncPerc
        
        ,case when nvl(d.recSalary.PercThruRangeCurr,0) * 100 < 100 then  d.recSalary.Merit else null end as recmeritinc
        ,case when nvl(d.recSalary.PercThruRangeCurr,0) * 100 < 100 then  d.recSalary.MeritPerc else null end as RecMeritIncPerc
        
        ,treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).MeritPercModifier meritpercmodifier
        ,treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).PAPercModifier PAPercModifier
        ,d.recSalary.matrixModifier matrixmodifier
        /*  this would also need to change in ng_compService */
        ,15 as salaryIncWarningThreshold -- this would come from the hr_fy_cycles table (new field)
        ,10 as Icpincwarningthreshold 
        ,6 as ltiIncWarningThreshold

        
        /* ICP */
        ,d.compEmp.eligibility.isICPEligible ICPEligible
        ,round(d.recICP.ICPAmt,0)    as icprecommendedinc
        ,round(d.recICP.ICPPerc * 100,2)   as icprecommendedincperc
        ,d.compInput.ICPOutsideRangeJust as icpoutsiderangejust
        ,round(d.recSalary.PercThruRangeCurr * 100,1)  percentthrurangecurr
        
        ,round(decode(d.compInput.NewJobCode,null,nvl(d.getNewPTR(),0) * 100
          ,decode(d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE,null,null,0,null
            ,(d.getNewSalary() - d.compInput.NewJobInfo.lowFTE) / (d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE) * 100) ),1) percentthrurangenew
        
        
        ,d.compEmp.icpsalary icpsalary
        ,d.compInput.ICPAward icpamount
        ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPCompanyMod  icpcompanymodifier 
        ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPIndivMod    icpindivmodifier 
        ,decode(d.compEmp.ICPSalary,null,null,0,null,
          d.compInput.ICPAward / d.compEmp.ICPSalary * 100) icppercentofsalary  
        ,d.compEmp.ICPTargetPercent * 100 as icptargetperc
        
        
        ,d.compEmp.icpsalary * NVL(d.compEmp.ICPTargetPercent,0)  AS icptargetamt -- (Formula: is = ICP Sal  X  ICP Target % )
        ,d.compInput.ICPIndivModifier icpindivmodifiernew  
        
        /* LTI */
        ,d.compEmp.payScaleLevel payScaleLevel
        ,d.compEmp.eligibility.isLTIEligible LTIEligible 
        ,round(nvl(d.recLTI.LTIAmt,0),0)    as ltirecommendedvalue
        ,round(nvl(d.recLTI.LTIPerc * 100,0),2)   as ltirecommendedperc
        
        ,d.compInput.LTIGrantAmt grantamt
        ,d.recLTI.LTIGuidelines.TargetGrant   TargetGrant 
        ,d.compInput.LTGrantModifier as ltimodifier
        ,d.compInput.LTIGrantOutSideRangeJust as LTIGrantOutSideRangeJust  

        ,d.compEmp.UnvestedSharesValue as unvestedsharesvalue
        
        ,decode(nvl(d.compEmp.FTSalary,0),0,null
          ,d.compEmp.UnvestedSharesValue / (d.getNewSalary() * d.compEmp.CurrencyUSD) * 100) unvestedamountaspercentofbase
        
        ,nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0) as unvestedsharesvaluenew
        ,decode(nvl(d.compEmp.FTSalary,0),0,null,(nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0)) / (d.getNewSalary() * d.compEmp.CurrencyUSD) * 100) unvestedamountnewpercent
        ,nvl(d.compInput.LastModifiedString,'N/A') lastmodifiedbystring 
    
    from tmp_emp_org o
        ,hr_employees e
        ,hr_compOrg d
        ,hr_jobs j
        ,hr_personnel_areas pa
        ,hr_org_units ou
    where o.eid = e.emp_id
    and o.eid = d.eid
    and d.compEmp.JobCode = j.job_code(+)
    and d.compEmp.PAID = pa.paid(+)
    and d.compEmp.orgUnitCode = ou.org_unit_code(+)
    order by e.last_name, e.first_name
) y    ;


end getDataDownload;

PROCEDURE salaryIcreaseAnalysis (
      p_Data IN OUT Globals.genRefCursor,
      p_ManagerID NUMBER,
      p_CycleID   NUMBER,
      p_ManagerName OUT nocopy VARCHAR2) is

begin
  
  /* This is really a "rollup" group by rating */
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);

open p_Data for  
  
  select   
     o.ratingID
    ,o.rating 
    ,COUNT(1) EmpCount
    ,sum(COUNT(1)) over() EmpCountTotal
    ,sum(o.elig) EligCount 
    ,sum(sum(o.elig)) over () EligCountTotal
    --,sum(sum(o.IncPercAll)) over() IncPercAllSum
    -- ,sum(sum(o.RecIncCount)) over() RecIncCountSum
    ,round(Hrshared.getPercent(sum(o.IncPercAll) , sum(o.RecIncCount) ) / 100 ,2) AvgIncPerc
    ,round(Hrshared.getPercent(sum(sum(o.IncPercAll)) over() , sum(sum(o.RecIncCount)) over() ) / 100 ,2) AvgIncPercTotal
    
    ,sum(o.LT35) LT35Count
    ,sum(o.B3570) B3570Count
    ,sum(o.GT70) GT70Count
    ,sum(sum(o.LT35)) OVER() LT35CountTotal
    ,sum(sum(o.B3570)) OVER() B3570CountTotal
    ,sum(sum(o.GT70)) OVER() GT70CountTotal
    
    ,sum(o.LT35IncPerc) LT35IncPercSum
    ,sum(o.B3570IncPerc) B3570IncPercSum 
    ,sum(o.GT70IncPerc) GT70IncPercSum
    
    ,round(Hrshared.getPercent(sum(LT35IncPerc), sum(o.LT35)) / 100,2) LT35AvgIncPerc
    ,round(Hrshared.getPercent(sum(B3570IncPerc), sum(o.B3570)) / 100,2) B3570AvgIncPerc
    ,round(Hrshared.getPercent(sum(GT70IncPerc), sum(o.GT70)) / 100,2) GT70AvgIncPerc
    
    ,round(Hrshared.getPercent(sum(sum(LT35IncPerc)) over (), sum(sum(o.LT35)) over() ) / 100,2) LT35AvgIncPercTotal
    ,round(Hrshared.getPercent(sum(sum(B3570IncPerc)) over(), sum(sum(o.B3570)) over () ) / 100,2) B3570AvgIncPercTotal
    ,round(Hrshared.getPercent(sum(sum(GT70IncPerc)) over(), sum(sum(o.GT70)) over() ) / 100,2) GT70AvgIncPercTotal
    
    from (
      select
         r.eid
        ,r.ratingID
       -- ,COUNT(1) EmpCount
        ,r.rating
        ,r.elig
        ,r.ptrnew
        ,r.EmpWithInc
        ,r.IncPerc
        ,decode(r.elig,0,0,nvl(r.IncPerc,0)) IncPercAll
        ,case
            when r.elig = 0 then 0
            else 1
            end as RecIncCount
            
        ,case
            when r.elig = 0 then 0
            when r.ptrnew < 35 then 1
            else 0
            end as LT35
        ,case
            when r.elig = 0 then 0
            when r.ptrnew < 35 then r.IncPerc
            else 0
            end as LT35IncPerc    
        ,case
            when r.elig = 0 then 0
            when r.ptrnew between 35 and 70 then 1
            else 0
            end as B3570
        ,case
            when r.elig = 0 then 0
            when r.ptrnew between 35 and 70 then r.IncPerc
            else 0
            end as B3570IncPerc     
        ,case
            when r.elig = 0 then 0
            when r.ptrnew > 70 then 1
            else 0
            end as GT70 
        ,case
            when r.elig = 0 then 0
            when r.ptrnew > 70 then r.IncPerc
            else 0
            end as GT70IncPerc    
      from (
        select 
           d.eid
          ,Hrshared.getRatingID(NVL(d.compEmp.contributionCalibration,'Not Calibrated')) ratingID
          ,nvl(d.compEmp.contributionCalibration,'Not Calibrated') Rating
          --,round(d.recSalary.PercThruRangeCurr * 100,1)  ptr
          ,d.compEmp.eligibility.isSalaryEligible elig
          ,decode(d.compEmp.eligibility.isSalaryEligible,0,0
              ,decode(NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0),0,0,1)) EmpWithInc
          ,round(Hrshared.getPercent(NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0),NVL(d.compEmp.FTSalary,0)),2) IncPerc
          
          ,round(decode(d.compInput.NewJobCode,null,nvl(d.getNewPTR(),0) * 100
                ,decode(d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE,null,null,0,null
                  ,(d.getNewSalary() - d.compInput.NewJobInfo.lowFTE) / (d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE) * 100) ),1) ptrnew
              
      
         FROM hr_compOrg d 
            START WITH d.managerid = p_ManagerID  
            CONNECT BY PRIOR d.eid = d.managerid
              AND PRIOR d.cycleid = p_CycleID
       ) r 
  ) o
  group by o.ratingID, o.rating
  order by o.ratingID;
  

  

  

end salaryIcreaseAnalysis;


PROCEDURE ratingAnalysisSalICP (
      p_Merit IN OUT Globals.genRefCursor,
      p_Salary IN OUT Globals.genRefCursor,
      p_ICP IN OUT Globals.genRefCursor,
      p_ManagerID NUMBER,
      p_CycleID   NUMBER,
      p_ManagerName OUT nocopy VARCHAR2) is
begin
  
  /* This is really a "rollup" group by rating */
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  ng_compRollup.putSalICPIncreaseRollup(
      p_ManagerID,
      p_CycleID); 
  
  
  open p_Merit for 
    SELECT o.*,
      SUM(o.EmpCount) OVER () EmpCountTotal,
      SUM(o.MeritWithInc) OVER () MeritWithIncTotal
      ,o.EmpCount - o.EligCount AS NotEligCount
      ,sum(o.EmpCount) over() - sum(o.EligCount) over() AS NotEligCountTotal
      
      ,Hrshared.getPercent(SUM(o.MeritWithInc) OVER(),SUM(o.EmpCount) OVER () ) PercWithIncTotal,
      MAX(o.MaxIncPerc) OVER () MaxIncPercTotal,
      MIN(o.MinIncPerc) OVER () MinIncPercTotal,
      AVG(o.AvgIncPerc) OVER () AvgIncPercTotal,
      Hrshared.getPercent(o.EmpCount, SUM(o.EmpCount) OVER () ) PercWithRating,
      Hrshared.getPercent(SUM(o.EmpCount) OVER (), SUM(o.EmpCount) OVER () ) PercWithRatingTotal,
      Hrshared.getPercent(o.MeritWithInc,o.EligCount) PercMeritWithInc
  FROM (
   SELECT r.rating,
      COUNT(1) EmpCount,
      SUM(r.IS_ELIG) EligCount
      ,sum(decode(r.IS_ELIG,0,0,decode(nvl(r.MERIT_INC,0),0,0,1))) MeritWithInc 
      ,MAX(Hrshared.getPercent(r.MERIT_INC,r.FT_SAL)) MaxIncPerc,
      MIN(Hrshared.getPercent(r.MERIT_INC,r.FT_SAL)) MinIncPerc,
      AVG(Hrshared.getPercent(r.MERIT_INC,r.FT_SAL)) AvgIncPerc
   FROM TMP_INCROLLUP r
   GROUP BY r.rating_id,r.rating
   ORDER BY r.rating_id
  )o;
    
  open p_Salary for 
    SELECT o.*,
      SUM(o.EmpCount) OVER () EmpCountTotal,
      SUM(o.CountWithInc) OVER() CountWithIncTotal,
      Hrshared.getPercent(SUM(o.CountWithInc) OVER(),SUM(o.EmpCount) OVER () ) PercWithIncTotal
      
      ,o.EmpCount - o.EligCount AS NotEligCount
      ,sum(o.EmpCount) over() - sum(o.EligCount) over() AS NotEligCountTotal
      
      ,MAX(o.MaxIncPerc) OVER () MaxIncPercTotal,
      MIN(o.MinIncPerc) OVER () MinIncPercTotal,
      AVG(o.AvgIncPerc) OVER () AvgIncPercTotal,
      Hrshared.getPercent(o.EmpCount, SUM(o.EmpCount) OVER () ) PercWithRating,
      Hrshared.getPercent(SUM(o.EmpCount) OVER (), SUM(o.EmpCount) OVER () ) PercWithRatingTotal,
      Hrshared.getPercent(o.CountWithInc,o.EligCount) PercCountWithInc
  FROM (
   SELECT r.rating,
      COUNT(1) EmpCount,
      SUM(r.IS_ELIG) EligCount    
      ,sum(decode(r.IS_ELIG,0,0,DECODE(r.MERIT_INC + r.ADJ_INC + r.PA_INC,0,0,1))) CountWithInc 
      ,MAX(Hrshared.getPercent(r.MERIT_INC + r.ADJ_INC + r.PA_INC,r.FT_SAL)) MaxIncPerc,
      MIN(Hrshared.getPercent(r.MERIT_INC + r.ADJ_INC + r.PA_INC,r.FT_SAL)) MinIncPerc,
      AVG(Hrshared.getPercent(r.MERIT_INC + r.ADJ_INC + r.PA_INC,r.FT_SAL)) AvgIncPerc
   FROM TMP_INCROLLUP r
   GROUP BY r.rating_id,r.rating
   ORDER BY r.rating_id
  )o;
    
  open p_ICP for 
    SELECT o.*,
        SUM(o.EmpCount) OVER () EmpCountTotal,
        SUM(o.CountRecAward) OVER () CountRecAwardTotal
        ,o.EmpCount - o.EligCount AS NotEligCount
        ,sum(o.EmpCount) over() - sum(o.EligCount) over() AS NotEligCountTotal
        ,Hrshared.getPercent(SUM(o.CountRecAward) OVER(),SUM(o.EmpCount) OVER () ) PercWithIncTotal
        ,Hrshared.getPercent(SUM(o.CountRecAward) OVER (),SUM(EligCount) OVER ()) PercCountRecAwardTotal
        ,MAX(o.MaxIndMod) OVER () MaxIndModTotal,
        MIN(o.MinIndMod) OVER () MinIndModTotal,
        AVG(o.AvgIndMod) OVER () AvgIndModTotal,
        Hrshared.getPercent(o.EmpCount, SUM(o.EmpCount) OVER () ) PercWithRating,
        Hrshared.getPercent(SUM(o.EmpCount) OVER (), SUM(o.EmpCount) OVER () ) PercWithRatingTotal,
        Hrshared.getPercent(o.CountRecAward, o.EligCount) PercCountRecAward
        ,SUM(EligCount) OVER () EligCountTotal
    FROM (
     SELECT r.rating,
            COUNT(1) EmpCount,
            SUM(r.ICP_ELIG) EligCount,
            sum(decode(r.ICP_ELIG,0,0,decode(nvl(r.ICP_AWARD,0),0,0,1))) CountRecAward,       
            MAX(r.NEWICP_INDMOD) MaxIndMod,
            MIN(r.NEWICP_INDMOD) MinIndMod,
            AVG(r.NEWICP_INDMOD) AvgIndMod
            
     FROM TMP_INCROLLUP r
     GROUP BY r.rating_id,r.rating
     ORDER BY r.rating_id
    )o;


end ratingAnalysisSalICP;

PROCEDURE IncreaseAvgByCal ( 
   p_data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is
  
begin

  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  ng_compRollup.putSalICPIncreaseRollup(
      p_ManagerID,
      p_CycleID); 
      
open p_data for 
SELECT

   o.org_seq, o.orgName,
   Hrshared.getPercent(o.SumMeritExceeds , o.EligSumEX) AvgPercentExceeds,
   Hrshared.getPercent(o.SumMeritSU , o.EligSumSU) AvgPercentSU,
   Hrshared.getPercent(o.SumMeritNI , o.EligSumNI) AvgPercentNI,
   Hrshared.getPercent(o.SumMeritNR , o.EligSumNR) AvgPercentNR,

   Hrshared.getPercent(o.IncExceeds , o.EligSumEX) AvgIncExceeds,
   Hrshared.getPercent(o.IncSU , o.EligSumSU) AvgIncSU,
   Hrshared.getPercent(o.IncNI , o.EligSumNI) AvgIncNI,
   Hrshared.getPercent(o.IncNR , o.EligSumNR) AvgIncNR,

   Hrshared.getPercent(SUM(o.SumMeritExceeds) OVER() , SUM(o.EligSumEX) OVER()) AvgPercentExceedsTotal,
   Hrshared.getPercent(SUM(o.SumMeritSU) OVER() , SUM(o.EligSumSU) OVER()) AvgPercentSUTotal,

   Hrshared.getPercent(SUM(o.SumMeritNI) OVER() , SUM(o.EligSumNI) OVER()) AvgPercentNITotal,
   Hrshared.getPercent(SUM(o.SumMeritNR) OVER() , SUM(o.EligSumNR) OVER()) AvgPercentNRTotal,

   Hrshared.getPercent(SUM(o.IncExceeds) OVER() , SUM(o.EligSumEX) OVER()) AvgIncExceedsTotal,
   Hrshared.getPercent(SUM(o.IncSU) OVER() , SUM(o.EligSumSU) OVER()) AvgIncSUTotal,
   Hrshared.getPercent(SUM(o.IncNI) OVER() , SUM(o.EligSumNI) OVER() )AvgIncNITotal,
   Hrshared.getPercent(SUM(o.IncNR) OVER() , SUM(o.EligSumNR) OVER()) AvgIncNRTotal


FROM(
 SELECT r.ORG_SEQ,r.ORGNAME,

     SUM(DECODE(r.RATING,'High',DECODE(r.IS_ELIG,1,1,0),0)) EligSumEX,
     SUM(DECODE(r.RATING,'Solid',DECODE(r.IS_ELIG,1,1,0),0)) EligSumSU,
     SUM(DECODE(r.RATING,'Low',DECODE(r.IS_ELIG,1,1,0),0)) EligSumNI,
     SUM(DECODE(r.RATING,'Not Calibrated',DECODE(r.IS_ELIG,1,1,0),0)) EligSumNR,

     SUM(DECODE(r.RATING,'High',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, r.MERIT_INC / r.FT_SAL) ,0),0)) SumMeritExceeds,
     SUM(DECODE(r.RATING,'Solid',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, r.MERIT_INC / r.FT_SAL) ,0),0)) SumMeritSU,
     SUM(DECODE(r.RATING,'Low',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, r.MERIT_INC / r.FT_SAL) ,0),0)) SumMeritNI,
     SUM(DECODE(r.RATING,'Not Calibrated',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, r.MERIT_INC / r.FT_SAL) ,0),0)) SumMeritNR,

     SUM(DECODE(r.RATING,'High',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0) / r.FT_SAL) ,0))) IncExceeds,
     SUM(DECODE(r.RATING,'Low',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0) / r.FT_SAL) ,0))) IncNI,
     SUM(DECODE(r.RATING,'Solid',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0) / r.FT_SAL) ,0))) IncSU,
     SUM(DECODE(r.RATING,'Not Calibrated',DECODE(r.IS_ELIG,1, DECODE(r.FT_SAL,0,0, NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0) / r.FT_SAL) ,0))) IncNR

 FROM TMP_INCROLLUP r
  GROUP BY r.ORG_SEQ,r.ORGNAME
  ORDER BY r.ORG_SEQ
)o;

end IncreaseAvgByCal;


PROCEDURE salicpPosInRange(
   p_data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is

begin
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);

  
  open p_data for 
 select
  y.rating
  ,round(avg(y.ptr),2) AveragePTR
  ,round(avg(y.ptrnew),2) AveragePTRNew
from (
        
  select o.rating, o.ptr
        ,case when nvl(FTEHighMinusLow,0) <> 0 then
          round((NVL(o.ftsalarynew,0) - o.LowFTE) / o.FTEHighMinusLow * 100,2)
        else null end as PTRNew
  from (
    select 
       d.eid
      ,nvl(d.compEmp.contributionCalibration,'Not Calibrated') Rating
      ,round(d.recSalary.PercThruRangeCurr * 100,2)  PTR
      ,decode(nvl(d.compInput.LumpSumAmt,0),0,
        NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0)
        ,NVL(d.compEmp.FTSalary,0)
      ) ftsalarynew
      
      ,decode(d.compInput.NewJobCode,null
        ,d.recSalary.JobMarketData.highFTE - d.recSalary.JobMarketData.LowFTE
        ,d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE) FTEHighMinusLow
      ,decode(d.compInput.NewJobCode,null
        ,d.recSalary.JobMarketData.highFTE
        ,d.compInput.NewJobInfo.highFTE) highFTE
      ,decode(d.compInput.NewJobCode,null
        ,d.recSalary.JobMarketData.LowFTE
        ,d.compInput.NewJobInfo.LowFTE) LowFTE  
      
     FROM hr_compOrg d 
        START WITH d.managerid = p_ManagerID 
        CONNECT BY PRIOR d.eid = d.managerid
          AND PRIOR d.cycleid = p_CycleID
  )o 
)y
 group by y.rating
  ORDER BY Hrshared.getRatingID(y.Rating);
  
end salicpPosInRange;


PROCEDURE EmpMarketRangePositioning(
     p_cursor IN OUT Globals.genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2)IS

BEGIN
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  ng_compRollup.putSalICPIncreaseRollup(
      p_ManagerID,
      p_CycleID); 

OPEN p_cursor FOR
SELECT b.rating,
     MAX(b.totalEmp) totalEmp,
     MAX(rSum) empCount,
     ROUND(Hrshared.getPercent(SUM(b.u80),MAX(b.totalEmp)),2) rU80,
     ROUND(Hrshared.getPercent(SUM(b.r80_89),MAX(b.totalEmp)),2) r8089,
     ROUND(Hrshared.getPercent(SUM(b.r90_95),MAX(b.totalEmp)),2) r9095,
     ROUND(Hrshared.getPercent(SUM(b.r96_105),MAX(b.totalEmp)),2) r96105,
     ROUND(Hrshared.getPercent(SUM(b.r106_120),MAX(b.totalEmp)),2) r106120,
     ROUND(Hrshared.getPercent(SUM(b.gt120),MAX(b.totalEmp)),2) rgt120,

     ROUND(Hrshared.getPercent(SUM(b.u80) + SUM(b.r80_89),MAX(b.totalEmp)),2) LessComp,
     ROUND(Hrshared.getPercent(SUM(b.r90_95) + SUM(b.r96_105),MAX(b.totalEmp)),2) Comp,
     ROUND(Hrshared.getPercent(SUM(b.r106_120) + SUM(b.gt120),MAX(b.totalEmp)),2) HighlyComp,

     ROUND(Hrshared.getPercent(SUM(SUM(b.u80)) OVER() + SUM(SUM(b.r80_89)) OVER(),MAX(b.totalEmp)),2) LessCompTotal,
     ROUND(Hrshared.getPercent(SUM(SUM(b.r90_95)) OVER() + SUM(SUM(b.r96_105)) OVER(),MAX(b.totalEmp)),2) CompTotal,
     ROUND(Hrshared.getPercent(SUM(SUM(b.r106_120)) OVER() + SUM(SUM(b.gt120)) OVER(),MAX(b.totalEmp)),2) HighlyCompTotal,

     ROUND(Hrshared.getPercent(SUM(SUM(b.u80)) OVER(),MAX(b.totalEmp)),2) rU80Total,
     ROUND(Hrshared.getPercent(SUM(SUM(b.r80_89)) OVER(),MAX(b.totalEmp)),2) r8089Total,
     ROUND(Hrshared.getPercent(SUM(SUM(b.r90_95)) OVER(),MAX(b.totalEmp)),2) r9095Total,
     ROUND(Hrshared.getPercent(SUM(SUM(b.r96_105)) OVER(),MAX(b.totalEmp)),2) r96105Total,
     ROUND(Hrshared.getPercent(SUM(SUM(b.r106_120)) OVER(),MAX(b.totalEmp)),2) r106120Total,
     ROUND(Hrshared.getPercent(SUM(SUM(b.gt120)) OVER(),MAX(b.totalEmp)),2) rgt120Total
 FROM(
  SELECT
    a.rating,
    COUNT(1) OVER(PARTITION BY a.rating) rSum,
    COUNT(1) OVER() totalEmp,
    CASE WHEN a.cr < .80 THEN 1 ELSE 0 END AS u80,
    CASE WHEN a.cr >= .80 AND a.cr < .90 THEN 1 ELSE 0 END AS r80_89,
    --CASE WHEN a.cr BETWEEN .80 AND .89 THEN 1 ELSE 0 END AS r80_89,
    CASE WHEN a.cr >= .90 AND a.cr < .96 THEN 1 ELSE 0 END AS r90_95,
    -- CASE WHEN a.cr BETWEEN .90 AND .95 THEN 1 ELSE 0 END AS r90_95,
    CASE WHEN a.cr >= .96 AND a.cr < 1.06 THEN 1 ELSE 0 END AS r96_105,
    -- CASE WHEN a.cr BETWEEN .96 AND 1.05 THEN 1 ELSE 0 END AS r96_105,
    CASE WHEN a.cr >= 1.06 AND a.cr <= 1.20 THEN 1 ELSE 0 END AS r106_120,
    --CASE WHEN a.cr BETWEEN 1.06 AND 1.2 THEN 1 ELSE 0 END AS r106_120,
    CASE WHEN a.cr > 1.20 THEN 1 ELSE 0 END AS gt120
  FROM(
   SELECT r.rating,
   DECODE(r.MID_FTE,0,0, r.NEW_FT_SAL / r.MID_FTE) CR
   FROM TMP_INCROLLUP r
   WHERE r.IS_ELIG = 1
   AND NVL(r.MID_FTE,0) != 0
  )a
 )b
 GROUP BY b.rating
 ORDER BY DECODE(b.rating,'High',1,'Solid',2,'Low',3,4);

END EmpMarketRangePositioning;


PROCEDURE getRatingChart(
     p_cursor IN OUT genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2) is
    
begin
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  open p_cursor for 
    select
    o.rating
    ,SUM(COUNT(o.eid)) OVER() EmpCountTotal
    ,Hrshared.getPercent(COUNT(o.eid), SUM(COUNT(o.eid)) OVER()) RatingPercent
  from(
    select 
     d.eid
    ,nvl(d.compEmp.contributionCalibration,'Not Calibrated') Rating
    
   FROM hr_compOrg d 
      START WITH d.managerid = p_ManagerID 
      CONNECT BY PRIOR d.eid = d.managerid
        AND PRIOR d.cycleid = p_CycleID
  )o
  group by o.Rating
  ORDER BY Hrshared.getRatingID(o.Rating);
  
end getRatingChart;

PROCEDURE getICPIndModByCal(
     p_cursor IN OUT genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2) is
    
begin
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  ng_compRollup.putSalICPIncreaseRollup(
      p_ManagerID,
      p_CycleID);   
  
  
  open p_cursor for 
   SELECT o.*,
    o.EmpCount - o.EligCount AS NotEligCount,
    
    Hrshared.getPercent(o.CountRecAward, o.EligCount) PercCountRecAward,
    
    Hrshared.getPercent(SUM(o.CountRecAward) OVER (), SUM(EligCount) OVER ()) PercCountRecAwardTotal,
    MAX(o.MaxIndMod) OVER () MaxIndModTotal,
    MIN(o.MinIndMod) OVER () MinIndModTotal
  
    ,Hrshared.getPercent(o.IndivModSum, o.CountRecAward) / 100 AvgIndMod
    ,Hrshared.getPercent(sum(o.IndivModSum) over(), sum(o.CountRecAward) over()) / 100 AvgIndModTotal
  
    ,Hrshared.getPercent(o.EmpCount, SUM(o.EmpCount) OVER () ) PercWithRating
    ,Hrshared.getPercent(SUM(o.EmpCount) OVER (), SUM(o.EmpCount) OVER () ) PercWithRatingTotal,
    SUM(o.EmpCount) OVER () EmpCountTotal,
    SUM(o.CountRecAward) OVER () CountRecAwardTotal,
    SUM(EligCount) OVER () EligCountTotal
   FROM (
         SELECT r.rating,
                COUNT(1) EmpCount
                ,SUM(r.ICP_ELIG) EligCount
                ,sum(decode(r.ICP_ELIG,0,0,decode(nvl(r.ICP_AWARD,0),0,0,1))) CountRecAward        
                ,MAX(r.NEWICP_INDMOD) MaxIndMod
                ,MIN(r.NEWICP_INDMOD) MinIndMod
                ,SUM(DECODE(r.ICP_ELIG,0,0,r.NEWICP_INDMOD)) IndivModSum
              
         FROM TMP_INCROLLUP r
         GROUP BY r.rating_id,r.rating
         ORDER BY r.rating_id
   )o ;
  
end getICPIndModByCal;
/* ///////////////////////////////////////////////// */
PROCEDURE getLTIIndModByCal(
     p_LTIAvgByCal IN OUT genRefCursor
    ,p_LTIAvgAsPct in out genRefCursor 
    ,p_LTIAvgByCal912 IN OUT genRefCursor
    ,p_LTIAvgAsPct912 in out genRefCursor
    ,p_ManagerID NUMBER
    ,p_CycleID NUMBER
    ,p_ManagerName OUT nocopy VARCHAR2) is
    

begin


  p_ManagerName := ng_shared.getEmpName(p_ManagerID);

  
  open p_LTIAvgByCal for 
    select
         o.ratingID
        ,o.rating 
        ,COUNT(1) EmpCount
        --,sum(COUNT(1)) over() EmpCountTotal
        ,sum(o.elig) EligCount 
        --,sum(sum(o.elig)) over () EligCountTotal
        
        ,COUNT(1) - sum(o.elig)  NotEligCount
       -- ,(sum(COUNT(1)) over() - sum(sum(o.elig)) over ()) NotEligCountTotal
        
        ,sum(o.RecAwardCount) RecAwardCount
       -- ,sum(sum(o.RecAwardCount)) over () RecAwardCountTotal
        
        ,round(Hrshared.getPercent(COUNT(1), SUM(COUNT(1)) OVER () ),2) PercWithRating
        --,round(Hrshared.getPercent(SUM(COUNT(1)) OVER (), SUM(COUNT(1)) OVER () ),2) PercWithRatingTotal
        
        ,round(Hrshared.getPercent( sum(o.RecAwardCount) , sum(o.elig) ),2) RecAwardPerc 
        --,round(Hrshared.getPercent( sum(sum(o.RecAwardCount)) over () , sum(sum(o.elig)) over () ),2) RecAwardPercTotal
        ,round(Hrshared.getPercent( sum(o.ltimodifier) , sum(o.elig) ) / 100 ,2) AvgLTIMod
        --,round(Hrshared.getPercent( sum(sum(o.ltimodifier)) over() , sum(sum(o.elig)) over() ) / 100 ,2) AvgLTIModtotal
        ,round(Hrshared.getPercent( sum(o.unvamtaspercbase) , sum(o.elig) ) / 100 ,2) Avgunvamtaspercbase
    from (
            SELECT 
                 d.eid
                ,Hrshared.getRatingID(NVL(d.compEmp.potentialCalibration,'Not Calibrated')) ratingID
                ,nvl(d.compEmp.potentialCalibration,'Not Calibrated') Rating     
                ,d.compEmp.eligibility.isLTIEligible elig
                ,case  when d.compEmp.eligibility.isLTIEligible = 1 and NVL(d.compInput.LTIGrantAmt, 0) > 0 then 1 else 0 end as RecAwardCount
                ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,
                  d.compInput.LTIGrantAmt
                ) LTIGrantAmt 
                ,d.compInput.LTGrantModifier as ltimodifier
                ,decode(nvl(d.compEmp.FTSalary,0),0,null,(nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0)) / (decode(nvl(d.compInput.LumpSumAmt,0),0, NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0),NVL(d.compEmp.FTSalary,0)) * d.compEmp.CurrencyUSD) * 100) unvamtaspercbase
                
                ,d.compEmp.compLevelID compLevelID
                FROM hr_compOrg d  WHERE   d.cycleid = p_CycleID                
                    START WITH d.managerid = p_ManagerID
                    CONNECT BY PRIOR d.eid = d.managerid
                     AND PRIOR d.cycleid = p_CycleID                   
  ) o
  group by o.ratingID, o.rating
  order by o.ratingID;
                  
  open p_LTIAvgAsPct for 
    select
         o.compLevelID
        ,o.CompLevelDesc 
        ,COUNT(1) EmpCount
        ,sum(COUNT(1)) over() EmpCountTotal
        ,sum(o.elig) EligCount 
       -- ,sum(sum(o.elig)) over () EligCountTotal
        
        ,COUNT(1) - sum(o.elig)  NotEligCount
        --,(sum(COUNT(1)) over() - sum(sum(o.elig)) over ()) NotEligCountTotal
        
        ,sum(o.RecAwardCount) RecAwardCount
       -- ,sum(sum(o.RecAwardCount)) over () RecAwardCountTotal
        
        ,round(Hrshared.getPercent(COUNT(1), SUM(COUNT(1)) OVER () ),2) PercWithRating
       -- ,round(Hrshared.getPercent(SUM(COUNT(1)) OVER (), SUM(COUNT(1)) OVER () ),2) PercWithRatingTotal
      
        ,round(Hrshared.getPercent( sum(o.RecAwardCount) , sum(o.elig) ),2) RecAwardPerc 
        --,round(Hrshared.getPercent( sum(sum(o.RecAwardCount)) over () , sum(sum(o.elig)) over () ),2) RecAwardPercTotal
        ,round(Hrshared.getPercent( sum(o.ltimodifier) , sum(o.elig) ) / 100 ,2) AvgLTIMod
       -- ,round(Hrshared.getPercent( sum(sum(o.ltimodifier)) over() , sum(sum(o.elig)) over() ) / 100 ,2) AvgLTIModtotal
        ,round(Hrshared.getPercent( sum(o.unvamtaspercbase) , sum(o.elig) ) / 100 ,2) Avgunvamtaspercbase
        
    from (
            SELECT 
                 d.eid
                ,Hrshared.getRatingID(NVL(d.compEmp.potentialCalibration,'Not Calibrated')) ratingID
                ,nvl(d.compEmp.potentialCalibration,'Not Calibrated') Rating     
                ,d.compEmp.eligibility.isLTIEligible elig
                ,case  when d.compEmp.eligibility.isLTIEligible = 1 and NVL(d.compInput.LTIGrantAmt, 0) > 0 then 1 else 0 end as RecAwardCount
                ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,
                  d.compInput.LTIGrantAmt
                ) LTIGrantAmt 
                ,d.compInput.LTGrantModifier as ltimodifier
                ,decode(nvl(d.compEmp.FTSalary,0),0,null,(nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0)) / (decode(nvl(d.compInput.LumpSumAmt,0),0, NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0),NVL(d.compEmp.FTSalary,0)) * d.compEmp.CurrencyUSD) * 100) unvamtaspercbase
                
                ,d.compEmp.compLevelID compLevelID
                ,case
                  when d.compEmp.compLevelID = 1 then 'Band 1-6'
                  when d.compEmp.compLevelID = 2 then 'Band 7-8'
                  else 'Band ' || to_char(d.compEmp.compLevelID + 6) 
                end as CompLevelDesc
                
                FROM hr_compOrg d  
                  WHERE   d.cycleid = p_CycleID 
                  and d.compEmp.compLevelID < 6
                    START WITH d.managerid = p_ManagerID
                    CONNECT BY PRIOR d.eid = d.managerid
                     AND PRIOR d.cycleid = p_CycleID                   
  ) o
  group by o.compLevelID, o.CompLevelDesc
  order by o.compLevelID;
                  

  open p_LTIAvgByCal912 for 
    select
         o.ratingID
        ,o.rating 
        ,COUNT(1) EmpCount
        ,sum(o.elig) EligCount 
        ,COUNT(1) - sum(o.elig)  NotEligCount
        ,sum(o.RecAwardCount) RecAwardCount
        ,round(Hrshared.getPercent(COUNT(1), SUM(COUNT(1)) OVER () ),2) PercWithRating
        ,round(Hrshared.getPercent( sum(o.RecAwardCount) , sum(o.elig) ),2) RecAwardPerc 
        ,round(Hrshared.getPercent( sum(o.ltimodifier) , sum(o.elig) ) / 100 ,2) AvgLTIMod
        ,round(Hrshared.getPercent( sum(o.unvamtaspercbase) , sum(o.elig) ) / 100 ,2) Avgunvamtaspercbase
    from (
            SELECT 
                 d.eid
                ,Hrshared.getRatingID(NVL(d.compEmp.potentialCalibration,'Not Calibrated')) ratingID
                ,nvl(d.compEmp.potentialCalibration,'Not Calibrated') Rating     
                ,d.compEmp.eligibility.isLTIEligible elig
                ,case  when d.compEmp.eligibility.isLTIEligible = 1 and NVL(d.compInput.LTIGrantAmt, 0) > 0 then 1 else 0 end as RecAwardCount
                ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,
                  d.compInput.LTIGrantAmt
                ) LTIGrantAmt 
                ,d.compInput.LTGrantModifier as ltimodifier
                ,decode(nvl(d.compEmp.FTSalary,0),0,null,(nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0)) / (decode(nvl(d.compInput.LumpSumAmt,0),0, NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0),NVL(d.compEmp.FTSalary,0)) * d.compEmp.CurrencyUSD) * 100) unvamtaspercbase
                
                ,d.compEmp.compLevelID compLevelID
                FROM hr_compOrg d  WHERE   d.cycleid = p_CycleID 
                  and d.compEmp.compLevelID between 3 and 6
                    START WITH d.managerid = p_ManagerID
                    CONNECT BY PRIOR d.eid = d.managerid
                     AND PRIOR d.cycleid = p_CycleID                   
  ) o
  group by o.ratingID, o.rating
  order by o.ratingID;

open p_LTIAvgAsPct912 for 
    select
         o.compLevelID
        ,o.CompLevelDesc 
        ,COUNT(1) EmpCount
        ,sum(COUNT(1)) over() EmpCountTotal
        ,sum(o.elig) EligCount 
        ,COUNT(1) - sum(o.elig)  NotEligCount
        ,sum(o.RecAwardCount) RecAwardCount
        ,round(Hrshared.getPercent(COUNT(1), SUM(COUNT(1)) OVER () ),2) PercWithRating
        ,round(Hrshared.getPercent( sum(o.RecAwardCount) , sum(o.elig) ),2) RecAwardPerc 
        ,round(Hrshared.getPercent( sum(o.ltimodifier) , sum(o.elig) ) / 100 ,2) AvgLTIMod
        ,round(Hrshared.getPercent( sum(o.unvamtaspercbase) , sum(o.elig) ) / 100 ,2) Avgunvamtaspercbase
        
    from (
            SELECT 
                 d.eid
                ,Hrshared.getRatingID(NVL(d.compEmp.potentialCalibration,'Not Calibrated')) ratingID
                ,nvl(d.compEmp.potentialCalibration,'Not Calibrated') Rating     
                ,d.compEmp.eligibility.isLTIEligible elig
                ,case  when d.compEmp.eligibility.isLTIEligible = 1 and NVL(d.compInput.LTIGrantAmt, 0) > 0 then 1 else 0 end as RecAwardCount
                ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,
                  d.compInput.LTIGrantAmt
                ) LTIGrantAmt 
                ,d.compInput.LTGrantModifier as ltimodifier
                ,decode(nvl(d.compEmp.FTSalary,0),0,null,(nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0)) / (decode(nvl(d.compInput.LumpSumAmt,0),0, NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0),NVL(d.compEmp.FTSalary,0)) * d.compEmp.CurrencyUSD) * 100) unvamtaspercbase
                
                ,d.compEmp.compLevelID compLevelID
                ,case
                  when d.compEmp.compLevelID = 1 then 'Band 1-6'
                  when d.compEmp.compLevelID = 2 then 'Band 7-8'
                  else 'Band ' || to_char(d.compEmp.compLevelID + 6) 
                end as CompLevelDesc
                
                FROM hr_compOrg d  
                  WHERE   d.cycleid = p_CycleID 
                  and d.compEmp.compLevelID between 3 and 6
                    START WITH d.managerid = p_ManagerID
                    CONNECT BY PRIOR d.eid = d.managerid
                     AND PRIOR d.cycleid = p_CycleID                   
  ) o
  group by o.compLevelID, o.CompLevelDesc
  order by o.compLevelID;
  
end getLTIIndModByCal;
/* ///////////////////////////////////////////////// */
procedure getCompLetters (
         p_Letters in OUT genRefCursor
        ,p_EmployeeIDList VARCHAR2 default null
        ,p_CycleID number
        ,p_Countries VARCHAR2 DEFAULT NULL) is

begin

  delete from tmp_emp_org;
  
  if p_EmployeeIDList is not null then 
    insert into tmp_emp_org(eid)
    select d.eid from hr_compOrg d 
    where d.eid in (
       SELECT COLUMN_VALUE AS EID
          from table (cast (utils.getvarchartable(p_EmployeeIDList) as varchartable)));
  else
    insert into tmp_emp_org(eid)
    select d.eid from hr_compOrg d 
      where d.compEmp.EmploymentCountry in (SELECT column_value FROM TABLE (CAST (Utils.getvarchartable (p_Countries) AS VarcharTable) ))
      and d.cycleid = p_CycleID;
        
  end if;



open p_Letters for
SELECT
   e.EMP_ID EmployeeID
  ,d.managerid ManagerID
  ,decode(m.KNOWN_AS,null,m.FIRST_NAME,m.KNOWN_AS) || ' ' || m.last_name as ManagerName
  ,mj.job_title ManagerJobTitle
  ,e.DISPLAY_NAME EmployeeName
  ,decode(e.KNOWN_AS,null,e.FIRST_NAME,e.KNOWN_AS) EmployeeletterIntroName
  ,e.FIRST_NAME FirstName
  ,e.KNOWN_AS KnownAs
  ,e.MIDDLE_NAME MiddleName
  ,e.LAST_NAME LastName
  ,e.STREET_ADDRESS StreetAddress
  ,e.ADDRESS_LINE2 StreetAddressLine2
  ,e.CITY City
  ,e.STATE State
  ,e.district
  ,e.ZIPCODE ZipCode
  ,e.COUNTRY Country
  ,d.compEmp.compensationGroup compensationGroup
  ,d.compEmp.EmploymentCountry EmploymentCountry
  ,decode(d.compInput.NewJobCode, null ,j.job_title,
      decode(nvl(d.compInput.PromotionEffectiveDate,ng_compReports.geteffdate),
            ng_compReports.geteffdate, d.compInput.NewJobInfo.JobTitle,
            j.job_title)

  ) JobTitle
  ,j.job_level joblevel
  ,case when d.compInput.PromotionEffectiveDate = ng_compReports.geteffdate and d.compInput.NewJobInfo.JobLevel > j.job_level then 1 else 0 end as isPromo
  
  ,decode(d.compInput.PromotionEffectiveDate
    ,ng_compReports.geteffdate,d.compInput.NewJobCode,null) NewJobCode
  ,d.compInput.NewJobCode PromoJobCode
  
  ,d.compInput.PromotionEffectiveDate PromotionEffectiveDate
  ,decode(d.compInput.NewJobCode, null, j.job_grade,
      decode(nvl(d.compInput.PromotionEffectiveDate,ng_compReports.geteffdate),
            ng_compReports.geteffdate, d.compInput.NewJobInfo.CareerBand,
            j.job_grade)

  ) CareerBand
  ,DECODE(j.JOB_EXEMPT, 'Y', 'Exempt', 'EX', 'Exempt' ,'N', 'Non-Exempt', 'NEX','Non-Exempt', NULL) jobexempt
  ,d.compInput.NewJobInfo.JobExempt JobExemptNew
  
  ,(NVL(d.compEmp.FTSalary,0) * NVL(d.compEmp.percentTimeWorked,100) ) AnnualSalary
  
  --,(d.getNewSalary() * NVL(d.compEmp.percentTimeWorked,100) ) AnnualSalaryNew
  ,(decode(nvl(d.compInput.LumpSumAmt,0),0,
      NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) 
      + decode(d.compInput.AdjEffectiveDate
          ,ng_compReports.geteffdate,nvl(d.compInput.AdjustmentAmt,0),0)
      + decode(d.compInput.PromotionEffectiveDate
          ,ng_compReports.geteffdate,nvl(d.compInput.PromotionAmt,0),0)
      ,NVL(d.compEmp.FTSalary,0)
    ) * NVL(d.compEmp.percentTimeWorked,100) )AnnualSalaryNew
    
  ,d.compEmp.SalCurrency SalCurrency
  ,nvl(d.compInput.LumpSumAmt,0) LumpSumAmt
  ,d.compEmp.eligibility.isSalaryEligible salaryeligible
  ,d.compInput.ICPAward icpamount
  ,d.compEmp.eligibility.isICPEligible icpeligible
  ,d.compEmp.ICPTargetPercent * 100 ICPTargetPercent
  
  ,case when d.compInput.NewJobCode is null then (d.compEmp.ICPTargetPercent * 100) when d.compEmp.ICPTargetPercent > d.compInput.NewJobInfo.ICPTargetPercent then d.compEmp.ICPTargetPercent else d.compInput.NewJobInfo.ICPTargetPercent end as ICPTargetPercentNew
  ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPCompanyMod  icpcompanymodifier 
  ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPIndivMod    icpindivmodifier 
  ,d.compEmp.icpsalary icpsalary
  ,d.compEmp.icpsalary * NVL(d.compEmp.ICPTargetPercent,0)  AS icptargetamt
  ,nvl(d.compInput.ICPIndivModifier,0) icpindivmodifiernew   
  ,d.compEmp.compLevelID compLevelID
  ,d.compEmp.DirectReports DirectReports
  ,d.compInput.LTIGrantAmt LTIGrantAmt
  ,d.recLTI.LTIGuidelines.TargetGrant   TargetGrant 
  ,d.compInput.LTGrantModifier as ltimodifier
  ,d.compEmp.eligibility.isLTIEligible LTIEligible
  
from
   hr_compOrg d
  ,hr_employees e
  ,hr_employees m
  ,hr_jobs j, hr_jobs mj
  ,tmp_emp_org o
  
where o.eid = d.eid
  and d.eid = e.emp_id
  and d.managerid = m.emp_id
  and d.compEmp.JobCode = j.job_code(+)
  and d.manager.compEmp.JobCode = mj.job_code(+)
  and d.cycleid = p_CycleID
  and nvl(d.compEmp.eligibility.isSalaryEligible,0) 
    + nvl(d.compEmp.eligibility.isICPEligible,0) + nvl(d.compEmp.eligibility.isLTIEligible,0) <> 0;
  
  
  --and e.emp_id in(SELECT COLUMN_VALUE AS EID from table (cast (utils.getvarchartable(p_EmployeeIDList) as varchartable)));
  
  
end getCompLetters;
/* ///////////////////////////////////////////////// */
procedure putTotalReports(p_ManagerID NUMBER, p_CycleID   NUMBER) is

begin
  delete from tmp_emp_org; -- Need to replace this with a temp table after testing
  -- let's get the total org in a temp table so we don't run the same query
  insert into tmp_emp_org(eid) 
  select d.eid FROM hr_compOrg d 
        WHERE   d.cycleid = p_CycleID
          START WITH d.managerid = p_ManagerID
          CONNECT BY PRIOR d.eid = d.managerid
            AND PRIOR d.cycleid = p_CycleID;
    
end putTotalReports;
/* ///////////////////////////////////////////////// */
function geteffdate return date is
begin
return const_effdate;
end geteffdate;

function getSAPEmpType(p_EmpType varchar2) return VARCHAR2 is

v_ToReturn varchar2(25) := p_emptype;

begin

    IF p_emptype in('Salary','Expatriate','PT Salary <=20 hr wk',
                'PT Salary > 20 hr wk',
                'Salary -Non Exempt 2',
                'Salaried Part-Time') then v_toreturn := 'SALARIED';
    ELSIF p_emptype in('Hourly','Hourly Part-Time','Full-time Hourly', 'PT Salary < 20 hr wk', 'PT Salary >=20 hr wk',
                      'PT hourly <=20 hr wk', 'PT hourly < 20 hr wk', 'PT hourly >=20 hr wk',
                      'PT hourly >20 hr wk') then v_toreturn := 'HOURLY';
    END IF;

  RETURN v_ToReturn;

end getSAPEmpType;


END ng_compReports;
/
