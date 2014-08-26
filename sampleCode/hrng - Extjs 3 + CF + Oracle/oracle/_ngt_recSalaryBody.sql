
create or replace TYPE BODY ngt_recSalary AS

  constructor function ngt_recSalary (
       cached int default 0
      ,EID number 
      ,cycleID number default 0
      ,ContributionCalibration varchar2 default 'Not calibrated'
      ,PercThruRangeCurr float default 0
      ,Merit number default 0
      ,MeritPerc float default 0
      ,LumpSum number default 0
      ,LumpSumPec float default 0
      
  )return self as result is

  begin
  
      self.cached := cached;
      self.cycleID := cycleID;
      self.EID := EID;
      return;
  end;
  
  member function recalc return ngt_recSalary is
     
   cursor c_recmatrix   is
    SELECT FY_CYCLE_IDFK CycleID,
      COMP_TYPE_IDFK CompTypeId,
      RANGE_START RangeStart,
      RANGE_END RangeEnd,
      range_id RangeID,
      GROUP_ID GroupId,
      RANGE_DESC RangeDesc,
      LOW,
      SOLID,
      HIGH   
    FROM HR_COMP_REC_MATRIX 
    where fy_cycle_idfk = self.CYCLEID
    AND COMP_TYPE_IDFK = 1;
    
    my ngt_recSalary := self;
    v_tmprec number;   
    v_tempRangeID number;
    v_jmdRef ref ngt_JobMarketData;
    v_jmd ngt_JobMarketData;
    v_meritpamodRef ref ngt_compCycleMod;
    v_meritpamod ngt_compCycleMod;
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
    
    

        begin
        SELECT REF(t) into v_meritpamodRef FROM hr_compCycleMod t WHERE modID = v_compEmp.CAID and cycleid = self.cycleID; 
          EXCEPTION
              WHEN OTHERS THEN
              if SQLERRM = 'ORA-01403: no data found' then
              --return my;
                null;
              end if;      
        end;
  
        my.MeritPAMod := v_meritpamodRef;
        
        

        
        
        
        BEGIN
          UTL_REF.select_object (my.MeritPAMod, v_meritpamod);
          EXCEPTION
              WHEN OTHERS THEN
              if SQLERRM = 'ORA-01403: no data found' then
                v_meritpamod := new ngt_meritpamod(  
                     cycleID => self.cycleID
                    ,modID => v_compEmp.CAID
                    ,cached => 0
                    ,MeritPercModifier => 0
                    ,PAPercModifier => 0
                    ,CAID => v_compEmp.CAID
                );
              end if;
        END;      
      
        my.ContributionCalibration := v_compEmp.ContributionCalibration;  
    
        
        BEGIN
         SELECT REF(t) into v_jmdRef FROM hr_CompJobMarketData t WHERE caid = v_compEmp.CAID and jobCode = v_compEmp.jobCode and cycleid = self.cycleID;    
        EXCEPTION 
              WHEN OTHERS THEN
              if SQLERRM = 'ORA-01403: no data found' then
              
              --return my;
              null;
              
              
              end if; 
             --RAISE;
        END;
        my.JobMarketData := v_jmdRef;
        
        BEGIN
          UTL_REF.select_object (my.JobMarketData, v_jmd);
          EXCEPTION
              WHEN OTHERS THEN
              if SQLERRM = 'ORA-01403: no data found' then
                v_jmd := new ngt_JobMarketData(
                      cached => 0
                    ,cycleID => self.cycleID
                    ,JobCode => null
                    ,CAID => null
                    ,LowFTE => null
                    ,midFTE => null 
                    ,highFTE => null
                );
              end if;
        END; 


        -- calc percent thru range current      
        if (nvl(v_jmd.HighFTE,0) - nvl(v_jmd.LowFTE,0)) <> 0 then
          my.PercThruRangeCurr := (NVL(v_compEmp.FTSalary,0) - v_jmd.LowFTE) / (nvl(v_jmd.HighFTE,0) - nvl(v_jmd.LowFTE,0));
        else 
          my.PercThruRangeCurr := null;
        end if;
        
           -- go over the merit values
        for x in c_recmatrix  loop
          
          if x.rangeStart is null and my.PercThruRangeCurr * 100 < x.rangeEnd then  
            v_tempRangeID := x.rangeID;
          elsif x.rangeEnd is null and my.PercThruRangeCurr * 100 > x.rangeStart then
            v_tempRangeID := x.rangeID;
          else
              
--              if my.PercThruRangeCurr * 100 between x.RangeStart and x.rangeend then
--                v_tempRangeID := x.rangeID;
--              end if; -- eo find in range
              
              if my.PercThruRangeCurr * 100 > x.RangeStart and my.PercThruRangeCurr * 100 <= x.rangeend then
                v_tempRangeID := x.rangeID;
              end if; -- eo find in range
              
              
          end if;

          if v_tempRangeID = x.rangeid then
              if  my.ContributionCalibration = 'High' then
                my.matrixModifier  := x.high;
              elsif my.ContributionCalibration = 'Solid' then
                my.matrixModifier  := x.solid;
              elsif my.ContributionCalibration = 'Low' then
                my.matrixModifier  := x.low;
              end if;
          end if;
          
        end loop;
  
        v_tmprec := round((treat(v_meritpamod as ngt_meritpamod).MeritPercModifier * v_compEmp.FTSalary * my.matrixModifier ) / 100,0);
  
        if my.PercThruRangeCurr > 1 then
          my.Merit := 0;
          my.MeritPerc := 0;
          my.LumpSum := v_tmprec;
          if nvl(v_compEmp.FTSalary,0) <> 0 then 
            my.LumpSumPec := round(v_tmprec / v_compEmp.FTSalary * 100,1);
          end if;
        else 
          my.Merit := v_tmprec;
          my.LumpSum := v_tmprec;
          if nvl(v_compEmp.FTSalary,0) <> 0 then 
            my.MeritPerc := round(v_tmprec / v_compEmp.FTSalary * 100,1);
            my.LumpSumPec := round(v_tmprec / v_compEmp.FTSalary * 100,1);
          end if;  
        end if;
        
        my.cached := 1;
     
     return my;
     
  end;
  
  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN  'PTR=' || to_char(PercThruRangeCurr,'99.9999')
             || '; Merit=' || Merit
             || '; MeritPerc=' || MeritPerc
             || '; LumpSum='  || LumpSum
             || '; LumpSumPec=' || LumpSumPec
             || '; ContributionCalibration=' || ContributionCalibration
             || '; matrixModifier=' || matrixModifier
             || ';cached=' || cached
             ;
   END;
   
end;
/
--
/* -- test it
set serveroutput on;
declare

  p_CycleID number := 45;
  jmd ref ngt_JobMarketData;
  arecSal ngt_recSalary;
  
begin

    arecSal := New ngt_recSalary(
         cached => 0
        ,EID => 106620 
        ,CycleID => p_CycleID
    );
    -- DBMS_OUTPUT.put_line ('JobData: ' || jm.print()); 
    DBMS_OUTPUT.put_line ('Info: ' || arecSal.recalc().print());

end;

*/

