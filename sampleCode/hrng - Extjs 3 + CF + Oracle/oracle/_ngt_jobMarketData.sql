/*
  Type: ngt_JobMarketData
  Author: Jose Alfonso
  
*/

create or replace type ngt_JobMarketData as object (
   cached int
  ,cycleID number
	,JobCode varchar2(50 byte)
	,CAID VARCHAR2(6 BYTE)
	,LowFTE number
	,midFTE number 
	,highFTE number
    
  ,constructor function ngt_JobMarketData (
       cached int default 0
      ,cycleID number default 0
      ,JobCode varchar2
      ,CAID VARCHAR2
      ,LowFTE number
      ,midFTE number 
      ,highFTE number
      
  )return self as result
  
  ,member function isCached return boolean
  ,member function print return varchar2
  
);
/

create or replace type body ngt_JobMarketData as

  constructor function ngt_JobMarketData (
       cached int default 0
      ,cycleID number default 0
      ,JobCode varchar2
      ,CAID VARCHAR2
      ,LowFTE number
      ,midFTE number 
      ,highFTE number
  )return self as result 
  is
  begin
      self.cached := cached;
      self.cycleID := cycleID;
      self.JobCode := JobCode;
      self.CAID := CAID;
      self.LowFTE := LowFTE;
      self.midFTE := midFTE;
      self.highFTE := highFTE;
      return;
  end;

  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'cached='
             || cached
             || '; cycleID='
             || cycleID
             || '; JobCode='
             || JobCode
             || '; CAID='
             || CAID
             || '; LowFTE='
             || LowFTE
             || '; midFTE='
             || midFTE
             || '; highFTE='
             || highFTE
             ;
   END;

end;
/


CREATE TABLE hr_CompJobMarketData OF ngt_JobMarketData
(
   CONSTRAINT hr_compjobMarketData_pk PRIMARY KEY (cycleID,JobCode,CAID)
);
/