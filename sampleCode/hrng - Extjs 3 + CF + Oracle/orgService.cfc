<cfcomponent name="orgService" output="false" ExtDirect="true">
	
	<cffunction name="init" access="public" output="false" returntype="orgService">
		<cfscript>
			variables.util = createobject('component','hrtools.cfcs.core.util');
			return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="setorgGateway" access="public" returntype="void" output="false" hint="I set the orgGateway.">
		<cfargument name="orgGateway" type="any" required="true" hint="orgGateway" />
		<cfset variables['orgGateway'] = arguments.orgGateway />
	</cffunction>	
	<cffunction name="getorgGateway" access="public" returntype="any" output="false" hint="I return the orgGateway.">
		<cfreturn variables['orgGateway'] />
	</cffunction>

	<cffunction name="createCompInput" access="public" returntype="struct" hint="simplified compInput object creation.">
		<cfargument name="EmployeeID" type="numeric" required="yes">
		<cfargument name="CycleID" type="numeric" required="yes" hint="The Cycle ID">
		<cfargument name="MeritAmt" type="string" required="no" default="">
		<cfargument name="MeritPerc" type="string" required="no" default="">
		<cfargument name="MeritOutsideRangeJust" type="string" required="no" default="">
		<cfargument name="LumpSumAmt" type="string" required="no" default="">
		<cfargument name="LumpSumPerc" type="string" required="no" default="">
		<cfargument name="LumpSumOutsideRangeJust" type="string" required="no" default="">
		<cfargument name="AdjustmentAmt" type="string" required="no" default="">
		<cfargument name="AdjustmentPerc" type="string" required="no" default="">
		<cfargument name="AdjustmentReason" type="string" required="no" default="">
		<cfargument name="AdjEffectiveDate" type="string" required="no" default="">
		<cfargument name="AdjustmentOutsideRangeJust" type="string" required="no" default="">
		<cfargument name="NewJobCode" type="string" required="no" default="">
		<cfargument name="NewJobJustification" type="string" required="no" default="">
		<cfargument name="PromotionAmt" type="string" required="no" default="">
		<cfargument name="PromotionPerc" type="string" required="no" default="">
		<cfargument name="PromotionEffectiveDate" type="string" required="no" default="">
		<cfargument name="PromotionOutsideRangeJust" type="string" required="no" default="">
		<cfargument name="ICPAward" type="string" required="no" default="">
		<cfargument name="ICPIndivModifier" type="string" required="no" default="">
		<cfargument name="ICPOutsideRangeJust" type="string" required="no" default="">
		<cfargument name="LTIGrantTarget" type="string" required="no" default="">
		<cfargument name="LTIGrantAmt" type="string" required="no" default="">
		<cfargument name="LTGrantModifier" type="string" required="no" default="">
		<cfargument name="LTIGrantOutSideRangeJust" type="string" required="no" default="">
		<cfargument name="LTIReceived" type="string" required="no" default="">
		<cfargument name="SalICPComments" type="string" required="no" default="">
		<cfargument name="EquityComments" type="string" required="no" default="">
		<cfargument name="lastModifiedByID" type="string" required="no" default="">
		<cfargument name="lastModifiedOnBehalfOfID" type="string" required="no" default="">
		<cfscript>
			var compInput = {
				 cache = 0
				,EmployeeID = arguments.EmployeeID
				,cycleid = arguments.cycleid
		        ,MeritAmt = arguments.MeritAmt
		        ,MeritPerc = arguments.MeritPerc
		        ,MeritOutsideRangeJust = arguments.MeritOutsideRangeJust
		        ,LumpSumAmt = arguments.LumpSumAmt
		        ,LumpSumPerc = arguments.LumpSumPerc
		        ,LumpSumOutsideRangeJust = arguments.LumpSumOutsideRangeJust
		        ,AdjustmentAmt = arguments.AdjustmentAmt
		        ,AdjustmentPerc = arguments.AdjustmentPerc
		        ,AdjustmentReason = arguments.AdjustmentReason
		        ,AdjEffectiveDate = arguments.AdjEffectiveDate
		        ,AdjustmentOutsideRangeJust = arguments.AdjustmentOutsideRangeJust
		        ,NewJobCode = arguments.NewJobCode
		        ,NewJobJustification = arguments.NewJobJustification
		        ,PromotionAmt = arguments.PromotionAmt
		        ,PromotionPerc = arguments.PromotionPerc
		        ,PromotionEffectiveDate = arguments.PromotionEffectiveDate
		        ,PromotionOutsideRangeJust = arguments.PromotionOutsideRangeJust
		        ,ICPAward = arguments.ICPAward
		        ,ICPIndivModifier = arguments.ICPIndivModifier
		        ,ICPOutsideRangeJust = arguments.ICPOutsideRangeJust
		        ,LTIGrantTarget = arguments.LTIGrantTarget
		        ,LTIGrantAmt = arguments.LTIGrantAmt
		        ,LTGrantModifier = arguments.LTGrantModifier
		        ,LTIGrantOutSideRangeJust = arguments.LTIGrantOutSideRangeJust
		        ,LTIReceived = arguments.LTIReceived
		        ,SalICPComments = arguments.SalICPComments
		        ,EquityComments = arguments.EquityComments
		        ,lastModifiedByID = arguments.lastModifiedByID
				,lastModifiedOnBehalfOfID = arguments.lastModifiedOnBehalfOfID			
			};
			return compInput;
		</cfscript>
	</cffunction>

	<cffunction name="getManagerOrg" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfargument name="ManagerID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfargument name="OrgType" type="string" default="1">
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="userID" type="string" default="0">
		<cfargument name="start" type="string" required="true" default="0" />
		<cfargument name="limit" type="string" required="true" default="25" />
		<cfargument name="sort" type="string" required="true" default="employeename" />
		<cfargument name="dir" type="string" required="true" default="ASC" />
		<cfscript>
			var qData = "";
			var aData = "";
			var MyStruct = StructNew();
			var idx = "";
			var _end = "";
						
			// prep the paging
			if(not len(trim(arguments.limit)) or not isnumeric(arguments.limit)) arguments.limit = 25;
			if(not len(trim(arguments.start)) or not isnumeric(arguments.start) or arguments.start eq 0) arguments.start = 1;				
			if(arguments.start eq 1) _end = arguments.limit;
			else { // set end point for oracle
				arguments.start = arguments.start + 1;
				_end = arguments.start + arguments.limit;
			}

			qData = getOrgGateway().getManagerOrgFromPackage(
						 ManagerID=arguments.ManagerID
						,CycleID=arguments.CycleID
						,orgType=arguments.orgType
						,SearchCriteria=replace(arguments.SearchCriteria,"'","''",'all')
						,start=arguments.start
						,sort=arguments.sort
						,dir=arguments.dir
						,end=_end
						,userid=arguments.userid).org;
						
			aData = variables.util.queryToArray(qData);
			
			if(listfindnocase(qData.columnlist,'totalcount') AND len(trim(qData.totalcount[1]))) MyStruct.RecordCount = qData.totalcount[1];
			else MyStruct.RecordCount = qData.recordcount;
			
			MyStruct.TOTALCOUNT = qData.totalcount[1];
			MyStruct.DATA = ArrayNew(1);
			for(idx = 1; idx lte qData.RecordCount; idx++){
				ArrayAppend(MyStruct.data, Duplicate(aData[idx]));
			}

			MyStruct.Success = true;
					
			return MyStruct;
		</cfscript>
	</cffunction>

	<cffunction name="getJobsSearch" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfargument name="JobCode" type="string" required="no" default="">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfargument name="CAID" type="string" required="no" default="">
		<cfargument name="GradeFilter" type="string" required="no" default="">
		<cfargument name="JobLevel" type="string" required="no" default="">
		<cfargument name="JobTitle" type="string" required="no">
		<cfargument name="ExcludeJobCode" type="string" required="no" hint="Useful when searching"> 
		<cfargument name="JobFamily" type="string" required="no">
		<cfargument name="JobFunctArea" type="string" required="no">
		<cfargument name="start" type="numeric" required="true" default="0" />
		<cfargument name="limit" type="numeric" required="true" default="24" />
		<cfargument name="sort" type="string" required="true" default="Platform" />
		<cfargument name="dir" type="string" required="true" default="ASC" />
		<cfscript>
			var qData = getOrgGateway().getJobSearchQuery(argumentCollection=arguments);
			var aData = variables.util.queryToArray(qData);
			var MyStruct = StructNew();
			var idx = "";
			
			Arguments.start++;
			Arguments.limit--;

			if(start + limit gt qData.RecordCount){
				Arguments.limit = qData.RecordCount - Arguments.start;
			}

			MyStruct.DATA = ArrayNew(1);
			for(idx = Arguments.start; idx lte Arguments.start + Arguments.limit; idx++){
				ArrayAppend(MyStruct.DATA, Duplicate(aData[idx]));
			}

			MyStruct.RecordCount = qData.RecordCount;
			MyStruct.Success = true;

			return MyStruct;
		</cfscript>
	</cffunction>

	<cffunction name="getManagerBudget" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfargument name="ManagerID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfargument name="getEquity" type="numeric" required="yes" hint="Bring Equity info" default="1">
		<cfargument name="showHoldback" type="numeric" required="false" hint="Bring Equity info" default="0">
		<cfscript>
			var qData = getOrgGateway().getManagerBudgetFromPackage(argumentCollection=arguments).budget;
			var aData = variables.util.queryToArray(qData);
			var MyStruct = StructNew();
			var idx = "";

			MyStruct.data = ArrayNew(1);
			
			for(idx = 1; idx lte qData.RecordCount; idx++){
				ArrayAppend(MyStruct.data, Duplicate(aData[idx]));
			}

			MyStruct.RecordCount = qData.RecordCount;
			MyStruct.Success = true;

			return MyStruct;
		</cfscript>
	</cffunction>		
	
	<cffunction name="saveCompInput" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfscript>
			var result = structNew(); 
			var check = "";
		    var compInput = createCompInput(argumentCollection=arguments);
				try {
					check = getorgGateway().saveCompInput(compInput);
					if(check) result.success = true;
				} catch (any e) {
					result.success = false;
					result.ErrorComponent = 'orgService';
					result.ErrorMethod = 'saveCompInput';
					result.ErrorType = "InvocationError";
					result.ErrorMessage = e.Message & e.detail;
				}
			return result;
		</cfscript>
	</cffunction>
	
	<cffunction name="searchEmployees" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfargument name="ManagerID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfargument name="OrgType" type="string" default="1">
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" required="true" default="0" />
		<cfargument name="limit" required="true" default="20" />	
		<cfargument name="userID" type="string" default="0">
		<cfargument name="ManagersOnly" type="numeric" required="yes" default="0">	
		<cfscript>
			var qData = "";
			var aData = "";
			var MyStruct = StructNew();
			var idx = "";
			var _end = "";

			// TODO: ASAP Find if user is admin, in which case all managers can be shown
			
			// prep the paging
			if(not len(trim(arguments.start)) or arguments.start eq 0) arguments.start = 1;				
			if(arguments.start eq 1) _end = arguments.limit;
			else { // set end point for oracle
				arguments.start = arguments.start + 1;
				_end = arguments.start + arguments.limit;
			}

			qData = getOrgGateway().searchEmployeesByPageFromPackage(
						 ManagerID=arguments.ManagerID
						,CycleID=arguments.CycleID
						,SearchCriteria=trim(arguments.SearchCriteria)
						,start=arguments.start
						,end=_end
						,userid=arguments.userid
						,ManagersOnly=arguments.ManagersOnly);
						
			aData = variables.util.queryToArray(qData);
			
			if(listfindnocase(qData.columnlist,'totalcount') AND len(trim(qData.totalcount[1]))) MyStruct.RecordCount = qData.totalcount[1];
			else MyStruct.RecordCount = qData.recordcount;
			
			MyStruct.DATA = ArrayNew(1);
			for(idx = 1; idx lte qData.RecordCount; idx++){
				ArrayAppend(MyStruct.data, Duplicate(aData[idx]));
			}

			MyStruct.Success = true;
					
			return MyStruct;
		</cfscript>
	</cffunction>
	
	<cffunction name="getOrgforTree" access="public" ExtDirect="true" returntype="array">  
		<cfargument name="managerID" type="numeric" required="true" default="99999999" />
		<cfargument name="cycleID" type="numeric" required="true" />
		<!--- <cfargument name="UserSession" type="struct" required="true"/> --->
	    <cfscript>
			var qData = "";	
			var nodes = ArrayNew(1);
			var temp = "";	
			var sToReturn = "";
			
			qData = getOrgGateway().getOrgforTreeQuery(argumentcollection=arguments);
					
		</cfscript> 
		<cfoutput query="qData">
			<cfscript>
				temp = StructNew();
		        temp['id'] = '#eid#';
		        temp['text'] = '#empName#';
				temp['cls'] = 'forum-ct';
				temp['iconCls'] = 'forum-parent';
				temp['expanded'] = false;
		      	temp['leaf'] = iif(dr eq 0,de('true'),de('false'));

				ArrayAppend(nodes, temp);
			</cfscript>
		</cfoutput>
		<cfreturn nodes /> 
	</cffunction>

	
	<!--- progress/history --->
	<cffunction name="getManagerProgress" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfargument name="ManagerID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfargument name="sort" type="string" required="true" default="" />
		<cfargument name="dir" type="string" required="true" default="ASC" />
		<cfscript>
			var qData = getorgGateway().getManagerProgressQueryFromPackage(argumentCollection=arguments).PlanningProgress;
			var aData = variables.util.queryToArray(qData);
			var MyStruct = StructNew();
			var idx = "";

			MyStruct.data = ArrayNew(1);
			for(idx = 1; idx lte qData.RecordCount; idx++){
				ArrayAppend(MyStruct.data, Duplicate(aData[idx]));
			}

			MyStruct.RecordCount = qData.RecordCount;
			MyStruct.Success = true;

			return MyStruct;
		</cfscript>
	</cffunction>

	<cffunction name="getCompHistory" access="public" returntype="struct" ExtDirect="true" output="false">
		<cfargument name="EmployeeID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfargument name="historyKey" type="string" required="true" default="SalaryHistory" />
		<cfscript>
			var stHistory = setCompHistory(argumentcollection=arguments);
			return stHistory[historyKey]; 
		</cfscript>
	</cffunction>
	
	<cffunction name="setCompHistory" access="public" returntype="struct" ExtDirect="true" output="false" hint="This method places history in cache because it does not change very often.">
		<cfargument name="EmployeeID" type="numeric" required="no" default="0">
		<cfargument name="CycleID" type="numeric" required="no" default="0">
		<cfscript>
			var qData = "";
			var aData = "";
			var MyStruct = StructNew();
			var idx = "";
			var stHistory = "";
			var itm = "";		
			// ensure we have the keys
			if(Not structKeyExists(application,'compHist')) application.compHist = StructNew();
			if(Not structKeyExists(application.compHist,CycleID)) application.compHist[CycleID] = StructNew();
		</cfscript>
		
		<cfif Not structKeyExists(application.compHist[CycleID],arguments.EmployeeID)>
			<cfset stHistory = getorgGateway().getSalaryHistoryFromPackage(argumentCollection=arguments) />
			<cfloop collection="#stHistory#" item="itm">
				<cfscript>
					MyStruct = StructNew();				
					qData = stHistory[itm];
					aData = variables.util.queryToArray(qData);
					MyStruct.data = ArrayNew(1);
					for(idx = 1; idx lte qData.RecordCount; idx++){
						ArrayAppend(MyStruct.data, Duplicate(aData[idx]));
					}
		
					MyStruct.RecordCount = qData.RecordCount;
					MyStruct.Success = true;
					// add it to the history struct
					stHistory[itm] = MyStruct;
				</cfscript>
			</cfloop>
			<cfset application.compHist[arguments.CycleID][arguments.EmployeeID] = stHistory />
		</cfif>	
		<cfreturn application.compHist[arguments.CycleID][arguments.EmployeeID] />
	</cffunction>

</cfcomponent>	