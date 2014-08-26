<cfcomponent displayname="userGateway" output="false">

	<cffunction name="init" access="public" output="false" returntype="userGateway">
		<cfargument name="dsn" type="string" required="true" />
		<cfset variables.dsn = arguments.dsn />
		<cfreturn this />
	</cffunction>

    <cffunction name="setUtils" access="public" returntype="void" output="false">
        <cfargument name="Utils" type="any" required="true" hint="Utils" />
        <cfset variables['Utils'] = arguments.Utils />
    </cffunction>   
    <cffunction name="getUtils" access="public" returntype="any" output="false">
        <cfreturn variables['Utils'] />
    </cffunction>


	<!--- superseeded 
	<cffunction name="getByAttributesQuery" access="public" output="false" returntype="query">
		<cfargument name="UserName" type="String" required="false" />
		<cfargument name="FirstName" type="String" required="false" />
		<cfargument name="MI" type="String" required="false" />
		<cfargument name="LastName" type="String" required="false" />
		<cfargument name="Email" type="String" required="false" />
		<cfargument name="Password" type="String" required="false" />
		<cfargument name="Created" type="Date" required="false" />
		<cfargument name="IsActive" type="numeric" required="false" />
		<cfargument name="Permissions" type="string" required="false" />
		<cfargument name="ClientId" type="string" required="false" />
		<cfargument name="ClientName" type="string" required="false" />
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="20" required="no" />
		<cfargument name="sort" type="any" required="false" default="" />					
		<cfscript>
			var qList = "";
            //var Data = StructNew();
            // var qFoundRows = "";
            if(len(trim(arguments.searchCriteria))) arguments.searchCriteria = replace(arguments.searchCriteria,"'","''",'all');
        </cfscript>	
		<cfquery name="qList" datasource="#variables.dsn#">
			SELECT
				u.user_name UserName,
				u.first_name FirstName,
				u.MI,
				u.last_name LastName,
				CONCAT_WS(', ',u.last_name, u.first_name) UserFullName,
				u.Email,
				u.Password,
				u.created_dt Created,
				ifnull(u.permissions,'User') AS permissions,
				ifnull(u.is_active,0) IsActive
				,u.client_idfk ClientId
				,c.company_name clientName
				,c.city clientCity
			FROM	ics_users u
				left join ics_company c on u.client_idfk = c.company_id
			WHERE	0=0

		<cfif structKeyExists(arguments,"UserName") and len(arguments.UserName)>
			AND	u.user_name = <cfqueryparam value="#arguments.UserName#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"Password") and len(arguments.Password)>
			AND	u.Password = <cfqueryparam value="#arguments.Password#" CFSQLType="cf_sql_varchar" />
		</cfif>		
		<cfif structKeyExists(arguments,"FirstName") and len(arguments.FirstName)>
			AND	u.First_Name = <cfqueryparam value="#arguments.FirstName#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"MI") and len(arguments.MI)>
			AND	u.MI = <cfqueryparam value="#arguments.MI#" CFSQLType="cf_sql_char" />
		</cfif>
		<cfif structKeyExists(arguments,"LastName") and len(arguments.LastName)>
			AND	u.Last_Name = <cfqueryparam value="#arguments.LastName#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"Email") and len(arguments.Email)>
			AND	u.Email = <cfqueryparam value="#arguments.Email#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"permissions") and len(arguments.permissions)>
			AND	u.permissions = <cfqueryparam value="#arguments.permissions#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"Created") and len(arguments.Created)>
			AND	u.Created_dt = <cfqueryparam value="#arguments.Created#" CFSQLType="cf_sql_timestamp" />
		</cfif>
		<cfif structKeyExists(arguments,"IsActive") and len(arguments.IsActive)>
			AND	u.Is_Active = <cfqueryparam value="#arguments.IsActive#" CFSQLType="cf_sql_numeric" />
		</cfif>
		<cfif structKeyExists(arguments,"ClientID") and len(arguments.ClientID)>
			AND	u.client_idfk = <cfqueryparam value="#arguments.ClientID#" CFSQLType="cf_sql_numeric" />
		</cfif>
		<cfif isDefined("arguments.SearchCriteria") AND len(trim(arguments.SearchCriteria))>
		and LOWER(CONCAT_WS(' ', trim(u.user_name), trim(u.Email), trim(u.last_name), trim(u.first_name), trim(ifnull(u.permissions,'User') ), trim(c.company_name), trim(c.city)  )) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(trim(arguments.SearchCriteria))#%">
	    </cfif>
		<cfif structKeyExists(arguments, "sort") and len(arguments.sort)>
			ORDER BY #arguments.sort#
		</cfif>
		<cfif arguments.end neq 0>
	    LIMIT <cfqueryparam value="#arguments.start#" CFSQLType="cf_sql_numeric" />,<cfqueryparam value="#arguments.end#" CFSQLType="cf_sql_numeric" />	
		</cfif>		
		</cfquery>	
		<cfreturn qList />
	</cffunction> --->

	<cffunction name="getByAttributes" access="public" output="false" returntype="struct">
		<cfargument name="UserName" type="String" required="false" />
		<cfargument name="FirstName" type="String" required="false" />
		<cfargument name="MI" type="String" required="false" />
		<cfargument name="LastName" type="String" required="false" />
		<cfargument name="Email" type="String" required="false" />
		<cfargument name="Password" type="String" required="false" />
		<cfargument name="Created" type="Date" required="false" />
		<cfargument name="IsActive" type="numeric" required="false" />
		<cfargument name="Permissions" type="string" required="false" />
		<cfargument name="ClientId" type="string" required="false" />
		<cfargument name="ClientName" type="string" required="false" />
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="20" required="no" />
		<cfargument name="sort" type="any" required="false" default="" />
		<cfscript>
			var data = getByAttributesQuery(argumentCollection=arguments);
			var qList = data.resultset;
			var arrObjects = arrayNew(1);
			var tmpObj = "";
			var i = 0;	
			var dataSt = StructNew();
		</cfscript>
		<cfloop from="1" to="#qList.recordCount#" index="i">
			<cfset tmpObj = createObject("component","user").init(argumentCollection=getUtils().queryRowToStruct(qList,i)) />
			<cfset arrayAppend(arrObjects,tmpObj) />
		</cfloop>	
		<cfscript>
			dataSt['totalcount'] = data.totalcount;
			dataSt['resultset'] = arrObjects;
			return dataSt;
		</cfscript>
	</cffunction>

	<cffunction name="getByAttributesQuery" access="public" output="false" returntype="struct">
		<cfargument name="UserName" type="String" required="false" />
		<cfargument name="FirstName" type="String" required="false" />
		<cfargument name="MI" type="String" required="false" />
		<cfargument name="LastName" type="String" required="false" />
		<cfargument name="Email" type="String" required="false" />
		<cfargument name="Password" type="String" required="false" />
		<cfargument name="Created" type="Date" required="false" />
		<cfargument name="IsActive" type="numeric" required="false" />
		<cfargument name="Permissions" type="string" required="false" />
		<cfargument name="ClientId" type="string" required="false" />
		<cfargument name="ClientName" type="string" required="false" />
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="20" required="no" />
		<cfargument name="sort" type="any" required="false" default="" />					
		<cfscript>
			var qList = "";
            var Data = StructNew();
            if(len(trim(arguments.searchCriteria))) arguments.searchCriteria = replace(arguments.searchCriteria,"'","''",'all');
        </cfscript>	
        <cftransaction>
		<cfquery name="qList" datasource="#variables.dsn#">
			select SQL_CALC_FOUND_ROWS

				u.user_name UserName,
				u.first_name FirstName,
				u.MI,
				u.last_name LastName,
				CONCAT_WS(', ',u.last_name, u.first_name) UserFullName,
				u.Email,
				u.Password,
				u.created_dt Created,
				ifnull(u.permissions,'User') AS permissions,
				ifnull(u.is_active,0) IsActive
				,u.client_idfk ClientId
				,c.company_name ClientName
				,c.city ClientCity
				,u.client_access_id_list ClientAccessIdList
			FROM	ics_users u
				left join ics_company c on u.client_idfk = c.company_id
			WHERE	0=0

		<cfif structKeyExists(arguments,"UserName") and len(arguments.UserName)>
			AND	u.user_name = <cfqueryparam value="#arguments.UserName#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"Password") and len(arguments.Password)>
			AND	u.Password = <cfqueryparam value="#arguments.Password#" CFSQLType="cf_sql_varchar" />
		</cfif>		
		<cfif structKeyExists(arguments,"FirstName") and len(arguments.FirstName)>
			AND	u.First_Name = <cfqueryparam value="#arguments.FirstName#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"MI") and len(arguments.MI)>
			AND	u.MI = <cfqueryparam value="#arguments.MI#" CFSQLType="cf_sql_char" />
		</cfif>
		<cfif structKeyExists(arguments,"LastName") and len(arguments.LastName)>
			AND	u.Last_Name = <cfqueryparam value="#arguments.LastName#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"Email") and len(arguments.Email)>
			AND	u.Email = <cfqueryparam value="#arguments.Email#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"permissions") and len(arguments.permissions)>
			AND	u.permissions = <cfqueryparam value="#arguments.permissions#" CFSQLType="cf_sql_varchar" />
		</cfif>
		<cfif structKeyExists(arguments,"Created") and len(arguments.Created)>
			AND	u.Created_dt = <cfqueryparam value="#arguments.Created#" CFSQLType="cf_sql_timestamp" />
		</cfif>
		<cfif structKeyExists(arguments,"IsActive") and len(arguments.IsActive)>
			AND	u.Is_Active = <cfqueryparam value="#arguments.IsActive#" CFSQLType="cf_sql_numeric" />
		</cfif>
		<cfif structKeyExists(arguments,"ClientID") and len(arguments.ClientID)>
			AND	u.client_idfk = <cfqueryparam value="#arguments.ClientID#" CFSQLType="cf_sql_numeric" />
		</cfif>
		<cfif isDefined("arguments.SearchCriteria") AND len(trim(arguments.SearchCriteria))>
		and LOWER(CONCAT_WS(' ', trim(u.user_name), trim(u.Email), trim(u.last_name), trim(u.first_name), trim(ifnull(u.permissions,'User') ), trim(c.company_name), trim(c.city), trim(u.client_idfk)  )) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(trim(arguments.SearchCriteria))#%">
	    </cfif>
		<cfif structKeyExists(arguments, "sort") and len(arguments.sort)>
			ORDER BY #arguments.sort#
		</cfif>
		<cfif arguments.end neq 0>
	    LIMIT <cfqueryparam value="#arguments.start#" CFSQLType="cf_sql_numeric" />,<cfqueryparam value="#arguments.end#" CFSQLType="cf_sql_numeric" />	
		</cfif>
		</cfquery>
		<cfif qList.recordcount>
            <cfquery name="local.qFoundRows" datasource="#variables.dsn#">
              SELECT found_rows() AS foundRows
            </cfquery>
        </cfif>
        </cftransaction>      
        <cfscript>
            Data['resultset'] = qList;

            if(qList.recordcount){
            	Data['totalcount'] = local.qFoundRows.foundRows;
	        } else {
	        	Data['totalcount'] = 0;
    		}
            return Data;
        </cfscript>
	</cffunction>



	<!--- /// DAO /// --->
	
	<cffunction name="create" access="public" output="false" returntype="boolean">
		<cfargument name="user" type="user" required="true" />
		<cfset var qCreate = "" />
		<cftry>
			<cftransaction>
			<cfquery name="qCreate" datasource="#variables.dsn#">
				INSERT INTO ics_users
					(
					User_Name,
					First_Name,
					MI,
					Last_Name,
					Email,
					Password,
					Created_dt,
					permissions,
					Is_Active
					,client_idfk
					,client_access_id_list
					)
				VALUES
					(
					<cfqueryparam value="#arguments.user.getUserName()#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.user.getFirstName()#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.user.getMI()#" CFSQLType="cf_sql_char" />,
					<cfqueryparam value="#arguments.user.getLastName()#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.user.getEmail()#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.user.getPassword()#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.user.getCreated()#" CFSQLType="cf_sql_timestamp" null="#not len(arguments.user.getCreated())#" />,
					<cfqueryparam value="#arguments.user.getPermissions()#" CFSQLType="cf_sql_varchar" null="#not len(arguments.user.getPermissions())#" />,
					<cfqueryparam value="#arguments.user.getIsActive()#" CFSQLType="cf_sql_numeric" null="#not len(arguments.user.getIsActive())#" />
					,<cfqueryparam value="#ucase(arguments.user.getClientId())#" CFSQLType="cf_sql_varchar" null="#not len(arguments.user.getClientId())#" />
					,<cfqueryparam value="#ucase(arguments.user.getClientAccessIdList())#" CFSQLType="cf_sql_varchar" null="#not len(arguments.user.getClientAccessIdList())#" />
					)
			</cfquery>
			</cftransaction>
			<cfcatch type="database">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn true />
	</cffunction>

	<cffunction name="read" access="public" output="false" returntype="void">
		<cfargument name="user" type="user" required="true" />
		<cfset var qRead = "" />
		<cfset var strReturn = structNew() />
		<cftry>
			<cfquery name="qRead" datasource="#variables.dsn#">
				SELECT
					user_name UserName,
					first_name FirstName,
					MI,
					last_name LastName,
					Email,
					Password,
					created_dt Created,
					permissions,
					is_active IsActive
					,client_idfk ClientId
					,client_access_id_list clientAccessIdList
				FROM	ics_users
				WHERE	user_name = <cfqueryparam value="#arguments.user.getUserName()#" CFSQLType="cf_sql_varchar" />
			</cfquery>
			<cfcatch type="database">
				<!--- leave the bean as is and set an empty query for the conditional logic below --->
				<cfset qRead = queryNew("id") />
			</cfcatch>
		</cftry>
		<cfscript>
			if(qRead.recordCount){
				strReturn = getUtils().queryRowToStruct(qRead);
				arguments.user.init(argumentCollection=strReturn);
			}
		</cfscript>
	</cffunction>

	<cffunction name="update" access="public" output="false" returntype="boolean">
		<cfargument name="user" type="user" required="true" />
		<cfset var qUpdate = "" />
		<cftry>
			<cftransaction>
			<cfquery name="qUpdate" datasource="#variables.dsn#">
				UPDATE	ics_users
				SET
					User_Name = <cfqueryparam value="#arguments.user.getUserName()#" CFSQLType="cf_sql_varchar" />,
					First_Name = <cfqueryparam value="#arguments.user.getFirstName()#" CFSQLType="cf_sql_varchar" />,
					MI = <cfqueryparam value="#arguments.user.getMI()#" CFSQLType="cf_sql_char" />,
					Last_Name = <cfqueryparam value="#arguments.user.getLastName()#" CFSQLType="cf_sql_varchar" />,
					Email = <cfqueryparam value="#arguments.user.getEmail()#" CFSQLType="cf_sql_varchar" />,
					Password = <cfqueryparam value="#arguments.user.getPassword()#" CFSQLType="cf_sql_varchar" />,
					Created_dt = <cfqueryparam value="#arguments.user.getCreated()#" CFSQLType="cf_sql_timestamp" null="#not len(arguments.user.getCreated())#" />,
					permissions = <cfqueryparam value="#arguments.user.getPermissions()#" CFSQLType="cf_sql_varchar" null="#not len(arguments.user.getPermissions())#" />,
					Is_Active = <cfqueryparam value="#arguments.user.getIsActive()#" CFSQLType="cf_sql_numeric" null="#not len(arguments.user.getIsActive())#" />
					,client_idfk = <cfqueryparam value="#ucase(arguments.user.getClientId())#" CFSQLType="cf_sql_varchar" null="#not len(arguments.user.getClientId())#" />
					,client_access_id_list = <cfqueryparam value="#ucase(arguments.user.getClientAccessIdList())#" CFSQLType="cf_sql_varchar" null="#not len(arguments.user.getClientAccessIdList())#" />
				WHERE	user_name = <cfqueryparam value="#arguments.user.getUserName()#" CFSQLType="cf_sql_varchar" />
			</cfquery>
			</cftransaction>
			<cfcatch type="database">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn true />
	</cffunction>

	<cffunction name="delete" access="public" output="false" returntype="boolean">
		<cfargument name="user" type="user" required="true" />
		<cfset var qDelete = "">
		<cftry>
			<cfquery name="qDelete" datasource="#variables.dsn#">
				DELETE FROM	ics_users 
				WHERE	user_name = <cfqueryparam value="#arguments.user.getUserName()#" CFSQLType="cf_sql_varchar" />
			</cfquery>
			<cfcatch type="database">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn true />
	</cffunction>

	<cffunction name="exists" access="public" output="false" returntype="boolean">
		<cfargument name="user" type="user" required="true" />
		<cfset var qExists = "">
		<cfquery name="qExists" datasource="#variables.dsn#" maxrows="1">
			SELECT count(1) as idexists
			FROM	ics_users
			WHERE	User_Name = <cfqueryparam value="#arguments.user.getUserName()#" CFSQLType="cf_sql_varchar" />
		</cfquery>
		<cfif qExists.idexists>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>

	<cffunction name="save" access="public" output="false" returntype="boolean">
		<cfargument name="user" type="user" required="true" />	
		<cfscript>
			var success = false;
			if(Not exists(arguments.user)) success = create(arguments.user);
			else success = update(arguments.user);
			return success;	
		</cfscript>
	</cffunction>

	<cffunction name="logUser" access="public" output="false" returntype="boolean">
		<cfargument name="UserName" type="String" required="true" />
		<cfargument name="ServerSessionID" type="string" default="" />
		<cfargument name="OriginIP" type="string" default="" />
		<cfargument name="sessionStart" type="date" default="#now()#" />
		<cfargument name="sessionEnd" type="string" default="" />
		<cfargument name="sessionLength" type="string" default="" />
		<cfargument name="Environment" type="string" />
		<cfargument name="doCheck" type="boolean" default="true" />
		<cfscript>
			var qLog = '';
			var isUpdate = false;
		</cfscript>
		<cftry>
			<cftransaction>			
			<cfif arguments.doCheck>
				<cfquery name="qLog" datasource="#variables.dsn#">
					select count(1) dcount from ics_user_log 
					where user_name = <cfqueryparam value="#arguments.UserName#" CFSQLType="cf_sql_varchar" />
					and server_session_id = <cfqueryparam value="#arguments.ServerSessionID#" CFSQLType="cf_sql_varchar" />
				</cfquery>
				<cfset isUpdate = qLog.dcount />	
			</cfif>
			<cfif isUpdate>
				<cfquery name="qLog" datasource="#variables.dsn#">
				update ics_user_log
				set session_end_dt = <cfqueryparam value="#arguments.sessionEnd#" CFSQLType="CF_SQL_TIMESTAMP" />
					,session_length = <cfqueryparam value="#arguments.sessionLength#" CFSQLType="cf_sql_varchar">
				where user_name = <cfqueryparam value="#arguments.UserName#" CFSQLType="cf_sql_varchar" />
				and server_session_id = <cfqueryparam value="#arguments.ServerSessionID#" CFSQLType="cf_sql_varchar" />	
				</cfquery>
			<cfelse>
			<cfquery name="qLog" datasource="#variables.dsn#">
				INSERT INTO ics_user_log
					(
					User_Name,
					server_session_id,
					origin_ip,
					session_start_dt,
					session_end_dt,
					session_length,
					environment
					)
				VALUES
					(
					<cfqueryparam value="#arguments.UserName#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.ServerSessionID#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.OriginIP#" CFSQLType="cf_sql_varchar" />,
					<cfqueryparam value="#arguments.sessionStart#" CFSQLType="CF_SQL_TIMESTAMP" />,
					<cfqueryparam value="#arguments.sessionEnd#" CFSQLType="CF_SQL_TIMESTAMP" null="#not len(arguments.sessionEnd) or not isDate(arguments.sessionEnd)#" />,
					<cfqueryparam value="#arguments.sessionLength#" CFSQLType="cf_sql_varchar" null="#not len(arguments.sessionLength)#" />,
					<cfqueryparam value="#arguments.Environment#" CFSQLType="cf_sql_varchar" />
					)
			</cfquery>
			</cfif>
			</cftransaction>
			<cfcatch type="database">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn true />
	</cffunction>

	<cffunction name="getUserLogsQuery" access="public" returntype="struct">
		<cfargument name="userName" type="string" required="no" default="">   
		<cfargument name="reportRange" type="string" required="no" default="">
		<cfargument name="Environment" type="string" required="no" default="prod">  
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="0" required="no" />
		<cfargument name="sort" type="any" required="false" default="" />
		<cfargument name="dir" type="string" required="false" default="ASC" />
		<cfscript>
            var Data = StructNew();
            var qList = "";
        </cfscript> 
        <cftransaction>
		<cfquery name="qList" datasource="#variables.dsn#">
		select SQL_CALC_FOUND_ROWS
			o.* from (
			select 
				 l.session_log_id logId
				,l.server_session_id sessionId
				,l.user_name userName
				,l.origin_ip OriginIp
				,date_format(l.session_start_dt + INTERVAL 3 hour,'%I:%i:%S %p') sessionStart
				,date_format(l.session_end_dt + INTERVAL 3 hour,'%I:%i:%S %p') sessionEnd
				,l.session_length duration
				,l.environment
				,left(DATE_FORMAT(l.session_start_dt, '%m/%d/%Y'),10) sessionDate
				,concat_ws(' ', u.first_name, u.last_name) userFullName
				,c.company_name companyName
			from ics_user_log l
				left join ics_users u on l.user_name = u.user_name
				left join ics_company c on u.client_idfk = c.company_id
			where 0=0
			
			<cfif len(trim(arguments.reportRange))>
				<cfif arguments.reportRange eq 'TW'>
					and yearweek(session_start_dt) = yearweek(now())
				<cfelseif arguments.reportRange eq 'LW'>
					and yearweek(session_start_dt) = yearweek(SUBTIME(now(),'7 0:0:0'))
				<cfelseif arguments.reportRange eq 'TM'>
					and l.session_start_dt BETWEEN date_format(NOW(), '%Y-%m-01') AND date_format(NOW() + INTERVAL 1 MONTH, '%Y-%m-01')
				<cfelseif arguments.reportRange eq 'LM'>
					and l.session_start_dt BETWEEN date_format(NOW() - INTERVAL 1 MONTH, '%Y-%m-01') AND date_format(NOW(), '%Y-%m-01')
				<cfelseif arguments.reportRange eq '30'>
					and l.session_start_dt BETWEEN date_format(NOW() - INTERVAL 1 MONTH, '%Y-%m-01') AND date_format(NOW(), '%Y-%m-01')
				</cfif>
			</cfif>
			<cfif structKeyExists(application,'isLiveServer') and application.isLiveServer>
				and lower(l.user_name) <> 'jgalfo'
			</cfif>
			<cfif structKeyExists(arguments,'Environment') and len(trim(arguments.Environment))>
				and lower(l.environment) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.environment#">
			</cfif>
			order by l.environment, l.session_start_dt desc, l.user_name		
		) o	    
        
		where 0=0
		
		<cfif isDefined("arguments.SearchCriteria") AND len(trim(arguments.SearchCriteria))>
		and LOWER(CONCAT_WS(' ', trim(o.userName), trim(o.userFullName), trim(o.sessionDate), trim(o.companyName)  )) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(trim(arguments.SearchCriteria))#%">
	    </cfif>
	    <cfif structKeyExists(arguments, "sort") and len(arguments.sort)>
            ORDER BY #arguments.sort#
        </cfif>	
		
		<cfif arguments.end neq 0 and arguments.reportRange neq 'All'>
	    LIMIT <cfqueryparam value="#arguments.start#" CFSQLType="cf_sql_numeric" />,<cfqueryparam value="#arguments.end#" CFSQLType="cf_sql_numeric" />	
		</cfif>
		</cfquery>
		<cfif qList.recordcount>
            <cfquery name="qFoundRows" datasource="#variables.dsn#">
              SELECT found_rows() AS foundRows
            </cfquery>
        </cfif>
        </cftransaction>      
        <cfscript>
            Data['resultset'] = qList;
            Data['totalcount'] = qFoundRows.foundRows;
            return Data;
        </cfscript>
	</cffunction>
		
</cfcomponent>
