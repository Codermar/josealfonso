
/*

drop package ng_compService;
--drop type ngt_compOrgRefs force;
drop table hr_compOrg cascade constraints;
drop type ngt_compOrg force;

*/

CREATE or replace TYPE ngt_compOrg AS OBJECT (
     eid number
    ,cycleid number 
    ,doRefresh int
    ,empname varchar2(100)
    ,managerid number
    ,manager ref ngt_compOrg
    ,compEmp ref ngt_compEmp
    ,compInput ref ngt_compInput
    ,recICP ngt_recICP
    ,recSalary ngt_recSalary
    ,recLTI ngt_recLTI
    ,compAccess ref ngt_compAccess
    ,cycleInfo ref ngt_cycleInfo
    --,permissions
    --,UserAccessList
    --,managerAccessList
    --,Assignments
    
    
    ,member function printOrg (str IN varchar2 DEFAULT NULL) RETURN varchar2
    ,member function getNewSalary return number
    ,member function getNewPTR return number
    
    ,static function getOrg(
         managerID number
        ,cycleID number 
        ,orgType number default 0
      ) return sys_refcursor
      
 )
   NOT FINAL;
/

CREATE OR REPLACE TYPE BODY ngt_compOrg AS
   
  static function getOrg(
     managerID number
    ,cycleID number 
    ,orgType number default 0
  ) return sys_refcursor is
  
    v_sql varchar2(4000);
    v_refcur sys_refcursor;
    
  begin

    v_sql := 'select value(t) from hr_compOrg t where t.cycleid = ' || CycleID;
    
    if orgType = 0 then
      v_sql := v_sql  || ' START WITH t.managerid = ' || managerID
                      || ' CONNECT BY PRIOR t.eid = t.managerid'
                      || ' AND PRIOR t.cycleid = ' || CycleID;
    elsif orgType = 1 then
      v_sql := v_sql || ' AND t.managerid = ' || managerID;    
    end if;
    
    DBMS_OUTPUT.put_line ('SQL: ' || v_sql);
  
    v_sql := 'BEGIN OPEN :lcur FOR ' || v_sql || '; END;';
    
    execute immediate v_sql using in out v_refcur;
    
    return v_refcur;
    
  end; -- eo getOrg   
  
  member function getNewSalary return number is

    v_compEmp ngt_compEmp;
    v_compInput ngt_compInput;
    v_NewFTSalary number;
    
  begin

       UTL_REF.select_object (self.compEmp, v_compEmp);
       UTL_REF.select_object (self.compInput, v_compInput);

        -- New FT Salary
        if nvl(v_compInput.LumpSumAmt,0) = 0 then
            v_NewFTSalary := NVL(v_compEmp.FTSalary,0) + NVL(v_compInput.MeritAmt,0) + NVL(v_compInput.AdjustmentAmt,0) + NVL(v_compInput.PromotionAmt,0);
        else 
           v_NewFTSalary := NVL(v_compEmp.FTSalary,0);
        end if;

      return v_NewFTSalary;
      
  end; -- eo getNewSalary
  
  member function getNewPTR return number is
     
    v_newPTR number;
    v_jmd ngt_JobMarketData;

  begin
  
      UTL_REF.select_object (self.recSalary.jobMarketData, v_jmd);

        if (nvl(v_jmd.highFTE,0) - nvl(v_jmd.LowFTE,0)) <> 0 then
          v_newPTR := (NVL(self.getNewSalary(),0) - v_jmd.LowFTE) / (nvl(v_jmd.highFTE,0) - nvl(v_jmd.LowFTE,0));
        else v_newPTR := null; end if;
      
    return v_newPTR;
    
  end; -- eo getNewPTR
  
   
   MEMBER FUNCTION printOrg (str IN VARCHAR2) RETURN VARCHAR2 IS
      bt ngt_compOrg;
   BEGIN
      IF self.manager IS NULL
      THEN
         RETURN str;
      ELSE
         UTL_REF.select_object (self.manager, bt);
         RETURN bt.printOrg (NVL (str, self.eid)) || ' [' || bt.eid || ']';
      END IF;
   END;
END;
/

--CREATE TYPE ngt_compOrgRefs AS TABLE OF REF ngt_compOrg;
--/


CREATE TABLE hr_compOrg OF ngt_compOrg
(
   CONSTRAINT hr_compOrg_pk PRIMARY KEY (eid,cycleid)
  ,CONSTRAINT hr_compOrg_self_ref FOREIGN KEY (manager) REFERENCES hr_compOrg
  ,constraint hr_compOrg_compEmp foreign key (compEmp) references hr_compEmp
  ,constraint hr_compOrg_compInput foreign key (compInput) references hr_compInput
  
  --,constraint hr_compOrg_icpmod foreign key (icpmod) references hr_compCycleMod
  --,constraint hr_compOrg_meritpamod foreign key (meritpamod) references hr_compCycleMod
  --,constraint hr_compOrg_compRecMatrix foreign key (compRecMatrix) references hr_compRecMatrix
  -- ,constraint hr_compOrg_jobMarketData foreign key (jobMarketData) references hr_jobMarketData
);
/

