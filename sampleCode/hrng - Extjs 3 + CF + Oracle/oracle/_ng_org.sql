set define off;
create or replace
package ng_org as

/*
  getCompOrg may eventually replace getOrg depending on how we manage the comp data

*/

cursor c_managers(p_Managerid number, p_CycleID number) is
    select distinct d.eid, d.empname
    FROM hr_compOrg d 
    WHERE  d.cycleid = p_cycleID
      and d.managerid = p_Managerid
      and d.eid in (select t.managerid from hr_compOrg t where t.cycleid = p_cycleID);

cursor c_directManagers(p_managerID number, p_CycleID number) is
    select distinct d.eid, d.empname
    FROM hr_compOrg d 
    WHERE  d.cycleid = p_cycleID
      and d.managerid = p_Managerid
      and d.eid in (select t.managerid from hr_compOrg t where t.cycleid = p_cycleID);
      
TYPE genRefCursor IS REF CURSOR;

TYPE EmpCompOrgRecord IS RECORD (
      EID number,
      ManagerID number,
      EmploymentCountry varchar2(100 byte),
      Tabbed number
      );

TYPE EmpCycleRecType IS RECORD (
      EmployeeID HR_CYCLE_DATA.emp_idfk%TYPE,
      ManagerID HR_CYCLE_DATA.manager_idfk%TYPE,
      CareerBand HR_CYCLE_DATA.cycle_grade%TYPE,
      OrgID HR_CYCLE_DATA.pa_idfk%TYPE,
      CompLevelID HR_CYCLE_DATA.COMP_LEVEL_ID%type,
      jobCode HR_CYCLE_DATA.job_code_idfk%TYPE,
      DirectReports HR_CYCLE_DATA.DIRECT_REPORTS%type,
      TotalReports HR_CYCLE_DATA.TOTAL_REPORTS%type,
      FullTimeSalary HR_CYCLE_DATA.full_time_salary%type,
      PercentTimeWorked HR_CYCLE_DATA.PERCENT_TIME_WORKED%type,
      ICPTargetPercent HR_CYCLE_DATA.ICP_TARGET_PERC_FORCALC%type,
      ICPIndivModifier HR_CYCLE_DATA.ICP_LAST_INDIV_MODIFIER%type,
      orgUnitCode HR_CYCLE_DATA.org_unit_code%type,
      CAID HR_CYCLE_DATA.CA_IDFK%type,
      SalCurrency HR_CYCLE_DATA.SALARY_CURRENCY_IDFK%type,
      CurrencyUSD HR_CYCLE_DATA.CURRENCY_USD_VAL%type,
      PMType HR_CYCLE_DATA.pm_type%type,
      CompensationGroup HR_CYCLE_DATA.COMPENSATION_GROUP%type,
      PayScaleLevel HR_CYCLE_DATA.pay_scale_level%type,
      EarningsEligible HR_CYCLE_DATA.EARNINGS_ELIGIBLE%type,
      EmploymentCountry HR_CYCLE_DATA.employment_country_txt%type,
      Tabbed number
      );
    
FUNCTION getCompOrg (p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER,
    p_EmpIDList varchar2 default null,
    p_Countries VARCHAR2 DEFAULT NULL) RETURN sys_refcursor;    
    
FUNCTION getOrg (p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER,
    p_EmpIDList varchar2 default null,
    p_Countries VARCHAR2 DEFAULT NULL) RETURN sys_refcursor;

  -------------- constants ----------------
  const_DirectReports  CONSTANT  INTEGER  := 1;
  const_TotalReports   CONSTANT  INTEGER  := 0;
  const_DottedLine CONSTANT INTEGER    := 2;
  const_Countries CONSTANT INTEGER    := 3;
  const_JobChange CONSTANT INTEGER := 4;
  const_JobChangeByCountry CONSTANT INTEGER := 5;
  const_ManagersOnly CONSTANT INTEGER := 6;
  
end ng_org;
/



create or replace
package body ng_org as


FUNCTION getCompOrg (p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER,
    p_EmpIDList varchar2 default null,
    p_Countries VARCHAR2 DEFAULT NULL) RETURN sys_refcursor
AS mycurs sys_refcursor;


BEGIN

IF p_OrgType = ng_globals.const_DirectReports THEN

	OPEN mycurs FOR
    select
       d.eid
      ,d.managerid
      ,d.compEmp.employmentCountry EmploymentCountry
      ,7 AS Tabbed
    from hr_compOrg d 
    where   d.cycleid = p_CycleID 
    and d.managerid = p_ManagerID;


 ELSIF p_OrgType = ng_globals.const_TotalReports THEN
 OPEN mycurs FOR
      select
         d.eid
        ,d.managerid
        ,d.compEmp.employmentCountry EmploymentCountry
        ,(10*(LEVEL-1)) AS Tabbed
      from hr_compOrg d 
      where   d.cycleid = p_CycleID 
      start with d.managerid = p_ManagerID
      connect by prior d.eid = d.managerid
      and prior d.cycleid = p_CycleID;

--ELSIF p_OrgType = ng_globals.const_managersOnly THEN
--OPEN mycurs FOR
--     SELECT cd.emp_idfk eid,
--   	 		e.DISPLAY_NAME_LF EmployeeName
--    FROM hr_comp_emp cd,
--   		 HR_EMPLOYEES e
--    WHERE cd.emp_idfk = e.emp_id
-- AND cd.fy_cycle_idfk = p_CycleID
--   AND  cd.manager_idfk = p_ManagerID
--   AND cd.DIRECT_REPORTS > 0
--   ORDER BY e.last_name, e.first_name;

ELSIF p_OrgType = ng_globals.const_Countries THEN
	  OPEN mycurs FOR
    select
         d.eid
        ,d.managerid
        ,d.compEmp.employmentCountry EmploymentCountry
        ,7 AS Tabbed
      from hr_compOrg d 
      where   d.cycleid = p_CycleID 
      AND d.compEmp.employmentCountry IN ( SELECT * FROM TABLE (CAST (Utils.getvarchartable (p_Countries) AS VarcharTable) ));

ELSIF p_orgType = ng_globals.const_DottedLine THEN
  OPEN mycurs FOR
    select
         d.eid
        ,d.managerid
        ,d.compEmp.employmentCountry EmploymentCountry
        ,7 AS Tabbed
      from hr_compOrg d 
      where   d.cycleid = p_CycleID 
      AND d.eid IN (
								SELECT ASSIGN_EMP_IDFK
								FROM HR_ASSIGNMENTS
								WHERE  ASSIGNMENT_TYPE_IDFK = 2
								AND EMP_IDFK = p_managerID
								AND FY_CYCLE_IDFK = p_CycleID
								);
                
ELSIF p_orgtype = ng_globals.const_EmpList then -- orgtype 5 
  OPEN mycurs FOR
    select
         d.eid
        ,d.managerid
        ,d.compEmp.employmentCountry EmploymentCountry
        ,7 AS Tabbed
      from hr_compOrg d 
      where   d.cycleid = p_CycleID 
      AND d.eid IN (SELECT COLUMN_VALUE AS EID
                   from table (cast (utils.getvarchartable(p_EmpIDList) as varchartable)));
END IF;

RETURN mycurs;

END getCompOrg;


FUNCTION getOrg (p_ManagerID NUMBER,
    p_CycleID number,
    p_OrgType IN NUMBER,
    p_EmpIDList varchar2 default null,
    p_Countries VARCHAR2 DEFAULT NULL) RETURN sys_refcursor
AS mycurs sys_refcursor;

BEGIN

IF p_OrgType = ng_globals.const_DirectReports THEN

	OPEN mycurs FOR
  SELECT cd.emp_idfk EmployeeID,
          cd.manager_idfk managerID,
          cd.cycle_grade CareerBand,
          cd.org_idfk  OrgID,
          cd.comp_level_id CompLevelID,
          cd.job_code_idfk JobCode,
          cd.direct_reports DirectReports,
          cd.total_reports TotalReports,
          cd.full_time_salary FullTimeSalary,
          NVL(cd.PERCENT_TIME_WORKED,100) / 100 PercentTimeWorked,
          cd.ICP_TARGET_PERC_FORCALC ICPTargetPercent,
          cd.ICP_LAST_INDIV_MODIFIER ICPIndivModifier,
          cd.org_unit_code orgUnitCode,
          cd.CA_IDFK CAID,
          cd.SALARY_CURRENCY_IDFK SalCurrency,
          cd.CURRENCY_USD_VAL CurrencyUSD,
          cd.pm_type PMType,
          cd.COMPENSATION_GROUP CompensationGroup,
          cd.pay_scale_level PayScaleLevel,
          cd.EARNINGS_ELIGIBLE EarningsEligible,
          cd.employment_country_txt EmploymentCountry,
          7 AS Tabbed
    FROM HR_CYCLE_DATA cd
    WHERE   cd.FY_CYCLE_IDFK = p_CycleID
   AND  cd.manager_idfk = p_ManagerID;


 ELSIF p_OrgType = ng_globals.const_TotalReports THEN
 OPEN mycurs FOR
  SELECT cd.emp_idfk EmployeeID,
          cd.manager_idfk managerID,
          cd.cycle_grade CareerBand,
          cd.org_idfk  OrgID,
          cd.comp_level_id CompLevelID,
          cd.job_code_idfk JobCode,
          cd.direct_reports DirectReports,
          cd.total_reports TotalReports,
          cd.full_time_salary FullTimeSalary,
          NVL(cd.PERCENT_TIME_WORKED,100) / 100 PercentTimeWorked,
          cd.ICP_TARGET_PERC_FORCALC ICPTargetPercent,
          cd.ICP_LAST_INDIV_MODIFIER ICPIndivModifier,
          cd.org_unit_code orgUnitCode,
          cd.CA_IDFK CAID,
          cd.SALARY_CURRENCY_IDFK SalCurrency,
          cd.CURRENCY_USD_VAL CurrencyUSD,
          cd.pm_type PMType,
          cd.COMPENSATION_GROUP CompensationGroup,
          cd.pay_scale_level PayScaleLevel,
          cd.EARNINGS_ELIGIBLE EarningsEligible,
          cd.employment_country_txt EmploymentCountry,
          (10*(LEVEL-1)) AS Tabbed

    FROM HR_CYCLE_DATA cd
    WHERE   cd.FY_CYCLE_IDFK = p_CycleID
      START WITH cd.manager_idfk = p_ManagerID
      CONNECT BY PRIOR cd.emp_idfk = cd.manager_idfk
        AND PRIOR cd.FY_CYCLE_IDFK = p_CycleID;

--ELSIF p_OrgType = ng_globals.const_managersOnly THEN
--OPEN mycurs FOR
--     SELECT cd.emp_idfk EmployeeID,
--   	 		e.DISPLAY_NAME_LF EmployeeName
--    FROM HR_CYCLE_DATA cd,
--   		 HR_EMPLOYEES e
--    WHERE cd.emp_idfk = e.emp_id
-- AND cd.FY_CYCLE_IDFK = p_CycleID
--   AND  cd.manager_idfk = p_ManagerID
--   AND cd.DIRECT_REPORTS > 0
--   ORDER BY e.last_name, e.first_name;


ELSIF p_OrgType = ng_globals.const_Countries THEN
	  OPEN mycurs FOR
  SELECT cd.emp_idfk EmployeeID,
          cd.manager_idfk managerID,
          cd.cycle_grade CareerBand,
          cd.org_idfk  OrgID,
          cd.comp_level_id CompLevelID,
          cd.job_code_idfk JobCode,
          cd.direct_reports DirectReports,
          cd.total_reports TotalReports,
          cd.full_time_salary FullTimeSalary,
          NVL(cd.PERCENT_TIME_WORKED,100) / 100 PercentTimeWorked,
          cd.ICP_TARGET_PERC_FORCALC ICPTargetPercent,
          cd.ICP_LAST_INDIV_MODIFIER ICPIndivModifier,
          cd.org_unit_code orgUnitCode,
          cd.CA_IDFK CAID,
          cd.SALARY_CURRENCY_IDFK SalCurrency,
          cd.CURRENCY_USD_VAL CurrencyUSD,
          cd.pm_type PMType,
          cd.COMPENSATION_GROUP CompensationGroup,
          cd.pay_scale_level PayScaleLevel,
          cd.EARNINGS_ELIGIBLE EarningsEligible,
          cd.employment_country_txt EmploymentCountry,
          7 AS Tabbed
    FROM HR_CYCLE_DATA cd
    WHERE   cd.FY_CYCLE_IDFK = p_CycleID
   AND cd.EMPLOYMENT_COUNTRY_TXT IN (
                 SELECT *
                   FROM TABLE (CAST (Utils.getvarchartable (p_Countries) AS VarcharTable)
                              ));

ELSIF p_orgType = ng_globals.const_DottedLine THEN
  OPEN mycurs FOR
  SELECT cd.emp_idfk EmployeeID,
          cd.manager_idfk managerID,
          cd.cycle_grade CareerBand,
          cd.org_idfk  OrgID,
          cd.comp_level_id CompLevelID,
          cd.job_code_idfk JobCode,
          cd.direct_reports DirectReports,
          cd.total_reports TotalReports,
          cd.full_time_salary FullTimeSalary,
          NVL(cd.PERCENT_TIME_WORKED,100) / 100 PercentTimeWorked,
          cd.ICP_TARGET_PERC_FORCALC ICPTargetPercent,
          cd.ICP_LAST_INDIV_MODIFIER ICPIndivModifier,
          cd.org_unit_code orgUnitCode,
          cd.CA_IDFK CAID,
          cd.SALARY_CURRENCY_IDFK SalCurrency,
          cd.CURRENCY_USD_VAL CurrencyUSD,
          cd.pm_type PMType,
          cd.COMPENSATION_GROUP CompensationGroup,
          cd.pay_scale_level PayScaleLevel,
          cd.EARNINGS_ELIGIBLE EarningsEligible,
          cd.employment_country_txt EmploymentCountry,
          7 AS Tabbed
    FROM HR_CYCLE_DATA cd
    WHERE   cd.FY_CYCLE_IDFK = p_CycleID
    AND cd.emp_idfk IN (
								SELECT ASSIGN_EMP_IDFK
								FROM HR_ASSIGNMENTS
								WHERE  ASSIGNMENT_TYPE_IDFK = 2
								AND EMP_IDFK = p_managerID
								AND FY_CYCLE_IDFK = p_CycleID
								);
ELSIF p_orgtype = ng_globals.const_EmpList then
  OPEN mycurs FOR
  SELECT cd.emp_idfk EmployeeID,
          cd.manager_idfk managerID,
          cd.cycle_grade CareerBand,
          cd.org_idfk  OrgID,
          cd.comp_level_id CompLevelID,
          cd.job_code_idfk JobCode,
          cd.direct_reports DirectReports,
          cd.total_reports TotalReports,
          cd.full_time_salary FullTimeSalary,
          NVL(cd.PERCENT_TIME_WORKED,100) / 100 PercentTimeWorked,
          cd.ICP_TARGET_PERC_FORCALC ICPTargetPercent,
          cd.ICP_LAST_INDIV_MODIFIER ICPIndivModifier,
          cd.org_unit_code orgUnitCode,
          cd.CA_IDFK CAID,
          cd.SALARY_CURRENCY_IDFK SalCurrency,
          cd.CURRENCY_USD_VAL CurrencyUSD,
          cd.pm_type PMType,
          cd.COMPENSATION_GROUP CompensationGroup,
          cd.pay_scale_level PayScaleLevel,
          cd.EARNINGS_ELIGIBLE EarningsEligible,
          cd.employment_country_txt EmploymentCountry,
          7 AS Tabbed
    FROM HR_CYCLE_DATA cd
    WHERE   cd.FY_CYCLE_IDFK = p_CycleID
   AND cd.emp_idfk IN (SELECT COLUMN_VALUE AS EID
                   from table (cast (utils.getvarchartable(p_EmpIDList) as varchartable)));
END IF;

RETURN mycurs;

END getOrg;

end ng_org;
/
