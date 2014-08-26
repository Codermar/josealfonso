<cfcomponent displayname="event" output="false">

<cffunction name="init" access="public" returntype="event">
	<cfreturn this />
</cffunction>

<cffunction name="handleAjaxEvent" output="false" access="remote" returntype="string" returnformat="plain">
	<cfscript>
		// var result = "{success: false}"; // default
		var viewCollection = "";
		var serviceFactory = "";
		var thisRequest =  getRequestArgs("event");
		var UserSession = session;
		var eventComponent = "";
		var _Authenticated = isDefined("session.IsUserAuthenticated") AND session.IsUserAuthenticated;
		var _canDo = true; 
		var _protectedUserIDList = '1,3,11';
		var ReloadXML = false;
		var MyStruct = structNew();
			MyStruct.success = true;
			
		if(Not IsDefined("session.lang")) session.lang = "EN";
		if(Not IsDefined("application.ReloadConfigXML")) application.ReloadConfigXML = false;
		ReloadXML = application.ReloadConfigXML;
		
		thisRequest.Lang = session.Lang;
		thisRequest.UserSession = session;
		thisRequest.dsn = application.config.DSN;
		thisRequest.bean = listGetAt(thisRequest.event,1,'.');
		
		if(listlen(thisRequest.event,'.') gte 2)
			thisRequest.eventmethod = listGetAt(thisRequest.event,2,'.');
		else {
			thisRequest.eventmethod = '';
			// result = '{"success":false,"error":"notValidMethod","errormsg":"Invalid method call!"}';
			MyStruct.success = false;
			MyStruct.ErrorType = "notValidMethod";
			MyStruct.ErrorMessage = "Invalid method call!";
		}

		if (ReloadXML) {
			// reload service factory for this request
			serviceFactory = CreateObject('component', 'coldspring.beans.DefaultXmlBeanFactory').init(defaultProperties=application.config);
			serviceFactory.loadBeansFromXmlFile(application.config.Location); 
		} else {
			serviceFactory = application.serviceFactory;
		}
		eventComponent = serviceFactory.getBean(thisRequest.bean);
		// 
		if(NOT _Authenticated){
			/* If the session has timed out return error so login form can be shown to the user.
				We're observing any ajax connection and monitoring that the session is still alive */
			// result = '{"success":false,"error":"notAuthenticated","errormsg":"Your session has timed out!"}';
			MyStruct.success = false;
			MyStruct.ErrorType = "notAuthenticated";
			MyStruct.ErrorMessage = "Your session has timed out!";
		}
		
	</cfscript> 

	<cfif _Authenticated AND _CanDo>	
		<cfif len(trim(thisRequest.eventmethod))>
			<cftry>
			  <cfinvoke
				 component="#eventComponent#"
				 method="#thisRequest.eventmethod#"
				 argumentcollection="#thisRequest#"	
				 returnvariable="MyStruct.OperationResult">
			
				<cfcatch type="any">
					<cfscript>
						MyStruct.success = false;
						MyStruct.ErrorComponent = eventComponent;
						MyStruct.ErrorMethod = thisRequest.eventmethod;
						MyStruct.ErrorType = "InvocationError";
						MyStruct.ErrorMessage = cfcatch.Message & cfcatch.detail;
					</cfscript>
				</cfcatch>		
			</cftry>
		</cfif>	
	</cfif>	
	<cfreturn SerializeJson(MyStruct) />	
</cffunction> 

<cffunction name="getRequestArgs" access="public" returntype="struct">
	<cfargument name="ActionName" default="event" required="true" hint=""> 
	<cfscript>
			var ThisRequest = StructNew();
			if(Not StructKeyExists(url,arguments.ActionName)) url[arguments.ActionName] = "home";
			
			StructAppend(ThisRequest,url,false);
			StructAppend(ThisRequest,form,true); // form elements override url
	
			return ThisRequest;	
	</cfscript>
</cffunction>


</cfcomponent>