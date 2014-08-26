
create or replace type ngt_eligibility as object(
   cached int
  ,EID number
  ,cycleID number
	,isSalaryEligible int
	,isICPEligible int
	,isLTIEligible int
	,GeneratesSalary int
	,GeneratesICP int
	,GeneratesLTI int  

  ,CONSTRUCTOR  function ngt_eligibility(
         cached int default 0
        ,EID number default 0
        ,cycleID number default 0
        ,isSalaryEligible int default 0
        ,isICPEligible int default 0
        ,isLTIEligible int default 0
        ,GeneratesSalary int default 0
        ,GeneratesICP int default 0
        ,GeneratesLTI int   default 0       
        ) RETURN SELF AS RESULT
        
  ,MEMBER procedure setValues
  ,member function print return varchar2

);
/
CREATE or replace TYPE BODY ngt_eligibility AS

  -- this would be pretty generic for all objects
 CONSTRUCTOR FUNCTION ngt_eligibility(
          cached int default 0
        ,EID number default 0
        ,cycleID number default 0
        ,isSalaryEligible int default 0
        ,isICPEligible int default 0
        ,isLTIEligible int default 0
        ,GeneratesSalary int default 0
        ,GeneratesICP int default 0
        ,GeneratesLTI int   default 0       
        ) RETURN SELF AS RESULT is
        
    BEGIN
        self.cached := cached;
        self.eid := eid;
        self.cycleID := CycleID;      
        self.isSalaryEligible := 0;
        self.isICPEligible := 0;
        self.isLTIEligible := 0;
        self.GeneratesSalary := 0; 
        self.GeneratesICP := 0;
        self.GeneratesLTI := 0; 
        
        return;
    END;
  
  MEMBER procedure  setValues  IS
    CURSOR c_Eligibility IS
      SELECT
          MAX(DECODE(elig.COMP_TYPE_IDFK,1,elig.IS_ELIGIBLE,0)) isSalaryEligible,
          MAX(DECODE(elig.COMP_TYPE_IDFK,3,elig.IS_ELIGIBLE,0)) IsICPEligible,
          MAX(DECODE(elig.COMP_TYPE_IDFK,10,elig.IS_ELIGIBLE,0)) IsLTIEligible,
          MAX(DECODE(elig.COMP_TYPE_IDFK,1,elig.GENERATES_BUDGET,0)) GeneratesSalary,
          MAX(DECODE(elig.COMP_TYPE_IDFK,3,elig.GENERATES_BUDGET,0)) GeneratesICP,
          MAX(DECODE(elig.COMP_TYPE_IDFK,10,elig.GENERATES_BUDGET,0)) GeneratesLTI
           FROM HR_COMP_EMP_ELIGIBILITY elig
       WHERE elig.EMP_IDFK  = self.EID
       AND elig.FY_CYCLE_IDFK  = self.CycleID
       AND elig.COMP_TYPE_IDFK IN(1,3,10);
       
    r_elig c_Eligibility%ROWTYPE;
    
  begin
  
   --if (self.cached=0) then 
      open c_Eligibility; fetch c_Eligibility into r_elig; close c_Eligibility; 
      
      self.isSalaryEligible := r_elig.isSalaryEligible;
      self.isICPEligible := r_elig.isICPEligible;
      self.isLTIEligible := r_elig.isLTIEligible;
      self.GeneratesSalary := r_elig.GeneratesSalary; 
      self.GeneratesICP := r_elig.GeneratesICP;
      self.GeneratesLTI := r_elig.GeneratesLTI;    
      self.cached := 1;
    
  end;
 
   MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'cached='
             || cached
             || '; EID='
             || EID
             || '; isSalaryEligible='
             || isSalaryEligible
             || '; isICPEligible='
             || isICPEligible
             || '; isLTIEligible='
             || isLTIEligible
             || '; GeneratesSalary='
             || GeneratesSalary
             || '; GeneratesICP='
             || GeneratesICP
             || '; GeneratesLTI='
             || GeneratesLTI
             || '; cycleID='
             || cycleID          
             ;
   END;

   
end;
/