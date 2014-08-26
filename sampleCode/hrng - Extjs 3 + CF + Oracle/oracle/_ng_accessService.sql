set define off;
/*
  ng_accessService: Deals with comp user access, access overrides both individual and group based on permissions.
*/
create or replace package ng_accessService as

TYPE genRefCursor IS REF CURSOR;

cursor c_isAdmin(p_userID number) is
SELECT count(1)
    FROM HR_USER_PERMISSIONS up
    WHERE up.USER_IDFK = p_UserID
    AND up.PERMISSION_IDFK = 2;

CURSOR c_assignments(p_UserID number,p_CycleID number) is  
    SELECT a.ASSIGN_EMP_IDFK AssignedEmpID 
    FROM HR_ASSIGNMENTS a 
    WHERE a.FY_CYCLE_IDFK = p_cycleID
    AND a.EMP_IDFK = p_UserID 
    AND a.ASSIGNMENT_TYPE_IDFK = 1
  union
  select p_UserID as AssignedEmpID from dual;


PROCEDURE getUserAccess (
       p_HRGAssignments    IN OUT   genRefCursor
      ,p_UserAccessList     IN OUT   genRefCursor
      ,p_ManagerAccessList  IN OUT   genRefCursor
      ,p_Permissions    IN OUT   genRefCursor
      ,p_Cycles IN OUT   genRefCursor
      ,p_UserID             NUMBER
   );


procedure updateUserCycleAccess(p_userID number, p_cycleID number);

procedure updateAllUserCycleAccess(p_cycleID number);

procedure setCompAccess(p_UserID number, p_CycleID number, p_AccessType varchar2 );

procedure setCompIndivAccess(p_UserID number, p_CycleID number, p_AccessType varchar2 );

procedure deleteUserPermissions (p_UserID number, p_CycleId number, p_PermissionID number default null, p_PermissionIDList varchar2 default null);

procedure addUserPermission (p_UserID number, p_CycleId number, p_PermissionID number);

end ng_accessService;
/




create or replace package body ng_accessService as  

PROCEDURE getUserAccess (
       p_HRGAssignments    IN OUT   genRefCursor
      ,p_UserAccessList     IN OUT   genRefCursor
      ,p_ManagerAccessList  IN OUT   genRefCursor
      ,p_Permissions    IN OUT   genRefCursor
      ,p_Cycles IN OUT   genRefCursor
      ,p_UserID             NUMBER
   ) is
   
    v_baseSql varchar2(1000);
    v_sql varchar2(2000);
   
begin

  delete from TMP_SEARCHEMP;
 
  -- TODO: Review, this was taking too long...  
  for y in (select * from ng_cycleInfo i where i.CycleisActive = 1 and i.CycleTypeID in(3)) loop ---- temporarily just using the comp cycles 0,3
      
      v_baseSql := 
          'select d.eid employeeid, d.empName employeename, d.compEmp.directreports directReports ,' || y.cycleid
          || ' FROM hr_compOrg d' 
          || ' WHERE   d.cycleid =' || y.cycleid ; --|| ' and d.compEmp.directreports > 0' ;
          
      for x in c_assignments(p_UserID,y.CycleID) loop
          
          v_sql := v_baseSql || ' START WITH d.managerid = ' || x.AssignedEmpID 
                    || ' CONNECT BY PRIOR d.eid = d.managerid AND PRIOR d.cycleid =' || y.CycleID;
      
          execute immediate 'insert into TMP_SEARCHEMP(eid,employeename,directReports,cycleid) ' || v_sql;
          
          
      end loop;
   
    
  end loop;
  
  open p_HRGAssignments for
    select o.*
    ,case
      when o.ManagerAccess = 'CompReadOnly' and o.ManagerCycleAccess = 'CompReadOnly' and o.HRMCycleAccess = 'CompEdit' then 'CompEdit'
      else o.ManagerAccess
    end as HRGAccess
    ,aa.ASSIGNMENT_TYPE_IDFK AssignmentTypeID
    ,decode(aa.ASSIGNMENT_TYPE_IDFK
         ,1 ,'HRG'
         ,2, 'Dotted Line'
         ,'Unknown') AssignmentType
  from (
      select 
         d.eid AssignedEmpID
        ,d.empName AssignedEmployeeName
        ,d.cycleid
        ,case
          when d.compAccess.CycleAccess = 'CompNoAccess' then 'CompNoAccess'
          when d.cycleInfo.ManagerCycleAccess = 'CompEdit' and d.compAccess.CycleAccess = 'CompEdit' then 'CompEdit'
          when d.cycleInfo.ManagerCycleAccess in ('CompEdit','CompReadOnly') and d.compAccess.CycleAccess = 'CompReadOnly' then 'CompReadOnly'
          when d.cycleInfo.ManagerCycleAccess = 'CompReadOnly' and d.compAccess.CycleAccess in('CompEdit','CompReadOnly') then 'CompReadOnly'
        else
          'Unknown'
        end as ManagerAccess
        
        ,d.compAccess.CycleAccess CycleAccess 
        ,d.compAccess.LTIAccess LTIAccess
        ,d.cycleInfo.ManagerCycleAccess ManagerCycleAccess
        ,d.cycleInfo.HRMCycleAccess HRMCycleAccess
        ,d.compAccess.defaultCycleAccess defaultCycleAccess
        ,d.compAccess.defaultLTIAccess defaultLTIAccess
      from hr_compOrg d
   ) o ,HR_ASSIGNMENTS aa
   where  aa.ASSIGN_EMP_IDFK = o.AssignedEmpID
          and aa.FY_CYCLE_IDFK = o.cycleid
         and aa.EMP_IDFK = p_UserID
         and aa.fy_cycle_idfk in (45)
         and aa.ASSIGNMENT_TYPE_IDFK = 1;
         
  open p_UserAccessList for 
    select distinct eid,employeename,directReports,cycleid from TMP_SEARCHEMP;
  
  open p_ManagerAccessList for 
    select distinct eid,employeename,directReports,cycleid from TMP_SEARCHEMP where directReports > 0;
  
  open p_Permissions for 
     SELECT up.USER_IDFK UserID, up.PERMISSION_IDFK PermissionID, p.PERMISSION_NAME PermissionName, up.FY_CYCLE_IDFK CycleID
			FROM HR_USER_PERMISSIONS up, HR_PERMISSIONS p
			WHERE up.PERMISSION_IDFK = p.PERMISSION_ID 
			AND up.fy_cycle_idfk  in (45)
      AND up.USER_IDFK = p_userID;
      
    open  p_cycles for 
      select * from ng_cycleInfo i where i.CycleisActive = 1 and i.CycleTypeID in(3);
    
end getUserAccess;


procedure updateUserCycleAccess(p_userID number, p_cycleID number) is
    v_empAccess ngt_compAccess;
begin
    
    v_empAccess := New ngt_compAccess(
           cached => 0
          ,EID =>  p_userID
          ,CycleID => p_CycleID
          ,ForceLoad => 1
    );
    
    v_empAccess.save();
    
end updateUserCycleAccess;



procedure setCompAccess(p_UserID number, p_CycleID number, p_AccessType varchar2 ) is

  v_remPermIDList varchar2(50) := '21,22,23';
  v_addPermissionID number;
  
begin

  if p_AccessType = 'CompNoAccess' then
    v_remPermIDList := '21,22,23,26'; -- 27
    v_addPermissionID := 23;
  elsif p_accessType = 'CompReadOnly' then
    v_remPermIDList := '21,22,23'; -- 27
    v_addPermissionID := 22;
  elsif p_accessType = 'CompEdit' then
    v_remPermIDList := '21,22,23'; --26,27
    v_addPermissionID := 21;  
  end if;

  if v_addPermissionID is not null then
    -- remove permissions first to prevent constraint errors
    deleteUserPermissions(p_userid => p_UserID, p_cycleid => p_CycleID, p_PermissionID => null, p_PermissionIDList => v_remPermIDList);
    -- add the No Access restriction
    addUserPermission(p_userid => p_UserID, p_cycleid => p_CycleID, p_PermissionID => v_addPermissionID); 
    -- then update the ref
    updateUserCycleAccess(p_userid,p_CycleID);
   
    -- do the same for of the related managers
    for r in (  select 
                 d.eid
                ,d.empName
                ,decode(d.compEmp.directreports,0,'CompNoAccess','CompEdit') CycleAccess
               FROM hr_compOrg d
               where d.compEmp.directReports > 0
                  START WITH d.managerid = p_UserID 
                  CONNECT BY PRIOR d.eid = d.managerid
                    AND PRIOR d.cycleid = p_CycleID) loop
                   
      -- remove permissions first to prevent constraint errors
      deleteUserPermissions(p_userid => r.eid, p_cycleid => p_CycleID, p_PermissionID => null, p_PermissionIDList => v_remPermIDList);
      
      if r.CycleAccess = 'CompNoAccess' then
        -- add the No Access restriction
        addUserPermission(p_userid => r.eid, p_cycleid => p_CycleID, p_PermissionID => v_addPermissionID);
      end if;
      
      -- then update the ref
      updateUserCycleAccess(r.eid,p_CycleID);
      
    end loop;
  
  end if;

end setCompAccess;

procedure setCompIndivAccess(p_UserID number, p_CycleID number, p_AccessType varchar2 ) is

  v_remPermIDList varchar2(50) := '26,27,28';
  v_addPermissionID number;
  
begin

  if p_AccessType = 'CompNoAccess' then
    v_remPermIDList := '26,27,28'; 
    v_addPermissionID := 26;
  elsif p_accessType = 'CompReadOnly' then
    v_remPermIDList := '26,27,28'; 
    v_addPermissionID := 27;
  elsif p_accessType = 'CompEdit' then
    v_remPermIDList := '26,27,28';
    v_addPermissionID := 28;  
  end if;

  if v_addPermissionID is not null then
    -- remove permissions first to prevent constraint errors
    deleteUserPermissions(p_userid => p_UserID, p_cycleid => p_CycleID, p_PermissionID => null, p_PermissionIDList => v_remPermIDList);
    -- add the No Access restriction
    addUserPermission(p_userid => p_UserID, p_cycleid => p_CycleID, p_PermissionID => v_addPermissionID); 
    -- then update the ref
    updateUserCycleAccess(p_userid,p_CycleID);
  
  end if;  

end setCompIndivAccess;


procedure deleteUserPermissions (p_UserID number, p_CycleId number, p_PermissionID number default null, p_PermissionIDList varchar2 default null) is
  
  v_sql varchar2(500);
  
begin
  
  v_sql := 'DELETE FROM HR_USER_PERMISSIONS WHERE USER_IDFK =' || p_UserID ||' AND FY_CYCLE_IDFK = ' || p_CycleId ;
  
  if p_PermissionID is not null then
    v_sql := v_sql || ' AND PERMISSION_IDFK = ' || p_PermissionID;
	end if;

  if p_PermissionIDList is not null then 

    v_sql := v_sql || ' AND PERMISSION_IDFK IN ( SELECT * FROM TABLE (CAST (Utils.getNumberTable (''' || p_PermissionIDList || ''') AS numbertable)))';
    
  end if;
   
 
  if p_PermissionIDList is not null or p_PermissionID is not null then
    execute immediate v_sql;
  end if;
  
end deleteUserPermissions;

procedure addUserPermission (p_UserID number, p_CycleId number, p_PermissionID number) is

begin

		INSERT INTO HR_USER_PERMISSIONS (USER_IDFK, PERMISSION_IDFK, FY_CYCLE_IDFK) VALUES (p_UserID,p_PermissionID,p_CycleId);
    
end addUserPermission;

procedure updateAllUserCycleAccess(p_cycleID number) is

  v_empAccessRef ref ngt_compAccess;
  v_empAccess ngt_compAccess;
  
  v_cycleInfoRef ref ngt_cycleInfo;
  v_cycleInfo ngt_cycleInfo;
    
begin

  -- get cycle info object
  v_cycleInfo := New ngt_cycleInfo(
           cached => 0
          ,CycleID => p_CycleID
          ,ForceLoad => 1
    );
    v_cycleInfo.save();
    v_cycleInfoRef := v_cycleInfo.getRef(p_CycleID);
  
  for x in (select d.eid from hr_compOrg d where d.cycleid= p_Cycleid and d.compEmp.directreports > 0) loop
    
    v_empAccess := New ngt_compAccess(
           cached => 0
          ,EID =>  x.eid
          ,CycleID => p_CycleID
          ,ForceLoad => 1
    );
    
    
   -- DBMS_OUTPUT.put_line ('Info: ' || v_empAccess.get().print() );
    v_empAccess.save();
    
    -- the getAccessRef takes care of creating a record if it does not exist.
    v_empAccessRef := v_empAccess.getAccessRef(x.eid,p_CycleID);
     
     
    update hr_compOrg o set o = New ngt_compOrg( 
       eid
      ,cycleid 
      ,doRefresh
      ,empname
      ,managerid
      ,manager
      ,compEmp
      ,compInput
      ,recICP
      ,recSalary
      ,recLTI
      ,v_empAccessRef
      ,v_cycleInfoRef
      )
    where eid = x.eid and cycleid = p_cycleid;
       
  end loop;
  
  commit;

end updateAllUserCycleAccess;


end ng_accessService;
/