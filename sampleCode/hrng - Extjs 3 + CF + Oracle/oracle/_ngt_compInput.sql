/*
  ngt_compInput holds hrtool's comp input
 
  drop table hr_compInput cascade constraints;
  drop type ngt_compInput force;
 
*/


CREATE or replace TYPE ngt_compInput AS OBJECT (
   cached int
  ,EID number
  ,CycleID number 
  ,MeritAmt number
  ,MeritPerc float
  ,MeritOutsideRangeJust varchar2(350 byte)
  ,LumpSumAmt number
  ,LumpSumPerc float
  ,LumpSumOutsideRangeJust varchar2(350 byte)
  ,AdjustmentAmt number
  ,AdjustmentPerc float
  ,AdjustmentReason varchar2(350 byte)
  ,AdjEffectiveDate date
  ,AdjustmentOutsideRangeJust varchar2(350 byte)
  ,NewJobCode varchar2(350 byte) 
  ,NewJobInfo ngt_newJobInfo
  ,NewJobJustification varchar2(350 byte)
  ,PromotionAmt number
  ,PromotionPerc float
  ,PromotionEffectiveDate date
  ,PromotionOutsideRangeJust varchar2(350 byte)
  ,ICPAward number
  ,ICPIndivModifier float
  ,ICPOutsideRangeJust varchar2(350 byte) 
  ,LTIGrantAmt number
  ,LTGrantModifier float
  ,LTIGrantOutSideRangeJust varchar2(350 byte)
  ,LTIReceived number
  ,SalICPComments varchar2(4000)
  ,EquityComments varchar2(4000) 
  ,LastModifiedString varchar2(200)
  ,lastModifiedByID number
  ,lastModifiedOnBehalfOfID number
  ,lastModifiedOn date
  
  ,CONSTRUCTOR  function ngt_compInput(
       cached int default 0
      ,EID number default null
      ,CycleID number default null 
      ,MeritAmt number default null
      ,MeritPerc float default null
      ,MeritOutsideRangeJust varchar2 default null
      ,LumpSumAmt number default null
      ,LumpSumPerc float default null
      ,LumpSumOutsideRangeJust varchar2 default null
      ,AdjustmentAmt number default null
      ,AdjustmentPerc float default null
      ,AdjustmentReason varchar2 default null
      ,AdjEffectiveDate date default null
      ,AdjustmentOutsideRangeJust varchar2 default null
      ,NewJobCode varchar2 default null
      ,NewJobInfo ngt_newJobInfo  default null
      ,NewJobJustification varchar2 default null
      ,PromotionAmt number default null
      ,PromotionPerc float default null
      ,PromotionEffectiveDate date default null
      ,PromotionOutsideRangeJust varchar2 default null
      ,ICPAward number default null
      ,ICPIndivModifier float default null
      ,ICPOutsideRangeJust varchar2 default null
      ,LTIGrantAmt number default null
      ,LTGrantModifier float default null
      ,LTIGrantOutSideRangeJust varchar2 default null
      ,LTIReceived number default null
      ,SalICPComments varchar2 default null
      ,EquityComments varchar2 default null
      ,LastModifiedString varchar2 default null
      ,lastModifiedByID number default null
      ,lastModifiedOnBehalfOfID number default null
      ,lastModifiedOn date default sysdate
      
  )return self as result

  ,member function get return ngt_compInput

  ,member function print return varchar2
  
  ,member function getInputRef(p_EID number, p_CycleID number) return ref ngt_compInput
  
  ,member procedure save


) NOT FINAL;
/


-- persist the objects
create table hr_compInput of ngt_compInput (
     constraint hr_compInput_pk primary key (cycleID,EID)
    ,constraint hr_compInput_eid foreign key (eid) references hr_employees
    ,constraint hr_compInput_cycleid foreign key (cycleid) references hr_fy_cycles
    ,constraint hr_compInput_NewJobCode foreign key (NewJobCode) references hr_jobs
    );
/


CREATE or replace TYPE BODY ngt_compInput AS

 CONSTRUCTOR  function ngt_compInput(
       cached int default 0
      ,EID number default null
      ,CycleID number default null 
      ,MeritAmt number default null
      ,MeritPerc float default null
      ,MeritOutsideRangeJust varchar2 default null
      ,LumpSumAmt number default null
      ,LumpSumPerc float default null
      ,LumpSumOutsideRangeJust varchar2 default null
      ,AdjustmentAmt number default null
      ,AdjustmentPerc float default null
      ,AdjustmentReason varchar2 default null
      ,AdjEffectiveDate date default null
      ,AdjustmentOutsideRangeJust varchar2 default null
      ,NewJobCode varchar2 default null
      ,NewJobInfo ngt_newJobInfo  default null
      ,NewJobJustification varchar2 default null
      ,PromotionAmt number default null
      ,PromotionPerc float default null
      ,PromotionEffectiveDate date default null
      ,PromotionOutsideRangeJust varchar2 default null
      ,ICPAward number default null
      ,ICPIndivModifier float default null
      ,ICPOutsideRangeJust varchar2 default null
      ,LTIGrantAmt number default null
      ,LTGrantModifier float default null
      ,LTIGrantOutSideRangeJust varchar2 default null
      ,LTIReceived number default null
      ,SalICPComments varchar2 default null
      ,EquityComments varchar2 default null
      ,LastModifiedString varchar2 default null
      ,lastModifiedByID number default null
      ,lastModifiedOnBehalfOfID number default null
      ,lastModifiedOn date default sysdate
      
  )return self as result IS
    BEGIN
        SELF.cached := cached;
        SELF.EID := EID;
        self.CYCLEID := CycleID;    
        self.MeritAmt := MeritAmt;
        self.MeritPerc := MeritPerc;
        self.MeritOutsideRangeJust := MeritOutsideRangeJust;
        self.LumpSumAmt := LumpSumAmt;
        self.LumpSumPerc := LumpSumPerc;
        self.LumpSumOutsideRangeJust := LumpSumOutsideRangeJust;
        self.AdjustmentAmt := AdjustmentAmt;
        self.AdjustmentPerc := AdjustmentPerc;
        self.AdjustmentReason := AdjustmentReason;
        self.AdjEffectiveDate := AdjEffectiveDate;
        self.AdjustmentOutsideRangeJust := AdjustmentOutsideRangeJust;
        self.NewJobCode := NewJobCode;
        
        if NewJobInfo is null then     
          self.NewJobInfo := New ngt_newJobInfo(
               cached => 0
              ,EID =>  self.EID 
              ,CycleID => self.CycleID );
        else   
          self.NewJobInfo := NewJobInfo; 
        end if;
        
        self.NewJobJustification := NewJobJustification;
        self.PromotionAmt := PromotionAmt;
        self.PromotionPerc := PromotionPerc;
        self.PromotionEffectiveDate := PromotionEffectiveDate;
        self.PromotionOutsideRangeJust := PromotionOutsideRangeJust;
        self.ICPAward := ICPAward;
        self.ICPIndivModifier := ICPIndivModifier;
        self.ICPOutsideRangeJust := ICPOutsideRangeJust;
        self.LTIGrantAmt := LTIGrantAmt;
        self.LTGrantModifier := LTGrantModifier;
        self.LTIGrantOutSideRangeJust := LTIGrantOutSideRangeJust;
        self.LTIReceived := LTIReceived;
        self.SalICPComments := SalICPComments;
        self.EquityComments := EquityComments;
        self.LastModifiedString := LastModifiedString;
        self.lastModifiedByID := lastModifiedByID;
        self.lastModifiedOnBehalfOfID := lastModifiedOnBehalfOfID;
        self.lastModifiedOn := lastModifiedOn;
      
        return;
    END;
    
    -- //// get() ////
    member function get return ngt_compInput is
      my ngt_compInput := self;
      empInput ngt_compInput;
      
      cursor ccur is
        select value(t)
          from hr_compInput t
          where eid = self.eid
          and cycleid = self.cycleid;
    begin
      
      open ccur; fetch ccur into empInput;
        if ccur%notfound then
          empInput := new ngt_compInput(eid=>self.eid,cycleid=>self.cycleid);
          empInput.save();
        end if;
      close ccur;
      
      my := empInput;
      
      return my;
      
    end;
    -- /// getInputRef() ///
    member function getInputRef(p_EID number, p_CycleID number) return ref ngt_compInput 
      is
        v_compInputRef ref ngt_compInput;
        v_compInput ngt_compInput;
      begin
      
    
          BEGIN
            SELECT REF(t) into v_compInputRef FROM hr_compInput t WHERE eid = p_EID and cycleid = p_cycleID;
           EXCEPTION
                WHEN OTHERS THEN
                
                
                if SQLERRM = 'ORA-01403: no data found' then -- data not found so try to extract it and save it
                 
                  v_compInput := New ngt_compInput(
                       cached => 0
                      ,EID =>  p_eid
                      ,CycleID => p_cycleID );
                  -- save the object
                  v_compInput.save();
    
                else raise;
                end if;

                begin
                  SELECT REF(t) into v_compInputRef FROM hr_compInput t WHERE eid = p_eid and cycleid = p_cycleID;
                  exception 
                    when others then
                    
                    if SQLERRM = 'ORA-01403: no data found' then
                      v_compInputRef := NULL;
                    else raise;
                    end if;
    
                end;
               
               
          END;
    
          return v_compInputRef;
      
      end;    
        
    
    -- //// save() ////
    MEMBER PROCEDURE save IS
     BEGIN 
        UPDATE hr_compInput c SET c = self WHERE EID = self.EID;
  
        IF sql%ROWCOUNT = 0
        THEN
           INSERT INTO hr_compInput VALUES (self);
        END IF;
    END;
     
    -- //// save() ////
    MEMBER FUNCTION PRINT RETURN VARCHAR2
     IS
     BEGIN
        RETURN    
            'cached=' || cached
            || '; EID=' || EID
            || '; cycleID=' || cycleID
            || '; MeritAmt=' ||  MeritAmt
            || '; MeritPerc=' ||  MeritPerc
            || '; MeritOutsideRangeJust=' ||  MeritOutsideRangeJust
            || '; LumpSumAmt=' ||  LumpSumAmt
            || '; LumpSumPerc=' ||  LumpSumPerc
            || '; LumpSumOutsideRangeJust=' ||  LumpSumOutsideRangeJust
            || '; AdjustmentAmt=' ||  AdjustmentAmt
            || '; AdjustmentPerc=' ||  AdjustmentPerc
            || '; AdjustmentReason=' ||  AdjustmentReason
            || '; AdjEffectiveDate=' ||  AdjEffectiveDate
            || '; AdjustmentOutsideRangeJust=' ||  AdjustmentOutsideRangeJust 
            || '; NewJobCode=' ||  NewJobCode
            --|| '; NewJobInfo=' ||  NewJobInfo
            || '; NewJobJustification=' ||  NewJobJustification
            || '; PromotionAmt=' ||  PromotionAmt
            || '; PromotionPerc=' ||  PromotionPerc
            || '; PromotionEffectiveDate=' ||  PromotionEffectiveDate
            || '; PromotionOutsideRangeJust=' ||  PromotionOutsideRangeJust  
            
            || '; ICPAward=' ||  ICPAward
            || '; ICPIndivModifier=' ||  ICPIndivModifier
            || '; LTIGrantAmt=' ||  LTIGrantAmt
            || '; LTGrantModifier=' ||  LTGrantModifier
            || '; LTIGrantOutSideRangeJust=' ||  LTIGrantOutSideRangeJust
            || '; LTIReceived=' ||  LTIReceived
            || '; SalICPComments=' ||  SalICPComments
            || '; EquityComments=' ||  EquityComments
            || '; LastModifiedString=' ||  LastModifiedString
            ;
     END;
  
end;  
/

/* -- test it

set serveroutput on;
declare
  p_CycleID number := 45;
  v_compInput ngt_compInput;
begin
      v_compInput := New ngt_compInput(
           cached => 0
          ,EID =>  106620
          ,CycleID => p_CycleID );
      v_compInput.save();
      
      DBMS_OUTPUT.put_line ('Info: ' || v_compInput.get().print() );
end;
/
select value(t) from hr_compInput t
*/
--delete from hr_compOrg;
--delete from hr_compInput; 
--commit;

