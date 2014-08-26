/*

*/
CREATE or replace TYPE ngt_recICP AS OBJECT (
   cached int
  ,EID number 
  ,CycleID number
  ,icpmod ref ngt_compCycleMod
  ,compEmp ref ngt_compEmp
  ,ContributionCalibration varchar2(25 byte)
  ,ICPAmt number
  ,ICPPerc number

  ,constructor function ngt_recICP (
       cached int default 0
      ,EID number 
      ,cycleID number default 0
      ,ICPAmt number default 0
      ,ICPPerc float default 0
      
  )return self as result
  ,member function recalc return ngt_recICP
  ,member function isCached return boolean
  ,member function print return varchar2

)NOT FINAL;
/


CREATE or replace TYPE BODY ngt_recICP AS

  constructor function ngt_recICP (
       cached int default 0
      ,EID number
      ,cycleID number default 0
      ,ICPAmt number default 0
      ,ICPPerc float default 0
      
  )return self as result is

  begin
      self.cached := cached;
      self.EID := EID;
      self.cycleID := cycleID;
      self.ICPAmt := ICPAmt;
      self.ICPPerc := ICPPerc;
      return;
  end;

  member function recalc return ngt_recICP is

  cursor c_recmatrix(p_ContributionCalibration varchar2)  is
    SELECT  decode(p_ContributionCalibration, 
                'High' , HIGH,
                'Solid', SOLID,
                'Low',  LOW) as matrixmodifier    
    FROM HR_COMP_REC_MATRIX 
    where fy_cycle_idfk = self.CYCLEID
    AND COMP_TYPE_IDFK = 3
    and range_id = 1; -- there's only one record for ICP
    
    my ngt_recICP := self; 
    v_icpmodRef ref ngt_compCycleMod;
    v_icpmod ngt_compCycleMod;
    v_compEmp ngt_compEmp;  
    
  begin
        -- initialize the emp object so we can get the ref from it
        v_compEmp := New ngt_compEmp();
        my.compEmp := v_compEmp.getEmpRef(my.EID,my.CycleID);
          
        
        BEGIN
          UTL_REF.select_object (my.compEmp, v_compEmp);
        EXCEPTION
            WHEN OTHERS THEN
            if SQLERRM = 'ORA-01403: no data found' then
            
              v_compEmp := new ngt_compEmp(
                    cached => 0
                  ,EID => self.EID
                  ,cycleID => self.cycleID
                  ,managerID => 0
              );
            end if;
        END;
        
        SELECT REF(t) into v_icpmodRef FROM hr_compCycleMod t WHERE modID = 'ICPMod' and cycleid = my.cycleID;      
        my.icpmod := v_icpmodRef;
      
        
        
        open c_recmatrix(v_compEmp.ContributionCalibration) ; fetch c_recmatrix into my.ICPPerc; close c_recmatrix;
          
        
        BEGIN
          UTL_REF.select_object (my.icpmod, v_icpmod);
          EXCEPTION
              WHEN OTHERS THEN
              if SQLERRM = 'ORA-01403: no data found' then
                v_icpmod := new ngt_icpMod(  
                     cycleID => self.cycleID
                    ,modID => 'ICPMod'
                    ,cached => 0
                    ,ICPCompanyMod => 0
                    ,ICPIndivMod => 0
                );
              end if;
        END;
        
        my.ContributionCalibration := v_compEmp.ContributionCalibration;
        my.ICPAmt := (v_compEmp.ICPSalary * v_compEmp.ICPTargetPercent * (treat(v_icpmod as ngt_icpMod).ICPCompanyMod / 100) * my.ICPPerc);

        return my;
   end;

  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'ICPAmt=' || ICPAmt
              || '; ICPPerc=' || to_char(ICPPerc,'00.0000')
              || '; ContributionCalibration=' || ContributionCalibration
              || ';cached=' || cached
             ;
   END;
   
end;  
/

/* test it

set serveroutput on;
declare
  p_CycleID number := 45;
  arecSal ngt_recICP;
begin
      arecSal := New ngt_recICP(
         0
        ,106620
        ,p_CycleID
      );
      -- arecSal.recalc();
      
      DBMS_OUTPUT.put_line ('Info: ' || arecSal.recalc().print());
end;

*/

