/*
drop table hr_compBudget cascade constraints;
drop type ngt_compBudget force;
drop type ngt_managerBudget force;
*/

create or replace type ngt_managerBudget as object(
   cached int
  ,EID number
  ,cycleID number
  ,item varchar2(50)
	,Merit float
	,PA float
	,ICP float
	,LTI float

  ,CONSTRUCTOR  function ngt_managerBudget(
         cached int default 0
        ,EID number default 0
        ,cycleID number default 0
        ,item varchar2 default null
        ,Merit float default 0
        ,PA float default 0
        ,ICP float default 0
        ,LTI float default 0      
        ) RETURN SELF AS RESULT
        
  ,MEMBER procedure setValues
  ,member function print return varchar2

);
/
CREATE or replace TYPE BODY ngt_managerBudget AS

 CONSTRUCTOR FUNCTION ngt_managerBudget(
         cached int default 0
        ,EID number default 0
        ,cycleID number default 0
        ,item varchar2 default null
        ,Merit float default 0
        ,PA float default 0
        ,ICP float default 0
        ,LTI float default 0      
        ) RETURN SELF AS RESULT is
        
    BEGIN
        self.cached := cached;
        self.eid := eid;
        self.cycleID := CycleID; 
        self.item := Item;
        self.Merit := Merit;
        self.PA := PA;
        self.ICP := ICP;
        self.LTI := LTI;         
        return;
    END;
  
  MEMBER procedure  setValues  IS
    
  begin
    
      self.cached := 1;
    
  end; -- setvalues
 
   MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'cached='
             || cached
             || '; EID=' || EID
             || '; cycleID=' || cycleID  
             || '; item=' || item
             || '; Merit=' || Merit
             || '; PA=' || PA 
             || '; ICP=' || ICP
             || '; LTI=' || LTI       
             ;
   END;

   
end;
/

CREATE TABLE hr_compBudget OF ngt_managerBudget (
   CONSTRAINT hr_compBudget_pk PRIMARY KEY (eid,cycleid)
);
/

create or replace
TYPE ngt_compBudget  IS TABLE OF ngt_managerBudget;
/

