SET DEFINE OFF;

create or replace
PACKAGE           ng_shared 
AS
/* /// ng_shared package ////
  Shared cursors and functions for NG
  
*/


TYPE genRefCursor IS REF CURSOR;

TYPE EmpCycleAccessType IS RECORD (
      EmployeeID hr_employees.emp_id%TYPE,
      EmployeeDispName VARCHAR2(75),
      EmpAccessDispName varchar2(75),
      EmployeeName hr_employees.DISPLAY_NAME%TYPE,
      Email hr_employees.email%type,
      CurrentStatus hr_employees.CURRENT_STATUS%TYPE,
      LoginName hr_employees.login_name%TYPE,
      BrowsingMode varchar2(35),
      CycleID hr_cycle_data.fy_cycle_idfk%type,
      CycleGrade hr_cycle_data.cycle_grade%type,
     -- GradeforCalc hr_cycle_data.PAY_SCALE_LEVEL%type,
      DirectReports hr_cycle_data.direct_reports%TYPE,
      JobTitle hr_jobs.job_title%type,
      OrgName hr_personnel_Areas.personnel_area_name%type,
      OrgUnitShortText varchar(50),
      CompanyName varchar(50),
      TotalReports hr_cycle_data.total_reports%TYPE,
      FYID hr_fy_cycles.fy_idfk%type,
      HRToolID hr_fy_cycles.HRTOOL_IDFK%type,
      CycleName hr_fy_cycles.CYCLE_NAME%type,
      MinMgrGradeEligibility number,
      isAdmin int,
      CanView int,
      EditAccess int,
      hasCountryAccess int,
      CycleStatus varchar(25),
      IsDisabled int,
      IsManagerException int,
      TargetNode varchar2(25),
      CycleHasStarted int,
      MaxIndivModifier number(10,4),
      CycleHasEnded int,
      RelatedSACycleID number,
      TACycleID number,
      YECycleID number,
      isCycleAdmin int,
      CycleIsActive int,
      EditAccessByDefault int,
      NoAccess int,
      ReadOnly int,  
      ExtendedEdit int,
      BSAAccess int,
      HasAccessOverride int,
      HasAccessOverrideRO int,
      ReadOnlyOverride int,
      ManagerEditIsActive int,
      HRMEditIsActive int,
      BSAEditIsActive int,
      ToolaccessGranted VARCHAR2(75),
      PrelimToolAccessGranted VARCHAR(75),
      ToolaccessCategory VARCHAR2(75),
      GrantedAccessExplained VARCHAR2(2000), 
      LoginRoleMessage VARCHAR2(2000),
      EmploymentLocation VARCHAR2(50),
      EmploymentCountry VARCHAR2(50),
      BSAReadOnlyExpirDate DATE,
      StockHistoryCutoffDate DATE,
      HRMReadOnlyExpired int,
      EquityGrantValue float,
      blacksholes float
   );


TYPE EmpRecType IS RECORD (
      EmployeeID hr_employees.DISPLAY_NAME%TYPE,
      EmployeeName hr_employees.DISPLAY_NAME%TYPE,
      UserName hr_employees.login_name%TYPE,
      DirectReports hr_employees.direct_reports%TYPE,
      Status hr_employees.CURRENT_STATUS%TYPE
   );
   
   
-- /// cursors ////


CURSOR c_Eligibility(p_CycleID NUMBER, p_EmployeeID NUMBER) IS
SELECT
    MAX(DECODE(elig.COMP_TYPE_IDFK,1,elig.IS_ELIGIBLE,0)) IsSalEligible,
    MAX(DECODE(elig.COMP_TYPE_IDFK,3,elig.IS_ELIGIBLE,0)) IsICPEligible,
    MAX(DECODE(elig.COMP_TYPE_IDFK,10,elig.IS_ELIGIBLE,0)) IsLTIEligible,
    MAX(DECODE(elig.COMP_TYPE_IDFK,1,elig.GENERATES_BUDGET,0)) GeneratesSalBudget,
    MAX(DECODE(elig.COMP_TYPE_IDFK,3,elig.GENERATES_BUDGET,0)) GeneratesICPBudget,
    MAX(DECODE(elig.COMP_TYPE_IDFK,10,elig.GENERATES_BUDGET,0)) GeneratesLTIBudget
     FROM HR_COMP_EMP_ELIGIBILITY elig
 WHERE elig.EMP_IDFK  = p_EmployeeID
 AND elig.FY_CYCLE_IDFK  = p_CycleID
 AND elig.COMP_TYPE_IDFK IN(1,3,10)
 GROUP BY  elig.EMP_IDFK;

-- equity specific cursors
CURSOR c_EquityGuidelines(p_CompLevelID int, p_CycleID number) IS
  SELECT lv.COMP_LEVEL_ID CompLevelID, level_desc complevelDesc,
    lv.MID_QTY TargetGrant, lv.PARTIC_RATE ParticRate
  FROM HR_COMP_LEVELS lv
  where FY_CYCLE_IDFK = p_cycleid
  and COMP_LEVEL_ID = p_CompLevelID;


-- salicp cursors
CURSOR c_getMeritPAModifier(p_CycleID NUMBER, p_CAID VARCHAR2) IS
   SELECT merit_modifier MeritPercModifier,  pa_modifier PAPercModifier
   FROM HR_BUDGET_MODIFIERS
   WHERE  ca_idfk = p_CAID
   AND  fy_cycle_idfk = p_cycleid
   AND company_idfk = 0; -- as of 2010 we're using the same company (0 default)
   
-- as of 2010 , ORG_UNIT_CODEFK, COMPANY_IDFK are really not used   
CURSOR c_getICPModifier(p_CycleID IN HR_BUDGET_ICPMODIFIERS.fy_cycle_idfk%TYPE) IS
SELECT ICP_MODIFIER ICPBusinessModifier, icp_funding_level ICPFundingLevel
  FROM HR_BUDGET_ICPMODIFIERS
 WHERE fy_cycle_idfk = p_CycleID
 AND COMPANY_IDFK = 0; -- as of 2010 we're using the same company (0 default)

-- cycle cursors
CURSOR c_getCycleCtrlInfo(p_CycleID NUMBER) IS
   SELECT
   c.HRTOOL_IDFK ToolID,
   c.FY_IDFK,
   c.cycle_name,
   c.is_refresh_paused,
   CASE
		WHEN HRTOOL_IDFK = 'OPM' THEN 1
		WHEN TRUNC(empdata_refresh_end_dt) IS NULL AND TRUNC(empdata_refresh_start_dt) <= TO_DATE(SYSDATE) THEN 1
		WHEN TRUNC(empdata_refresh_start_dt) <= TO_DATE(SYSDATE) AND TRUNC(empdata_refresh_end_dt) >= TO_DATE(SYSDATE) THEN 1
		ELSE 0
		END AS IsRefreshActive,
   c.empdata_refresh_start_dt RefreshStartDate,
   c.empdata_refresh_end_dt RefreshEndDate,
   CASE
		WHEN HRTOOL_IDFK = 'OPM' THEN 1
		WHEN TRUNC(jobdata_refresh_end_dt) IS NULL AND TRUNC(jobdata_refresh_start_dt) <= TO_DATE(SYSDATE) THEN 1
		WHEN TRUNC(jobdata_refresh_start_dt) <= TO_DATE(SYSDATE) AND TRUNC(jobdata_refresh_end_dt) >= TO_DATE(SYSDATE) THEN 1
		ELSE 0
		END AS IsJobRefreshActive,
   c.jobdata_refresh_start_dt JobsRefreshStartDate,
   c.jobdata_refresh_end_dt JobsRefreshEndDate,
   c.start_dt,
   c.end_dt,
   c.fy_end_date,
   c.TERMINATION_CUTOFF_DATE TerminationCutoff,
   c.emp_eligibility_cutoff_date,
   c.loa_eligibility_cutoff_date,
   c.icp_loa_elig_cutoff_date, c.icp_emp_elig_cutoff_date, c.icp_term_cutoff_date,
   c.RELATED_CYCLE_IDFK RelatedSACycleID,
   c.TA_CYCLE_IDFK TACycleID
      FROM HR_FY_CYCLES c
     WHERE c.FY_CYCLE_ID = p_cycleid;
 

-- /// functions ////

FUNCTION getEmpName(p_EmployeeID IN NUMBER) RETURN VARCHAR2;

FUNCTION getPercent(p_num NUMBER, p_divisor NUMBER) RETURN NUMBER;

FUNCTION getRatingID(p_rating VARCHAR2) RETURN NUMBER;

FUNCTION getCompanyIDFromPA(p_PA VARCHAR2) RETURN NUMBER;
FUNCTION getCompanyNameFromPA(p_PA VARCHAR2) RETURN varchar2;

function getJobTitle(p_JobCode varchar2) return varchar2;

FUNCTION getSearchorg (p_EmployeeID NUMBER default null, 
    p_EmployeeName IN varchar2 default null,
    p_SearchType varchar2,
    p_ManagerID number,
    p_CycleID number default null) RETURN sys_refcursor;
  
  
-- /// procedures ////
PROCEDURE close_refcur (p_refcur IN OUT SYS_REFCURSOR);

PROCEDURE getEmpCycleData(
		  p_AllEmp      IN OUT   Globals.genrefcursor,
		  p_CA      IN OUT   Globals.genrefcursor,
		  p_PA      IN OUT   Globals.genrefcursor,
		  p_EmpData IN OUT   Globals.genrefcursor,
		  p_Orgs IN OUT Globals.genrefcursor,
		  p_Jobs IN OUT Globals.genrefcursor,
		  p_Curr IN OUT Globals.genrefcursor,
		  p_OrgUnit IN OUT Globals.genrefcursor,
		  p_CostCenter IN OUT Globals.genrefcursor,
		  p_CompGroup IN OUT Globals.genrefcursor,
		  p_emplType IN OUT Globals.genrefcursor,
		  p_Countries IN OUT Globals.genrefcursor,
		  p_EmpGroup IN OUT Globals.genrefcursor,
		  p_Preseve IN OUT Globals.genrefcursor,
		  p_EmployeeID NUMBER,
		  p_CycleID NUMBER,
		  p_ToolID VARCHAR2);

PROCEDURE saveHoldbacks(p_ManagerID IN NUMBER,
		  p_CycleId NUMBER, p_CompTypeID NUMBER, p_Value NUMBER,
		  p_LastModifiedByUserID NUMBER DEFAULT NULL,
		  p_LastModifiedAsRole VARCHAR2 DEFAULT 'Admin User');

PROCEDURE getEmpSearchResults(
    p_AllEmp      IN OUT   Globals.genrefcursor,
    p_EmployeeID NUMBER default null,
    p_EmployeeName varchar2 default null,
    p_UserID number,
    p_Distinct int default 0);

PROCEDURE updateCycleManagerNames(p_CycleID number);

PROCEDURE makeAuditTrailEntry(
    p_EmployeeID NUMBER,
    p_CycleID number,
    p_ModifiedByID number,
    p_OnBehalfOfID number default null,
    p_ModifierRole varchar2 default 'User',
    p_OldValue varchar2,
    p_NewValue varchar2,
    p_AuditItem varchar2,
		p_ModifiedVia varchar2 default 'Application',
		p_AuditContext varchar2 default null);

PROCEDURE updateMgrReports(p_ManagerID number, p_CycleID number, 
        p_CanDoCycleRefresh int default 0, 
        p_TopManagerID number default 117714);
   
     
END ng_shared;
/







create or replace
PACKAGE BODY  NG_SHARED 
AS

FUNCTION getCompanyIDFromPA(p_PA VARCHAR2) RETURN NUMBER IS
/* Derives the "Company ID" by using the employee's Personal Area (PA) as shown below:
    Begins with "AB" = Applied Biosystems
    CO10 = Applera/Corporate
    Begins with "CD" or "CL" = Celera (CD10, CL06, CL10)
    All others = Applied Biosystems (BP10, IN10, PB10, PK10) */
	v_CompanyID NUMBER := 2; -- default AB
BEGIN
	 IF p_PA = 'CO10' THEN v_CompanyID := 1;
	 ELSIF SUBSTR(p_PA,1,2) = 'AB' THEN v_CompanyID := 2;
   ELSIF SUBSTR(p_PA,1,4) = 'IN10' THEN v_CompanyID := 2;
   ELSIF SUBSTR(p_PA,1,1) = 'I' THEN v_CompanyID := 7;
	 ELSIF SUBSTR(p_PA,1,2) IN  ('CD','CL') THEN v_CompanyID := 3;
   ELSIF SUBSTR(p_PA,1,4) IN  ('AX10','PA01','PA10') THEN v_CompanyID := 3;
	 ELSE v_CompanyID := 2;
	 END IF;

	 RETURN v_CompanyID;
END getCompanyIDFromPA;

FUNCTION getCompanyNameFromPA(p_PA VARCHAR2) RETURN varchar2 is
/* Derives the "Company Name" by using the employee's Personal Area (PA) as shown below:
    Begins with "AB" = Applied Biosystems
    CO10 = Applera/Corporate
    Begins with "CD" or "CL" = Celera (CD10, CL06, CL10)
    All others = Applied Biosystems (BP10, IN10, PB10, PK10) */
  v_CompanyName VARCHAR2(50);

begin
	 IF p_PA = 'CO10' THEN v_CompanyName := 'Applera/Corporate';
	 ELSIF SUBSTR(p_PA,1,2) = 'AB' THEN v_CompanyName := 'Applied Biosystems';
   ELSIF SUBSTR(p_PA,1,4) = 'IN10' THEN v_CompanyName := 'Applied Biosystems';
   ELSIF SUBSTR(p_PA,1,1) = 'I' THEN v_CompanyName := 'Invitrogen';
	 ELSIF SUBSTR(p_PA,1,2) IN  ('CD','CL') THEN v_CompanyName := 'Celera';
   ELSIF SUBSTR(p_PA,1,4) IN  ('AX10','PA01','PA10') THEN v_CompanyName := 'Celera';
	 ELSE v_CompanyName := 'Applied Biosystems';
	 END IF;

	 RETURN v_CompanyName;
end getCompanyNameFromPA;

FUNCTION getEmpName(p_EmployeeID IN NUMBER) RETURN VARCHAR2 IS
v_employeeName VARCHAR2(100);
CURSOR c_getEmpName(p_EmployeeID  NUMBER) IS
   SELECT decode(e.known_as,null,e.first_name,e.known_as) || ' ' || e.last_name EmployeeName
   FROM HR_EMPLOYEES e
   WHERE e.emp_id = p_EmployeeID;
BEGIN
   OPEN c_getEmpName(p_EmployeeID);
   FETCH c_getEmpName INTO v_employeeName;
   CLOSE c_getEmpName;
   RETURN v_employeeName;
END getEmpName;

function getJobTitle(p_JobCode varchar2) return varchar2 is

cursor c_Job is
  select job_title
  from hr_jobs
  where job_code = p_JobCode;
v_return VARCHAR2(75);

begin
  open c_Job;
  fetch c_Job into v_return;
  close c_Job;
  
  return v_return;
end getJobTitle;

FUNCTION getPercent(p_num NUMBER, p_divisor NUMBER) RETURN NUMBER IS

BEGIN
	IF NVL(p_divisor,0) > 0 THEN
	 	RETURN (NVL(p_num,0) / p_divisor) * 100;
	ELSE RETURN 0;
	END IF;
END getPercent;

FUNCTION getRatingID(p_rating VARCHAR2) RETURN NUMBER IS
BEGIN
	 IF trim(p_rating) = 'Exceeds Expectations' THEN RETURN 1;
	 ELSIF trim(p_rating) = 'Successful' THEN RETURN 2;
	 ELSIF trim(p_rating) = 'Needs Improvement' THEN RETURN 3;
	 ELSIF trim(p_rating) = 'High' then return 1;
   ELSIF trim(p_rating) = 'Medium' or trim(p_rating) = 'Solid' then return 2;
  ELSIF trim(p_rating) = 'Low' then return 3;
   ELSE RETURN 4;
	 END IF;
END getRatingID;

PROCEDURE close_refcur (p_refcur IN OUT SYS_REFCURSOR) IS
BEGIN
    CLOSE p_refcur;
END;

PROCEDURE getEmpCycleData(
		  p_AllEmp      IN OUT   Globals.genrefcursor,
		  p_CA      IN OUT   Globals.genrefcursor,
		  p_PA      IN OUT   Globals.genrefcursor,
		  p_EmpData IN OUT   Globals.genrefcursor,
		  p_Orgs IN OUT Globals.genrefcursor,
		  p_Jobs IN OUT Globals.genrefcursor,
		  p_Curr IN OUT Globals.genrefcursor,
		  p_OrgUnit IN OUT Globals.genrefcursor,
		  p_CostCenter IN OUT Globals.genrefcursor,
		  p_CompGroup IN OUT Globals.genrefcursor,
		  p_emplType IN OUT Globals.genrefcursor,
		  p_Countries IN OUT Globals.genrefcursor,
		  p_EmpGroup IN OUT Globals.genrefcursor,
		  p_Preseve IN OUT Globals.genrefcursor,
		  p_EmployeeID NUMBER,
		  p_CycleID NUMBER,
		  p_ToolID VARCHAR2)IS
BEGIN

OPEN p_Jobs FOR SELECT JOB_CODE JobCode, JOB_CODE || ':  ' || JOB_TITLE JobTitle FROM HR_JOBS ORDER BY JOB_CODE;
OPEN p_Curr FOR SELECT CURRENCY_CODE CurrencyCode, VALUE_IN_USD CurrencyValue FROM HR_CURRENCIES WHERE FY_CYCLE_IDFK = p_CycleID ORDER BY CURRENCY_CODE;
OPEN p_OrgUnit FOR SELECT DISTINCT Org_Unit_Code OrgUnitCode FROM HR_CYCLE_DATA WHERE Org_Unit_Code IS NOT NULL ORDER BY Org_Unit_Code;
OPEN p_CostCenter FOR SELECT DISTINCT COST_CENTER_CODE CostCenterCode FROM HR_CYCLE_DATA WHERE COST_CENTER_CODE IS NOT NULL ORDER BY COST_CENTER_CODE;
OPEN p_CompGroup FOR SELECT DISTINCT COMPENSATION_GROUP CompGroup FROM HR_CYCLE_DATA WHERE COMPENSATION_GROUP IS NOT NULL ORDER BY COMPENSATION_GROUP;
OPEN p_emplType FOR SELECT DISTINCT Employment_Type FROM HR_CYCLE_DATA WHERE Employment_Type IS NOT NULL ORDER BY Employment_Type;
OPEN p_Countries FOR SELECT DISTINCT EMPLOYMENT_COUNTRY_TXT Country FROM HR_CYCLE_DATA ORDER BY EMPLOYMENT_COUNTRY_TXT;
OPEN p_EmpGroup FOR SELECT DISTINCT EMPLOYMENT_group_name EmploymentGroupName FROM HR_CYCLE_DATA WHERE EMPLOYMENT_group_name IS NOT NULL ORDER BY EMPLOYMENT_group_name;
OPEN p_Orgs FOR SELECT DIV_ID OrgID, DIV_ID || ':  ' || DIV_NAME OrgName FROM DIVISIONS ORDER BY DIV_ID;

OPEN p_Preseve FOR
SELECT DB_TABLE_NAME || ':' || DB_FIELD_NAME PreserveField
FROM HR_OVERRIDES
WHERE FY_CYCLE_IDFK = p_CycleID
AND PK_VALUE = TO_CHAR(p_EmployeeID);

OPEN p_AllEmp FOR
SELECT   e.emp_id EmployeeID,
         NVL (e.display_name_lf, 'None') || ' ID: ' || TO_CHAR (e.emp_id) EmployeeName
    FROM HR_EMPLOYEES e
   WHERE current_status = 'Active'
ORDER BY e.display_name_lf;

OPEN p_CA FOR
SELECT DISTINCT cd.CAID, TO_CHAR (cd.CAID) || ':  ' || cd.COMP_AREA_NAME CompAreaName
           FROM HR_COMP_AREAS cd
          WHERE cd.CAID IS NOT NULL
       ORDER BY cd.CAID;

OPEN p_PA FOR
SELECT DISTINCT PAID, PERSONNEL_AREA_NAME PersonnelAreaName
           FROM HR_PERSONNEL_AREAS
          WHERE PERSONNEL_AREA_NAME IS NOT NULL
       ORDER BY PERSONNEL_AREA_NAME;

OPEN p_EmpData FOR
		/* /// getCycleData() /// */
	SELECT
		e.EMP_ID EmployeeID,
		e.EMP_ID UserID,
		e.DISPLAY_NAME EmployeeName,
		e.DISPLAY_NAME EmpDisplayName,
		e.LOGIN_NAME UserName,
		e.FIRST_NAME FirstName,
		e.KNOWN_AS KnownAs,
		e.MIDDLE_NAME MiddleName,
		e.LAST_NAME LastName,
		e.DISPLAY_NAME_LF EmpDisplayNameLF,
		e.SSN,
		e.BIRTH_DATE DOB,
		TRUNC((SYSDATE -  NVL(E.BIRTH_DATE,SYSDATE) )/365) AS Age,
		e.GENDER,
		e.STREET_ADDRESS StreetAddress,
	    e.ADDRESS_LINE2 StreetAddressLine2,
	    e.CITY City,
	    e.STATE State,
		e.district,
	    e.ZIPCODE ZipCode,
	    e.COUNTRY Country,
		e.Ethnicity,
		e.LAST_HIRE_DATE MRHireDate,
		e.TERMINATED_DATE TerminatedDate,
		e.CURRENT_STATUS EmpStatus,
		LOWER(e.email) email,
		NVL(cd.Manager_idfk,99999999) ManagerID,
		trim(cd.CYCLE_GRADE) CareerBand,
		cd.PAY_SCALE_LEVEL payScaleLevel,
		DECODE(cd.EXEMPT_STATUS_ID, 1, 'Exempt', 'Non-Exempt') ExemptStatus,

 		(NVL(CD.FULL_TIME_SALARY,0) * cd.PERCENT_TIME_WORKED / 100) AnnualSalary,
		((NVL(CD.FULL_TIME_SALARY,0) * cd.PERCENT_TIME_WORKED) / 100 *  cu.VALUE_IN_USD) AnnualSalaryUSD,
		cd.PERCENT_TIME_WORKED PercentTimeWorked,
		cd.Employment_Type EmploymentType,
		cu.VALUE_IN_USD CurrencyInUSD,
		cd.FULL_TIME_SALARY FullTimeSalary,
		(cd.FULL_TIME_SALARY * cu.VALUE_IN_USD) FullTimeSalaryUSD,
		cd.SALARY_CURRENCY_IDFK SalaryCurrency,
		div.DIV_BUS_ID CompanyID,
		DECODE(SUBSTR(c.BUS_NAME, 1, 6), 'Celera', 'Celera', c.BUS_NAME) CompanyName,
		cd.ORG_IDFK OrgID,
		div.DIV_NAME OrgName,
		cd.JOB_CODE_IDFK JobCode,
		cd.POSITION_IDFK PositionID,
		cd.POSITION_TITLE PositionTitle,
		NVL(cd.DIRECT_REPORTS,0) DirectReports,
		NVL(cd.TOTAL_REPORTS,0) TotalReports,
		cd.MANAGER_NAME ManagerName,
		cd.CA_IDFK CAID,
 		cd.PA_IDFK PAID,
		cd.EMPLOYMENT_LOCATION_TXT EmploymentLocation,
 		cd.EMPLOYMENT_COUNTRY_TXT EmploymentCountry,
		cd.COMP_GLOBAL_REGION CompensationGlobalRegion,
		cd.COMPENSATION_GROUP CompensationGroup,
		NVL(cd.TTCC_PERCENT,0) PercentOfTTCC,
		DECODE(p_ToolID,'Equity',NVL(cd.TTCC_AMOUNT,0),
				DECODE(cd.ICP_Eligible_SAP,0,NULL,(cd.FULL_TIME_SALARY * NVL(cd.ICP_TARGET_PERC_FORCALC,0)) + cd.FULL_TIME_SALARY) ) TTCCAmount,

		NVL((cd.TTCC_AMOUNT * tcu.VALUE_IN_USD),0) AS TTCCAmountUSD,
		cd.TTCC_CURRENCY_IDFK TTCCCurrency,
		cd.pm_type PMType,
		 NVL(cd.comments,'None') Comments,
		NVL(cd.TARGET_COMMISSION,0) TargetCommission,
		NVL(cd.BONUS_TARGET,0) BonusTarget,
		cd.BRIDGED_SERVICE_DATE BridgedServiceDate,
		cd.COST_CENTER_CODE CostCenterCode,
 		cd.Org_Unit_Code OrgUnitCode,
		NVL(cd.ICP_TARGET_PERCENT,0) ICPTargetPercent,
		NVL(cd.ICP_TARGET_PERC_FORCALC,0) ICPTargetPercForCalc,
		cd.PERS_TARGET_PERCENT ICPPersonalTargetPercent,
		cd.LAST_LOA LastLOA,
		DECODE(cd.Employment_Type, 'Expatriate', 'Yes', 'No') Expatriate,
 		cd.IS_LOAELIGIBLE IsLOAEligible,
 		cd.IS_EMP_DURATION_ELIGIBLE IsEmpDurationEligible,
		cd.IS_TERMINATED_ELIGIBLE IsTerminatedEligible,
		cd.IS_RECORD_UPDATABLE isRecordUpdatable,
		cd.IS_ELIGIBILITY_UPDATABLE IsEligibilityUpdatable,

		/* /// Placeholder JGA Check /// */
		NULL AS PerformanceString,
		0 AS SAIsTopContributor,
		'0:0' ComboGrade,
		cd.pay_type PayType,
		cd.in_job_date InJobDate,
		cd.yearly_pay_periods YearlyPayPeriods,
		cd.earnings_eligible EarningsEligible,
		cd.earnings_overtime EarningsOvertime,
		cd.earnings_DNAaward EarningsDNAAward,
		Globals.getICPModifier(cd.fy_cycle_idfk,
								 div.div_bus_id,
								 cd.org_unit_code
								) AS ICPBusinessModifier,

		cd.ICP_Org_Unit_CodeFK ICPOrgUnitCode,
		cd.ICP_Eligible_SAP ICPEligibleSAP,
		cd.Last_Increase_Date LastIncreaseDate,
		cd.Base_Pay BasePay,
		cd.Position_Pay PositionPay,
		cd.Bonus_Eligible BonusEligible,
		cd.Payroll_Area PayrollArea,
		cd.Sal_Planning_Eligible_SAP SalPlanningEligibleSAP,
		cd.Sal_Compensation_Eligible_SAP SalCompensationEligibleSAP,
		cd.Sal_Commission_Eligible_SAP SalCommissionEligibleSAP,
		cd.Employment_Group_Name EmploymentGroupName,
		cd.Local_Grade LocalGrade,
		cd.ICP_Grade ICPGrade,
    cd.COMP_LEVEL_ID CompLevelID
	FROM
		HR_CYCLE_DATA cd, HR_EMPLOYEES e,
		DIVISIONS div, BUSINESSES c,
		HR_CURRENCIES cu,
		HR_CURRENCIES tcu

	WHERE cd.emp_idfk(+) = e.emp_id
	AND cd.ORG_IDFK = div.DIV_ID(+)
	AND div.DIV_BUS_ID = c.BUS_ID(+)
	AND cd.SALARY_CURRENCY_IDFK = cu.currency_code(+)
	AND cu.FY_CYCLE_IDFK(+) = cd.FY_CYCLE_IDFK
	AND cd.TTCC_CURRENCY_IDFK = tcu.currency_code(+)
	AND tcu.FY_CYCLE_IDFK(+) = cd.FY_CYCLE_IDFK
	AND e.emp_id = p_EmployeeID
	AND cd.FY_CYCLE_IDFK(+) = p_CycleID;



END getEmpCycleData;


PROCEDURE saveHoldbacks(p_ManagerID IN NUMBER,
		  p_CycleId NUMBER, p_CompTypeID NUMBER, p_Value NUMBER,
		  p_LastModifiedByUserID NUMBER DEFAULT NULL,
		  p_LastModifiedAsRole VARCHAR2 DEFAULT 'Admin User') IS

CURSOR c_getHB IS
SELECT  bg.MANAGER_IDFK ManagerID, bg.COMP_TYPE_IDFK CompTypeID,
                NVL(bg.HOLDBACK_QTY,0)  HoldbackQty
      FROM HR_COMP_BUDGET bg
	  WHERE bg.FY_CYCLE_IDFK = p_CycleID
	  AND bg.COMP_TYPE_IDFK = p_CompTypeID
	  AND NVL(bg.HOLDBACK_QTY,0) <> 0;

CURSOR c_existHB IS
SELECT  bg.MANAGER_IDFK ManagerID, bg.COMP_TYPE_IDFK CompTypeID,
                NVL(bg.HOLDBACK_QTY,0) HoldbackQty
      FROM HR_COMP_BUDGET bg
	  WHERE bg.FY_CYCLE_IDFK = p_CycleID
	  AND bg.COMP_TYPE_IDFK = p_CompTypeID
	  AND bg.MANAGER_IDFK = p_ManagerID;

CURSOR c_CTName IS
SELECT
	COMP_TYPE_NAME
	FROM HR_COMP_TYPES
	WHERE COMP_TYPE_ID = p_CompTypeID;

r_HB c_existHB%ROWTYPE;
v_isInPath PLS_INTEGER := 0;
v_oldVal NUMBER := NULL;
v_CTName VARCHAR2(25);
v_tmpMsg VARCHAR(50);

BEGIN

	 FOR x IN c_getHB LOOP
	 	 v_isInPath := Is_Cycleancestor(EmpID => p_ManagerID,
		 			   						  ManagerID => x.ManagerID,
											  CycleID => p_CycleID);
	 	 IF v_isInPath = 1 AND NVL(p_Value,0) != 0 THEN
		 	--Put_Trace(x.ManagerID || ' is ancestor of ' || p_ManagerID, p_Value, p_CompTypeID);
			DELETE HR_COMP_BUDGET WHERE MANAGER_IDFK = x.ManagerID AND COMP_TYPE_IDFK = p_CompTypeID AND FY_CYCLE_IDFK = p_CycleId;
		 	v_tmpMsg := ' (Removed from ' || x.ManagerID || ')';
		 ELSE
			  -- now check descendant
			 v_isInPath := Is_Cycleancestor(EmpID => x.ManagerID,
			 			   						  ManagerID => p_ManagerID,
												  CycleID => p_CycleID);
			 IF v_isInPath = 1 AND NVL(p_Value,0) != 0 THEN
			 	--Put_Trace( x.ManagerID || ' is descendant of ' || p_ManagerID, p_Value, p_CompTypeID);
				DELETE HR_COMP_BUDGET WHERE MANAGER_IDFK = x.ManagerID AND COMP_TYPE_IDFK = p_CompTypeID AND FY_CYCLE_IDFK = p_CycleId;
			 	v_tmpMsg := ' (Removed HB from ' || x.ManagerID || ')';
			 END IF;
		 END IF;
	 END LOOP;



	OPEN c_existHB;
	FETCH c_existHB INTO r_HB;
	 	  IF c_existHB%FOUND THEN
		  	 v_oldVal := r_HB.HoldbackQty;
		  END IF;
	CLOSE c_existHB;

	IF NVL(v_oldVal,0) != p_Value THEN

	   OPEN c_CTName;
	   FETCH c_CTName INTO v_CTName;
	   CLOSE c_CTName;

		-- delete old value
		DELETE FROM HR_COMP_BUDGET
		WHERE MANAGER_IDFK = p_ManagerID AND COMP_TYPE_IDFK = p_CompTypeID AND FY_CYCLE_IDFK = p_CycleId;
		-- new value
		INSERT INTO HR_COMP_BUDGET (MANAGER_IDFK, FY_CYCLE_IDFK, COMP_TYPE_IDFK, HOLDBACK_QTY)
		VALUES ( p_ManagerID, p_CycleID, p_comptypeid,p_Value);
	   	Dr.addAuditEntry (p_ManagerID,
                 p_CycleID,
                 p_LastModifiedByUserID,
                 p_LastModifiedByUserID,
                 p_LastModifiedAsRole,
                 v_oldVal,
                 'Added ' || p_Value || v_tmpMsg,
                 p_LastModifiedAsRole,
                 SYSDATE,
                 'Holdbacks',
                 v_CTName || ' Holdback'
                );
	END IF;


END saveHoldbacks;

PROCEDURE getEmpSearchResults(
    p_AllEmp      IN OUT   Globals.genrefcursor,
    p_EmployeeID NUMBER default null,
    p_EmployeeName varchar2 default null,
    p_UserID number,
    p_Distinct int default 0) is

    /*
      Search 
      
      1) Look for the employee (search criteria) in the table
      2) Search for the active cycles (in addition to the OPM cycle which will always be active)
          In which the UserID is either HRM or part of the hierarchy in reverse order. 
      
    */    
TYPE EmpRecType IS RECORD (
      EmployeeID hr_employees.DISPLAY_NAME%TYPE,
      EmployeeName hr_employees.DISPLAY_NAME%TYPE,
      CompLevelID hr_cycle_data.comp_level_id%type,
      UserName hr_employees.login_name%TYPE,
      DirectReports hr_employees.direct_reports%TYPE,
      Status hr_employees.CURRENT_STATUS%TYPE
   ); 
   
-- types to be used in the search
EmpCycleAccess hrshared.EmpCycleAccessType;
EmpRecord EmpRecType; -- from local declare so I don't brake other procs using hrshared.EmpRecType

CURSOR c_ActiveCycles is
  SELECT hc.fy_cycle_id cycleID, hc.fy_idfk FYID, hc.cycle_name CycleName,
    hc.hrtool_idfk HRToolID,
    NVL(hc.is_disabled,0) IsDisabled,
    CASE
			WHEN TRUNC(hc.START_DT) <= TO_DATE(SYSDATE) AND TRUNC(hc.END_DT) >= TO_DATE(SYSDATE) THEN 1
			ELSE 0
    END AS CycleIsActive,
    hc.RELATED_CYCLE_IDFK RelatedSACycleID    
    FROM hr_fy_cycles hc
    WHERE TRUNC(hc.START_DT) <= TO_DATE(SYSDATE) AND TRUNC(hc.END_DT) >= TO_DATE(SYSDATE)
    AND hc.hrtool_idfk != 'OPM'
    --AND NVL(hc.is_disabled,0) = 0
    UNION
    SELECT hc.fy_cycle_id cycleID, hc.fy_idfk FYID, hc.cycle_name CycleName,
    'OPM' as HRToolID,
    0 AS IsDisabled,
    1 AS CycleIsActive,
    0 as RelatedSACycleID
  FROM hr_fy_cycles hc
  WHERE hc.fy_cycle_id = 0;

  gen_refcur  SYS_REFCURSOR;
  toolAccessCur  SYS_REFCURSOR;
  v_SearchType varchar2(15);
  v_hasCycleAccess int := 0;
  v_FYID number;

BEGIN
    
    --delete from tracedebug;
    DELETE FROM TMP_SEARCH;
    
    FOR x IN c_ActiveCycles LOOP
       v_hasCycleAccess := 1;
     
     /* find User access to the cycles (non OPM cycles) */
     IF x.CycleID != 0 THEN
          -- return the record with the employee access
          toolaccess.getuseraccess(x.CycleID, 
                                  null,
                                  p_UserID,
                                  0, 0, 1, 0, NULL, NULL,
                                 toolAccessCur);
      LOOP
        FETCH toolAccessCur into EmpCycleAccess;
        EXIT WHEN toolAccessCur%NOTFOUND;
         -- put_trace(EmpCycleAccess.ToolaccessGranted, EmpCycleAccess.EmployeeID);
          IF EmpCycleAccess.ToolaccessGranted = 'No Access' THEN v_hasCycleAccess := 0; END IF;
       END LOOP;
     
     END IF; -- EO x.CycleID != 0
     
     
    
     -- for each of the active cycles get the possible managers I am supporting 
      FOR y IN (
                SELECT -- HRM only
                    a.ASSIGN_EMP_IDFK AssignedEmpID
                FROM HR_ASSIGNMENTS a
                WHERE a.FY_CYCLE_IDFK = x.CycleID
                AND a.EMP_IDFK = p_UserID
                AND a.ASSIGNMENT_TYPE_IDFK = 1
                UNION
                SELECT p_UserID AS AssignedEmpID FROM DUAL) LOOP

          IF p_employeeid is NOT null THEN
            if x.CycleID = 0 then v_SearchType := 'OPMByID'; else v_SearchType := 'OtherByID'; end if;     
          ELSE       
            if x.CycleID = 0 then v_SearchType := 'OPMByName'; else v_SearchType := 'OtherByName'; end if;
          END IF;
          
          -- find the employees if user has access to cycle
          IF v_hasCycleAccess = 1 THEN 
            -- return a recordset of employees found using the criteria
            gen_refcur := hrshared.getSearchorg(p_EmployeeID,p_EmployeeName,v_SearchType,y.AssignedEmpID,x.CycleID);
            
            LOOP
              FETCH gen_refcur INTO EmpRecord; 
              EXIT WHEN gen_refcur%NOTFOUND;
              -- put_trace(v_EmployeeName || ' ' || x.CycleID,v_EmployeeID,y.AssignedEmpID);
              if x.CycleID = 0 then 
                v_FYID := to_number(to_char(sysdate, 'yyyy'));
              else v_FYID := x.FYID; end if;
              
              INSERT INTO TMP_SEARCH (EID, EmployeeName, comp_level_id, CYCLENAME, CYCLEID, FOUND, managerid,
                      UserName, cycleIsActive, HRToolID,FYID,DirectReports,RelatedCycleID,
                      SEARCHTYPE,STATUS,isDisabled) 
                  VALUES (EmpRecord.EmployeeID, EmpRecord.EmployeeName, EmpRecord.CompLevelID, x.CycleName, x.CycleID, 1, y.AssignedEmpID,
                      EmpRecord.UserName, x.CycleIsActive , x.HrToolID, v_FYID, EmpRecord.DirectReports, x.RelatedSACycleID,
                      v_SearchType,EmpRecord.status, x.isDisabled );
                      
            END LOOP; -- eo gen_refcur
          END IF;  -- EO v_hasCycleAccess
         
      END LOOP; -- eo select
      
    END LOOP; -- eo x in c_ActiveCycles

   OPEN p_AllEmp FOR
      SELECT EID EmployeeID, CYCLENAME, CYCLEID, FOUND, EMPLOYEENAME, 
        ManagerID, 
        UserName,
        comp_level_id CompLevelID,
        cycleIsActive,
        isDisabled,
        HRToolID,
        FYID,
        DirectReports,
        RelatedCycleID as RelatedSACycleID,
        status as EmpStatus
      FROM TMP_SEARCH
      ORDER BY EmployeeID,CYCLEID,EMPLOYEENAME; 
    
END getEmpSearchResults;


FUNCTION getSearchorg (p_EmployeeID NUMBER default null, 
    p_EmployeeName IN varchar2 default null,
    p_SearchType varchar2,
    p_ManagerID number,
    p_CycleID number default null) RETURN sys_refcursor
AS mycurs sys_refcursor; 
    
BEGIN

IF p_SearchType = 'OPMByID' THEN

	OPEN mycurs FOR
	 SELECT e.emp_id EmployeeID,
				e.DISPLAY_NAME EmployeeName,
        null as CompLevelID,
        e.login_name UserName,
        e.direct_reports DirectReports,
        e.CURRENT_STATUS Status
  FROM HR_EMPLOYEES e  
  WHERE e.EMP_ID LIKE '%' || p_EmployeeID ||  '%'
  AND e.current_status = 'Active'
  START WITH e.manager_idfk	= p_ManagerID
						CONNECT BY PRIOR e.emp_id = e.manager_idfk;

 ELSIF p_SearchType = 'OPMByName' THEN
 OPEN mycurs FOR
  SELECT e.emp_id EmployeeID,
          e.DISPLAY_NAME EmployeeName,
          null as compLevelID,
          e.login_name UserName,
          e.direct_reports DirectReports,
          e.CURRENT_STATUS Status
    FROM HR_EMPLOYEES e  
    WHERE LOWER(e.DISPLAY_NAME) LIKE LOWER('%' || p_EmployeeName ||  '%')
    AND e.current_status = 'Active'
    START WITH e.manager_idfk	= p_ManagerID
						CONNECT BY PRIOR e.emp_id = e.manager_idfk;	
  
  ELSIF p_SearchType = 'OtherByID' THEN
    OPEN mycurs FOR
    SELECT cd.emp_idfk EmployeeID,
      e.DISPLAY_NAME EmployeeName,
      cd.comp_level_id CompLevelID,
      e.login_name UserName,
      cd.direct_reports DirectReports,
      e.CURRENT_STATUS Status
    FROM HR_CYCLE_DATA cd, hr_employees e
    WHERE cd.emp_idfk = e.emp_id  
      AND cd.FY_CYCLE_IDFK = p_CycleID
      AND e.EMP_ID LIKE '%' || p_EmployeeID ||  '%'
      AND e.current_status = 'Active'
      START WITH cd.manager_idfk = p_ManagerID
      CONNECT BY PRIOR cd.emp_idfk = cd.manager_idfk
        AND PRIOR cd.FY_CYCLE_IDFK = p_CycleID;  

  ELSIF p_SearchType = 'OtherByName' THEN
    OPEN mycurs FOR
    SELECT cd.emp_idfk EmployeeID,
      e.DISPLAY_NAME EmployeeName,
      cd.comp_level_id CompLevelID,
      e.login_name UserName,
      cd.direct_reports DirectReports,
      e.CURRENT_STATUS Status
    FROM HR_CYCLE_DATA cd, hr_employees e
    WHERE cd.emp_idfk = e.emp_id  
      AND cd.FY_CYCLE_IDFK = p_CycleID
      AND LOWER(e.DISPLAY_NAME) LIKE LOWER('%' || p_EmployeeName ||  '%')
      AND e.current_status = 'Active'
      START WITH cd.manager_idfk = p_ManagerID
      CONNECT BY PRIOR cd.emp_idfk = cd.manager_idfk
        AND PRIOR cd.FY_CYCLE_IDFK = p_CycleID; 
END IF;
  
  RETURN mycurs;
  
END getSearchorg;

PROCEDURE updateCycleManagerNames(p_CycleID number) is

BEGIN

  for x in (select distinct manager_idfk ManagerID from hr_cycle_data where fy_cycle_idfk = p_CycleID) loop
    update hr_cycle_data
    set manager_name = getEmpName(x.ManagerID)
    where manager_idfk = x.ManagerID 
    and fy_cycle_idfk = p_CycleID;
  end loop;

END updateCycleManagerNames;

PROCEDURE makeAuditTrailEntry(
    p_EmployeeID NUMBER,
    p_CycleID number,
    p_ModifiedByID number,
    p_OnBehalfOfID number default null,
    p_ModifierRole varchar2 default 'User',
    p_OldValue varchar2,
    p_NewValue varchar2,
    p_AuditItem varchar2,
		p_ModifiedVia varchar2 default 'Application',
		p_AuditContext varchar2 default null) IS

BEGIN

    INSERT
    INTO HR_AUDIT_TRAIL
      (
        EMP_IDFK,
        FY_CYCLE_IDFK,
        MODIFIED_BY_IDFK,
        ON_BEHALF_OF_IDFK,
        MODIFIER_ROLE,
        OLD_VALUE,
        NEW_VALUE,
        MODIFIED_VIA,
        MODIFIED_ON,
        AUDIT_CONTEXT,
        AUDIT_ITEM
      )
      VALUES
      (
        p_EmployeeID,
        p_CycleID,
        p_ModifiedByID,
        p_OnBehalfOfID,
        p_ModifierRole,
        p_OldValue,
        p_NewValue, 
        p_ModifiedVia,
        SYSDATE,
        p_AuditContext,
        p_AuditItem
      );

END makeAuditTrailEntry;

PROCEDURE updateMgrReports(p_ManagerID number, p_CycleID number, 
      p_CanDoCycleRefresh int default 0,
      p_TopManagerID number default 117714) IS

cursor c_ManagersOPM is
  SELECT e.emp_id EmployeeID
  FROM HR_EMPLOYEES e
  WHERE e.emp_id <> 99999999
  AND e.current_Status = 'Active'
  --AND e.direct_reports > 0
  CONNECT BY e.emp_id = PRIOR  e.manager_idfk
      AND e.emp_id not in(99999999,p_TopManagerID)
    START WITH e.emp_id = p_ManagerID 
  UNION
  SELECT e.emp_id EmployeeID
  FROM HR_EMPLOYEES e  
  WHERE e.emp_id <> p_ManagerID
  AND e.current_Status = 'Active'
  --AND e.direct_reports > 0
  START WITH e.emp_ID = p_ManagerID
    CONNECT BY PRIOR e.emp_id = e.MANAGER_IDFK;
    
cursor c_Managers is
  SELECT cd.emp_idfk EmployeeID
  FROM hr_cycle_data cd
  WHERE cd.emp_idfk <> 99999999
  --AND cd.direct_reports > 0
  CONNECT BY cd.emp_idfk = PRIOR  cd.manager_idfk
      AND cd.emp_idfk not in(99999999,p_TopManagerID)
      AND cd.fy_cycle_idfk = p_CycleID
    START WITH cd.emp_idfk = p_ManagerID 
    AND cd.fy_cycle_idfk = p_CycleID
  UNION
  SELECT cd.emp_idfk EmployeeID
  FROM hr_cycle_data cd  
  WHERE cd.emp_idfk <> p_ManagerID
  --AND cd.direct_reports > 0
  AND cd.fy_cycle_idfk = p_CycleID
  START WITH cd.emp_idfk = p_ManagerID
    CONNECT BY PRIOR cd.emp_idfk = cd.MANAGER_IDFK
    AND prior cd.fy_cycle_idfk = cd.FY_CYCLE_IDFK;


CURSOR c_DR (p_MANAGER_IDFK NUMBER) IS
   SELECT COUNT (1) AS CountEmp
     FROM HR_CYCLE_DATA h
    WHERE h.MANAGER_IDFK = p_MANAGER_IDFK
          AND h.FY_CYCLE_IDFK = p_CycleID;

CURSOR c_TR(p_MANAGER_IDFK NUMBER) IS
   SELECT     COUNT (1) AS CountEmp
         FROM HR_CYCLE_DATA h
        WHERE h.FY_CYCLE_IDFK = p_CycleID
   START WITH h.MANAGER_IDFK = p_MANAGER_IDFK
   CONNECT BY PRIOR h.EMP_IDFK = h.MANAGER_IDFK
          AND PRIOR h.FY_CYCLE_IDFK = p_CycleID;

CURSOR c_TROPM(p_ManagerID number) is
SELECT COUNT (1) AS CountEmp   
FROM HR_EMPLOYEES e
    WHERE e.CURRENT_STATUS = 'Active'
	   START WITH e.manager_idfk = p_ManagerID
	      CONNECT BY PRIOR e.emp_id = e.manager_idfk;

CURSOR c_DROPM(p_ManagerID number) is
SELECT COUNT (1) AS CountEmp   
FROM HR_EMPLOYEES e
    WHERE e.manager_idfk = p_ManagerID
    AND e.CURRENT_STATUS = 'Active';


v_EmpDirect   INTEGER;
v_Emptotal    INTEGER;
  
BEGIN

    if p_CycleID = 0 then
      for r_man in c_ManagersOPM loop
        v_EmpDirect := 0;
        v_Emptotal := 0;
      
        OPEN c_TROPM(r_man.EmployeeID); FETCH c_TROPM INTO v_Emptotal; CLOSE c_TROPM;
        OPEN c_DROPM(r_man.EmployeeID); FETCH c_DROPM into v_empdirect; CLOSE c_DROPM;
        
        UPDATE HR_EMPLOYEES SET TOTAL_REPORTS = v_Emptotal, DIRECT_REPORTS = v_EmpDirect WHERE EMP_ID = r_man.EmployeeID;
          
      end loop;
    else
      if p_CanDoCycleRefresh = 1 then

        FOR r_man IN c_Managers LOOP
            v_EmpDirect := 0;
            v_Emptotal := 0;

            OPEN c_DR (r_man.EmployeeID); FETCH c_DR INTO v_EmpDirect; CLOSE c_DR;
            OPEN c_TR (r_man.EmployeeID); FETCH c_TR INTO v_Emptotal; CLOSE c_TR;

            UPDATE HR_CYCLE_DATA SET TOTAL_REPORTS = v_Emptotal, DIRECT_REPORTS = v_EmpDirect
            WHERE EMP_IDFK = r_man.EmployeeID AND FY_CYCLE_IDFK = p_cycleId;
              
        END LOOP;

      end if; -- p_CanDoCycleRefresh
    end if; -- cycle 0 (opm)
  
END updateMgrReports;


END NG_SHARED;
/