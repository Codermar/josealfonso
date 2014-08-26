
/*
drop table hr_compOrg cascade constraints;
drop type ngt_recLTI force;

*/



/
CREATE or replace TYPE ngt_recLTI AS OBJECT (
   cached int
  ,EID number 
  ,CycleID number
  ,LTIGuidelines ref ngt_ltiGuidelines
  ,compEmp ref ngt_compEmp
  ,PotentialCalibration varchar2(25 byte)
  ,FTSalaryUSD number
  ,UEVPercMod number
  ,TargetGrant number
  ,LTIAmt number
  ,LTIPerc number

  ,constructor function ngt_recLTI (
       cached int default 0
      ,EID number 
      ,cycleID number default 0
      ,UEVPercMod number default 0
      ,LTIAmt number default 0
      ,LTIPerc float default 0
      
  )return self as result
  ,member function recalc return ngt_recLTI
  ,member function isCached return boolean
  ,member function print return varchar2

)NOT FINAL;
/


CREATE or replace TYPE BODY ngt_recLTI AS

  constructor function ngt_recLTI (
       cached int default 0
      ,EID number
      ,cycleID number default 0
      ,UEVPercMod number default 0
      ,LTIAmt number default 0
      ,LTIPerc float default 0
      
  )return self as result is

  begin
      self.cached := cached;
      self.EID := EID;
      self.cycleID := cycleID;
      self.UEVPercMod := UEVPercMod;
      self.LTIAmt := LTIAmt;
      self.LTIPerc := LTIPerc;
      return;
  end;

  member function recalc return ngt_recLTI is

   cursor c_recmatrix(p_groupid number)   is
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
    AND COMP_TYPE_IDFK = 10
    and GROUP_ID = p_groupid;
    
    my ngt_recLTI := self; 
    v_LTIGuidelinesRef ref ngt_ltiGuidelines;
    v_LTIGuidelines ngt_ltiGuidelines;
    v_compEmp ngt_compEmp;  
    v_tempRangeID number;
    v_groupid int;
    
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
        
        SELECT REF(t) into v_LTIGuidelinesRef FROM hr_compltiGuidelines t WHERE CompLevelID = v_compEmp.CompLevelID and cycleid = my.cycleID;      
        my.LTIGuidelines := v_LTIGuidelinesRef;
      
        BEGIN
          UTL_REF.select_object (my.LTIGuidelines, v_LTIGuidelines);
          EXCEPTION
              WHEN OTHERS THEN
              if SQLERRM = 'ORA-01403: no data found' then
                v_LTIGuidelines := new ngt_LTIGuidelines(  
                     cycleID => self.cycleID
                    ,cached => 0
                    ,CompLevelID => 0
                    ,TargetGrant => 0
                    ,ParticRate => 0
                    ,complevelDesc => null
                );
              end if;
        END;
        
        my.PotentialCalibration := v_compEmp.PotentialCalibration;
        my.FTSalaryUSD := v_compEmp.FTSalary * v_compEmp.currencyUSD;
        
       -- calculate the UEVPercMod -- TODO: confirm this formula
        if nvl(my.FTSalaryUSD,0) <> 0 then
        
          my.UEVPercMod := v_compEmp.UnvestedSharesValue / my.FTSalaryUSD;
        
        end if;

        -- only for band 9 and above        
        if v_compEmp.payScaleLevel between 6 and 12 then       
               
               -- find the group the employee is in based on payScaleLevel
               if v_compEmp.payScaleLevel between 9 and 10 then v_groupid := 0; 
               elsif v_compEmp.payScaleLevel between 11 and 12 then v_groupid := 1; 
               end if; 
                
     
                -- find the range to use 
                for x in c_recmatrix(v_groupid)  loop
                  
                  
                  if x.rangeStart is null and my.UEVPercMod * 100 < x.rangeEnd then  
                    v_tempRangeID := x.rangeID;
                  elsif x.rangeEnd is null and my.UEVPercMod * 100 > x.rangeStart then
                    v_tempRangeID := x.rangeID;
                  else
                      
--                      if my.UEVPercMod * 100 between x.RangeStart and x.rangeend then
--                        v_tempRangeID := x.rangeID;
--                      end if; -- eo find in range

                      if my.UEVPercMod * 100 > x.RangeStart and my.UEVPercMod * 100 <= x.rangeend then
                        v_tempRangeID := x.rangeID;
                      end if; -- eo find in range    
                      
                  end if;
                  
        
                  if v_tempRangeID = x.rangeid then
                      if  my.PotentialCalibration = 'High' then
                        my.LTIPerc  := x.high;
                      elsif my.PotentialCalibration = 'Solid' then
                        my.LTIPerc  := x.solid;
                      elsif my.PotentialCalibration = 'Low' then
                        my.LTIPerc  := x.low;
                      end if;
                  end if;
                  
                end loop;       
               
              
           -- Formula for LTIRec: equity target * potential /unvested equity value modifier 
           my.TargetGrant := treat(v_LTIGuidelines as ngt_LTIGuidelines).TargetGrant;
           my.LTIAmt :=  my.TargetGrant * my.LTIPerc;
        
        end if; -- v_compEmp.payScaleLevel > 8

        return my;
   end;

  member function isCached return boolean is
  begin
    if self.cached = 1 then return true; else return false; end if;
  end;
  
  MEMBER FUNCTION PRINT RETURN VARCHAR2
   IS
   BEGIN
      RETURN   'LTIAmt=' || LTIAmt 
             || '; LTIPerc=' || to_char(LTIPerc,'000.0000')
             || '; PotentialCalibration='|| PotentialCalibration
             || '; UEVPercMod=' || UEVPercMod
             || '; FTSalaryUSD:' || FTSalaryUSD
             || '; TargetGrant=' || TargetGrant
             || ';cached=' || cached
             ;
   END;
   
end;  
/
/* test it


set serveroutput on;
declare
  p_CycleID number := 45;
  aRec ngt_recLTI;
begin
      -- 1,45,1,10000,0,'Band 1-6')
      aRec := New ngt_recLTI(
         0
        ,117228
        ,p_CycleID
      );
      -- aRec.recalc();
      
      DBMS_OUTPUT.put_line ('Info: ' || aRec.recalc().print());
end;
/ */


