set define off;
create or replace package ng_compRollup AS

TYPE genRefCursor IS REF CURSOR;

TYPE SPRollupRecord IS RECORD (
       CycleID number
      ,empcount number
      ,EligibleCount number
      ,RecIncCount number
      ,MeritBudgeted number
      ,MeritAllocated number
      ,PABudgeted number
      ,PAAllocated number
      ,CurrentPayroll number
      ,NewPayroll number
      );
      
type ICPRollupRecord is record (
       CycleID number
      ,empcount number
      ,EligibleCount number
      ,RecIncCount number
      ,ICPBudgeted number
      ,ICPAllocated number
      );

type LTIRollupRecord is record (
       CycleID number
      ,empcount number
      ,EligibleCount number
      ,RecIncCount number
      ,LTIBudgeted number
      ,LTIAllocated number
      );

type salaryIncDataRecord is record(
     eid number
    ,empName varchar2(100 byte)
    ,salaryEligible int
    ,jobCode varchar2(15 byte)
    ,contribution varchar2(50 byte)
    ,potential varchar2(50 byte)
    ,ftsalaryusd number
    ,currencyExchange float
    ,meritIncUSD float
    ,promIncUSD float
    ,AdjIncUSD float
    ,ICPIncUSD float
    ,NewJobCode varchar2(15 byte)
    ,isJobChange int
    ,isPromotion int
    ,isICPElig int
    ,NewICPIndMod float  
    ,midFTE float
);    


cursor c_myorg(p_Managerid number, p_CycleID number) is
  select 
     d.eid
    ,d.managerid
    ,d.manager.empname managername
    ,0 as orgSeq
    ,d.compEmp.eligibility.isSalaryEligible SalaryEligible
    ,decode(d.compEmp.eligibility.isSalaryEligible,0,0, decode(d.compInput.MeritAmt,null,decode(d.compInput.LumpSumAmt,null,0,1),1) ) salarydone     
    ,d.compEmp.eligibility.isICPEligible icpeligible
    ,decode(d.compEmp.eligibility.isICPEligible,0,0,decode(d.compInput.ICPIndivModifier,null,0,1)) icpdone      
    ,d.compEmp.eligibility.isLTIEligible LTIEligible
    ,decode(d.compEmp.eligibility.isLTIEligible,0,0,decode(d.compInput.LTIGrantAmt,null,0,1)) ltidone /* by default if not elig, it's done */  
    FROM hr_compOrg d 
      WHERE   d.cycleid = p_cycleID 
      and d.managerid = p_managerid;

FUNCTION getSPRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor;  

FUNCTION getICPRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor; 

FUNCTION getLTIRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor; 

FUNCTION getIncRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor; 
    
PROCEDURE getRollupSP ( 
   p_Data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getRollupICP ( 
   p_Data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE getRollupLTI ( 
   p_Data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE IncreaseRollup (
   p_TotalInc IN OUT Globals.genRefCursor
  ,p_Merit IN OUT Globals.genRefCursor
  ,p_Promo IN OUT Globals.genRefCursor
  ,p_Adjust IN OUT Globals.genRefCursor
  ,p_jobChange IN OUT Globals.genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);

PROCEDURE putSalICPIncreaseRollup ( 
   p_ManagerID NUMBER
  ,p_CycleID   NUMBER);
  
PROCEDURE putIncRollup(
  p_orgseq NUMBER,
  p_OrgName VARCHAR2,
  p_EmployeeID NUMBER,
  p_isElig NUMBER,
  p_Rating VARCHAR2,
  p_TARating VARCHAR2,
  p_MeritInc NUMBER,
  p_PAInc NUMBER,
  p_IsPromo INT DEFAULT 0,
  p_IsJobChange INT DEFAULT 0,
  p_AdjInc NUMBER,
  p_FTSalary NUMBER,
  p_NewICPIndMod FLOAT,
  p_ICPElig INT DEFAULT 0,
  p_NewJobCode VARCHAR2,
  p_MidFTE NUMBER DEFAULT 0
  ,p_icpAward number default 0);
   
PROCEDURE putSPTempData(
  p_orgseq NUMBER,
  p_OrgName VARCHAR2,
  p_EmpCount NUMBER default 0,
  p_EligCount NUMBER default 0,
  p_IncCount NUMBER default 0,
  p_MeritBudgeted NUMBER default 0,
  p_MeritAllocated NUMBER default 0,
  p_Meritholdbacks NUMBER default 0,
  p_PABudgeted NUMBER default 0,
  p_PAAllocated NUMBER default 0,
  p_PAHoldbacks NUMBER default 0,
  p_CurrentPayroll NUMBER default 0,
  p_NewPayroll NUMBER default 0);

PROCEDURE putICPTempData(
  p_orgseq NUMBER,
  p_OrgName VARCHAR2,
  p_EmpCount NUMBER default 0,
  p_EligCount NUMBER default 0,
  p_IncCount NUMBER default 0,
  p_ICPBudgeted NUMBER default 0,
  p_ICPAllocated NUMBER default 0,
  p_ICPholdbacks NUMBER default 0);
  
END ng_compRollup;
/




create or replace package body ng_compRollup AS

PROCEDURE getRollupSP ( 
   p_Data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is


  r_hb ng_CompService.c_hb%rowtype;
  v_seq number := 0;
  v_tmp int := 0;
  v_hasHB int := 0;
  
  gen_refcur  SYS_REFCURSOR;
  r_budget  SPRollupRecord;
  
begin

  delete from TMP_ROLLUP;
  
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  -- get holdbacks
  open ng_CompService.c_hb(p_Managerid, p_CycleID); fetch ng_CompService.c_hb into r_hb; 
    if ng_CompService.c_hb%found and (nvl(r_hb.MeritHB,0) + nvl(r_hb.PAHB,0)) != 0 then
      v_hasHB := 1;
    end if;
  close ng_CompService.c_hb;

  -- /// Direct Reports ///
  -- get the data
  gen_refcur := ng_compRollup.getSPRollupOrg(p_ManagerID,p_CycleID,1); -- direct reports
  LOOP
      FETCH gen_refcur INTO r_budget;
      EXIT WHEN gen_refcur%NOTFOUND;

        putSPTempData(
           0
          ,'Your Direct Reports'
          ,r_budget.EmpCount
          ,r_budget.EligibleCount
          ,r_budget.RecIncCount
          ,r_budget.MeritBudgeted
          ,r_budget.MeritAllocated
          ,nvl(r_hb.MeritHB ,0)
          ,r_budget.PABudgeted
          ,r_budget.PAAllocated
          ,nvl(r_hb.PAHB,0)
          ,r_budget.CurrentPayroll
          ,r_budget.NewPayroll
          );
  END LOOP;

  -- /// managers  /// 
  for m in ng_org.c_directManagers(p_ManagerID, p_CycleID) loop
      v_seq := v_seq + 1;
      
      -- get the data
      gen_refcur := ng_compRollup.getSPRollupOrg(m.eid,p_CycleID,0); -- total reports
      
      -- get holdbacks (we only need to extract this once
      if(v_seq = 1) then
        open ng_CompService.c_hb(m.eid, p_CycleID); fetch ng_CompService.c_hb into r_hb; close ng_CompService.c_hb;
      end if;
      
      LOOP
          FETCH gen_refcur INTO r_budget;
          EXIT WHEN gen_refcur%NOTFOUND;
          
          putSPTempData(
             v_seq
            ,m.empname
            ,r_budget.EmpCount
            ,r_budget.EligibleCount
            ,r_budget.RecIncCount
            ,r_budget.MeritBudgeted
            ,r_budget.MeritAllocated
            ,nvl(r_hb.MeritHB ,0)
            ,r_budget.PABudgeted
            ,r_budget.PAAllocated
            ,nvl(r_hb.PAHB,0)
            ,r_budget.CurrentPayroll
            ,r_budget.NewPayroll
            );
            
    END LOOP;       
  end loop; -- managers    


OPEN p_Data FOR
select y.*  
    ,sum(y.SalaryBudgeted) over() SalaryBudgetedTotal
    ,sum(y.SalaryHoldback) over() SalaryHoldbackTotal
    ,Hrshared.getPercent(sum(y.SalaryHoldback) over() , sum(y.SalaryBudgeted) over() ) SalaryHoldbackPercTotal
    ,sum(y.SalaryAvailable) over() SalaryAvailableTotal
    ,sum(y.SalaryAllocated) over() SalaryAllocatedTotal
    ,sum(y.SalaryRemaining) over() SalaryRemainingTotal
    ,Hrshared.getPercent(sum(y.SalaryAllocated) over() , sum(y.SalaryAvailable) over()) SalaryAllocatedPercentTotal
    ,sum(y.CURRENT_PAYROLLUSD) over() CurrentPayRollTotal
    ,Hrshared.getPercent(sum(y.SalaryAllocated) over() , sum(y.CURRENT_PAYROLLUSD) over() ) CurrentPayRollPercentTotal
    ,sum(y.NEW_PAYROLLUSD) over() NewPayRollTotal
    
    ,sum(y.MERIT_REMAINING) over() MERIT_REMAININGTotal
    ,sum(y.PA_REMAINING) over() PA_REMAININGTotal
    ,sum(y.MeritHBAmt) over() MeritHoldbackTotal
    ,Hrshared.getPercent(sum(y.MeritHBAmt) over() , sum(y.MERIT_BUDGETED) over() ) MeritHoldbackPercTotal
    ,sum(y.PAHBAmt) over() PAHoldbackTotal
    ,Hrshared.getPercent( sum(y.PAHBAmt) over() , sum(y.PA_BUDGETED) over() ) PAHoldbackPercTotal
  from(
  select o.*
    ,SUM(o.EmpCount) OVER () EmpCountTotal
    ,SUM(o.EligibleCount) OVER () EligibleCountTotal
    ,SUM(o.RecIncCount) OVER () RecIncCountTotal
    ,Hrshared.getPercent(SUM(o.RecIncCount) OVER (), SUM(o.EligibleCount) OVER () ) RecIncCountPercentTotal
     
    ,SUM(o.MERIT_BUDGETED) OVER() MERIT_BUDGETEDTotal
    ,SUM(o.MERIT_AVAILABLE) OVER () MERIT_AVAILABLETotal
    ,SUM(o.MERIT_ALLOCATED) OVER () MERIT_ALLOCATEDTotal
    ,NVL(o.MERIT_AVAILABLE - o.MERIT_ALLOCATED,0) AS MERIT_REMAINING 
    ,Hrshared.getPercent(o.MERIT_ALLOCATED, o.MERIT_AVAILABLE) MERIT_ALLOCATEDPercent 
    ,Hrshared.getPercent(SUM(o.MERIT_ALLOCATED) OVER (), SUM(o.MERIT_AVAILABLE) OVER () ) MERIT_ALLOCATEDPercentTotal
    ,SUM(o.PA_BUDGETED) OVER() PA_BUDGETEDTotal
    ,SUM(o.PA_AVAILABLE) OVER() PA_AVAILABLETotal
    ,SUM(o.PA_ALLOCATED) OVER() PA_ALLOCATEDTotal  
    ,NVL(PA_AVAILABLE - PA_ALLOCATED,0) AS PA_REMAINING
    ,Hrshared.getPercent(SUM(o.PA_ALLOCATED) OVER() , SUM(o.PA_AVAILABLE) OVER() ) PA_ALLOCATEDPercentTotal
    ,Hrshared.getPercent(o.PA_ALLOCATED, o.PA_AVAILABLE) PA_ALLOCATEDPercent
     
     ,o.MERIT_BUDGETED + o.PA_BUDGETED AS SalaryBudgeted
     ,(o.MeritHBAmt + o.PAHBAmt) SalaryHoldback
     ,Hrshared.getPercent((o.MeritHBAmt + o.PAHBAmt) , (o.MERIT_BUDGETED + o.PA_BUDGETED) ) SalaryHoldbackPerc
     
     ,(o.MERIT_AVAILABLE + o.PA_AVAILABLE) as SalaryAvailable   
     ,(o.MERIT_ALLOCATED + o.PA_ALLOCATED) as SalaryAllocated
     ,(o.MERIT_AVAILABLE + o.PA_AVAILABLE) - (o.MERIT_ALLOCATED + o.PA_ALLOCATED) SalaryRemaining  
     ,Hrshared.getPercent((o.MERIT_ALLOCATED + o.PA_ALLOCATED), (o.MERIT_AVAILABLE + o.PA_AVAILABLE)) SalaryAllocatedPercent
     
  from (
   SELECT
      ORG_SEQ
     ,ORG_NAME
     ,EMP_COUNT EmpCount
     ,ELIG_COUNT EligibleCount
     ,INCR_COUNT RecIncCount
     ,Hrshared.getPercent(INCR_COUNT, ELIG_COUNT * 100) * 100 RecIncCountPercent
     
     ,PA_BUDGETED
     ,PA_HB PAHBPerc
     ,(PA_BUDGETED * PA_HB / 100) PAHBAmt
     -- AND  NVL(PA_HB,0) = 0 
     ,CASE WHEN ORG_SEQ = 0 and v_hasHB = 0 THEN SUM(PA_BUDGETED * PA_HB / 100) OVER() + PA_BUDGETED
        else PA_BUDGETED - (PA_BUDGETED * PA_HB / 100)
      end as PA_AVAILABLE
      
     ,nvl(PA_ALLOCATED,0) PA_ALLOCATED
     
     ,MERIT_BUDGETED
     ,MERIT_HB MeritHBPerc
     ,(MERIT_BUDGETED * MERIT_HB / 100) MeritHBAmt
     
     ,CASE WHEN ORG_SEQ = 0 and v_hasHB = 0 THEN SUM(MERIT_BUDGETED * MERIT_HB / 100) OVER() + MERIT_BUDGETED
        ELSE MERIT_BUDGETED - (MERIT_BUDGETED * MERIT_HB / 100)
      END AS MERIT_AVAILABLE
     
     ,nvl(MERIT_ALLOCATED,0) MERIT_ALLOCATED
     ,CURRENT_PAYROLLUSD 
     ,Hrshared.getPercent((MERIT_ALLOCATED + PA_ALLOCATED), CURRENT_PAYROLLUSD) CURRENT_PAYROLLUSDPercent
     
     ,NEW_PAYROLLUSD
  
     FROM TMP_ROLLUP
     ORDER BY ORG_SEQ
  )o   
)y;



end getRollupSP;

PROCEDURE putSalICPIncreaseRollup ( 
   p_ManagerID NUMBER
  ,p_CycleID   NUMBER) is
  
  v_seq number := 0;
  v_tmp int := 0;
  
  gen_refcur  SYS_REFCURSOR;
  r_inc  salaryIncDataRecord;  
  
begin

  delete from TMP_INCROLLUP;

  -- /// Direct Reports ///
  -- get the data
  gen_refcur := getIncRollupOrg(p_ManagerID,p_CycleID,1); -- direct reports
  LOOP
      FETCH gen_refcur INTO r_inc;
      EXIT WHEN gen_refcur%NOTFOUND;

        putIncRollup(
             0
            ,'Your Direct Reports' -- r_inc.empname
            ,r_inc.eid
            ,r_inc.salaryeligible
            ,r_inc.contribution
            ,null -- r_inc.potential -- is this really the field? TA Rating, maybe we were using this for a code "0:0"
            ,r_inc.meritIncUSD
            ,r_inc.promIncUSD
            ,r_inc.isPromotion
            ,r_inc.isJobChange
            ,r_inc.AdjIncUSD
            ,r_inc.ftsalaryUSD
            ,r_inc.NewICPIndMod
            ,r_inc.isICPElig
            ,r_inc.NewJobCode
            ,r_inc.midFTE
            ,r_inc.ICPIncUSD);  
          
  END LOOP;  
  
  -- /// managers  /// 
  for m in ng_org.c_directManagers(p_ManagerID, p_CycleID) loop
      v_seq := v_seq + 1;
      
      -- get the data
      gen_refcur := getIncRollupOrg(m.eid,p_CycleID,0); -- total reports
      
      LOOP
          FETCH gen_refcur INTO r_inc;
          EXIT WHEN gen_refcur%NOTFOUND;
          
          putIncRollup(
             v_seq
            ,m.empname
            ,r_inc.eid
            ,r_inc.salaryeligible
            ,r_inc.contribution
            ,null -- r_inc.potential -- is this really the field? TA Rating, maybe we were using this for a code "0:0"
            ,r_inc.meritIncUSD
            ,r_inc.promIncUSD
            ,r_inc.isPromotion
            ,r_inc.isJobChange
            ,r_inc.AdjIncUSD
            ,r_inc.ftsalaryUSD
            ,r_inc.NewICPIndMod
            ,r_inc.isICPElig
            ,r_inc.NewJobCode
            ,r_inc.midFTE
            ,r_inc.ICPIncUSD);
        
    END LOOP;       
  end loop; -- managers

end putSalICPIncreaseRollup;

PROCEDURE getRollupICP ( 
   p_Data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is

  r_hb ng_CompService.c_hb%rowtype;
  v_seq number := 0;
  v_tmp int := 0;
  v_hasHB int := 0;
  
  gen_refcur  SYS_REFCURSOR;
  r_budget  ICPRollupRecord;
  
begin
  /*
    NOTE: getRollupLTI and getRollupICP are doing pretty much the same thing and using the same fields and returning the very same cursor definition.
          If you are making changes to either one, please check if it should be done on the other one as well.
          Also, note that in the CF side, they both use the same renderer so renaming columns can affect that.
  */
  
  delete from td;
  
  delete from TMP_ROLLUP;
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  -- get holdbacks
  open ng_CompService.c_hb(p_Managerid, p_CycleID); fetch ng_CompService.c_hb into r_hb; 
    if ng_CompService.c_hb%found and nvl(r_hb.ICPHB,0) != 0 then
      v_hasHB := 1;
    end if;
  close ng_CompService.c_hb;

  -- /// Direct Reports ///
  -- get the data
  gen_refcur := getICPRollupOrg(p_ManagerID,p_CycleID,1); -- direct reports
  
  LOOP
      FETCH gen_refcur INTO r_budget;
      EXIT WHEN gen_refcur%NOTFOUND;
        
        putICPTempData(
           0
          ,'Your Direct Reports'
          ,r_budget.EmpCount
          ,r_budget.EligibleCount
          ,r_budget.RecIncCount
          ,r_budget.ICPBudgeted
          ,r_budget.ICPAllocated
          ,nvl(r_hb.ICPHB ,0)
          );
   
          
  END LOOP;

  -- /// managers  /// 
  for m in ng_org.c_directManagers(p_ManagerID, p_CycleID) loop
      v_seq := v_seq + 1;
      -- get the data
      gen_refcur := getICPRollupOrg(m.eid,p_CycleID,0); -- total reports
      
      -- get holdbacks (we only need to extract this once
      if(v_seq = 1) then
        open ng_CompService.c_hb(m.eid, p_CycleID); fetch ng_CompService.c_hb into r_hb; close ng_CompService.c_hb;
      end if;
      
      LOOP
          FETCH gen_refcur INTO r_budget;
          EXIT WHEN gen_refcur%NOTFOUND;   
          
          putICPTempData(
             v_seq
            ,m.empname
            ,r_budget.EmpCount
            ,r_budget.EligibleCount
            ,r_budget.RecIncCount
            ,r_budget.ICPBudgeted
            ,r_budget.ICPAllocated
            ,nvl(r_hb.ICPHB ,0)
            );
            
    END LOOP;       
  end loop; -- managers    

 OPEN p_Data FOR
SELECT o.*,
    SUM(o.EmpCount) OVER () EmpCountTotal
    ,SUM(o.EligibleCount) OVER () EligibleCountTotal
    ,SUM(o.RecIncCount) OVER () RecIncCountTotal
    ,Hrshared.getPercent(SUM(o.RecIncCount) OVER (), SUM(o.EligibleCount) OVER () ) RecIncCountPercentTotal
    ,sum(o.Budgeted) over() BudgetedTotal
    ,SUM(o.AVAILABLE) OVER() AVAILABLETotal
    ,SUM(o.ALLOCATED) OVER() ALLOCATEDTotal
    ,nvl(o.AVAILABLE,0) - nvl(o.ALLOCATED,0) AS REMAINING
    ,SUM(NVL(o.AVAILABLE,0) - nvl(o.ALLOCATED,0)) OVER () REMAININGTotal
    
    ,Hrshared.getPercent(o.ALLOCATED,AVAILABLE) AllocatedPercent
    ,Hrshared.getPercent(SUM(o.ALLOCATED) OVER (), SUM(o.AVAILABLE) OVER () ) ALLOCATEDPercentTotal
    ,sum(o.HBAmt) over () HBAmtTotal 
    ,sum(o.HBAmt) over() / sum(o.Budgeted) over() * 100 HBPercTotal
    
 FROM (
    SELECT
      ORG_SEQ, ORG_NAME, EMP_COUNT EmpCount
      ,ELIG_COUNT EligibleCount
      ,INCR_COUNT RecIncCount    
      ,Hrshared.getPercent(INCR_COUNT, ELIG_COUNT * 100) * 100 PercentRecAward     
      ,ICP_BUDGETED Budgeted
      ,ICP_HB HBPerc
      ,nvl(ICP_HBAMT,0) HBAmt
      -- this line adds the hb to the manager's available if he is the one with the holdback. Old: and NVL(ICP_HBAMT,0) = 0 --
      ,case when ORG_SEQ = 0 and v_hasHB = 0 then sum(ICP_HBAMT) over() + ICP_BUDGETED
        else nvl(ICP_BUDGETED,0) - nvl(ICP_HBAMT,0) 
        end as AVAILABLE  
    
    ,nvl(ICP_ALLOCATED,0) Allocated

   FROM TMP_ROLLUP
   ORDER BY ORG_SEQ
 )o ;

end getRollupICP; 
/* ///////////////////////////////////////////////// */
PROCEDURE getRollupLTI ( 
   p_Data IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is
  
  /*
    NOTE: getRollupLTI and getRollupICP are doing pretty much the same thing and using the same fields and returning the very same cursor definition.
          If you are making changes to either one, please check if it should be done on the other one as well.
          Also, note that in the CF side, they both use the same renderer so renaming columns can affect that.
  */
   r_hb ng_CompService.c_hb%rowtype;
  v_seq number := 0;
  v_tmp int := 0;
  v_hasHB int := 0;
  
  gen_refcur  SYS_REFCURSOR;
  r_budget  LTIRollupRecord;
  
begin
  
  delete from TMP_ROLLUP;
  p_ManagerName := ng_shared.getEmpName(p_ManagerID);
  
  -- reused data collector
  -- PUTRollupLTI(p_ManagerID,p_CycleID);
  
  
  -- get holdbacks
  open ng_CompService.c_hb(p_Managerid, p_CycleID); fetch ng_CompService.c_hb into r_hb; 
    if ng_CompService.c_hb%found and nvl(r_hb.LTIHB,0) != 0 then
      v_hasHB := 1;
    end if;
  close ng_CompService.c_hb;

  -- /// Direct Reports ///
  -- get the data
  gen_refcur := getLTIRollupOrg(p_ManagerID,p_CycleID,1); -- direct reports
  LOOP
      FETCH gen_refcur INTO r_budget;
      EXIT WHEN gen_refcur%NOTFOUND;

        putICPTempData(
           0
          ,'Your Direct Reports'
          ,r_budget.EmpCount
          ,r_budget.EligibleCount
          ,r_budget.RecIncCount
          ,r_budget.LTIBudgeted
          ,r_budget.LTIAllocated
          ,nvl(r_hb.LTIHB ,0)
          );
   
          
  END LOOP;

  -- /// managers  /// 
  for m in ng_org.c_directManagers(p_ManagerID, p_CycleID) loop
      v_seq := v_seq + 1;
      -- get the data
      gen_refcur := getLTIRollupOrg(m.eid,p_CycleID,0); -- total reports
      
      -- get holdbacks (we only need to extract this once
      if(v_seq = 1) then
        open ng_CompService.c_hb(m.eid, p_CycleID); fetch ng_CompService.c_hb into r_hb; close ng_CompService.c_hb;
      end if;
      
      LOOP
          FETCH gen_refcur INTO r_budget;
          EXIT WHEN gen_refcur%NOTFOUND;
          
          putICPTempData(
             v_seq
            ,m.empname
            ,r_budget.EmpCount
            ,r_budget.EligibleCount
            ,r_budget.RecIncCount
            ,r_budget.LTIBudgeted
            ,r_budget.LTIAllocated
            ,nvl(r_hb.LTIHB ,0)
            );
            
    END LOOP;       
  end loop; -- managers   
  
  
 OPEN p_Data FOR
SELECT o.*,
     SUM(o.EmpCount) OVER () EmpCountTotal
    ,SUM(o.EligibleCount) OVER () EligibleCountTotal
    ,SUM(o.RecIncCount) OVER () RecIncCountTotal
    ,Hrshared.getPercent(SUM(o.RecIncCount) OVER (), SUM(o.EligibleCount) OVER () ) RecIncCountPercentTotal
    ,sum(o.Budgeted) over() BudgetedTotal
    ,SUM(o.AVAILABLE) OVER() AVAILABLETotal
    ,SUM(o.ALLOCATED) OVER() ALLOCATEDTotal
    ,nvl(o.AVAILABLE,0) - nvl(o.ALLOCATED,0) AS REMAINING
    ,SUM(NVL(o.AVAILABLE,0) - nvl(o.ALLOCATED,0)) OVER () REMAININGTotal
    
    ,Hrshared.getPercent(o.ALLOCATED,AVAILABLE) AllocatedPercent
    ,Hrshared.getPercent(SUM(o.ALLOCATED) OVER (), SUM(o.AVAILABLE) OVER () ) ALLOCATEDPercentTotal
    ,sum(o.HBAmt) over () HBAmtTotal 
    ,sum(o.HBAmt) over() / sum(o.Budgeted) over() * 100 HBPercTotal
    
 FROM (
    SELECT
      ORG_SEQ, ORG_NAME, EMP_COUNT EmpCount
     ,ELIG_COUNT EligibleCount
     ,INCR_COUNT RecIncCount
     
     ,Hrshared.getPercent(INCR_COUNT, ELIG_COUNT * 100) * 100 PercentRecAward
     
    ,ICP_BUDGETED Budgeted
    ,ICP_HB HBPerc
    ,nvl(ICP_HBAMT,0) HBAmt
    --  AND NVL(ICP_HBAMT,0) = 0
    ,CASE WHEN ORG_SEQ = 0 and v_hasHB = 0 THEN SUM(ICP_HBAMT) OVER() + ICP_BUDGETED
      else nvl(ICP_BUDGETED,0) - nvl(ICP_HBAMT,0) 
      end as AVAILABLE   
    ,nvl(ICP_ALLOCATED,0) Allocated

   FROM TMP_ROLLUP
   ORDER BY ORG_SEQ
 )o ;
  
end getRollupLTI;
/* ///////////////////////////////////////////////// */
PROCEDURE IncreaseRollup (
   p_TotalInc IN OUT Globals.genRefCursor
  ,p_Merit IN OUT Globals.genRefCursor
  ,p_Promo IN OUT Globals.genRefCursor
  ,p_Adjust IN OUT Globals.genRefCursor
  ,p_jobChange IN OUT Globals.genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is
  
begin
    
    --delete from TMP_ROLLUP;
    p_ManagerName := ng_shared.getEmpName(p_ManagerID);

  -- get the data
  putSalicpIncreaseRollup(
    p_ManagerID,
    p_CycleID);



open p_TotalInc for 
SELECT o.*,
    SUM(o.EmpCount) OVER() EmpCountTotal,
    SUM(o.EligCount) OVER() EligCountTotal,
    SUM(o.IncEmpSum) OVER() IncEmpSumTotal,
    Hrshared.getPercent(SUM(o.IncEmpSum) OVER(),SUM(o.EligCount) OVER()) TotalIncPercTotal,
    Hrshared.getPercent(SUM(o.IncSum) OVER(), SUM(o.FTSalSum) OVER()) AvgPercentTotal,
    Hrshared.getPercent(o.IncEmpSum,o.EligCount) IncPercent,
    Hrshared.getPercent(o.IncSum,o.FTSalSum) AvgPercent
 FROM(
  SELECT r.ORG_SEQ,r.ORGNAME,
      COUNT(r.EID) EmpCount,
      SUM(r.IS_ELIG) EligCount,
      SUM(DECODE(r.IS_ELIG,1,DECODE(NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0),0,0,1),0)) IncEmpSum,
      SUM(DECODE(r.IS_ELIG,1,NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0),0)) IncSum,
      SUM(DECODE(DECODE(r.IS_ELIG,1,NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0),0),0,0,r.FT_SAL)) FTSalSum
  FROM TMP_INCROLLUP r
  group by r.ORG_SEQ, r.ORGNAME
  ORDER BY r.ORG_SEQ
)o;

open p_Merit for 
SELECT o.*,
     SUM(o.EmpCount) over () EmpCountSUM
    ,SUM(o.EligCount) over () EligCountSUM 
    ,SUM(o.MeritIncEmpSum) over () MeritIncEmpSumTotal
    ,SUM(o.FTSalSum) over() FTSalSumTotal
    ,SUM(o.MeritIncSum) over() MeritIncSumTotal
    ,SUM(o.MeritIncEmpSumHigh) over() MeritIncEmpSumHighTotal
    ,SUM(o.MeritIncSumHigh) over() MeritIncSumHighTotal
    ,SUM(o.MeritIncEmpSumMedium) over() MeritIncEmpSumMediumTotal
    ,SUM(o.MeritIncSumMedium) over() MeritIncSumMediumTotal
		,SUM(o.MeritIncEmpSumLow) over() MeritIncEmpSumLowTotal
    ,SUM(o.MeritIncSumLow) over() MeritIncSumLowTotal

    ,Hrshared.getPercent(o.MeritIncEmpSum,o.EligCount)  MeritIncPercent,
    Hrshared.getPercent(o.MeritIncSum, o.FTSalSum) AvgPercent,
    Hrshared.getPercent(o.MeritIncEmpSumHigh,o.EligCount) MeritIncPercentHigh,
    Hrshared.getPercent(o.MeritIncSumHigh,o.FTSalSumHigh) AvgPercentHigh,
    Hrshared.getPercent(o.MeritIncEmpSumLow ,o.EligCount) MeritIncPercentLow,
    Hrshared.getPercent(o.MeritIncSumLow,o.FTSalSumLow) AvgPercentLow,
    Hrshared.getPercent(o.MeritIncEmpSumMedium,o.EligCount)  MeritIncPercentMedium,
    Hrshared.getPercent(o.MeritIncSumMedium , o.FTSalSumMedium)  AvgPercentMedium
FROM(
 SELECT r.ORG_SEQ,r.ORGNAME,
     COUNT(r.EID) EmpCount,
     SUM(r.IS_ELIG) EligCount,
     SUM(DECODE(NVL(r.MERIT_INC,0),0,0,1)) MeritIncEmpSum,
     SUM(r.MERIT_INC) MeritIncSum,
     SUM(DECODE(NVL(r.MERIT_INC,0),0,0,r.FT_SAL)) FTSalSum,

     SUM(DECODE(r.RATING,'High',DECODE(NVL(r.MERIT_INC,0),0,0,r.FT_SAL) ,0)) FTSalSumHigh,
     SUM(DECODE(r.RATING,'Low',DECODE(NVL(r.MERIT_INC,0),0,0,r.FT_SAL) ,0)) FTSalSumLow,
     SUM(DECODE(r.RATING,'Solid',DECODE(NVL(r.MERIT_INC,0),0,0,r.FT_SAL) ,0)) FTSalSumMedium,

     SUM(DECODE(r.RATING,'High',DECODE(r.IS_ELIG,1,DECODE(r.MERIT_INC,0,0,1),0),0)) MeritIncEmpSumHigh,
     SUM(DECODE(r.RATING,'High',DECODE(r.IS_ELIG,1,DECODE(r.MERIT_INC,0,0,r.MERIT_INC),0),0)) MeritIncSumHigh,

     SUM(DECODE(r.RATING,'Low',DECODE(r.IS_ELIG,1,DECODE(r.MERIT_INC,0,0,1),0),0)) MeritIncEmpSumLow,
     SUM(DECODE(r.RATING,'Low',DECODE(NVL(r.MERIT_INC,0),0,0,r.MERIT_INC),0)) MeritIncSumLow,
     SUM(DECODE(r.RATING,'Solid',DECODE(r.IS_ELIG,1,DECODE(r.MERIT_INC,0,0,1),0),0)) MeritIncEmpSumMedium,
     SUM(DECODE(r.RATING,'Solid',DECODE(NVL(r.MERIT_INC,0),0,0,r.MERIT_INC),0)) MeritIncSumMedium

 FROM TMP_INCROLLUP r
 GROUP BY r.ORG_SEQ, r.ORGNAME
 ORDER BY r.ORG_SEQ
)o;
  
open p_Promo for 
SELECT o.*,
    Hrshared.getPercent(o.PromIncEmpSum,o.EligCount)  PromIncPercent,
    Hrshared.getPercent(o.PromotedEmpSum,o.EligCount)  PromotedEmpPercent,
    Hrshared.getPercent(o.PromIncSum, o.FTSalSum)  AvgPercent,
    Hrshared.getPercent(o.PromotedIncSum, o.FTSalSum) AvgPercentPromoted,
    SUM(o.EmpCount) OVER() EmpCountTotal,
    SUM(o.EligCount) OVER() EligCountTotal,
    SUM(o.PromotedEmpSum) OVER () PromotedEmpSumTotal,
    SUM(o.PromotedIncSum) OVER () PromotedIncSumTotal,
    SUM(o.PromIncEmpSum) OVER () PromIncEmpSumTotal,
    SUM(o.FTSalSum) OVER () FTSalSumTotal
FROM(
 SELECT r.ORG_SEQ,r.ORGNAME,
     COUNT(r.EID) EmpCount,
     SUM(r.IS_ELIG) EligCount,
     SUM(DECODE(NVL(r.PA_INC,0),0,0,1)) PromIncEmpSum,
     SUM(DECODE(NVL(r.PA_INC,0),0,0,r.PA_INC)) PromIncSum,
     SUM(DECODE(NVL(r.IS_PROMOTION,0),0,0,1)) PromotedEmpSum,
     SUM(DECODE(r.IS_PROMOTION,0,0,r.PA_INC)) PromotedIncSum,
     SUM(DECODE(NVL(r.PA_INC,0),0,0,r.FT_SAL)) FTSalSum
 FROM TMP_INCROLLUP r
 GROUP BY r.ORG_SEQ,r.ORGNAME
 ORDER BY r.ORG_SEQ
)o;
  
open p_Adjust for 
SELECT o.*,
    SUM(o.EmpCount) OVER() EmpCountTotal,
    SUM(o.EligCount) OVER() EligCountTotal,
    SUM(o.AdjIncEmpSum) OVER() AdjIncEmpSumTotal,
    Hrshared.getPercent(SUM(o.AdjIncEmpSum) OVER(), SUM(o.EligCount) OVER()) AdjIncPercentTotal,
    Hrshared.getPercent(SUM(o.AdjIncSum) OVER (), SUM(o.FTSalSum) OVER()) AdjIncSUMAllAvgTotal,

    Hrshared.getPercent(SUM(o.AdjIncSum) OVER(), SUM(o.FTSalSum) OVER()) AvgPercentTotal,
    Hrshared.getPercent(o.AdjIncEmpSum,o.EligCount) AdjIncPercent,
    Hrshared.getPercent(o.AdjIncSum,o.FTSalSum) AvgPercent,
    SUM(o.AdjIncSum) OVER () AdjIncSUMAll,
    Hrshared.getPercent(SUM(o.AdjIncSum) OVER (), o.FTSalSum) AdjIncSUMAllAvg
FROM(
 SELECT r.ORG_SEQ,r.ORGNAME,
     COUNT(r.EID) EmpCount,
     SUM(r.IS_ELIG) EligCount,
     SUM(DECODE(NVL(r.ADJ_INC,0),0,0,1)) AdjIncEmpSum,
     SUM(DECODE(NVL(r.ADJ_INC,0),0,0,r.ADJ_INC)) AdjIncSum,
     SUM(DECODE(NVL(r.ADJ_INC,0),0,0,r.FT_SAL)) FTSalSum

 FROM TMP_INCROLLUP r
 GROUP BY r.ORG_SEQ,r.ORGNAME
 ORDER BY r.ORG_SEQ
)o;
  
open p_jobChange for 
SELECT o.*
    ,SUM(o.EmpCount) over() EmpCountSUM
    ,SUM(o.EligCount) over() EligCountSUM
    ,SUM(o.ChangeJobEmpSum) over() ChangeJobEmpSumSUM
    ,SUM(o.TotalIncSum) over() TotalIncSumTotal
    ,SUM(o.FTSalSum) over() FTSalSumTotal
    ,Hrshared.getPercent(o.ChangeJobEmpSum,o.EligCount) ChangeJobPercent,
    Hrshared.getPercent(o.TotalIncSum,o.FTSalSum) AvgTotalIncrease
FROM(
 SELECT r.ORG_SEQ,r.ORGNAME,
     COUNT(r.EID) EmpCount,
     SUM(r.IS_ELIG) EligCount,
     SUM(DECODE(NVL(r.IS_JOBCHANGE,0),0,0,1)) ChangeJobEmpSum,
     SUM(DECODE(NVL(r.IS_JOBCHANGE,0),0,0,r.PA_INC + r.MERIT_INC + r.ADJ_INC)) TotalIncSum,
     SUM(DECODE(NVL(r.PA_INC + r.MERIT_INC + r.ADJ_INC,0),0,0,r.FT_SAL)) FTSalSum
 FROM TMP_INCROLLUP r
 GROUP BY r.ORG_SEQ,r.ORGNAME
 ORDER BY r.ORG_SEQ
)o;

  
  
end IncreaseRollup;








/* -- ////////////////////////// -- */
PROCEDURE putSPTempData(
  p_orgseq NUMBER,
  p_OrgName VARCHAR2,
  p_EmpCount NUMBER default 0,
  p_EligCount NUMBER default 0,
  p_IncCount NUMBER default 0,
  p_MeritBudgeted NUMBER default 0,
  p_MeritAllocated NUMBER default 0,
  p_Meritholdbacks NUMBER default 0,
  p_PABudgeted NUMBER default 0,
  p_PAAllocated NUMBER default 0,
  p_PAHoldbacks NUMBER default 0,
  p_CurrentPayroll NUMBER default 0,
  p_NewPayroll NUMBER default 0) IS

  v_MeritAvailable NUMBER := 0;
  v_MeritRemaining NUMBER := 0;
  v_PAAvailable NUMBER := 0;
  v_PARemaining NUMBER :=0;

BEGIN

  v_MeritAvailable := p_MeritBudgeted - ( p_MeritBudgeted * p_Meritholdbacks / 100);
  v_MeritRemaining := v_MeritAvailable - p_MeritAllocated;
  v_PAAvailable := p_PABudgeted - ( p_PABudgeted * p_PAHoldbacks / 100);
  v_PARemaining := v_PAAvailable - p_PAAllocated;

INSERT INTO TMP_ROLLUP (
   ORG_SEQ, ORG_NAME, EMP_COUNT,
   ELIG_COUNT, INCR_COUNT,
   MERIT_BUDGETED, MERIT_AVAILABLE, MERIT_ALLOCATED,
   PA_BUDGETED, PA_AVAILABLE, PA_ALLOCATED,
   CURRENT_PAYROLLUSD,
   NEW_PAYROLLUSD, MERIT_HB, PA_HB)
VALUES (
   p_orgseq, p_OrgName, p_EmpCount,
   p_EligCount,
   p_IncCount
    ,p_MeritBudgeted
    ,v_MeritAvailable
    ,p_MeritAllocated
    ,p_PABudgeted
    ,v_PAAvailable
    ,p_PAAllocated
   
   ,NVL(p_CurrentPayroll,0)
   ,NVL(p_NewPayroll,0)
   ,p_Meritholdbacks
   ,p_PAHoldbacks
 );

END putSPTempData;

PROCEDURE putICPTempData(
  p_orgseq NUMBER,
  p_OrgName VARCHAR2,
  p_EmpCount NUMBER default 0,
  p_EligCount NUMBER default 0,
  p_IncCount NUMBER default 0,
  p_ICPBudgeted NUMBER default 0,
  p_ICPAllocated NUMBER default 0,
  p_ICPholdbacks NUMBER default 0) IS

  v_ICPAvailable NUMBER := 0;
  v_ICPRemaining NUMBER := 0;
  v_PAAvailable NUMBER := 0;
  v_PARemaining NUMBER :=0;

BEGIN

  v_ICPAvailable := p_ICPBudgeted - ( p_ICPBudgeted * p_ICPholdbacks / 100);

INSERT INTO TMP_ROLLUP (
   ORG_SEQ, ORG_NAME, EMP_COUNT,
   ELIG_COUNT, INCR_COUNT,
   ICP_BUDGETED, ICP_AVAILABLE, ICP_ALLOCATED, ICP_HBAMT, ICP_HB)
VALUES (p_orgseq, p_OrgName, p_EmpCount,
  p_EligCount, p_IncCount
  ,p_ICPBudgeted
  ,v_ICPAvailable
  ,p_ICPAllocated
  ,p_ICPBudgeted * p_ICPholdbacks / 100  
  ,p_ICPholdbacks
  );

END putICPTempData;

FUNCTION getSPRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor
AS mycurs sys_refcursor;

v_sql varchar2(4000) := 
  'SELECT d.cycleid, count(1) over() as empcount'      
      || '  ,d.compEmp.eligibility.isSalaryEligible EligibleCount'
      || '  ,case  when d.compEmp.eligibility.isSalaryEligible = 1 and ( NVL(d.compInput.MeritAmt, 0) > 0 or NVL(d.compInput.AdjustmentAmt,0) > 0 ) then 1 else 0 end as RecIncCount '
      || '  ,decode(d.compEmp.Eligibility.GeneratesSalary,0,0,'
      || '      NVL((d.compEmp.FTSalary * treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).MeritPercModifier) * d.compEmp.CurrencyUSD / 100,0)'
      || '  ) MeritBudgeted'     
      || '  ,decode(d.compEmp.Eligibility.GeneratesSalary,0,0,'
      || '    (NVL(d.compInput.MeritAmt, 0) + NVL(d.compInput.LumpSumAmt, 0)) * d.compEmp.CurrencyUSD'
      || '  ) MeritAllocated '      
      || '  ,decode(d.compEmp.Eligibility.GeneratesSalary,0,0,'
      || '    NVL((d.compEmp.FTSalary  * treat(deref(d.recSalary.MeritPAMod) as ngt_meritpamod).PAPercModifier) * d.compEmp.CurrencyUSD / 100, 0)'
      || '  ) PABudgeted'     
      || '  ,decode(d.compEmp.Eligibility.GeneratesSalary,0,0,'
      || '    (NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0)) * d.compEmp.CurrencyUSD'
      || '  ) PAAllocated' 
      || '  ,(NVL(d.compEmp.FTSalary,0) * NVL(d.compEmp.percentTimeWorked,100) ) * d.compEmp.CurrencyUSD AnnualSalary'
      || '  ,(decode(d.compEmp.eligibility.isSalaryEligible,0,nvl(d.compEmp.FTSalary,0)'
      || '  ,decode(nvl(d.compInput.LumpSumAmt,0),0'
      || '      ,NVL(d.compEmp.FTSalary,0) + NVL(d.compInput.MeritAmt,0) + NVL(d.compInput.AdjustmentAmt,0) + NVL(d.compInput.PromotionAmt,0)'
      || '        ,nvl(d.compEmp.FTSalary,0) ) ) * NVL(d.compEmp.percentTimeWorked,100) ) * d.compEmp.CurrencyUSD AnnualSalaryNew'    
      || '  FROM hr_compOrg d  WHERE   d.cycleid = ' || p_CycleID ;



begin

  if p_OrgType = 0 then -- total reports
    
    v_sql := v_sql 
        || ' START WITH d.managerid = ' || p_Managerid
        || '  CONNECT BY PRIOR d.eid = d.managerid'
        || '    AND PRIOR d.cycleid = ' || p_CycleID;
    
  else -- direct reports
    
    v_sql := v_sql 
      || 'AND d.managerid = ' || p_Managerid;
      
  end if;
  
  -- Now add the sums
  v_sql := 
    'select o.cycleid ' 
    || '  ,max(o.empcount) EmpCount'
    || '  ,sum(o.EligibleCount) EligibleCount'
    || '  ,sum(o.RecIncCount) RecIncCount'
    || '  ,sum(o.MeritBudgeted) MeritBudgeted'
    || '  ,sum(o.MeritAllocated) MeritAllocated'
    || '  ,sum(o.PABudgeted) PABudgeted'
    || '  ,sum(o.PAAllocated) PAAllocated'
    || '  ,sum(o.AnnualSalary) CurrentPayroll'
    || '  ,sum(o.AnnualSalaryNew) NewPayroll ' 
    || '  from (' || v_sql 
                  || ') o group by o.cycleid'; 
  
  
  
  open mycurs for v_sql;
  RETURN mycurs;
  
end getSPRollupOrg;

FUNCTION getICPRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor 
AS mycurs sys_refcursor;

v_sql varchar2(4000) := 
  'SELECT d.cycleid, count(1) over() as empcount'      
      || '  ,d.compEmp.eligibility.isICPEligible EligibleCount'
      || '  ,case  when d.compEmp.eligibility.isICPEligible = 1 and NVL(d.compInput.ICPAward, 0) > 0 then 1 else 0 end as RecIncCount '    
      || '  ,decode(d.compEmp.Eligibility.GeneratesICP,0,0,   '   
      || '    (treat(deref(d.recICP.icpMod) as ngt_icpMod).ICPCompanyMod * treat(deref(d.recICP.icpMod) as ngt_icpMod).ICPIndivMod) /100' 
      || '    * ((d.compEmp.ICPSalary * d.compEmp.ICPTargetPercent /100) * d.compEmp.CurrencyUSD)'
      || '  ) ICPBudgeted'
      || '  ,decode(d.compEmp.Eligibility.GeneratesICP,0,0,'
      || '    d.compInput.ICPAward *  d.compEmp.CurrencyUSD  '  
      || '  ) ICPAllocated  '
      || '  FROM hr_compOrg d  WHERE   d.cycleid = ' || p_CycleID ;

   
begin

  if p_OrgType = 0 then -- total reports
    
    v_sql := v_sql 
        || ' START WITH d.managerid = ' || p_Managerid
        || '  CONNECT BY PRIOR d.eid = d.managerid'
        || '    AND PRIOR d.cycleid = ' || p_CycleID;
    
  else -- direct reports
    
    v_sql := v_sql 
      || 'AND d.managerid = ' || p_Managerid;
      
  end if;
  
  -- Now add the sums
  v_sql := 
    'select o.cycleid' 
    || '  ,max(o.empcount) EmpCount'
    || '  ,sum(o.EligibleCount) EligibleCount'
    || '  ,sum(o.RecIncCount) RecIncCountTotal'
    || '  ,sum(o.ICPBudgeted) ICPBudgeted'
    || '  ,sum(o.ICPAllocated) ICPAllocated '
    || '   from (' || v_sql 
                  || ') o group by o.cycleid';   
  
  
  open mycurs for v_sql;
  RETURN mycurs;
  
end getICPRollupOrg;   

FUNCTION getLTIRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor 
AS mycurs sys_refcursor;

v_sql varchar2(4000) := 
  'SELECT d.cycleid, count(1) over() as empcount'      
      || '  ,d.compEmp.eligibility.isLTIEligible EligibleCount'
      || '  ,case  when d.compEmp.eligibility.isLTIEligible = 1 and NVL(d.compInput.LTIGrantAmt, 0) > 0 then 1 else 0 end as RecIncCount '    
      || '  ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,'
      || '    d.recLTI.LTIGuidelines.TargetGrant * d.recLTI.LTIGuidelines.ParticRate / 100'
      || '  ) LTIBudgeted '
      || '  ,decode(d.compEmp.Eligibility.GeneratesLTI,0,0,'
      || '    d.compInput.LTIGrantAmt'
      || '  ) LTIAllocated '
      || '  FROM hr_compOrg d  WHERE   d.cycleid = ' || p_CycleID ;

  
begin

  if p_OrgType = 0 then -- total reports
    
    v_sql := v_sql 
        || ' START WITH d.managerid = ' || p_Managerid
        || '  CONNECT BY PRIOR d.eid = d.managerid'
        || '    AND PRIOR d.cycleid = ' || p_CycleID;
    
  else -- direct reports
    
    v_sql := v_sql 
      || 'AND d.managerid = ' || p_Managerid;
      
  end if;
  
  -- Now add the sums
  v_sql := 
    'select o.cycleid' 
    || '  ,max(o.empcount) EmpCount'
    || '  ,sum(o.EligibleCount) EligibleCount'
    || '  ,sum(o.RecIncCount) RecIncCountTotal'
    || '  ,sum(o.LTIBudgeted) LTIBudgeted'
    || '  ,sum(o.LTIAllocated) LTIAllocated '
    || '   from (' || v_sql 
                  || ') o group by o.cycleid';   
  
  
  open mycurs for v_sql;
  RETURN mycurs;
  
end getLTIRollupOrg; 

FUNCTION getIncRollupOrg (
    p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER) RETURN sys_refcursor
AS mycurs sys_refcursor; 

v_sql varchar2(4000) := 
  'select d.eid ,d.empName'
  ||  ',d.compEmp.eligibility.isSalaryEligible SalaryEligible'
  ||  ',d.compEmp.JobCode JobCode'
  ||  ',d.compEmp.contributionCalibration contribution'
  ||  ',d.compEmp.potentialCalibration   potential'
  ||  ',d.compEmp.FTSalary * d.compEmp.CurrencyUSD ftsalaryUSD'
  ||  ',d.compEmp.CurrencyUSD currencyUSD'
  ||  ',d.compInput.MeritAmt * d.compEmp.CurrencyUSD meritIncUSD'
  ||  ',d.compInput.PromotionAmt * d.compEmp.CurrencyUSD promIncUSD'
  ||  ',d.compInput.AdjustmentAmt  * d.compEmp.CurrencyUSD  AdjIncUSD'
  ||  ',d.compInput.ICPAward * d.compEmp.CurrencyUSD ICPIncUSD'
  ||  ',d.compInput.NewJobCode newjobcode '
  ||  ',case when d.compInput.NewJobCode is not null and d.compEmp.JobCode != d.compInput.NewJobCode then 1 else 0 end as isJobChange'
  ||  ',case when d.compInput.NewJobCode is not null and d.compInput.NewJobInfo.JobLevel > j.job_level then 1 else 0 end as isPromotion'
  ||  ',d.compEmp.eligibility.isICPEligible icpeligible'
  ||  ',d.compInput.ICPIndivModifier icpindivmodifiernew ' 
  ||  ',case when d.compInput.NewJobCode is not null and d.compEmp.JobCode != d.compInput.NewJobCode then d.compInput.NewJobInfo.midFTE else d.recSalary.JobMarketData.midFTE end as midFTE'
  || '  FROM hr_compOrg d, hr_jobs j WHERE d.compEmp.JobCode = j.job_code(+) AND d.cycleid = ' || p_CycleID ;

   
begin

  if p_OrgType = 0 then -- total reports
    
    v_sql := v_sql 
        || ' START WITH d.managerid = ' || p_Managerid
        || '  CONNECT BY PRIOR d.eid = d.managerid'
        || '    AND PRIOR d.cycleid = ' || p_CycleID;
    
  else -- direct reports
    
    v_sql := v_sql 
      || 'AND d.managerid = ' || p_Managerid;
      
  end if;
  
  open mycurs for v_sql;
  RETURN mycurs;
  
end getIncRollupOrg;



PROCEDURE putIncRollup(
  p_orgseq NUMBER,
  p_OrgName VARCHAR2,
  p_EmployeeID NUMBER,
  p_isElig NUMBER,
  p_Rating VARCHAR2,
  p_TARating VARCHAR2,
  p_MeritInc NUMBER,
  p_PAInc NUMBER,
  p_IsPromo INT DEFAULT 0,
  p_IsJobChange INT DEFAULT 0,
  p_AdjInc NUMBER,
  p_FTSalary NUMBER,
  p_NewICPIndMod FLOAT,
  p_ICPElig INT DEFAULT 0,
  p_NewJobCode VARCHAR2,
  p_MidFTE NUMBER DEFAULT 0
  ,p_icpAward number default 0) IS

BEGIN

INSERT INTO TMP_INCROLLUP (
   ORG_SEQ, ORGNAME, EID,
   IS_ELIG, RATING, RATING_ID, MERIT_INC,
   PA_INC, ADJ_INC, FT_SAL, NEW_FT_SAL,
   IS_PROMOTION, NEW_JOBCODE, MID_FTE, IS_JOBCHANGE, TARATING, newICP_IndMod, ICP_ELIG, icp_award)
VALUES ( p_orgseq,p_OrgName, p_EmployeeID,
  NVL(p_isElig,0), NVL(p_Rating,'Not Calibrated'),
  Hrshared.getRatingID(NVL(p_Rating,'Not Calibrated')),
  DECODE(NVL(p_IsElig,0),0,0,NVL(p_MeritInc,0)),
  DECODE(NVL(p_IsElig,0),0,0,NVL(p_PAInc,0)),
  DECODE(NVL(p_IsElig,0),0,0,NVL(p_AdjInc,0)),
  NVL(p_FTSalary,0),
  DECODE(NVL(p_IsElig,0),0,0,NVL(p_MeritInc,0))
  + DECODE(NVL(p_IsElig,0),0,0,NVL(p_AdjInc,0))
  + DECODE(NVL(p_IsElig,0),0,0,NVL(p_PAInc,0))
  + NVL(p_FTSalary,0),
  p_IsPromo,
  p_NewJobCode,
  p_MidFTE,
  NVL(p_IsJobChange,0),
  NVL(p_TARating,'0:0'),
  DECODE(p_ICPElig,1, p_NewICPIndMod,0),
  NVL(p_ICPElig,0)
  ,p_icpAward
  );
  
END putIncRollup;
   

END ng_compRollup;
/
