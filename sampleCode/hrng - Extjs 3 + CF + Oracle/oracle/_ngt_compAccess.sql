/*
set serveroutput on;
drop table hr_CompAccess cascade constraints;
drop type ngt_compAccess force;

*/


create or replace type ngt_compAccess as object (
   cached int
  ,EID number
  ,cycleID number
	,CycleAccess varchar2(50 byte)
  ,LTIAccess varchar2(25 byte)
  ,defaultCycleAccess varchar2(50 byte)
  ,defaultLTIAccess varchar2(25 byte)
  ,IndivOverride varchar2(25 byte)
  ,forceLoad int
  
  ,constructor function ngt_compAccess (
       cached int default 0
      ,EID number default 0
      ,cycleID number default 0
      ,CycleAccess varchar2 default null
      ,LTIAccess varchar2 default null 
      ,defaultCycleAccess varchar2 default null
      ,defaultLTIAccess varchar2 default null
      ,IndivOverride varchar2 default null
      ,forceLoad int default 0
      
  ) return self as result

  ,member function get return ngt_compAccess
  ,member function setFromTables return ngt_compAccess
  ,member function isCached return boolean
  ,member function print return varchar2
  ,member function getAccessRef(p_EID number, p_CycleID number) return ref ngt_compAccess
  ,member procedure save
  
);
/


-- persist the objects
CREATE TABLE hr_CompAccess OF ngt_compAccess
(
   CONSTRAINT hr_compAccess_pk PRIMARY KEY (cycleID,EID)
);
/




/* -- test it

set serveroutput on;
declare
  
  p_EID number := 115791; --101213; --124903;
  p_CycleID number := 45;
  v_empAccess ngt_compAccess;
  v_empAccessRef ref ngt_compAccess;
  
begin

    -- initialize
    v_empAccess := New ngt_compAccess(
           cached => 0
          ,EID =>  p_EID
          ,CycleID => p_CycleID
          ,ForceLoad => 1);
      
      -- the getAccessRef takes care of creating a record if it does not exist.
     -- v_empAccessRef := v_empAccess.getAccessRef(p_EID,p_CycleID);
     
     v_empAccess.save();
      
    -- DBMS_OUTPUT.put_line ('Info: ' || v_empAccess.setFromTables().print() );
    
      DBMS_OUTPUT.put_line ('Info: ' || v_empAccess.get().print() );
      
      
end;
/

 */
