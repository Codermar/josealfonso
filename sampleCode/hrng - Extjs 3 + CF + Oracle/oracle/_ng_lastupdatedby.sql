
CREATE or replace TYPE ng_lastUpdatedBy AS OBJECT (
   EID number
  ,onBehalfOfID number
  ,updaterName varchar2(75 byte)
  ,updaterSub varchar2(75 byte)
  ,UpdatedOn DATE
  ,UpdatingRole varchar2(25 byte)
  ,LastModifiedByString varchar2(100 byte)

  ,MEMBER procedure setValues(p_EID number, p_onBehalfOfID number)
  
  ,CONSTRUCTOR  function ng_lastUpdatedBy(p_EID number, p_onBehalfOfID number) RETURN
      SELF AS RESULT

);
/
CREATE or replace TYPE BODY ng_lastUpdatedBy AS

 CONSTRUCTOR FUNCTION ng_lastUpdatedBy(p_EID number, p_onBehalfOfID number) RETURN SELF AS RESULT IS
    BEGIN
        SELF.EID := p_EID;
        self.onBehalfOfID := p_onBehalfOfID;
        self.UpdatedOn := SYSDATE;
        self.UpdatingRole := 'User';
        return;
    END;


  MEMBER procedure  setValues(p_EID number, p_onBehalfOfID number) IS
    CURSOR c_empName(p_EID NUMBER) IS
      SELECT m.display_name FROM HR_EMPLOYEES m WHERE m.emp_id = p_EID;   
    
    v_Updater varchar2(75 byte);
    --v_UpdaterSub varchar2(75 byte);
    --v_modifyString varchar2(250 byte);
  begin
   

      -- update the date no matter what
      self.UpdatedOn := sysdate;
      
      -- but only update the names if they are different
      if self.EID <> p_EID then
        self.EID := p_EID;
        open c_empName(p_EID); fetch c_empName into v_Updater; close c_empName;
        self.updaterName := v_Updater;
        if self.onBehalfOfID <> p_onBehalfOfID then
          open c_empName(p_onBehalfOfID); fetch c_empName into v_Updater; close c_empName;
          self.UpdaterSub := v_Updater;
        end if;
      end if;
    
    self.LastModifiedByString := self.updaterName || '^' || self.UpdaterSub;   

  end;
  
end;  
/