/*
*/
create or replace type ngt_compRecMatrix as object (
   cached int
  ,cycleID number
  ,GroupID number
  ,CompTypeID number
  ,RangeID number
  ,RangeDesc varchar2(75 byte)
  ,RangeStart    NUMBER
  ,RangeEnd number
  ,Low   NUMBER(10,4)
  ,Solid NUMBER(10,4)
  ,High  NUMBER(10,4)
    
  ,constructor function ngt_compRecMatrix (
       cached int default 0
      ,cycleID number default 0
      ,GroupID number default 0
      ,CompTypeID number default 0
      ,RangeID float default 0
      ,RangeDesc varchar2 default null
      ,RangeStart number default null
      ,RangeEnd number default null
      ,Low number default null
      ,Solid number default null
      ,High number default null
      
  )return self as result
  
  ,member function isCached return boolean
  ,member function print return varchar2
  
);
/

create or replace type body ngt_compRecMatrix as

  constructor function ngt_compRecMatrix (
       cached int default 0
      ,cycleID number default 0
      ,GroupID number default 0
      ,CompTypeID number default 0
      ,RangeID float default 0
      ,RangeDesc varchar2 default null
      ,RangeStart number default null
      ,RangeEnd number default null
      ,Low number default null
      ,Solid number default null
      ,High number default null
  )return self as result 
  is
  begin
      self.cached := cached;
      self.cycleID := cycleID;
      self.GroupID := GroupID;
      self.CompTypeID := CompTypeID;
      self.RangeID := RangeID;
      self.RangeDesc := RangeDesc;
      self.RangeStart := RangeStart;
      self.RangeEnd := RangeEnd;
      self.Low := Low;
      self.Solid := Solid;
      self.High := High;
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
             || '; GroupID='
             || GroupID
             || '; CompTypeID='
             || CompTypeID
             || '; RangeID='
             || RangeID
             || '; RangeDesc='
             || RangeDesc
             || '; RangeStart='
             || RangeStart
             || '; RangeEnd='
             || RangeEnd
             || '; Low='
             || Low
             || '; Solid='
             || Solid
             || '; High='
             || High
             ;
   END;

end;
/

--CREATE TYPE hr_compRecMatrix AS TABLE OF ngt_compRecMatrix;



CREATE TABLE hr_compRecMatrix OF ngt_compRecMatrix
(
   CONSTRAINT hr_compRecMatrix_pk PRIMARY KEY (cycleID,GroupID,CompTypeID,RangeID)
);
/