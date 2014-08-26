
create or replace type body ngt_cycleInfo as

  constructor function ngt_cycleInfo (
       cached int default 0
      ,cycleid number default 0
      ,CycleName varchar2 default null
      ,ToolID varchar2 default null
      ,CycleTypeID number default null
      ,cycleStartDate date default null
      ,CycleEndDate date default null
      ,CycleIsActive int default 0 
      ,ManagerCycleAccess varchar2 default null
      ,HRMCycleAccess varchar2 default null
      ,ManagerEditActivationDate date default null
      ,ManagerReadOnlyActivationDate date default null
      ,HRMrEditActivationDate date default null
      ,HRMReadOnlyActivationDate date default null
      ,HRGLetterEnableDate date default null
      ,ManagerLetterEnableDate date default null
      ,forceLoad int default 0
      
  )return self as result 
  is
  
  begin
      self.cached := cached;
      self.cycleID := cycleID;
      self.CycleName := CycleName;
      self.ToolID := ToolID;
      self.CycleTypeID := CycleTypeID;
      self.cycleStartDate := cycleStartDate;
      self.CycleEndDate := CycleEndDate;
      self.CycleIsActive := CycleIsActive;
      self.ManagerCycleAccess := ManagerCycleAccess;
      self.HRMCycleAccess := HRMCycleAccess;
      self.ManagerEditActivationDate := ManagerEditActivationDate;
      self.ManagerReadOnlyActivationDate := ManagerReadOnlyActivationDate;
      self.HRMrEditActivationDate := HRMrEditActivationDate;
      self.HRMReadOnlyActivationDate := HRMReadOnlyActivationDate;
      self.forceLoad := forceLoad;
      self.HRGLetterEnableDate := HRGLetterEnableDate;
      self.ManagerLetterEnableDate := ManagerLetterEnableDate;
      
      if forceLoad = 1 then self := get(); end if;
      
      return;
  end;

  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
   -- //// get() ////
  member function get return ngt_cycleInfo is
    my ngt_cycleInfo := self;
    tmpobj ngt_cycleInfo;
    
    cursor ccur is
      select value(t)
        from hr_cycleInfo t
        where cycleid = self.cycleid;
  begin
    
    if self.forceLoad = 1 then
      tmpobj := setFromTables();
      tmpobj.save();
    else
      open ccur; fetch ccur into tmpobj;
        if ccur%notfound then
          tmpobj := setFromTables();
          tmpobj.save();
        end if;
      close ccur;      
    end if;
    
    my := tmpobj;
    
    return my;
    
  end;  

  -- //// setFromTables() ////
    member function setFromTables return ngt_cycleInfo is
      my ngt_cycleInfo := self;
      
      cursor c_cycleinfo is
      select  
         o.CycleID
        ,o.CycleName 
        ,o.ToolID 
        ,o.CycleTypeID
        ,o.CycleStartDate
        ,o.CycleEndDate
        ,o.CycleIsActive
        ,case
          when o.ToolID = 'OPM' then 'Edit'
          when o.CycleIsActive = 0 then 'CompReadOnly'
          when o.CycleIsActive = 1 and TRUNC(o.ManagerEditActivationDate) <= TO_DATE(SYSDATE) AND TRUNC(o.ManagerReadOnlyActivationDate) >= TO_DATE(SYSDATE) THEN 'CompEdit'
          when o.CycleIsActive = 1 and TRUNC(o.ManagerEditActivationDate) > TO_DATE(SYSDATE) then 'CompReadOnly'
          when o.CycleIsActive = 1 and TRUNC(o.ManagerReadOnlyActivationDate) <= TO_DATE(SYSDATE) then 'CompReadOnly'
          else 'Unknown'
        end as ManagerCycleAccess
        ,case
          when o.ToolID = 'OPM' then 'Edit'
          when o.CycleIsActive = 0 then 'CompReadOnly'
          when o.CycleIsActive = 1 and TRUNC(o.HRMrEditActivationDate) <= TO_DATE(SYSDATE) AND TRUNC(o.HRMReadOnlyActivationDate) >= TO_DATE(SYSDATE) THEN 'CompEdit'
          when o.CycleIsActive = 1 and TRUNC(o.HRMrEditActivationDate) > TO_DATE(SYSDATE) then 'CompReadOnly'
          when o.CycleIsActive = 1 and TRUNC(o.HRMReadOnlyActivationDate) <= TO_DATE(SYSDATE) then 'CompReadOnly'
          else 'Unknown'
        end as HRMCycleAccess
        ,o.ManagerEditActivationDate
        ,o.ManagerReadOnlyActivationDate
        ,o.HRMrEditActivationDate
        ,o.HRMReadOnlyActivationDate
        ,o.MinLTIAccessLevel
        ,o.HRGLetterEnableDate
        ,o.ManagerLetterEnableDate
      from (
          select
                 hc.FY_CYCLE_ID CycleID
                ,hc.CYCLE_NAME CycleName 
                ,hc.HRTOOL_IDFK ToolID 
                ,hc.cycle_type_idfk CycleTypeID
                ,hc.START_DT CycleStartDate
                ,hc.END_DT CycleEndDate
                ,CASE
                     WHEN TRUNC(hc.END_DT) IS NULL AND TRUNC(hc.START_DT) <= TO_DATE(SYSDATE) THEN 1
                     WHEN TRUNC(hc.START_DT) <= TO_DATE(SYSDATE) AND TRUNC(hc.END_DT) >= TO_DATE(SYSDATE) THEN 1
                     ELSE 0
                 END AS CycleIsActive
                
                ,hc.MANAGER_EDIT_ACTIVATION_DATE ManagerEditActivationDate
                ,hc.MANAGER_READONLY_EXP_DATE ManagerReadOnlyActivationDate
                ,hc.HRM_EDIT_ACTIVATION_DATE HRMrEditActivationDate
                ,hc.HRM_READONLY_EXP_DATE HRMReadOnlyActivationDate   
                ,hc.MIN_MGR_GRADE_ELIGIBILITY MinMgrGradeEligibility
                ,hc.MIN_MGR_GRADE_ELIGIBILITY MinLTIAccessLevel
                ,hc.HRM_ENABLE_LETTER_DATE HRGLetterEnableDate
                ,hc.MANAGER_ENABLE_LETTER_DATE ManagerLetterEnableDate
          from 
            HR_FY_CYCLES hc
          where hc.FY_CYCLE_ID = self.cycleid
      ) o ;
    
      r_cycle c_cycleinfo%rowtype;        
    
      
    begin
      
      if (self.cached=0) then 
      
        open c_cycleinfo; fetch c_cycleinfo into r_cycle; close c_cycleinfo;     

          
          my.cached := 1;
          my.cycleID := r_cycle.cycleID;
          my.CycleName := r_cycle.CycleName;
          my.ToolID := r_cycle.ToolID;
          my.CycleTypeID := r_cycle.CycleTypeID;
          my.cycleStartDate := r_cycle.cycleStartDate;
          my.CycleEndDate := r_cycle.CycleEndDate;
          my.CycleIsActive := r_cycle.CycleIsActive;
          my.ManagerCycleAccess := r_cycle.ManagerCycleAccess;
          my.HRMCycleAccess := r_cycle.HRMCycleAccess;
          my.ManagerEditActivationDate := r_cycle.ManagerEditActivationDate;
          my.ManagerReadOnlyActivationDate := r_cycle.ManagerReadOnlyActivationDate;
          my.HRMrEditActivationDate := r_cycle.HRMrEditActivationDate;
          my.HRMReadOnlyActivationDate := r_cycle.HRMReadOnlyActivationDate;     
          my.forceLoad := 0;
          my.HRGLetterEnableDate := r_cycle.HRGLetterEnableDate;
          my.ManagerLetterEnableDate := r_cycle.ManagerLetterEnableDate;
       end if;
       
      return my;
      
    end;  -- setFromTables
  
  
   -- //// save() ////
  MEMBER PROCEDURE save IS
   
   BEGIN
      
      UPDATE hr_cycleInfo c SET c = self WHERE cycleid = self.cycleid;

      IF sql%ROWCOUNT = 0
      THEN
         INSERT INTO hr_cycleInfo VALUES (self);
      END IF;
  END; 
  
-- /// getRef() ///
  member function getRef(p_CycleID number) return ref ngt_cycleInfo 
  is
    v_cycleInfoRef ref ngt_cycleInfo;
    v_cycleInfo ngt_cycleInfo;
  begin

      BEGIN
        SELECT REF(t) into v_cycleInfoRef FROM hr_cycleInfo t WHERE cycleid = p_cycleID;
       EXCEPTION
            WHEN OTHERS THEN
            
            
            if SQLERRM = 'ORA-01403: no data found' then -- data not found so try to extract it and save it

              v_cycleInfo := New ngt_cycleInfo(
                   cached => 0
                  ,CycleID => p_cycleID
                  ,ForceLoad => 1);
              
              -- save the object
              v_cycleInfo.save();

            else raise;
            end if;
            
            
            
            begin
              SELECT REF(t) into v_cycleInfoRef FROM hr_cycleInfo t WHERE cycleid = p_cycleID;
              exception 
                when others then
                
                if SQLERRM = 'ORA-01403: no data found' then
                  v_cycleInfoRef := NULL;
                else raise;
                end if;
            end; 
      END;


      return v_cycleInfoRef;
  
  end;  
  
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'cycleID=' || cycleID
                  || '; CycleName=' || CycleName
                  || '; ToolID=' || ToolID
                  || '; CycleTypeID=' || CycleTypeID
                  || '; cycleStartDate=' || cycleStartDate
                  || '; CycleEndDate=' || CycleEndDate
                  || '; ManagerCycleAccess=' || ManagerCycleAccess
                  || '; HRMCycleAccess=' || HRMCycleAccess
                  || '; ManagerEditActivationDate=' || ManagerEditActivationDate
                  || '; ManagerReadOnlyActivationDate=' || ManagerReadOnlyActivationDate
                  || '; HRMrEditActivationDate=' || HRMrEditActivationDate
                  || '; HRMReadOnlyActivationDate=' || HRMReadOnlyActivationDate
                  || '; HRGLetterEnableDate=' || HRGLetterEnableDate
                  || '; ManagerLetterEnableDate=' || ManagerLetterEnableDate
                  || ';cached=' || cached
             ;
   END;  
  
  
end;
/

/* -- test it


set serveroutput on;
declare
  
  p_CycleID number := 45;
  v_cycleInfo ngt_cycleInfo;
  v_cycleInfoRef ref ngt_cycleInfo;
  
begin

    -- initialize
    v_cycleInfo := New ngt_cycleInfo(
           cached => 0
          ,CycleID => p_CycleID
          ,ForceLoad => 1);
      
      -- the getRef takes care of creating a record if it does not exist.
     -- v_cycleInfoRef := v_cycleInfo.getRef(p_EID,p_CycleID);
     
    -- v_cycleInfo.save();
      
    -- DBMS_OUTPUT.put_line ('Info: ' || v_cycleInfo.setFromTables().print() );
    
      DBMS_OUTPUT.put_line ('Info: ' || v_cycleInfo.get().print() );
      
      
end;
/
 */

      