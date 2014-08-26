/*
  
*/
CREATE or replace TYPE ngt_compCycleMod AS OBJECT (
     cycleID number 
    ,modID varchar2(100)
    ,cached int

    ,NOT INSTANTIABLE member function isCached return boolean
    ,MEMBER FUNCTION PRINT RETURN VARCHAR2
  )
   NOT INSTANTIABLE
   NOT FINAL;
/

-- Now ICP Modifier as subtype of cycle
create or replace type ngt_icpMod under ngt_compCycleMod (
   ICPCompanyMod float
  ,ICPIndivMod float
  
  ,constructor function ngt_icpMod (
       cycleID number default 0
      ,modID varchar2 default 'ICPMod'
      ,cached int default 0
      ,ICPCompanyMod float default 0
      ,ICPIndivMod float default 0
  )return self as result
  
  ,overriding member function isCached return boolean
  ,overriding member function print return varchar2
  
);
/

create or replace type body ngt_icpMod as 
  
  constructor function ngt_icpMod (
       cycleID number
      ,modID varchar2
      ,cached int
      ,ICPCompanyMod float
      ,ICPIndivMod float
  )return self as result 
  is
  begin
      self.cycleID := cycleID;
      self.modID := modID;
      self.cached := cached;
      self.ICPCompanyMod := ICPCompanyMod;
      self.ICPIndivMod := ICPIndivMod;
      
      if ICPCompanyMod is not null then return;
      else
          raise_application_error (-20000
                                , 'ICPCompanyMod ' || ICPCompanyMod || ' is invalid'
                                 );
      end if;
  end;
  
  overriding member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  OVERRIDING MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'CycleID='
             || cycleID
             || '; modID='
             || modID
             || '; ICPCompanyMod='
             || ICPCompanyMod
             || '; ICPIndivMod='
             || ICPIndivMod
             || '; cached='
             || cached;
   END;

end;
/


-- MeritPA Modifier subtype
create or replace type ngt_meritpamod under ngt_compCycleMod (
   MeritPercModifier float
  ,PAPercModifier float
  ,CAID varchar2(6 byte)
  
  ,constructor function ngt_meritpamod (
       cycleID number default 0
      ,modID varchar2 default 'MeritPAMod'
      ,cached int default 0
      ,MeritPercModifier float default 0
      ,PAPercModifier float default 0
      ,CAID varchar2 default null
  )return self as result
  
  ,overriding member function isCached return boolean
  ,overriding member function print return varchar2
);
/

create or replace type body ngt_meritpamod as
 
  constructor function ngt_meritpamod (
       cycleID number
      ,modID varchar2
      ,cached int 
      ,MeritPercModifier float
      ,PAPercModifier float
      ,CAID varchar2
  ) return self as result 
  is
  begin
      self.cycleID := cycleID;
      self.modID := modID;
      self.cached := cached;
      self.MeritPercModifier := MeritPercModifier;
      self.PAPercModifier := PAPercModifier;
      self.CAID := CAID;
      
      if CAID is not null then return;
      else
          raise_application_error (-20000
                                , 'CAID ' || CAID || ' is invalid'
                                 );
      end if;
  end;
  
  overriding member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  OVERRIDING MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'CycleID='
             || cycleID
             || '; modID='
             || modID
             || '; MeritPercModifier='
             || MeritPercModifier
             || '; PAPercModifier='
             || PAPercModifier
             || '; CAID='
             || CAID;
   END;

end;
/
-- persist the objects
create table hr_compCycleMod of ngt_compCycleMod (constraint hr_compCycleMod_pk primary key (cycleID,modID));
