
/*
  ng_compEmpBody 
  Saves cycle information for comp employees

*/

CREATE or replace TYPE BODY ngt_compEmp AS

  constructor function ngt_compEmp (
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
      
  )return self as result is
    
    
  begin
      
      self.cached := cached;
      self.EID := EID;
      self.cycleID := cycleID; 
      self.managerID := managerID;
      self.careerBand := careerBand;
      self.PAID := PAID;
      self.CAID := CAID;
      self.compLevelID := compLevelID;
      self.payScaleLevel := payScaleLevel;
      self.EmploymentGroup := EmploymentGroup;
      self.EmploymentPayType := EmploymentPayType;
      self.jobCode := jobCode;
      self.mrhiredate := mrhiredate;
      self.FTsalary := FTsalary;
      self.yearlyPayPeriods := yearlyPayPeriods;
      self.percentTimeWorked := percentTimeWorked;
      self.salCurrency := salCurrency;
      self.currencyUSD := currencyUSD;
      self.compensationGroup := compensationGroup; 
      self.ICPTargetPercent := ICPTargetPercent;
      self.ICPIndivModifier := ICPIndivModifier;
      self.ICPSalary := ICPSalary;
      self.orgUnitCode := orgUnitCode; 
      self.EmploymentLocation := EmploymentLocation;
      self.employmentCountry := employmentCountry;
      self.contributionCalibration := contributionCalibration;
      self.potentialCalibration := potentialCalibration;
      
      self.contributionCalibrationprev := contributionCalibrationprev;
      self.potentialCalibrationprev := potentialCalibrationprev;
      
      self.UnvestedSharesValue := UnvestedSharesValue;
      self.directReports := directReports;
      self.totalReports := totalReports;
      
      self.BridgedServiceDate := BridgedServiceDate;
      self.InJobDate  := InJobDate; 
      self.LastLOA  := LastLOA;
      self.LastIncreaseDate  := LastIncreaseDate;
      self.LastIncreasePercent  := LastIncreasePercent;
      self.CostCenterCode  := CostCenterCode;
      self.CompGlobalRegion  := CompGlobalRegion;
      
      self.isEligibilityUpdatable := isEligibilityUpdatable;
      self.isRecordUpdatable := isRecordUpdatable; 
      self.forceLoad := forceLoad;
      self.eligibility := eligibility;
      
      if forceLoad = 1 then self := get(); end if;
      
      return;
  end;
  
    -- //// get() ////
    member function get return ngt_compEmp is
      my ngt_compEmp := self;
      emp ngt_compEmp;
      
      cursor ccur is
        select value(t)
          from hr_compEmp t
          where eid = self.eid
          and cycleid = self.cycleid;
    begin
      
      if self.forceLoad = 1 then
        emp := setFromTables();
        emp.save();
      else
      
        open ccur; fetch ccur into emp;
          if ccur%notfound then
            emp := setFromTables();
            emp.save();
          end if;
        close ccur;
      end if;
      
      my := emp;
      
      return my;
      
    end;
    
    -- //// setFromTables() ////
    member function setFromTables return ngt_compEmp is
      
      my ngt_compEmp := self;
      
      cursor c_compInfo is
        SELECT 
               1 as cached
              ,ce.emp_idfk EID
              ,ce.fy_cycle_idfk CycleID
              ,ce.manager_idfk ManagerID
              ,j.job_grade CareerBand
              ,ce.pa_idfk  PAID
              ,ce.CA_IDFK CAID
              ,ce.comp_level_id CompLevelID
              ,to_number(j.job_level) PayScaleLevel
              ,ce.EMPLOYMENT_GROUP_NAME EmploymentGroup
              ,ce.PAY_TYPE EmploymentPayType
              ,ce.job_code_idfk JobCode
              ,ce.MR_HIRE_DATE MRHireDate
              ,ce.full_time_salary FTsalary
              ,NVL(ce.PERCENT_TIME_WORKED,100) / 100 PercentTimeWorked
              ,ce.SALARY_CURRENCY_IDFK SalCurrency
              ,cu.value_in_usd  CurrencyUSD
              ,ce.COMPENSATION_GROUP CompensationGroup
              ,decode(ce.ICP_PERS_TARGET_PERCENT,NULL,ce.ICP_TARGET_PERCENT,ce.ICP_PERS_TARGET_PERCENT) ICPTargetPercent
              ,ce.ICP_LAST_INDIV_MODIFIER ICPIndivModifier
              ,ce.icp_salary ICPSalary
              ,ce.org_unit_codefk orgUnitCode
              ,ce.EMPLOYMENT_LOCATION_TXT EmploymentLocation
              ,ce.employment_country_txt EmploymentCountry
              ,ce.direct_reports DirectReports
              ,ce.total_reports TotalReports
              ,ce.BRIDGED_SERVICE_DATE BridgedServiceDate
              ,ce.IN_JOB_DATE InJobDate
              ,ce.LAST_LOA LastLOA
              ,ce.LAST_INCREASE_DATE LastIncreaseDate
              ,ce.LAST_INCREASE_PERCENT LastIncreasePercent
              ,ce.COST_CENTER_CODE CostCenterCode
              ,ce.YEARLY_PAY_PERIODS YearlyPayPeriods
              ,ce.COMP_GLOBAL_REGION CompGlobalRegion
              ,ce.CONTRIBUTION_CALIBRATION ContributionCalibration
              ,ce.POTENTIAL_CALIBRATION PotentialCalibration
              ,ce.UNVESTED_SHARES_VALUE UnvestedSharesValue 
              ,ce.IS_ELIGIBILITY_UPDATABLE IsEligibilityUpdatable -- determines if eligibility would be updatable 
              ,ce.IS_RECORD_UPDATABLE IsRecordUpdatable
        FROM HR_COMP_EMP ce, hr_jobs j
            ,hr_currencies cu
        WHERE ce.job_code_idfk = j.job_code (+)  
        AND ce.FY_CYCLE_IDFK = self.cycleid
       AND  ce.emp_idfk = self.eid
       AND ce.FY_CYCLE_IDFK = cu.FY_CYCLE_IDFK(+) 
       AND ce.salary_currency_idfk = cu.currency_code(+);
    
      r_emp c_compInfo%rowtype;        
      v_Elig ngt_eligibility := new ngt_eligibility();
      
    begin
      
      if (self.cached=0) then 
        open c_compInfo; fetch c_compInfo into r_emp; close c_compInfo;     
          
          my.managerID := r_emp.ManagerID;
          my.careerBand := r_emp.CareerBand;
          my.PAID := r_emp.PAID;
          my.CAID := r_emp.CAID;
          my.compLevelID := r_emp.CompLevelID;
          my.payScaleLevel := r_emp.PayScaleLevel;
          my.EmploymentGroup := r_emp.EmploymentGroup;
          my.EmploymentPayType := r_emp.EmploymentPayType;
          my.jobCode := r_emp.jobCode;
          my.mrhiredate := r_emp.mrhiredate;
          my.FTsalary := r_emp.FTsalary;
          my.yearlyPayPeriods := r_emp.yearlyPayPeriods;
          my.percentTimeWorked := r_emp.PercentTimeWorked;
          my.salCurrency := r_emp.SalCurrency;
          my.currencyUSD := r_emp.CurrencyUSD;
          my.compensationGroup := r_emp.CompensationGroup;
          my.ICPTargetPercent := r_emp.ICPTargetPercent;
          my.ICPIndivModifier := r_emp.ICPIndivModifier;
          my.ICPSalary := r_emp.ICPSalary;
          my.orgUnitCode := r_emp.orgUnitCode;
          my.employmentCountry := r_emp.EmploymentCountry;
          my.EmploymentLocation := r_emp.EmploymentLocation;
          my.contributionCalibration := r_emp.ContributionCalibration;
          my.potentialCalibration := r_emp.PotentialCalibration;
          my.contributionCalibrationprev := null;
          my.potentialCalibrationprev := null;
          
          my.UnvestedSharesValue  := r_emp.UnvestedSharesValue;
          my.directReports := r_emp.DirectReports;
          my.totalReports := r_emp.TotalReports;
          
          my.BridgedServiceDate := r_emp.BridgedServiceDate;
          my.InJobDate  := r_emp.InJobDate; 
          my.LastLOA  := r_emp.LastLOA;
          my.LastIncreaseDate  := r_emp.LastIncreaseDate;
          my.LastIncreasePercent  := r_emp.LastIncreasePercent;
          my.CostCenterCode  := r_emp.CostCenterCode;
          my.CompGlobalRegion  := r_emp.CompGlobalRegion;
          
          my.isEligibilityUpdatable := r_emp.IsEligibilityUpdatable;
          my.isRecordUpdatable := r_emp.IsRecordUpdatable;
          my.forceLoad := 0;
          my.cached := 1;
          
          v_Elig := New ngt_Eligibility(
               cached => 0
              ,EID =>  self.eid
              ,CycleID => self.cycleid );
              
          v_Elig.setvalues();

          my.eligibility := v_Elig;

       
       end if;
      return my;
    end;
  
  -- //// save() ////
  MEMBER PROCEDURE save IS
   BEGIN
      
      UPDATE hr_compEmp c SET c = self WHERE EID = self.EID and cycleid = self.cycleid;

      IF sql%ROWCOUNT = 0
      THEN
         INSERT INTO hr_compEmp VALUES (self);
      END IF;
  END;
  
   
  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  -- /// getEmpRef() ///
  member function getEmpRef(p_EID number, p_CycleID number) return ref ngt_compEmp 
  is
    v_compEmpRef ref ngt_compEmp;
    v_compEmp ngt_compEmp;
  begin

      BEGIN
        SELECT REF(t) into v_compEmpRef FROM hr_compEmp t WHERE eid = p_EID and cycleid = p_cycleID;
       EXCEPTION
            WHEN OTHERS THEN
            
            
            if SQLERRM = 'ORA-01403: no data found' then -- data not found so try to extract it and save it
             -- DBMS_OUTPUT.put_line ('Failed at first block...' || SQLERRM);
              v_compEmp := New ngt_compEmp(
                   cached => 0
                  ,EID =>  p_eid
                  ,CycleID => p_cycleID
                  ,managerid => 0
                  ,ForceLoad => 1);
              -- save the object
              v_compEmp.save();

            else raise;
            end if;
            
            
            
            begin
              SELECT REF(t) into v_compEmpRef FROM hr_compEmp t WHERE eid = p_eid and cycleid = p_cycleID;
              exception 
                when others then
                
                if SQLERRM = 'ORA-01403: no data found' then
                  v_compEmpRef := NULL;
                else raise;
                end if;

            end;
           
           
      END;

      return v_compEmpRef;
  
  end;
  
  
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'cached='
            || cached
            || '; EID=' || EID
            || '; cycleID=' ||  cycleID
            || '; managerID=' ||  managerID
            || '; careerBand=' ||  careerBand
            || '; PAID=' ||  PAID
            || '; CAID=' ||  CAID
            || '; compLevelID=' ||  compLevelID
            || '; payScaleLevel=' ||  payScaleLevel
            || '; EmploymentPayType=' ||  EmploymentPayType
            || '; jobCode=' ||  jobCode
            || '; mrhiredate=' ||  mrhiredate
            || '; FTsalary=' ||  FTsalary
            || '; percentTimeWorked=' ||  percentTimeWorked
            || '; salCurrency=' ||  salCurrency
            || '; currencyUSD=' ||  currencyUSD
            || '; compensationGroup=' ||  compensationGroup
            || '; ICPTargetPercent=' ||  ICPTargetPercent
            || '; ICPIndivModifier=' ||  ICPIndivModifier
            || '; ICPSalary=' ||  ICPSalary
            || '; yearlyPayPeriods=' ||  yearlyPayPeriods
            
            || '; orgUnitCode=' ||  orgUnitCode
            || '; EmploymentLocation=' ||  EmploymentLocation
            || '; employmentCountry=' ||  employmentCountry
            || '; contributionCalibration=' ||  contributionCalibration
            || '; potentialCalibration=' ||  potentialCalibration
            || '; contributionCalibrationprev=' ||  contributionCalibrationprev
            || '; potentialCalibrationprev=' ||  potentialCalibrationprev
            || '; UnvestedSharesValue=' ||  UnvestedSharesValue
            || '; directReports=' ||  directReports
            || '; totalReports='  ||  totalReports
            
            
            || '; BridgedServiceDate='  ||  BridgedServiceDate
            || '; InJobDate='  ||  InJobDate
            || '; LastLOA='  ||  LastLOA
            || '; LastIncreaseDate='  ||  LastIncreaseDate
            || '; LastIncreasePercent='  ||  LastIncreasePercent
            || '; CostCenterCode='  ||  CostCenterCode
            || '; CompGlobalRegion='  ||  CompGlobalRegion
            
            || '; isEligibilityUpdatable=' ||  isEligibilityUpdatable
            || '; isRecordUpdatable=' ||  isRecordUpdatable
            
             ;
   END;
   
   
end;
/

/* -- test it

set serveroutput on;
declare
  p_CycleID number := 45;
  anEmp ngt_compEmp;
begin
      anEmp := New ngt_compEmp(
           cached => 0
          ,EID =>  106620
          ,CycleID => p_CycleID
          ,managerid => 0
          ,ForceLoad => 1);
      
      anEmp.save();
      
      DBMS_OUTPUT.put_line ('Info: ' || anEmp.setFromTables().print() );
      
      -- anEmp.save();
      -- DBMS_OUTPUT.put_line ('Info: ' || anEmp.get().print() );
end;
 */

