/*

*/

create or replace type body ngt_compAccess as

  constructor function ngt_compAccess (
       cached int default 0
      ,EID number default 0
      ,cycleID number default 0
      ,CycleAccess varchar2  default null
      ,LTIAccess varchar2 default null 
      ,defaultCycleAccess varchar2 default null
      ,defaultLTIAccess varchar2 default null
      ,IndivOverride varchar2 default null
      ,forceLoad int default 0
      
  )return self as result 
  is
  
  begin
      self.cached := cached;
      self.EID := EID;
      self.cycleID := cycleID;
      self.CycleAccess := CycleAccess;
      self.LTIAccess := LTIAccess;
      self.forceLoad := forceLoad;
      self.defaultCycleAccess := defaultCycleAccess;
      self.defaultLTIAccess := defaultLTIAccess;
      self.IndivOverride := IndivOverride;
      self.forceLoad := forceLoad;
      
      if forceLoad = 1 then self := get(); end if;
      
      return;
  end;

  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  
    -- //// get() ////
    member function get return ngt_compAccess is
      my ngt_compAccess := self;
      emp ngt_compAccess;
      
      cursor ccur is
        select value(t)
          from hr_CompAccess t
          where eid = self.eid
          and cycleid = self.cycleid;
    begin
      
      if self.forceLoad = 1 then
        emp := setFromTables();
        emp.save();
      else
        open ccur; fetch ccur into emp;
          if ccur%notfound then
            emp := setFromTables();
            emp.save();
          end if;
        close ccur;      
      end if;
      
      my := emp;
      
      return my;
      
    end;  
  
  
    -- //// setFromTables() ////
    member function setFromTables return ngt_compAccess is
      my ngt_compAccess := self;
      
      cursor c_empinfo is
        select
           d.eid
          ,d.empName
          ,decode(d.compEmp.directreports,0,'CompNoAccess','CompEdit') CycleAccess
          ,case when d.compEmp.compLevelID > 4 then 'LTIAccess' else 'LTINoAccess' end as LTIAccess
          ,d.compEmp.compLevelID compLevelID
          
        FROM hr_compOrg d
        where d.cycleid = self.cycleid
        and d.compEmp.directreports > 0
        and d.eid = self.EID;
    
      r_emp c_empinfo%rowtype;        
    
      cursor c_cycleAccess is
       select p.PERMISSION_NAME CycleAccess
       from HR_PERMISSIONS p
       where p.PERMISSION_ID = (
            SELECT max(PERMISSION_IDFK) compAccessID
            FROM HR_USER_PERMISSIONS up
            WHERE up.fy_cycle_idfk = self.cycleid
            and up.USER_IDFK = self.EID
            AND up.PERMISSION_IDFK between 21 and 23);
     
     cursor c_ltiaccess is
       select p.PERMISSION_NAME LTIAccess
       from HR_PERMISSIONS p
       where p.PERMISSION_ID = (
            SELECT max(PERMISSION_IDFK) compAccessID
            FROM HR_USER_PERMISSIONS up
            WHERE up.fy_cycle_idfk = self.cycleid
            and up.USER_IDFK = self.EID
            AND up.PERMISSION_IDFK between 24 and 25);
      
      cursor c_override is
       select p.PERMISSION_NAME LTIAccess
       from HR_PERMISSIONS p
       where p.PERMISSION_ID = (
            SELECT max(PERMISSION_IDFK) compAccessID
            FROM HR_USER_PERMISSIONS up
            WHERE up.fy_cycle_idfk = self.cycleid
            and up.USER_IDFK = self.EID
            AND up.PERMISSION_IDFK between 26 and 28);      
            
      -- 26: compReadOnlyOverride
      -- 27: compEditOverride
      
      v_tmp varchar2(25);
      
    begin
      
      if (self.cached=0) then 
      
        open c_empinfo; fetch c_empinfo into r_emp; close c_empinfo;     

          my.CycleAccess := r_emp.CycleAccess;
          my.LTIAccess := r_emp.LTIAccess;
          my.cached := 1;
          my.forceLoad := 0;
          my.defaultCycleAccess := r_emp.CycleAccess;
          my.defaultLTIAccess := r_emp.LTIAccess;
      
          -- get an access override if it exists
          open c_cycleAccess; fetch c_cycleAccess into v_tmp; 
            if c_cycleAccess%found then     
              my.CycleAccess := v_tmp;
            end if;
          close c_cycleAccess; 
          
          -- get individual overrides if they exists
          open c_override; fetch c_override into v_tmp; 
            if c_override%found then     
              my.IndivOverride := v_tmp;
            end if;
          close c_override;
          
          if my.CycleAccess != 'CompNoAccess' then
            -- find if there's an override for LTI
            open c_ltiaccess; fetch c_ltiaccess into v_tmp; 
              if c_ltiaccess%found then
                my.LTIAccess := v_tmp;
              end if;
            close c_ltiaccess;
            
          end if;
       
       end if;
       
      return my;
      
    end;  -- setFromTables
  
  
   -- //// save() ////
  MEMBER PROCEDURE save IS
   BEGIN
      
      UPDATE hr_CompAccess c SET c = self WHERE EID = self.EID and cycleid = self.cycleid;
      IF sql%ROWCOUNT = 0
      THEN
         INSERT INTO hr_CompAccess VALUES (self);
      END IF;
  END; 
  
  

  -- /// getAccessRef() ///
  member function getAccessRef(p_EID number, p_CycleID number) return ref ngt_compAccess 
  is
    v_compEmpRef ref ngt_compAccess;
    v_compEmp ngt_compAccess;
  begin

      BEGIN
        SELECT REF(t) into v_compEmpRef FROM hr_CompAccess t WHERE eid = p_EID and cycleid = p_cycleID;
       EXCEPTION
            WHEN OTHERS THEN
            
            
            if SQLERRM = 'ORA-01403: no data found' then -- data not found so try to extract it and save it

              v_compEmp := New ngt_compAccess(
                   cached => 0
                  ,EID =>  p_eid
                  ,CycleID => p_cycleID
                  ,ForceLoad => 1);
              
              -- save the object
              v_compEmp.save();

            else raise;
            end if;
            
            
            
            begin
              SELECT REF(t) into v_compEmpRef FROM hr_CompAccess t WHERE eid = p_eid and cycleid = p_cycleID;
              exception 
                when others then
                
                if SQLERRM = 'ORA-01403: no data found' then
                  v_compEmpRef := NULL;
                else raise;
                end if;
            end; 
      END;


      return v_compEmpRef;
  
  end;  
  
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'EID=' || EID
             || '; cycleID=' || cycleID
             || '; CycleAccess=' || CycleAccess
             || '; LTIAccess=' || LTIAccess
             || '; defaultCycleAccess=' || defaultCycleAccess
             || '; defaultLTIAccess=' || defaultLTIAccess
             || '; IndivOverride=' || IndivOverride
             || ';cached=' || cached
             ;
   END;

end;
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
