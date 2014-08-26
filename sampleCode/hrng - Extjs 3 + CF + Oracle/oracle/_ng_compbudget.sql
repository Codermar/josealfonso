set define off;
create or replace
PACKAGE           ng_compbudget 
AS

  meritcomptypeid   CONSTANT INTEGER := 1;
  pacomptypeid      CONSTANT INTEGER := 2;
  icpcomptypeid     CONSTANT INTEGER := 3;
  GrantCompTypeId   CONSTANT INTEGER := 10;
  

CURSOR c_CompData(p_EmployeeID NUMBER, p_CycleID NUMBER) IS
	SELECT
      CD.FULL_TIME_SALARY  FTSalary,
      cd.SALARY_CURRENCY_IDFK Currency,
      cd.JOB_CODE_IDFK JobCode,
      cd.CYCLE_GRADE CareerBand,
      cd.CA_IDFK CAID,
      cd.PA_IDFK PAID,
      ng_shared.getCompanyIDFromPA(cd.PA_IDFK) CompanyID,
      cd.ORG_UNIT_CODE,
      NVL(cd.PERCENT_TIME_WORKED,100) PERCENT_TIME_WORKED,
      cd.last_hire_date MRHireDate,
      decode(cd.ICP_TARGET_PERC_FORCALC,null,cd.ICP_TARGET_PERCENT, cd.ICP_TARGET_PERC_FORCALC) ICPTargetPercent,
      cd.EMPLOYMENT_COUNTRY_TXT,
      co.MERIT_AMT MeritAmount,
      co.MERIT_PERCENT,
      co.LUMPSUM_AMT LumpSumAmount,
      co.LUMPSUM_PERCENT LumpSumPercent,
      co.ADJUSTMENT_AMT AdjustmentAmount,
      co.ADJUSTMENT_PERCENT AdjustmentPercent,
      co.PROMOTION_AMT PromotionAmount,
      co.PROMOTION_PERCENT PromotionPercent,
      NVL(co.CONTRIBUTION_CALIBRATION,'Not Calibrated') CONTRIBUTION_CALIBRATION,
      NVL(co.ICP_INDIV_MOD_NEW,0) NewICPIndivModifier,
      cd.EARNINGS_ELIGIBLE EarningsEligible,
      co.grant_amt GrantAmount,
      co.grant_modifier_perc GrantModifierPerc,
      co.icp_award_amt ICPAmount,
      co.icp_salary ICPSalary
      
    FROM  HR_CYCLE_DATA cd,
		  HR_CYCLE_COMP co
    WHERE cd.EMP_IDFK = co.EMP_IDFK(+)
	AND cd.FY_CYCLE_IDFK = co.FY_CYCLE_IDFK(+)
	AND cd.FY_CYCLE_IDFK = p_CycleID
 AND  cd.EMP_IDFK = p_EmployeeID;


PROCEDURE getManagerCompBudget ( 
      p_cursor      IN OUT   Globals.genrefcursor,
      p_managerid            NUMBER,
      p_cycleid              NUMBER,
      p_doEquity in int default 1);
   
   
end ng_compbudget;
/

create or replace
PACKAGE BODY         ng_compbudget 
AS

  
PROCEDURE getManagerCompBudget ( 
      p_cursor      IN OUT   Globals.genrefcursor,
      p_managerid            NUMBER,
      p_cycleid              NUMBER,
      p_doEquity in int default 1) IS

  v_GrantBudgeted float := 0;
  v_GrantAvailableTotal float := 0;
  v_Grant_Pool float := 0;
  v_Grant_Allocated float := 0;
  v_GrantAllocatedTotal float := 0;
  
  v_MeritBudgeted float := 0;
  v_MeritAvailableTotal float := 0;
  v_Merit_Pool float := 0;
  v_Merit_Allocated float := 0;
  v_MeritAllocatedTotal float := 0;
  
  v_PABudgeted float := 0;
  v_PAAvailableTotal float := 0;
  v_PA_Pool float := 0;
  v_PA_Allocated float := 0;
  v_PAAllocatedTotal float := 0;

  v_ICPBudgeted float := 0;
  v_ICPAvailableTotal float := 0;
  v_ICP_Pool float := 0;
  v_ICP_Allocated float := 0;
  v_ICPAllocatedTotal float := 0;
  
  v_Holdbacks_Merit  FLOAT := 0;
	v_Holdbacks_PA     FLOAT := 0;
  v_Holdbacks_ICP   Float := 0;
  v_Holdbacks_grant    FLOAT := 0;
  
  gen_refcur  SYS_REFCURSOR;
  EmpRecord   ng_org.EmpCycleRecType;
  
  r_elegibility ng_shared.c_Eligibility%ROWTYPE;
  r_guidelines ng_shared.c_EquityGuidelines%rowtype;
  r_compdata c_compdata%rowtype;
  r_MeritPAModifier ng_shared.c_getMeritPAModifier%rowtype;
  r_ICPModifiers ng_shared.c_getICPModifier%rowtype;
  
BEGIN      

     -- First we need to get the holdbacks (for all 3 CompTypes, Merit 1, ICP 3 and LTI 10)
    FOR r_hold IN ng_shared.c_GetHoldback(p_CycleID,p_ManagerID) LOOP
        IF r_hold.CompTypeID = MeritCompTypeID THEN
         v_Holdbacks_Merit := r_hold.HoldbackQty;
       ELSIF r_hold.CompTypeID = PACompTypeID THEN
         v_Holdbacks_PA := r_hold.HoldbackQty;
       ELSIF r_hold.CompTypeID = ICPCompTypeID THEN
         v_Holdbacks_ICP := r_hold.HoldbackQty;
       ELSIF r_hold.CompTypeID = GrantCompTypeId THEN
         v_Holdbacks_grant := r_hold.HoldbackQty;  
       END IF;
    END LOOP;
     
      -- global icp modifier for all
      OPEN ng_shared.c_getICPModifier(p_CycleID);
      FETCH ng_shared.c_getICPModifier INTO r_ICPModifiers;
      CLOSE ng_shared.c_getICPModifier;
     
     
     
  -- get the organization (total reports for the budget)
   gen_refcur := ng_org.getOrg(p_ManagerID,p_CycleID,0); -- 0 = total reports
   
    LOOP
        FETCH gen_refcur INTO EmpRecord;
        EXIT WHEN gen_refcur%NOTFOUND;

        -- reset values
        v_GrantBudgeted := 0;
        v_Grant_Allocated := 0;
        v_MeritBudgeted := 0;
        v_Merit_Allocated := 0;
        v_PABudgeted := 0;
        v_PA_Allocated := 0;
        v_ICPBudgeted := 0;
        v_ICP_Allocated := 0;
        
        
        /* DOC: ng_shared.c_Eligibility:
          Returns Elegibility Information in a grouped row with all required values, defaults to 0 if no record is found 
          The following values can then be used:
          
          r_elegibility.IsSalEligible;
          r_elegibility.IsICPEligible;
          r_elegibility.IsLTIEligible;
          
          r_elegibility.GeneratesSalBudget;
          r_elegibility.GeneratesICPBudget;
          r_elegibility.GeneratesLTIBudget
        */ 
          
          OPEN ng_shared.c_Eligibility(p_CycleID,EmpRecord.EmployeeID);
          FETCH ng_shared.c_Eligibility INTO r_elegibility;
          CLOSE ng_shared.c_Eligibility;

        
      
          -- compdata for the employee, this includes all comp data collected
          OPEN c_CompData(EmpRecord.EmployeeID,p_CycleID);
          FETCH c_CompData INTO r_compdata;
          CLOSE c_CompData;
    
    
    
    /* //// salicp section //// */
    
    -- /// Merit/Prom/Adj ///
    if r_elegibility.IsSalEligible = 1 then
      
      -- merit modifiers is by CAID 
        OPEN ng_shared.c_getMeritPAModifier(p_CycleID,EmpRecord.CAID);
        FETCH ng_shared.c_getMeritPAModifier INTO r_MeritPAModifier;
        CLOSE ng_shared.c_getMeritPAModifier;
      
      -- EmpRecord.CurrencyUSD
    
      IF r_elegibility.GeneratesSalBudget = 1 THEN
        
        -- QUestion: is the budgeted here supposed to be FT salary or Annual salary as shown in previous app?
        v_MeritBudgeted  := NVL(r_compdata.FTSalary * r_MeritPAModifier.MeritPercModifier * EmpRecord.CurrencyUSD / 100,0);
        -- Merit: QUestion: is this right? sum the lump sum to the merit?
        -- TODO: Review this:
        v_Merit_Allocated :=   NVL(r_compdata.MeritAmount, 0) + NVL(r_compdata.LumpSumAmount, 0);
        
        -- PA
        v_PABudgeted := NVL(r_compdata.FTSalary  * r_MeritPAModifier.PAPercModifier * EmpRecord.CurrencyUSD / 100, 0);
        v_PA_Allocated :=  (NVL(r_compdata.AdjustmentAmount,0) + NVL(r_compdata.PromotionAmount,0)) * EmpRecord.CurrencyUSD;
        
        -- testing
        -- pt(EmpRecord.SalCurrency,EmpRecord.Employeeid,EmpRecord.CurrencyUSD,v_MeritBudgeted,r_MeritPAModifier.MeritPercModifier,EmpRecord.CAID,r_compdata.FTSalary);
        
        
        
      END IF; -- eo r_elegibility.GeneratesSalBudget = 1
    
    end if; -- eo r_elegibility.IsSalEligible = 1
    
    -- /// ICP ///
    if r_elegibility.IsICPEligible = 1 then
        -- New formula: ICP Funding Level X ICP Earnings X ICP Target 
        v_ICPBudgeted := NVL((r_ICPModifiers.ICPFundingLevel/100) * r_compdata.EarningsEligible * r_compdata.ICPTargetPercent  * EmpRecord.CurrencyUSD ,0);
        v_ICP_Allocated := NVL(r_compdata.EarningsEligible * r_compdata.ICPTargetPercent * (r_ICPModifiers.ICPBusinessModifier /100) 
                                    * (r_compdata.NewICPIndivModifier /100) * EmpRecord.CurrencyUSD ,0);
        --v_ICPAward := NVL(r_compdata.EarningsEligible,0) * NVL(r_ICPModifiers.ICPBusinessModifier/100,0) * NVL(r_compdata.ICPTargetPercent,0) * NVL(r_compdata.NewICPIndivModifier/100,0);
  
    end if; -- oe r_elegibility.IsICPEligible
    
    
    -- running totals
    v_Merit_Pool := v_Merit_Pool + NVL(v_MeritBudgeted,0);
    v_MeritAllocatedTotal := v_MeritAllocatedTotal + NVL(v_Merit_Allocated,0);
    v_PA_Pool := v_PA_Pool + NVL(v_PABudgeted,0);
    v_PAAllocatedTotal := v_PAAllocatedTotal + NVL(v_PA_Allocated,0);
    v_ICP_Pool := v_ICP_Pool + NVL(v_ICPBudgeted,0);
    v_ICPAllocatedTotal := v_ICPAllocatedTotal + NVL(v_ICP_Allocated,0);
    
    
    
    /* //// Equity section //// */
    -- Only gather equity info if manager is allowed
    if p_doEquity = 1 then
    
      OPEN ng_shared.c_EquityGuidelines(EmpREcord.CompLevelID,p_CycleID);
      FETCH ng_shared.c_EquityGuidelines INTO r_guidelines;
      CLOSE ng_shared.c_EquityGuidelines;


      IF r_elegibility.GeneratesLTIBudget = 1 THEN
      
         -- p_ParticRate := r_guidelines.ParticRate;
          v_GrantBudgeted := r_guidelines.TargetGrant * r_guidelines.ParticRate / 100;
          
          IF r_elegibility.IsLTIEligible = 1  THEN
           v_Grant_Allocated := r_compdata.GrantAmount;
          END IF; -- r_elegibility.IsLTIEligible
          
      END IF; -- EO r_elegibility.GeneratesLTIBudget

          -- running totals
          v_Grant_Pool := v_Grant_Pool + NVL(v_GrantBudgeted,0);
          v_GrantAllocatedTotal := v_GrantAllocatedTotal + NVL(v_Grant_Allocated,0);
    
    end if; -- eo p_doEquity
    
    
    
     --put_trace(r_elegibility.IsLTIEligible,EmpRecord.EmployeeID,'eligible: ' || r_elegibility.IsLTIEligible || ' budgeted: ' || v_GrantBudgeted || ' allocated:' || v_Grant_Allocated);
          
    END LOOP; -- eo loop over employees
    
    
    -- running totals
    if p_doEquity = 1 then  
      v_GrantAvailableTotal  :=  v_Grant_Pool - (v_Grant_Pool  * v_Holdbacks_grant / 100 );      
    end if; --
    
    v_MeritAvailableTotal  :=  v_Merit_Pool - (v_Merit_Pool  * v_Holdbacks_Merit / 100 );
    v_PAAvailableTotal  :=  v_PA_Pool - (v_PA_Pool  * v_Holdbacks_PA / 100 );
    v_ICPAvailableTotal  :=  v_ICP_Pool - (v_ICP_Pool  * v_Holdbacks_ICP / 100 );
    
    
   /*  -- test budget table */
      delete from TST_COMPBUDGET;
      -- equity
      Insert into TST_COMPBUDGET (MANAGERID,CYCLEID,COMPTYPEID,BudgetPool,AUTHORIZEDPOOL,ALLOCATED,HOLDBACK,HOLDBACKAMT) 
      values (p_ManagerID,p_CycleID,10,v_Grant_Pool,v_GrantAvailableTotal,v_GrantAllocatedTotal,v_Holdbacks_grant,(v_Grant_Pool  * v_Holdbacks_grant / 100 ));
      -- merit
      Insert into TST_COMPBUDGET (MANAGERID,CYCLEID,COMPTYPEID,BudgetPool,AUTHORIZEDPOOL,ALLOCATED,HOLDBACK,HOLDBACKAMT) 
      values (p_ManagerID,p_CycleID,1,v_Merit_Pool,v_MeritAvailableTotal,v_MeritAllocatedTotal,v_Holdbacks_Merit,(v_Merit_Pool  * v_Holdbacks_Merit / 100 ));
      -- PA
      Insert into TST_COMPBUDGET (MANAGERID,CYCLEID,COMPTYPEID,BudgetPool,AUTHORIZEDPOOL,ALLOCATED,HOLDBACK,HOLDBACKAMT) 
      values (p_ManagerID,p_CycleID,2,v_PA_Pool,v_PAAvailableTotal,v_PAAllocatedTotal,v_Holdbacks_PA,(v_PA_Pool  * v_Holdbacks_PA / 100 ));
      -- ICP
      Insert into TST_COMPBUDGET (MANAGERID,CYCLEID,COMPTYPEID,BudgetPool,AUTHORIZEDPOOL,ALLOCATED,HOLDBACK,HOLDBACKAMT) 
      values (p_ManagerID,p_CycleID,3,v_ICP_Pool,v_ICPAvailableTotal,v_ICPAllocatedTotal,v_Holdbacks_ICP,(v_ICP_Pool  * v_Holdbacks_ICP / 100 ));
    
          

   OPEN p_cursor FOR
   SELECT 
      'Budget Pool' as item,
      NVL(v_Merit_Pool,0) AS Merit,
      NVL(v_PA_Pool,0) as PA,
      NVL(v_ICP_Pool,0) as ICP,
      NVL(v_Grant_Pool,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Authorized Pool' as item,
      NVL(v_MeritAvailableTotal,0) AS Merit,
      NVL(v_PAAvailableTotal,0) as PA,
      NVL(v_ICPAvailableTotal,0) as ICP,
      NVL(v_GrantAvailableTotal,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Allocated' as item,
      NVL(v_MeritAllocatedTotal,0) AS Merit,
      NVL(v_PAAllocatedTotal,0) as PA,
      NVL(v_ICPAllocatedTotal,0) as ICP,
      NVL(v_GrantAllocatedTotal,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Over/Under' as item,
      NVL(v_MeritAvailableTotal,0) - NVL(v_MeritAllocatedTotal,0) AS Merit,
      NVL(v_PAAvailableTotal,0) - NVL(v_PAAllocatedTotal,0) as PA,
      NVL(v_ICPAvailableTotal,0) - NVL(v_ICPAllocatedTotal,0) as ICP,
      NVL(v_GrantAvailableTotal,0) - NVL(v_GrantAllocatedTotal,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Holdback' as item,
      NVL(v_Holdbacks_Merit,0) AS Merit,
      NVL(v_Holdbacks_PA,0) as PA,
      NVL(v_Holdbacks_ICP,0) as ICP,
      NVL(v_Holdbacks_grant,0) AS LTI
  FROM DUAL
  UNION ALL
     SELECT 
      'Holdback Amount' as item,
      (v_Merit_Pool  * v_Holdbacks_Merit / 100 ) AS Merit,
      (v_PA_Pool  * v_Holdbacks_PA / 100 ) as PA,
      (v_ICP_Pool  * v_Holdbacks_ICP / 100 ) as ICP,
      (v_Grant_Pool  * v_Holdbacks_grant / 100 ) AS LTI
  FROM DUAL;
   
END getManagerCompBudget;

   
end ng_compbudget;
/
