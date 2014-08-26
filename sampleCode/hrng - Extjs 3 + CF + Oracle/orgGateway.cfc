<cfcomponent displayname="orgGateway" output="false">
	
	<cffunction name="init" access="public" output="false" returntype="orgGateway">
		<cfargument name="dsn" type="string" required="true" />
		<cfset variables.dsn = arguments.dsn />
		<cfreturn this />
	</cffunction>	
	
	<cffunction name="getManagerOrgFromPackage" access="public" returntype="struct">
		<cfargument name="managerID" type="numeric" required="yes">
		<cfargument name="CycleID" type="numeric" required="yes" hint="The Cycle ID">
		<cfargument name="OrgType" type="string" default="1">
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="20" required="no" />
		<cfargument name="sort" type="string" required="true" default="employeename" />
		<cfargument name="dir" type="string" required="true" default="ASC" />
		<cfargument name="userID" type="numeric" required="yes" default="0">
		<cfset var Data = StructNew()>
		<cfstoredproc procedure="ng_compService.getManagerOrg" datasource="#variables.dsn#">
			<cfprocresult name="Data.org">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_ManagerID" value="#arguments.managerID#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_CycleID" value="#arguments.CycleID#">	
			<cfprocparam type="In" cfsqltype="CF_SQL_INTEGER" variable="p_OrgType" value="#arguments.OrgType#">
			<cfprocparam type="In" cfsqltype="cf_SQL_VARCHAR" variable="p_SearchCriteria" value="#arguments.SearchCriteria#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_Start" value="#arguments.start#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_End" value="#arguments.end#">
			<cfprocparam type="In" cfsqltype="cf_SQL_VARCHAR" variable="p_sort" value="#arguments.sort#">
			<cfprocparam type="In" cfsqltype="cf_SQL_VARCHAR" variable="p_dir" value="#arguments.dir#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_userID" value="#arguments.UserID#">	
		</cfstoredproc>
		<cfreturn Data />
	</cffunction>

	<cffunction name="getManagerBudgetFromPackage" access="public" returntype="struct">
		<cfargument name="managerID" type="numeric" required="yes">
		<cfargument name="CycleID" type="numeric" required="yes" hint="The Cycle ID">
		<cfargument name="getEquity" type="numeric" required="yes" hint="Bring Equity info" default="1">
		<cfargument name="showHoldback" type="numeric" required="false" hint="Bring Equity info" default="0">
		<cfset var Data = StructNew()>
		<cfstoredproc procedure="ng_compService.getManagerCompBudget" datasource="#application.config.dsn#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_ManagerID" value="#arguments.managerID#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_CycleID" value="#arguments.CycleID#">	
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_doEquity" value="#arguments.getEquity#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_showHoldback" value="#arguments.showHoldback#">
			<cfprocresult name="Data.budget">
		</cfstoredproc>
		<cfreturn Data />
	</cffunction>
	
	<cffunction name="searchEmployeesByPageFromPackage" access="public" returntype="query">
		<cfargument name="ManagerID" type="numeric" required="yes">
		<cfargument name="CycleID" type="numeric" required="yes" hint="The Cycle ID">
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="20" required="no" />
		<cfargument name="userID" type="numeric" required="yes" default="0">
		<cfargument name="ManagersOnly" type="numeric" required="yes" default="0">
		<cfset var qData = "" />
		<cfstoredproc procedure="ng_compService.searchEmployeesByPage" datasource="#variables.dsn#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_ManagerID" value="#arguments.ManagerID#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_CycleID" value="#arguments.CycleID#">
			<cfprocparam type="In" cfsqltype="cf_SQL_VARCHAR" variable="p_SearchCriteria" value="#trim(arguments.SearchCriteria)#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_Start" value="#arguments.start#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_End" value="#arguments.end#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_userID" value="#arguments.userID#">	
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_ManagersOnly" value="#arguments.ManagersOnly#">		
			<cfprocresult name="qData" resultset="1">
		</cfstoredproc>
		<cfreturn qData />
	</cffunction>
	
	<cffunction name="saveCompInput" access="public" output="false" returntype="boolean">	
		<cfargument name="compInput" type="struct" required="true" />
		<cfscript>
			var success = updateCompInput(arguments.compInput);
			return success;	
		</cfscript>
	</cffunction>

	<cffunction name="updateCompInput" access="public" output="false" returntype="boolean" hint="The v_compInput.save() actually takes care of creating or updating the object.">
		<cfargument name="compInput" type="struct" required="true" />
		<cfset var qUpdate = "" />
		<cftry>
			<cfquery name="qUpdate" datasource="#variables.dsn#">
			declare
				v_compInput ngt_compInput;
			begin
			      v_compInput := New ngt_compInput(
					 cached => 0
					,EID =>  <cfqueryparam value="#arguments.compInput.EmployeeID#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.EmployeeID)#" />
					,CycleID => <cfqueryparam value="#arguments.compInput.CycleID#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.CycleID)#" />         
					,MeritAmt => <cfqueryparam value="#arguments.compInput.MeritAmt#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.MeritAmt)#" />  
					,MeritPerc => <cfqueryparam value="#arguments.compInput.MeritPerc#" CFSQLType="cf_sql_numeric" scale="1" null="#not len(arguments.compInput.MeritPerc)#" /> 
					,MeritOutsideRangeJust => <cfqueryparam value="#arguments.compInput.MeritOutsideRangeJust#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.MeritOutsideRangeJust)#" />
					,LumpSumAmt => <cfqueryparam value="#arguments.compInput.LumpSumAmt#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.LumpSumAmt)#" />
					,LumpSumPerc => <cfqueryparam value="#arguments.compInput.LumpSumPerc#" CFSQLType="cf_sql_numeric" scale="1" null="#not len(arguments.compInput.LumpSumPerc)#" />
					,LumpSumOutsideRangeJust => <cfqueryparam value="#arguments.compInput.LumpSumOutsideRangeJust#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.LumpSumOutsideRangeJust)#" />
					,AdjustmentAmt => <cfqueryparam value="#arguments.compInput.AdjustmentAmt#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.AdjustmentAmt)#" />
					,AdjustmentPerc => <cfqueryparam value="#arguments.compInput.AdjustmentPerc#" CFSQLType="cf_sql_numeric" scale="1" null="#not len(arguments.compInput.AdjustmentPerc)#" />
					,AdjustmentReason => <cfqueryparam value="#arguments.compInput.AdjustmentReason#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.AdjustmentReason)#" />
					,AdjustmentOutsideRangeJust => <cfqueryparam value="#arguments.compInput.AdjustmentOutsideRangeJust#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.AdjustmentOutsideRangeJust)#" />
					,AdjEffectiveDate => <cfqueryparam value="#arguments.compInput.AdjEffectiveDate#" CFSQLType="cf_sql_date" null="#not len(arguments.compInput.AdjEffectiveDate)#" />
					,NewJobCode => <cfqueryparam value="#arguments.compInput.NewJobCode#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.NewJobCode)#" />
					,NewJobJustification => <cfqueryparam value="#arguments.compInput.NewJobJustification#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.NewJobJustification)#" />
					,PromotionAmt => <cfqueryparam value="#arguments.compInput.PromotionAmt#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.PromotionAmt)#" />
					,PromotionPerc => <cfqueryparam value="#arguments.compInput.PromotionPerc#" CFSQLType="cf_sql_numeric" scale="1" null="#not len(arguments.compInput.PromotionPerc)#" />
					,PromotionEffectiveDate => <cfqueryparam value="#arguments.compInput.PromotionEffectiveDate#" CFSQLType="cf_sql_date" null="#not len(arguments.compInput.PromotionEffectiveDate)#" />
					,PromotionOutsideRangeJust => <cfqueryparam value="#arguments.compInput.PromotionOutsideRangeJust#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.PromotionOutsideRangeJust)#" />
					,ICPAward => <cfqueryparam value="#arguments.compInput.ICPAward#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.ICPAward)#" /> 
					,ICPOutsideRangeJust => <cfqueryparam value="#arguments.compInput.ICPOutsideRangeJust#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.ICPOutsideRangeJust)#" />
					,ICPIndivModifier => <cfqueryparam value="#arguments.compInput.ICPIndivModifier#" CFSQLType="cf_sql_numeric" scale="1" null="#not len(arguments.compInput.ICPIndivModifier)#" /> 
					,LTIGrantAmt => <cfqueryparam value="#arguments.compInput.LTIGrantAmt#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.LTIGrantAmt)#" />
					,LTGrantModifier => <cfqueryparam value="#arguments.compInput.LTGrantModifier#" CFSQLType="cf_sql_numeric" scale="1" null="#not len(arguments.compInput.LTGrantModifier)#" />
					,LTIGrantOutSideRangeJust => <cfqueryparam value="#arguments.compInput.LTIGrantOutSideRangeJust#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.LTIGrantOutSideRangeJust)#" />
					,LTIReceived => <cfqueryparam value="#arguments.compInput.LTIReceived#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.LTIReceived)#" /> 
					,SalICPComments => <cfqueryparam value="#arguments.compInput.SalICPComments#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.SalICPComments)#" />
					,EquityComments => <cfqueryparam value="#arguments.compInput.EquityComments#" CFSQLType="cf_sql_varchar" null="#not len(arguments.compInput.EquityComments)#" />
					,lastModifiedByID => <cfqueryparam value="#arguments.compInput.lastModifiedByID#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.lastModifiedByID)#" />
					,lastModifiedOnBehalfOfID => <cfqueryparam value="#arguments.compInput.lastModifiedOnBehalfOfID#" CFSQLType="cf_sql_numeric" null="#not len(arguments.compInput.lastModifiedOnBehalfOfID)#" />
					,lastModifiedOn => SYSDATE
			        );
			      
			      v_compInput.save();
			
			end;			
			</cfquery>
			<cfcatch type="database">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn true />
	</cffunction>
	
	<!--- reports --->
	<cffunction name="getManagerProgressQueryFromPackage" access="public" returntype="struct">
		<cfargument name="managerID" type="numeric" required="yes">
		<cfargument name="CycleID" type="numeric" required="yes" hint="The Cycle ID">
		<cfset var Data = StructNew()>
		<cfstoredproc procedure="ng_compProgReports.getManagerProgress" datasource="#variables.dsn#">
			
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_ManagerID" value="#arguments.managerID#">
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_CycleID" value="#arguments.CycleID#">
			<cfprocparam type="Out" cfsqltype="CF_SQL_VARCHAR" variable="Data.ManagerName">
			<cfprocresult name="Data.PlanningProgress" resultset="1">	
		</cfstoredproc>
		<cfreturn Data />
	</cffunction>
	
	<!--- Jobs --->
	<cffunction name="getJobSearchQuery" access="public" returntype="query">
	<cfargument name="JobCode" type="string" required="no" default="">
	<cfargument name="CycleID" type="numeric" required="no" default="0">
	<cfargument name="CAID" type="string" required="no" default="">
	<cfargument name="GradeFilter" type="string" required="no" default="">
	<cfargument name="JobLevel" type="string" required="no" default="">
	<cfargument name="JobTitle" type="string" required="no">
	<cfargument name="ExcludeJobCode" type="string" required="no" hint="Useful when searching">
	<cfargument name="JobCategory" type="string" required="no">
	<cfargument name="JobFamily" type="string" required="no">
	<cfargument name="JobFunctArea" type="string" required="no">	
	<cfargument name="SortBy" type="string" required="no" default="">
	<cfargument name="JobCountry" type="string" required="no" default="">
	<cfargument name="IsLegacy" type="numeric" required="no" default="0">
		<cfset var qJobs = "">
		<cfquery name="qJobs" datasource="#variables.dsn#">
		/* /// getJobSearchQuery() /// */
		 select 
		 	 o.*
	        ,jd.CA_IDFK CAID
	        ,jd.LOW_FTE LowFTE
	        ,jd.HIGH_FTE HighFTE
	        ,r.ICP_PERCENT * 100 ICPTargetPercent
	     from (
	     		SELECT 
		           j.JOB_CODE JobCode
		          ,j.job_title JobTitle
		          ,DECODE(j.JOB_EXEMPT, 'Y', 'Exempt', 'EX', 'Exempt' ,'N', 'Non-Exempt', 'NEX','Non-Exempt', NULL) JobExempt
		          ,j.job_grade CareerBand
		          ,j.job_level JobLevel
		          ,j.JOB_FAMILY JobFamily
		        FROM HR_JOBS j
		        WHERE 0=0

	        <cfif isDefined("arguments.JobCode") AND len(trim(arguments.JobCode))>
			AND LOWER(j.JOB_CODE) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Lcase(trim(arguments.JobCode))#">
			</cfif>
			
			<cfif isDefined("arguments.GradeFilter") AND len(trim(arguments.GradeFilter))>
			 AND j.JOB_GRADE IN(<cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#arguments.GradeFilter#" list="yes">)
			</cfif>
			
			<cfif isDefined("arguments.JobLevel") AND len(trim(arguments.JobLevel))>
			 AND j.JOB_LEVEL IN(<cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#arguments.JobLevel#" list="yes" separator="^">)
			</cfif>
			
			<cfif isDefined("arguments.JobFamily") AND len(trim(arguments.JobFamily))>
			 AND j.JOB_FAMILY = <cfqueryparam value="#trim(arguments.JobFamily)#" cfsqltype="CF_SQL_VARCHAR">
			</cfif>
			
			<cfif isDefined("arguments.JobFunctArea") AND len(trim(arguments.JobFunctArea))>
			AND j.JOB_FUNC_AREA = <cfqueryparam value="#trim(arguments.JobFunctArea)#" cfsqltype="CF_SQL_VARCHAR">
			</cfif>
			
			<cfif isDefined("arguments.JobTitle") AND len(trim(arguments.JobTitle))>
			AND LOWER(j.JOB_TITLE) || ' ' || LOWER(j.JOB_CODE) LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(trim(arguments.JobTitle))#%">
			</cfif>
			
			<cfif isDefined("arguments.ExcludeJobCode") AND len(trim(arguments.ExcludeJobCode))>
			AND j.JOB_CODE <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.ExcludeJobCode)#">
			</cfif>
			
			<cfif len(trim(arguments.JobCountry))>
			AND substr(j.job_code, 5, 2) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.JobCountry)#">
			</cfif>
			
	        <cfif isDefined("arguments.IsLegacy")>
			AND j.IS_LEGACY_JOB = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#Lcase(trim(arguments.IsLegacy))#">
			</cfif>
			
	     )o, HR_JOBS_DATA jd, HR_ICP_RATES r
	     where o.jobcode = jd.JOBCODE_IDFK(+)
	     and jd.FY_CYCLE_IDFK(+) = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#Lcase(trim(arguments.CycleID))#">
	     and jd.CA_IDFK(+) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.CAID)#">
		 and Getnumericval(r.GRADE_IDFK) = o.jobLevel
		 and r.FY_CYCLE_IDFK(+) = <cfqueryparam cfsqltype="CF_SQL_NUMBER" value="#Lcase(trim(arguments.CycleID))#">
		 
			<cfswitch expression="#arguments.SortBy#">
				<cfcase value="JobTitle">
					ORDER BY o.JobTitle
				</cfcase>
				<cfcase value="JobGrade">
					ORDER BY o.JobLevel
				</cfcase>
				<cfcase value="JobCode">
					ORDER BY o.JobCode
				</cfcase>
			</cfswitch>
		</cfquery>
		<cfreturn qJobs />
	</cffunction>	
	
	<cffunction name="getSalaryHistoryFromPackage" access="public" returntype="struct" hint="">
		<cfargument name="EmployeeID" type="numeric" required="yes">
		<cfargument name="CycleID" type="numeric" required="yes" hint="The current cycle ID">	
		<cfset var stData = StructNew()>
		<cfstoredproc procedure="ng_compHistory.getCompHistory" datasource="#variables.dsn#">
			<cfprocresult name="stData.SalaryHistory" resultset="1">
			<cfprocresult name="stData.ICPHistory" resultset="2">
			<cfprocresult name="stData.LTIHistory" resultset="3">
			<cfprocresult name="stData.OtherPaymts" resultset="4">	
			<cfprocparam type="In" cfsqltype="CF_SQL_NUMERIC" variable="p_EmployeeID" value="#arguments.EmployeeID#">
			<cfprocparam type="In" cfsqltype="CF_SQL_INTEGER" variable="p_CycleID" value="#arguments.CycleID#">
		</cfstoredproc>
		<cfreturn stData />
	</cffunction>
	
	<!--- <cffunction name="getManagerProgressQuery" access="public" returntype="query" hint="This only reports on direct reports">
		<cfargument name="ManagerID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no">
		<cfset var qData = "">
		<cfquery name="qData" datasource="#variables.dsn#">
			select
		    o.managerid
		   ,o.managername
		   ,sum(o.SalaryEligible) SalaryEligible
		   ,sum(o.salarydone) salarydone
		   ,sum(o.icpeligible) icpeligible
		   ,sum(o.icpdone) icpdone
		   ,sum(o.LTIEligible) LTIEligible
		   ,sum(o.ltidone) ltidone
		   
		  from (
		    select 
		      d.eid
		      ,d.managerid
		      ,d.manager.empname managername
		      ,d.compEmp.eligibility.isSalaryEligible SalaryEligible
		      ,decode(d.compEmp.eligibility.isSalaryEligible,0,0, decode(d.compInput.MeritAmt,null,decode(d.compInput.LumpSumAmt,null,0,1),1) ) salarydone     
		      ,d.compEmp.eligibility.isICPEligible icpeligible
		      ,decode(d.compEmp.eligibility.isICPEligible,0,0,decode(d.compInput.ICPIndivModifier,null,0,1)) icpdone      
		      ,d.compEmp.eligibility.isLTIEligible LTIEligible
		      ,decode(d.compEmp.eligibility.isLTIEligible,0,0,decode(d.compInput.LTIGrantAmt,null,0,1)) ltidone /* by default if not elig, it's done */
 
		      
		      FROM hr_compOrg d 
		        WHERE   d.cycleid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.CycleID#">
		        and level < 3 -- only direct report managers and the manager running it  
		          START WITH d.managerid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.ManagerID#">
		          CONNECT BY PRIOR d.eid = d.managerid
		            AND PRIOR d.cycleid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.CycleID#">
		 ) o
		 group by o.managerid, o.managername		
		</cfquery>
		<cfreturn qData />
	</cffunction>  --->
	
	<cffunction name="getOrgforTreeQuery" access="public" returntype="query">
		<cfargument name="managerID" type="numeric" required="true" default="99999999" />
		<cfargument name="cycleID" type="numeric" required="true" />
		<cfset var qOrg = "">
		<cfquery name="qOrg" datasource="#variables.dsn#">	
		   select 
		     d.eid
		    ,d.empName
		    ,d.managerid
		    ,d.compEmp.DirectReports DR
		    ,d.compEmp.TotalReports TR
		    <!--- ,level Hlevel --->		    
		   FROM hr_compOrg d
		   where d.managerid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.managerID#"> 
		   and d.cycleid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.cycleID#">
		   order by d.empName
		 <!---      START WITH d.managerid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.managerID#"> 
		      CONNECT BY PRIOR d.eid = d.managerid
		        AND PRIOR d.cycleid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.cycleID#"> --->
		</cfquery>
		<cfreturn qOrg />
	</cffunction>
		
</cfcomponent>	