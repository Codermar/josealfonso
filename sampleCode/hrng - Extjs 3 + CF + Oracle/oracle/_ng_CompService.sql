create or replace package ng_CompService as
/*
  Package: ng_CompService
  Author: Jose Alfonso
  Description: Support hrtools
  
*/
TYPE genRefCursor IS REF CURSOR;

  cursor c_HB(p_Managerid number, p_CycleID number) is
      SELECT 
         MAX(DECODE(bg.COMP_TYPE_IDFK,1,NVL(bg.HOLDBACK_QTY,0),0)) MeritHB
        ,MAX(DECODE(bg.COMP_TYPE_IDFK,2,NVL(bg.HOLDBACK_QTY,0),0)) PAHB
        ,MAX(DECODE(bg.COMP_TYPE_IDFK,3,NVL(bg.HOLDBACK_QTY,0),0)) ICPHB
        ,MAX(DECODE(bg.COMP_TYPE_IDFK,10,NVL(bg.HOLDBACK_QTY,0),0)) LTIHB
        
        FROM HR_COMP_BUDGET bg
        WHERE bg.MANAGER_IDFK IN(   
          select t.eid
            from hr_compOrg t
            WHERE t.cycleid = p_CycleID
            and t.compEmp.DirectReports <> 0
            and bg.Manager_idfk <> p_ManagerID
            CONNECT BY t.eid = prior t.managerid
            AND prior t.cycleid = bg.FY_CYCLE_IDFK
            start with t.eid = p_ManagerID
            and t.cycleid = p_CycleID
        );

cursor c_isAdmin(p_userID number) is 
SELECT count(1)
    FROM HR_USER_PERMISSIONS up
    WHERE up.USER_IDFK = p_UserID
    AND up.PERMISSION_IDFK = 2;

CURSOR c_assignments(p_UserID number,p_CycleID number) is  
  SELECT a.ASSIGN_EMP_IDFK AssignedEmpID, d.empName EmployeeName 
    FROM HR_ASSIGNMENTS a, hr_compOrg d 
    WHERE a.ASSIGN_EMP_IDFK = d.eid
    and a.FY_CYCLE_IDFK = d.cycleid
    and a.FY_CYCLE_IDFK = p_cycleID
    AND a.EMP_IDFK = p_UserID 
    AND a.ASSIGNMENT_TYPE_IDFK = 1
  union
  select p_UserID as AssignedEmpID, 'My Org' as EmployeeName from dual;

--    SELECT a.ASSIGN_EMP_IDFK AssignedEmpID 
--    FROM HR_ASSIGNMENTS a 
--    WHERE a.FY_CYCLE_IDFK = p_cycleID
--    AND a.EMP_IDFK = p_UserID 
--    AND a.ASSIGNMENT_TYPE_IDFK = 1
--  union
--  select p_UserID as AssignedEmpID from dual;

PROCEDURE getManagerOrg (
       p_cursorEmp    IN OUT   genRefCursor
      ,p_ManagerID             NUMBER
      ,p_CycleID               NUMBER
      ,p_OrgType               INTEGER
      ,p_SearchCriteria varchar2 default null
      ,p_start    number default 1
      ,p_end    number default 25
      ,p_sort varchar2 default null
      ,p_dir varchar2 default 'ASC'
      ,p_userID    number default 0
   );


PROCEDURE getManagerCompBudget ( 
      p_cursor      IN OUT   genRefCursor,
      p_managerid            NUMBER,
      p_cycleid              NUMBER,
      p_doEquity in int default 1
      ,p_showHoldback in int default 0);

PROCEDURE searchEmployeesByPage (
       p_recordset   IN OUT   genRefCursor
      ,p_ManagerID             NUMBER
      ,p_CycleID               NUMBER
      ,p_SearchCriteria varchar2
      ,p_start    number
      ,p_end    number
      ,p_userID    number default 0
      ,p_ManagersOnly number default 0
   );


FUNCTION getOrgBudget (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_doEquity in int default 1) RETURN sys_refcursor;


-- utils
PROCEDURE runUpdateProcJobByName(p_cycleid NUMBER, p_procName varchar2); 

procedure UpdateBudgetModifiers(p_CycleID number);

procedure markRecordOutdated(p_CycleID number, p_EID number, p_Section varchar2);

procedure updateCompData(p_CycleID number, p_EID number default null);

procedure recalcRecommendations(p_CycleID number, p_EID number);

procedure UpdateMarketDataObjTable(p_CycleID number);

PROCEDURE ngEmpUpdate (   
   p_CycleID   NUMBER
  ,p_OrgType INTEGER
  ,p_ManagerID NUMBER default null
  ,p_EmpIDList VARCHAR2 DEFAULT NULL);
  
PROCEDURE ngEmpUpdateByID (   
   p_CycleID   NUMBER
  ,p_EID NUMBER);
  
procedure saveEligibility(p_CycleID number, p_EID number, p_CompTypeID int, p_EligValue int default 0, p_GenBudget int default null);

  
end ng_CompService;
/



create or replace
package body ng_CompService as


FUNCTION getOrgBudget (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_doEquity in int default 1) RETURN sys_refcursor
AS mycurs sys_refcursor;

      
  r_hb c_hb%rowtype;
  
  cursor c_budget is
  select cycleid
    ,round(sum(o.MeritBudgeted),0) MeritBudgeted
    ,round(sum(o.MeritAllocated),0) MeritAllocated
    ,round(sum(o.PABudgeted),0) PABudgeted
    ,round(sum(o.PAAllocated),0) PAAllocated
    ,round(sum(o.ICPBudgeted),0) ICPBudgeted
    ,round(sum(o.ICPAllocated),0) ICPAllocated
    ,round(sum(o.LTIBudgeted),0) LTIBudgeted
    ,round(sum(o.LTIAllocated),0) LTIAllocated
    
  from (
     
    SELECT t.cycleid
  
      ,decode(t.compEmp.Eligibility.GeneratesSalary,0,0,
          NVL((t.compEmp.FTSalary * treat(deref(t.recSalary.MeritPAMod) as ngt_meritpamod).MeritPercModifier) * t.compEmp.CurrencyUSD / 100,0)
      ) MeritBudgeted
      
      ,decode(t.compEmp.Eligibility.GeneratesSalary,0,0,
        (NVL(t.compInput.MeritAmt, 0) + NVL(t.compInput.LumpSumAmt, 0)) * t.compEmp.CurrencyUSD
      ) MeritAllocated 
      
      ,decode(t.compEmp.Eligibility.GeneratesSalary,0,0,
        NVL((t.compEmp.FTSalary  * treat(deref(t.recSalary.MeritPAMod) as ngt_meritpamod).PAPercModifier) * t.compEmp.CurrencyUSD / 100, 0)
      ) PABudgeted
      
      ,decode(t.compEmp.Eligibility.GeneratesSalary,0,0,
        (NVL(t.compInput.AdjustmentAmt,0) + NVL(t.compInput.PromotionAmt,0)) * t.compEmp.CurrencyUSD
      ) PAAllocated
  
      ,decode(t.compEmp.Eligibility.GeneratesICP,0,0,      
        (treat(deref(t.recICP.icpMod) as ngt_icpMod).ICPCompanyMod * treat(deref(t.recICP.icpMod) as ngt_icpMod).ICPIndivMod) /100 -- icp funding level
        * ((t.compEmp.ICPSalary * t.compEmp.ICPTargetPercent /100) * t.compEmp.CurrencyUSD)
      ) ICPBudgeted

      ,decode(t.compEmp.Eligibility.GeneratesICP,0,0,
        t.compInput.ICPAward *  t.compEmp.CurrencyUSD    
      ) ICPAllocated
      
      ,decode(t.compEmp.Eligibility.GeneratesLTI,0,0,
        t.recLTI.LTIGuidelines.TargetGrant * t.recLTI.LTIGuidelines.ParticRate / 100
      ) LTIBudgeted
      
      ,decode(t.compEmp.Eligibility.GeneratesLTI,0,0,
        t.compInput.LTIGrantAmt
      ) LTIAllocated
      
      FROM hr_compOrg t 
        WHERE   t.cycleid = p_CycleID
          START WITH t.managerid = p_ManagerID
          CONNECT BY PRIOR t.eid = t.managerid
            AND PRIOR t.cycleid = p_CycleID
  ) o group by cycleid;
 
  
  r_budget c_budget%rowtype;
  
  v_MeritAvailableTotal float := 0;
  v_PAAvailableTotal float := 0;
  v_ICPAvailableTotal float := 0;
  v_LTIAvailableTotal float := 0;
  
begin

  -- get holdbacks
  open c_hb(p_Managerid, p_CycleID); fetch c_hb into r_hb; close c_hb;

  open c_budget; fetch c_budget into r_budget; close c_budget;

    -- running totals
    if p_doEquity = 1 then 
      if nvl(r_hb.LTIHB,0) = 0 then v_LTIAvailableTotal  :=  nvl(r_budget.LTIBudgeted,0);
      else
        v_LTIAvailableTotal  :=  nvl(r_budget.LTIBudgeted,0) - (NVL(r_budget.LTIBudgeted,0)  * r_hb.LTIHB / 100 );
      end if;
    end if; 
    
    if nvl(r_hb.MeritHB ,0) = 0 then v_MeritAvailableTotal  :=  NVL(r_budget.MeritBudgeted,0);
    else
      v_MeritAvailableTotal  :=  NVL(r_budget.MeritBudgeted,0) - (NVL(r_budget.MeritBudgeted,0)  * r_hb.MeritHB / 100 );
    end if;
    
    if nvl(r_hb.PAHB,0) = 0 then v_PAAvailableTotal  :=  NVL(r_budget.PABudgeted,0) ;
    else
      v_PAAvailableTotal  :=  NVL(r_budget.PABudgeted,0) - (NVL(r_budget.PABudgeted,0)  * r_hb.PAHB / 100 );
    end if;
    
    if nvl(r_hb.ICPHB ,0) = 0 then v_ICPAvailableTotal  :=  NVL(r_budget.ICPBudgeted,0);
    else
      v_ICPAvailableTotal  :=  NVL(r_budget.ICPBudgeted,0) - (NVL(r_budget.ICPBudgeted,0)  * r_hb.ICPHB / 100 );
    end if;
  
OPEN mycurs FOR
   SELECT 
      'Budgeted' as item,
      NVL(r_budget.MeritBudgeted,0) AS Merit,
      NVL(r_budget.PABudgeted,0) as PA
      ,NVL(r_budget.ICPBudgeted,0) as ICP,
      NVL(r_budget.LTIBudgeted,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Available' as item,
      NVL(v_MeritAvailableTotal,0) AS Merit,
      NVL(v_PAAvailableTotal,0) as PA
      ,NVL(v_ICPAvailableTotal,0) as ICP,
      NVL(v_LTIAvailableTotal,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Allocated' as item,
      NVL(r_budget.MeritAllocated,0) AS Merit,
      NVL(r_budget.PAAllocated,0) as PA
      ,NVL(r_budget.ICPAllocated,0) as ICP,
      NVL(r_budget.LTIAllocated,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Over/Under' as item,
      NVL(v_MeritAvailableTotal,0) - NVL(r_budget.MeritAllocated,0) AS Merit,
      NVL(v_PAAvailableTotal,0) - NVL(r_budget.PAAllocated,0) as PA,
      NVL(v_ICPAvailableTotal,0) - NVL(r_budget.ICPAllocated,0) as ICP,
      NVL(v_LTIAvailableTotal,0) - NVL(r_budget.LTIAllocated,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Holdback' as item,
      NVL(r_hb.MeritHB,0) AS Merit,
      NVL(r_hb.PAHB,0) as PA,
      NVL(r_hb.ICPHB,0) as ICP,
      NVL(r_hb.LTIHB,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Holdback Amount' as item,
      (r_budget.MeritBudgeted  * r_hb.MeritHB / 100 ) AS Merit,
      (r_budget.PABudgeted  * r_hb.PAHB / 100 ) as PA,
      (r_budget.ICPBudgeted  * r_hb.ICPHB / 100 ) as ICP,
      (r_budget.LTIBudgeted  * r_hb.LTIHB / 100 ) AS LTI
  FROM DUAL; 

RETURN mycurs;

end getOrgBudget;

PROCEDURE getManagerCompBudget ( 
      p_cursor      IN OUT   genRefCursor,
      p_managerid            NUMBER,
      p_cycleid              NUMBER,
      p_doEquity in int default 1
      ,p_showHoldback in int default 0) is
      
  v_refcur  SYS_REFCURSOR;
  -- /// using a record type
  type budgetRecType is record(
     item varchar2(50)
    ,Merit float
    ,PA float
    ,ICP float
    ,LTI float
  );
  budgetRec budgetRecType;
  
  -- using an object table
  v_compBudget ngt_compBudget := ngt_compBudget();

begin
  
    v_refcur := ng_compService.getOrgBudget(p_ManagerID,p_CycleID,p_doEquity); 
   
    LOOP
        FETCH v_refcur INTO budgetRec;
        EXIT WHEN v_refcur%NOTFOUND;
        -- dbms_output.put_line(budgetRec.item || ': ' || budgetRec.Merit);
   
    v_compBudget.EXTEND;
        v_compBudget(v_compBudget.LAST) := ngt_managerBudget(
           cached => 1
          ,EID => p_ManagerID
          ,cycleID => p_CycleID
          ,item => budgetRec.item
          ,Merit => budgetRec.Merit
          ,PA => budgetRec.PA
          ,ICP => budgetRec.ICP
          ,LTI => budgetRec.LTI
    );
    end loop; 
  
  if p_showHoldback = 1 then
    open p_cursor for 
      select t.item
            ,t.merit
            ,t.pa
            ,t.merit + t.pa Salary
            ,t.icp
            ,t.lti
      FROM   TABLE(CAST(v_compBudget AS ngt_compBudget)) t;
  else 
    open p_cursor for select 
             t.item
            ,t.merit
            ,t.pa
            ,t.merit + t.pa Salary
            ,t.icp
            ,t.lti
    FROM   TABLE(CAST(v_compBudget AS ngt_compBudget)) t where t.item not like 'Holdback%';
  end if;
 
end getManagerCompBudget;


PROCEDURE getManagerOrg (
       p_cursorEmp    IN OUT   genRefCursor
      ,p_ManagerID             NUMBER
      ,p_CycleID               NUMBER
      ,p_OrgType               INTEGER
      ,p_SearchCriteria varchar2 default null
      ,p_start    number default 1
      ,p_end    number default 25
      ,p_sort varchar2 default null
      ,p_dir varchar2 default 'ASC'
      ,p_userID    number default 0
   ) is
   
  orgCursor  SYS_REFCURSOR;
  EmpRecord ng_org.EmpCompOrgRecord;
  
  v_sql varchar2(2000);  
  v_orgSql varchar2(14000) := 'SELECT  o.eid EmployeeID,' || p_OrgType || ' AS orgtype, COUNT(1) OVER () TotalCount'
        || ' ,decode(' || p_OrgType || ',2,''true'', decode(d.compEmp.DirectReports,0,''true'',''false'') ) hideorg'     
        || ' ,d.empname EmployeeName ,d.managerid ,d.manager.empname managername ,d.cycleid'
        || ' ,d.compEmp.DirectReports DirectReports,d.compEmp.TotalReports TotalReports'
        || ' ,0 as isModified /* placeholder for grid */'
        || ' ,d.compEmp.eligibility.isSalaryEligible SalaryEligible'
        || ' ,nvl(d.compEmp.FTSalary,0) FTSalary'
        || ' ,(NVL(d.compEmp.FTSalary,0) * NVL(d.compEmp.percentTimeWorked,100) ) AnnualSalary'
        || ' ,(d.getNewSalary() * NVL(d.compEmp.percentTimeWorked,100) ) AnnualSalaryNew'
        || ' ,(d.compEmp.percentTimeWorked * 100) percenttimeworked'
        || ' ,d.compEmp.EmploymentGroup EmploymentGroup'
        || ' ,d.compEmp.EmploymentPayType EmploymentPayType'
        || ' ,d.compEmp.CurrencyUSD CurrencyUSD'
        || ' ,d.compEmp.SalCurrency SalCurrency'
        || ' ,decode(d.compEmp.eligibility.isSalaryEligible,0,nvl(d.compEmp.FTSalary,0) ,d.getNewSalary() ) newftsalary'
        || ' ,d.compInput.MeritAmt meritamt'
        || ' ,d.compInput.MeritPerc meritperc'
        || ' ,d.compInput.MeritOutsideRangeJust MeritOutsideRangeJust'
        || ' ,d.compInput.AdjustmentAmt adjustmentamt'
        || ' ,d.compInput.AdjustmentPerc adjustmentperc'
        || ' ,to_char(d.compInput.AdjEffectiveDate,''MON-YYYY'') adjusteffectivedate'
        || ' ,d.compInput.AdjustmentReason AdjustmentReason'
        || ' ,d.compInput.AdjustmentOutsideRangeJust AdjustmentOutsideRangeJust' 
        || ' ,d.compInput.PromotionAmt promotionamt'
        || ' ,d.compInput.PromotionPerc promotionpercent'
        || ' ,to_char(d.compInput.PromotionEffectiveDate,''MON-YYYY'') PromotionEffectiveDate'
        || ' ,d.compInput.PromotionOutsideRangeJust PromotionOutsideRangeJust'      
        || ' ,d.recSalary.LumpSum lumpsumrecommendedinc'
        || ' ,d.recSalary.LumpSumPec lumpsumrecommendedperc'
        || ' ,d.compInput.LumpSumAmt lumpsumamt'
        || ' ,d.compInput.LumpSumPerc lumpsumperc'
        || ' ,d.compInput.LumpSumOutsideRangeJust as LumpSumOutsideRangeJust'          
        || ' ,NVL(d.compInput.MeritPerc,0) + NVL(d.compInput.LumpSumPerc,0) + NVL(d.compInput.AdjustmentPerc,0) + NVL(d.compInput.PromotionPerc,0) as totalpercinc /* total for worksheet */'
        || ' ,NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.LumpSumAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0) as totalamtinc'  
        || ' ,d.compEmp.caid caid ,d.compEmp.JobCode JobCode'
        || ' ,j.job_title jobTitle ,j.job_level joblevel'
        || ' ,j.job_grade careerBand ,j.job_family jobfamily'
        || ' ,j.job_func_area jobfunctarea ,j.job_level CompLevelID'
        || ' ,DECODE(j.JOB_EXEMPT, ''Y'', ''Exempt'', ''EX'', ''Exempt'' ,''N'', ''Non-Exempt'', ''NEX'',''Non-Exempt'', NULL) jobexempt'  
        || ' ,d.compInput.newjobjustification newjobjustification'
        || ' ,d.compInput.NewJobCode newjobcode '     
        || ' ,d.compInput.NewJobInfo.JobTitle NewJobTitle'
        || ' ,d.compInput.NewJobInfo.CareerBand NewCareerBand'
        || ' ,d.compInput.NewJobInfo.JobExempt JobExemptNew'
        || ' ,d.compInput.NewJobInfo.lowFTE lowftenew '
        || ' ,d.compInput.NewJobInfo.highFTE highftenew  '  
        || ' ,case when d.compInput.NewJobCode is null then (d.compEmp.ICPTargetPercent * 100) when d.compEmp.ICPTargetPercent > d.compInput.NewJobInfo.ICPTargetPercent then d.compEmp.ICPTargetPercent else d.compInput.NewJobInfo.ICPTargetPercent end as icptargetpercnew'  
        || ' ,d.compEmp.employmentlocation employmentlocation'
        || ' ,d.compEmp.employmentCountry EmploymentCountry'
        || ' ,d.compEmp.mrhiredate mrhiredate'
        || ' ,decode(d.compEmp.eligibility.isSalaryEligible,0,''true'',''false'') hidesalaryinput'
        || ' ,decode(d.compEmp.eligibility.isICPEligible,0,''true'',''false'') hideicpinput'
        || ' ,decode(d.compEmp.eligibility.isLTIEligible,0,''true'',''false'') hideltiinput'      
        || ' /* Goals and dialogs TODO: */'
        || ' ,''Not defined...'' as goalProgress'
        || ' ,nvl(d.compEmp.contributionCalibrationprev,''Not Calibrated'') as contributionprev '
        || ' ,nvl(d.compEmp.potentialCalibrationprev,''Not Calibrated'') as potentialprev'
        || ' ,EXTRACT( YEAR FROM sysdate) - 1 calibrationyearprev'
        || ' ,nvl(d.compEmp.contributionCalibration,''Not Calibrated'') contribution'
        || ' ,nvl(d.compEmp.potentialCalibration,''Not Calibrated'')   potential'
        || ' ,EXTRACT( YEAR FROM sysdate)      calibrationyear'     
        || ' /* Recommended values */'
        || ' ,d.recSalary.JobMarketData.highFTE  highFTE'
        || ' ,d.recSalary.JobMarketData.LowFTE   LowFTE'
        || ' ,round(d.recSalary.Merit,0)      recmeritinc'
        || ' ,round(d.recSalary.MeritPerc,1)  RecMeritIncPerc'
        || ' ,treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).MeritPercModifier meritpercmodifier'
        || ' ,d.recSalary.matrixModifier matrixmodifier'
        || ' /*  this would also need to change in ng_compReports */'
        || ' ,15 as salaryIncWarningThreshold /* this would come from the hr_fy_cycles table (new field) */'
        || ' ,10 as Icpincwarningthreshold '
        || ' ,6 as ltiIncWarningThreshold'
        || ' ,round(d.recSalary.PercThruRangeCurr * 100,1)  percentthrurangecurr'
        || ' ,round(decode(d.compInput.NewJobCode,null,nvl(d.getNewPTR(),0) * 100'
        || '   ,decode(d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE,null,null,0,null'
        || '     ,(d.getNewSalary() - d.compInput.NewJobInfo.lowFTE) / (d.compInput.NewJobInfo.highFTE - d.compInput.NewJobInfo.lowFTE) * 100) ),1) percentthrurangenew'             
        || ' /* ICP */'
        || ' ,d.compEmp.eligibility.isICPEligible ICPEligible'
        || ' ,round(d.recICP.ICPAmt,0)    as icprecommendedinc'
        || ' ,round(d.recICP.ICPPerc * 100,2)   as icprecommendedincperc'
        || ' ,d.compInput.ICPOutsideRangeJust as icpoutsiderangejust'
        || ' ,d.compEmp.icpsalary icpsalary'
        || ' ,d.compInput.ICPAward icpamount'
        || ' ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPCompanyMod  icpcompanymodifier '
        || ' ,treat(deref(d.recICP.icpmod) as ngt_icpMod).ICPIndivMod    icpindivmodifier '
        || ' ,decode(d.compEmp.ICPSalary,null,null,0,null,'
        || '   d.compInput.ICPAward / d.compEmp.ICPSalary * 100) icppercentofsalary ' 
        || ' ,d.compEmp.ICPTargetPercent * 100 as icptargetperc'
        || ' ,d.compEmp.icpsalary * NVL(d.compEmp.ICPTargetPercent,0)  AS icptargetamt'
        || ' ,d.compInput.ICPIndivModifier icpindivmodifiernew  '    
        || ' /* LTI */'
        || ' ,d.compEmp.payScaleLevel payScaleLevel'
        || ' ,d.compEmp.eligibility.isLTIEligible LTIEligible '
        || ' ,round(nvl(d.recLTI.LTIAmt,0),0)    as ltirecommendedvalue'
        || ' ,round(nvl(d.recLTI.LTIPerc * 100,0),2)   as ltirecommendedperc'
        || ' ,d.compInput.LTIGrantAmt grantamt'
        || ' ,d.recLTI.LTIGuidelines.TargetGrant   TargetGrant '
        || ' ,d.compInput.LTGrantModifier as ltimodifier'
        || ' ,d.compInput.LTIGrantOutSideRangeJust as LTIGrantOutSideRangeJust  '
        || ' ,d.compEmp.UnvestedSharesValue as unvestedsharesvalue'
        || ' ,decode(nvl(d.compEmp.FTSalary,0),0,null,d.compEmp.UnvestedSharesValue / (d.getNewSalary() * d.compEmp.CurrencyUSD) * 100) unvestedamountaspercentofbase'
        || ' ,nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0) as unvestedsharesvaluenew'
        || ' ,decode(nvl(d.compEmp.FTSalary,0),0,null,(nvl(d.compEmp.UnvestedSharesValue,0) + nvl(d.compInput.LTIGrantAmt,0)) / (d.getNewSalary() * d.compEmp.CurrencyUSD) * 100) unvestedamountnewpercent'
        || ' ,nvl(d.compInput.LastModifiedString,''N/A'') lastmodifiedbystring '      
    || ' FROM tmp_emp_org o'
    || '     ,hr_employees e'
    || '     ,hr_compOrg d'
    || '     ,hr_jobs j'
    || ' WHERE o.eid = e.emp_id'
    || ' and o.eid = d.eid'
    || ' and d.compEmp.JobCode = j.job_code(+) and d.cycleid = ' || p_cycleID;
  
      
    v_sortstr varchar2(100) := ' ORDER BY employeename';
    v_baseSql varchar2(1000);
    
    v_isAdmin int := 0;
    
begin
    
    open c_isAdmin(p_UserID); fetch c_isAdmin into v_isadmin;close c_isAdmin;
    
    delete from tmp_emp_org;
    
  if p_orgType = ng_globals.const_search then -- if we're doing a search...
          
    v_baseSql := 
          'select d.eid employeeid, d.empName employeename, null TotalCount'
          || ' FROM hr_compOrg d' 
          || ' WHERE   d.cycleid =' || p_cycleID ;  
          
          
    if(v_isAdmin != 1) then 
        -- go over assignments     
        FOR x IN c_assignments(p_UserID,p_CycleID) LOOP
            
            if(p_SearchCriteria is not null) then
              v_sql := v_baseSql || ' and lower(d.empName) || to_char(d.eid) LIKE ''%' || lower(p_SearchCriteria) || '%''';
            else
              v_sql := v_baseSql;
            end if;
            
            v_sql := v_sql || ' START WITH d.managerid = ' || x.AssignedEmpID 
                || ' CONNECT BY PRIOR d.eid = d.managerid AND PRIOR d.cycleid =' || p_CycleID;
  
            -- TODO: consolidate which temp table we'll be using...
            -- put the searched employees into tmp_org (see notes about this temp table)
            execute immediate 'insert into tmp_emp_org(eid,employeename,totalcount) ' || v_sql;
        end loop; 
    else
        if(p_SearchCriteria is not null) then
          v_sql := v_baseSql || ' and lower(d.empName) || to_char(d.eid) LIKE ''%' || lower(p_SearchCriteria) || '%''';
        else
          v_sql := v_baseSql;
        end if;
        execute immediate 'insert into tmp_emp_org(eid,employeename,totalcount) ' || v_sql;
    end if;
    
        
      v_orgSql := v_orgSql || ' order by e.last_name, e.first_name';
        
  else -- do regular orgs
      
      -- Get The org and place it in a temp table to be used as the base table
      orgCursor := ng_org.getCompOrg(p_ManagerID,p_CycleID,p_OrgType);
      
      LOOP
          FETCH orgCursor INTO EmpRecord;
          EXIT WHEN orgCursor%NOTFOUND;
          -- DBMS_OUTPUT.put_line ('EID: ' || EmpRecord.eid); 
          -- TODO: Using tmp_org for testing only. It's a regular table, eventually, we would use a temp table or a plsql table.
          insert into tmp_emp_org (eid) values(EmpRecord.eid);
          
      END LOOP; 
   
          if p_sort is not null then
            v_sortstr := ' ORDER BY ' || p_sort || ' ' || p_dir;
          end if;
   
          -- Here we will also need the calculated HRGAccess column
          v_orgSql := 'SELECT * FROM ( SELECT o.*'
                      || ',ROWNUM r  ' 
                      ||  ' FROM ( '
        
                              ||  v_orgSql || v_sortstr 
        
                       || ' ) o WHERE ROWNUM <= ' || p_end || ' /* end */ ) '
             || ' WHERE r >= ' || p_start ; 
   
   end if; -- 


   
   OPEN p_cursorEmp FOR v_orgSql;




end getManagerOrg;   

PROCEDURE searchEmployeesByPage (
       p_recordset   IN OUT   genRefCursor
      ,p_ManagerID             NUMBER
      ,p_CycleID               NUMBER
      ,p_SearchCriteria varchar2
      ,p_start    number
      ,p_end    number
      ,p_userID    number default 0
      ,p_ManagersOnly number default 0
      
   ) is
 
 v_baseSql varchar2(1000);
 v_sql varchar2(2000);  
 v_isAdmin int := 0;
 
begin
  
  open c_isAdmin(p_UserID); fetch c_isAdmin into v_isadmin;close c_isAdmin;

  delete from TMP_SEARCHEMP;
  
    v_baseSql := 
          'select d.eid employeeid, d.empName employeename'
          || ' FROM hr_compOrg d' 
          || ' WHERE   d.cycleid =' || p_cycleID ;  
          
     if(p_ManagersOnly = 1) then
      v_baseSql := v_baseSql || ' and d.compEmp.DirectReports <> 0';
     end if;
     
    if(v_isAdmin != 1) then 
        -- go over assignments     
        for x IN c_assignments(p_UserID,p_CycleID) loop
            
            if(p_SearchCriteria is not null) then
              v_sql := v_baseSql || ' and lower(d.empName) || to_char(d.eid) LIKE ''%' || lower(p_SearchCriteria) || '%''';
            else
              v_sql := v_baseSql;
            end if;
             
            v_sql := v_sql || ' START WITH d.managerid = ' || x.AssignedEmpID 
                || ' CONNECT BY PRIOR d.eid = d.managerid AND PRIOR d.cycleid =' || p_CycleID;
            
            
            -- then the manager's org
            execute immediate 'insert into TMP_SEARCHEMP(eid,employeename) ' || v_sql;

            if x.AssignedEmpID != p_UserID and lower(x.EmployeeName) || to_char(x.AssignedEmpID) like '%' || lower(p_SearchCriteria) || '%' then 
              -- insert the manager supported -- 
              insert into TMP_SEARCHEMP(eid,employeename) values (x.AssignedEmpID, x.EmployeeName );
            end if;
            
        end loop; 
        
    else
    
        if(p_SearchCriteria is not null) then
          v_sql := v_baseSql || ' and lower(d.empName) || to_char(d.eid) LIKE ''%' || lower(p_SearchCriteria) || '%''';
        else
          v_sql := v_baseSql;
        end if;
        execute immediate 'insert into TMP_SEARCHEMP(eid,employeename) ' || v_sql;
    
    end if;



    v_sql := 'SELECT *  FROM ( SELECT a.*, ROWNUM r, COUNT(1) OVER () TotalCount  FROM ( '
               ||  'select eid employeeid, employeename from TMP_SEARCHEMP'
               || ' ) a WHERE ROWNUM <= ' || p_end || ' /* end */ ) '
		 || ' WHERE r >= ' || p_start || '/* start */ ORDER BY employeename'; 



  open p_recordset for v_sql;
  
end searchEmployeesByPage;







procedure updateCompData(p_CycleID number, p_EID number default null) is

begin
  null;
end updateCompData;

procedure markRecordOutdated(p_CycleID number, p_EID number,p_Section varchar2) is

/* 
  Outdated.... Review 1/20
*/

begin
  
update hr_compOrg h
    set h = new ngt_compOrg(
     h.eid
    ,h.cycleid
    ,1 -- doRefresh
    ,h.empname
    ,h.managerid
    ,h.manager
    ,h.compEmp
    ,h.compInput
    ,h.recICP
    ,h.recSalary
    ,h.recLTI
    ,h.compAccess
    ,h.cycleInfo
    )
    where eid = p_EID and cycleid = p_CycleID;
end markRecordOutdated;
/* ///////////////////////////////////////////////// */
procedure recalcRecommendations(p_CycleID number, p_EID number) is

  recSalary ngt_recSalary;
  recICP ngt_recICP;
  recLTI ngt_recLTI;
  
begin
  
      recSalary := New ngt_recSalary(
         cached => 0
        ,EID =>  p_EID
        ,CycleID => p_CycleID
      );
    
      recICP := New ngt_recICP(
         0
        ,p_EID
        ,p_CycleID
      );
      recLTI := New ngt_recLTI(
         0
        ,p_EID
        ,p_CycleID
      );
      
  update hr_compOrg h
    set h = new ngt_compOrg(
     h.eid
    ,h.cycleid
    ,1 -- doRefresh
    ,h.empname
    ,h.managerid
    ,h.manager
    ,h.compEmp
    ,h.compInput
    ,recICP.recalc()
    ,recSalary.recalc()
    ,recLTI.recalc()
    ,h.compAccess
    ,h.cycleInfo
    )
    where eid = p_EID and cycleid = p_CycleID;
   
    
end recalcRecommendations;
/* ///////////////////////////////////////////////// */
procedure UpdateMarketDataObjTable(p_CycleID number) is
  /* Updates the object table hr_CompJobMarketData from the relational table HR_JOBS_DATA */
begin

  -- update market data
  for x in (SELECT 
        jd.JOBCODE_IDFK JobCode,
        jd.CA_IDFK CAID,
        jd.LOW_FTE LowFTE,
        jd.MID_FTE MidFTE,
        jd.HIGH_FTE HighFTE
     FROM HR_JOBS_DATA jd
     WHERE jd.FY_CYCLE_IDFK = p_CycleID ) loop
     
     -- insert into hr_CompJobMarketData values (New ngt_jobMarketData(1, p_CycleID,x.JobCode,x.CAID,x.LowFTE,x.midFTE,x.highFTE));
      UPDATE hr_CompJobMarketData m SET m = New ngt_jobMarketData(1, p_CycleID,x.JobCode,x.CAID,x.LowFTE,x.midFTE,x.highFTE)
      WHERE cycleid = p_CycleID and jobcode = x.JobCode and caid = x.caid;
      
      IF sql%ROWCOUNT = 0
      THEN
        insert into hr_CompJobMarketData values (New ngt_jobMarketData(1, p_CycleID,x.JobCode,x.CAID,x.LowFTE,x.midFTE,x.highFTE));
      END IF;
      
  end loop;  
  
end UpdateMarketDataObjTable;
/* ///////////////////////////////////////////////// */
procedure UpdateBudgetModifiers(p_CycleID number) is
  
begin
  
  -- budget modifiers
  for x in (SELECT ca_idfk CAID, merit_modifier MeritPercModifier,  pa_modifier PAPercModifier
             FROM HR_BUDGET_MODIFIERS
             WHERE fy_cycle_idfk =  p_CycleID
             AND company_idfk = 0) loop
  
      UPDATE hr_compCycleMod m SET m = New ngt_meritpamod(p_CycleID,x.CAID,0,x.MeritPercModifier,x.PAPercModifier,x.CAID)
      WHERE cycleid = p_CycleID and modID = x.CAID;
       
      IF sql%ROWCOUNT = 0
      THEN
         insert into hr_compCycleMod values (New ngt_meritpamod(p_CycleID,x.CAID,0,x.MeritPercModifier,x.PAPercModifier,x.CAID));
      END IF;

  end loop; 
  
end UpdateBudgetModifiers;
/* ///////////////////////////////////////////////// */
PROCEDURE runUpdateProcJobByName(p_cycleid NUMBER, p_procName varchar2) IS
  /*  places a job for the update procedure specified. (this is useful when calling these procs from 
      CF because without submitting a job the JDBC driver throws an error in cf8) */
 JobNo user_jobs.job%TYPE;
 cmdString VARCHAR2(250);
BEGIN
  cmdString := 'ng_compService.' || p_procName || '(' || p_CycleID || '); commit;';
  dbms_job.submit(JobNo,
      cmdString,
      SYSDATE,
      NULL
    );
END runUpdateProcJobByName;
/* ///////////////////////////////////////////////// */
PROCEDURE ngEmpUpdate (   
   p_CycleID   NUMBER
  ,p_OrgType INTEGER
  ,p_ManagerID NUMBER default null
  ,p_EmpIDList VARCHAR2 DEFAULT NULL) is

  orgCursor  SYS_REFCURSOR;
  EmpRecord ng_org.EmpCompOrgRecord;
  v_compEmp ngt_compEmp;
  
begin
    
  delete from tmp_emp_org;
  
  -- we should probably check that the updates are enabled for this cycle to prevent this from running inadvertedly
  

  -- Get The org and place it in a temp table to be used as the base table
      orgCursor := ng_org.getCompOrg(p_ManagerID,p_CycleID,p_OrgType,p_EmpIDList);
      
      LOOP
          FETCH orgCursor INTO EmpRecord;
          EXIT WHEN orgCursor%NOTFOUND;

          
      v_compEmp := New ngt_compEmp(
           cached => 0
          ,EID =>  EmpRecord.eid
          ,CycleID => p_CycleID
          ,managerid => 0
          ,ForceLoad => 1);
      
      v_compEmp.save();
          
          
          -- DBMS_OUTPUT.put_line ('Updating EID: ' || EmpRecord.eid); 
          recalcRecommendations(p_CycleID, EmpRecord.eid);
          
      END LOOP;
      
end ngEmpUpdate; 
/* ///////////////////////////////////////////////// */
PROCEDURE ngEmpUpdateByID (   
   p_CycleID   NUMBER
  ,p_EID NUMBER) is

  v_compEmp ngt_compEmp;

begin
        
      v_compEmp := New ngt_compEmp(
           cached => 0
          ,EID =>  p_EID
          ,CycleID => p_CycleID
          ,managerid => 0
          ,ForceLoad => 1);
      
      v_compEmp.save();
      
      recalcRecommendations(p_CycleID, p_EID);
          
end ngEmpUpdateByID;   
/* ///////////////////////////////////////////////// */
procedure saveEligibility(p_CycleID number, p_EID number, p_CompTypeID int, p_EligValue int default 0, p_GenBudget int default null) is

begin
  
  DELETE FROM HR_COMP_EMP_ELIGIBILITY WHERE EMP_IDFK = p_EID AND FY_CYCLE_IDFK = p_Cycleid AND COMP_TYPE_IDFK = p_CompTypeID;
  INSERT INTO HR_COMP_EMP_ELIGIBILITY (EMP_IDFK, FY_CYCLE_IDFK, COMP_TYPE_IDFK, IS_ELIGIBLE, GENERATES_BUDGET ) VALUES( p_EID, p_cycleid, p_CompTypeID, p_EligValue, nvl(p_GenBudget,p_EligValue) );
            
end saveEligibility;

end ng_CompService;
/
