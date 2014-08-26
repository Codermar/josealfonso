/*drop table hr_compLTIGuidelines cascade constraints;
drop type ngt_ltiGuidelines force;
*/


create or replace type ngt_ltiGuidelines as object (
   cached int
  ,cycleID number
  ,CompLevelID number 
  ,TargetGrant number
	,ParticRate number
  ,complevelDesc varchar2(50 byte)
    
  ,constructor function ngt_ltiGuidelines (
       cached int default 0
      ,cycleID number default 0
      ,CompLevelID number 
      ,TargetGrant number
      ,ParticRate number
      ,complevelDesc varchar2  
  )return self as result
  
  ,member function isCached return boolean
  ,member function print return varchar2
  
);
/

create or replace type body ngt_ltiGuidelines as

  constructor function ngt_ltiGuidelines (
       cached int default 0
      ,cycleID number default 0
      ,CompLevelID number 
      ,TargetGrant number
      ,ParticRate number
      ,complevelDesc varchar2 
  )return self as result 
  is
  begin
      self.cached := cached;
      self.cycleID := cycleID;
      self.CompLevelID := CompLevelID;
      self.TargetGrant := TargetGrant;    
      self.ParticRate := ParticRate;
      self.complevelDesc := complevelDesc;
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
             || '; TargetGrant='
             || TargetGrant
             || '; complevelDesc='
             || complevelDesc
             || '; CompLevelID='
             || CompLevelID
             || '; ParticRate='
             || ParticRate
             ;
   END;

end;
/

--CREATE TYPE hr_compRecMatrix AS TABLE OF ngt_ltiGuidelines;



CREATE TABLE hr_compltiGuidelines OF ngt_ltiGuidelines
(
   CONSTRAINT hr_compltiGuidelines_pk PRIMARY KEY (cycleID,CompLevelID)
);
/