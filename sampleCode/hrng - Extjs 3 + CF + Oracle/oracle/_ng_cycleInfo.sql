/* ng_cycleInfo view */
create or replace view ng_cycleInfo
  of ngt_cycleInfo with object identifier (cycleid)
as select  
   0 as cached
  ,o.CycleID
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
  -- ,0 as forceLoad -- in prod because ngt_cycleInfo is evolved this should go here instead of the last column
  ,o.HRGLetterEnableDate 
  ,o.ManagerLetterEnableDate 
  ,0 as forceLoad 
  
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
          ,hc.HRM_ENABLE_LETTER_DATE HRGLetterEnableDate
          ,hc.MANAGER_ENABLE_LETTER_DATE ManagerLetterEnableDate

    from HR_FY_CYCLES hc
   -- where hc.FY_CYCLE_ID = 45
) o ;
/

--select * from ng_compCycleInfo where toolid = 'Comp'


/*
select
   d.eid
  ,d.empName
  ,case when d.compEmp.compLevelID > 5 then 'LTIAccess' else 'LTINoAccess' end as LTIAccess
  ,d.compEmp.compLevelID compLevelID
  
FROM hr_compOrg d
where d.cycleid = 45
and d.compEmp.directreports > 0
and d.eid = 101213
*/

      