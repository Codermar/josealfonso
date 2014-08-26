/*
  ngt_newJobInfo
  Saves new job information in an object
  drop type ngt_newJobInfo force;
*/


create or replace type ngt_newJobInfo as object (
   cached int
  ,EID number 
  ,cycleID number 
	,JobCode varchar2(50 byte)
  ,JobTitle varchar2(150 byte)
  ,CareerBand varchar2(15 byte)
  ,JobLevel number
  ,JobExempt varchar2(25 byte)
	,CAID VARCHAR2(6 BYTE)
	,LowFTE number
	,midFTE number 
	,highFTE number
  ,ICPTargetPercent number
  
  ,constructor function ngt_newJobInfo (
       cached int default 0
      ,EID number
      ,cycleID number default 0
      ,JobCode varchar2 default null
      ,JobTitle varchar2 default null
      ,CareerBand varchar2 default null
      ,JobLevel number default null
      ,JobExempt varchar2 default null
      ,CAID VARCHAR2 default null
      ,LowFTE number default null
      ,midFTE number default null
      ,highFTE number default null
      ,ICPTargetPercent number default null
      
  )return self as result
  
  ,member function getFromTable return ngt_newJobInfo
  ,member function isCached return boolean
  ,member function print return varchar2
  
);
/

create or replace type body ngt_newJobInfo as

  constructor function ngt_newJobInfo (
       cached int default 0
      ,EID number 
      ,cycleID number default 0
      ,JobCode varchar2 default null
      ,JobTitle varchar2 default null
      ,CareerBand varchar2 default null
      ,JobLevel number default null
      ,JobExempt varchar2 default null
      ,CAID VARCHAR2 default null
      ,LowFTE number default null
      ,midFTE number default null
      ,highFTE number default null
      ,ICPTargetPercent number default null
      
  )return self as result 
  is
  begin
      self.cached := cached;
      self.EID := EID;
      self.cycleID := cycleID;
      self.JobCode := JobCode;
      self.JobTitle := JobTitle;
      self.CareerBand := CareerBand;
      self.JobLevel := JobLevel;
      self.JobExempt := JobExempt;
      self.CAID := CAID;
      self.LowFTE := LowFTE;
      self.midFTE := midFTE;
      self.highFTE := highFTE;
      self.ICPTargetPercent := ICPTargetPercent;
      return;
  end;

  -- //// getFromTable() ////
  member function getFromTable return ngt_newJobInfo is
      my ngt_newJobInfo := self;
      
      cursor ccur is
        select 
           jd.JOBCODE_IDFK JobCode
          ,j.job_title JobTitle
          ,DECODE(j.JOB_EXEMPT, 'Y', 'Exempt', 'EX', 'Exempt' ,'N', 'Non-Exempt', 'NEX','Non-Exempt', NULL) JobExempt
          ,j.job_grade CareerBand
          ,j.job_level JobLevel
          ,j.JOB_FAMILY JobFamily       
          ,jd.CA_IDFK CAID
          ,jd.LOW_FTE LowFTE
          ,jd.MID_FTE MidFTE
          ,jd.HIGH_FTE HighFTE
          ,r.ICP_PERCENT * 100 ICPTargetPercent
       from hr_jobs j , HR_JOBS_DATA jd, HR_ICP_RATES r 
       where j.job_code = self.JobCode
       and jd.JOBCODE_IDFK(+) = j.job_code 
       and jd.FY_CYCLE_IDFK(+) = self.cycleid
       and jd.CA_IDFK(+) = self.CAID
       and Getnumericval(r.GRADE_IDFK(+)) = j.job_level
       and r.FY_CYCLE_IDFK(+) = self.cycleid;
     
       r_job ccur%rowtype; 
       
    begin
      
      open ccur; fetch ccur into r_job; close ccur; 
        
        my.JobTitle := r_job.JobTitle;
        my.CareerBand := r_job.CareerBand;
        my.JobLevel := r_job.JobLevel;
        my.JobExempt := r_job.JobExempt;
        my.LowFTE := r_job.LowFTE;
        my.midFTE := r_job.midFTE;
        my.highFTE := r_job.highFTE;
        my.ICPTargetPercent := r_job.ICPTargetPercent;
        my.cached := 1;    
      
      return my;
      
    end;

  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN  'eid=' || EID  
             || '; cycleID=' || cycleID
             || '; JobCode=' || JobCode
             || '; JobTitle=' || JobTitle
             || '; CareerBand=' || CareerBand
             || '; JobLevel=' || JobLevel
             || '; JobExempt=' || JobExempt
             || '; CAID=' || CAID
             || '; LowFTE=' || LowFTE
             || '; midFTE=' || midFTE
             || '; highFTE=' || highFTE
             || '; ICPTargetPercent=' || ICPTargetPercent
             || '; cached=' || cached
             ;
   END;

end;
/
/* -- test it

set serveroutput on;
declare
  p_EID number := 101213;
  p_CycleID number := 45;
  v_newJobInfo ngt_newJobInfo;
begin
      v_newJobInfo := New ngt_newJobInfo(
           cached => 0
          ,EID =>  101213
          ,CycleID => p_CycleID
          ,JobCode => 'HRPL141'
          ,CAID => '30');
      --v_newJobInfo.save();
      
      DBMS_OUTPUT.put_line ('Info: ' || v_newJobInfo.getFromTable().print() );
end;
/
*/


