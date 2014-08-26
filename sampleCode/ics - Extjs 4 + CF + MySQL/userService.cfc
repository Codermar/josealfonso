<cfcomponent name="userService" output="false" ExtDirect="true">

    <cffunction name="init" access="public" output="false" returntype="userService">
        <cfreturn this/>
    </cffunction>
	
    <cffunction name="setuserGateway" access="public" returntype="void" output="false" hint="I set the userGateway.">
        <cfargument name="userGateway" type="any" required="true" hint="userGateway" />
        <cfset variables['userGateway'] = arguments.userGateway />
    </cffunction>   
    <cffunction name="getUserGateway" access="public" returntype="any" output="false" hint="I return the userGateway.">
        <cfreturn variables['userGateway'] />
    </cffunction>
	
    <cffunction name="setUtils" access="public" returntype="void" output="false">
        <cfargument name="Utils" type="any" required="true" hint="Utils" />
        <cfset variables['Utils'] = arguments.Utils />
    </cffunction>   
    <cffunction name="getUtils" access="public" returntype="any" output="false">
        <cfreturn variables['Utils'] />
    </cffunction>

	<cffunction name="createuser" access="public" output="false" returntype="user">
		<cfargument name="UserName" type="String" required="false" />
		<cfargument name="FirstName" type="String" required="false" />
		<cfargument name="MI" type="String" required="false" />
		<cfargument name="LastName" type="String" required="false" />
		<cfargument name="Email" type="String" required="false" />
		<cfargument name="Password" type="String" required="false" />
		<cfargument name="Created" type="Date" required="false" />
		<cfargument name="Permissions" type="string" required="false" />
		<cfargument name="IsActive" type="numeric" required="false" />
		<cfargument name="ClientId" type="string" required="false" />
		<cfargument name="ClientName" type="string" required="false" />
		<cfset var user = createObject("component","ics.cfcs.users.user").init(argumentCollection=arguments) />
		<cfreturn user />
	</cffunction>

	<cffunction name="getUser" access="public" output="false" returntype="user">
		<cfargument name="UserName" type="String" required="false" />		
		<cfset var user = createuser(argumentCollection=arguments) />
		<cfset getUserGateway().read(user) />
		<cfreturn user />
	</cffunction>

	<cffunction name="getUsers" access="public" output="false" returntype="struct" ExtDirect="true">
		<cfargument name="UserName" type="String" required="false" />
		<cfargument name="FirstName" type="String" required="false" />
		<cfargument name="MI" type="String" required="false" />
		<cfargument name="LastName" type="String" required="false" />
		<cfargument name="Email" type="String" required="false" />
		<cfargument name="Password" type="String" required="false" />
		<cfargument name="Created" type="Date" required="false" />
		<cfargument name="Permissions" type="string" required="false" />
		<cfargument name="IsActive" type="numeric" required="false" />
		<cfargument name="ClientId" type="string" required="false" />
		<cfargument name="ClientName" type="string" required="false" />
		<cfargument name="searchCriteria" type="string" default="">
		<cfargument name="start" type="string" required="true" default="0" />
        <cfargument name="limit" type="string" required="true" default="25" />
        <cfargument name="sort" type="any" required="false" default="" />
		<cfscript>
			var paging = getUtils().getPagingSetup(start=arguments.start,limit=arguments.limit);
			// trap to get a non admin user to get his own record only
			if(not  hasUserAdmin()) arguments.username=getUtils().getCurrentUserName();
			
				arguments.start=paging.start;
	            arguments.sort=arguments.sort;
	            arguments.end=paging.limit;

			return getUserGateway().getByAttributes(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<cffunction name="getUserLogs" access="public" output="false" returntype="struct" ExtDirect="true">
		<cfargument name="UserName" type="String" required="false" default="" />
		<cfargument name="reportRange" type="string" required="no" default="TW">
		<cfargument name="searchCriteria" type="string" default="">
		<cfargument name="start" type="string" required="true" default="0" />
        <cfargument name="limit" type="string" required="true" default="0" />
        <cfargument name="sort" type="any" required="false" default="" />
		<cfscript>
            var paging = getUtils().getPagingSetup(start=arguments.start,limit=arguments.limit);
            var data = "";	
            var env = application.Environment;
            if(env eq 'localhost') env = 'prod'; // show live log instead		
			// trap to get a non admin
			if(not  hasUserAdmin() ) arguments.username=getUtils().getCurrentUserName();
			
	        Data = getUserGateway().getUserLogsQuery(
	                UserName=arguments.UserName
	               ,reportRange = arguments.reportRange
	               ,searchCriteria=arguments.searchCriteria
	               ,environment=env
	               ,start=paging.start
	               ,sort=arguments.sort
	               ,end=paging.limit);
            
            return getUtils().setJSONDataStruct(Data);
		</cfscript>
	</cffunction>
	
	<cffunction name="getUserLogin" access="public" output="false" returntype="user">
		<cfargument name="UserName" type="String" required="true" />
		<cfargument name="password" type="String" required="true" />
		<cfargument name="IsActive" type="numeric" required="false" default="1" />	
		<cfscript>
			var user = createuser(argumentCollection=arguments);
			var strReturn = structNew(); 
			var qUser = getUserGateway().getByAttributesQuery(argumentCollection=arguments);

			if(qUser.recordCount){
				strReturn = getUtils().queryRowToStruct(qUser);
				user.init(argumentCollection=strReturn);
			}
			return user;
		</cfscript>
	</cffunction>
	
	<cffunction name="updateUser" access="public" output="false" returntype="struct" ExtDirect="true" ExtFormHandler="true">
		<cfargument name="UserName" type="String" required="true" />
		<cfscript> 
			var result = structNew();
			var user = createuser(argumentCollection=arguments);
			var check = '';
			if( hasUserAdmin() or getUtils.getCurrentUserName() eq arguments.userName )	{
				try {
					check = getUserGateway().save(user);
					if(check) result['success'] = true;
				} catch (any e) {
					result['success'] = false;
					result['errortype'] = "InvocationError";
					result['errormessage'] = e.Message & e.detail;
					result['errorcomponent'] = 'userService';
					result['errormethod'] = 'updateUser';
				}
			}	
			return result;
		</cfscript> 
	</cffunction>

	<cffunction name="deleteUser" access="public" output="false" returntype="struct" ExtDirect="true">
		<cfargument name="UserName" type="String" required="true" />		
		<cfscript>
			var result = structNew();
			var user = createuser(argumentCollection=arguments);
			var check = '';
			if( hasUserAdmin() )	{
				try {
					check = getUserGateway().delete(user);
					if(check) result['success'] = true;
				} catch (any e) {
					result['success'] = false;
					result['errortype'] = "InvocationError";
					result['errormessage'] = e.Message & e.detail;
					result['errorcomponent'] = 'userService';
					result['errormethod'] = 'updateUser';
				}
			}	
			return result;
		</cfscript>
	</cffunction>

	<cffunction name="logUser" access="public" output="false">
		<cfargument name="UserName" type="String" required="true" />
		<cfargument name="ServerSessionID" type="string" default="" />
		<cfargument name="OriginIP" type="string" default="" />
		<cfargument name="sessionStart" type="date" default="#now()#" />
		<cfargument name="sessionEnd" type="string" default="" />
		<cfargument name="sessionLength" type="string" default="" />
		<cfargument name="Environment" type="string" />
		<cfargument name="doCheck" type="boolean" default="true" />
		<cfscript>
			// log non-localhost only
			if(structKeyExists(application,'Environment') and application.Environment neq 'localhost'){
				getUserGateway().logUser(argumentCollection=arguments);		
			}		
		</cfscript>
	</cffunction>

	<cffunction name="hasPermission" returntype="boolean" ExtDirect="true">
		<cfargument name="Permission" required="yes" default="User">
		<cfargument name="PermissionKey" required="yes" default="UserInfo">
		<cfscript>
			var bVerify = false;			
			if(StructKeyExists(session,arguments.PermissionKey)){	
				if(ListFindNoCase(session[arguments.PermissionKey].Permissions,arguments.Permission)) bVerify = true;
				// other implied permissions	
				switch (arguments.permission){
					case 'canViewAllClients': {
						if(ListFindNoCase(session[arguments.PermissionKey].Permissions,'Admin')) bVerify = true;		
					break;}
				}
			}
			return bVerify;
		</cfscript>	
	</cffunction>
	
	<cffunction name="hasUserAdmin" returntype="boolean" ExtDirect="true">
		<cfreturn hasPermission('Admin') or hasPermission('UserAdmin') />
	</cffunction>
	
</cfcomponent>
