<cfcomponent displayname="icsReportsGateway" output="false">
    
	<cffunction name="init" access="public" output="false" returntype="icsReportsGateway">
	    <cfargument name="dsn" type="string" required="true" />
	    <cfset variables.dsn = arguments.dsn />
	    <cfreturn this />
	</cffunction>

	<cffunction name="getStateComplianceSummaryQuery" access="public" returntype="struct">
	    <cfargument name="productID" type="string" required="yes">
	    <cfargument name="showAll" type="numeric" required="yes" default="1">
	    <cfset var stData = structNew()>
        <cfquery name="stData.data" datasource="#variables.dsn#">
			select * from rpt_state_compl c
			where mbatfid = <cfqueryparam value="#arguments.productID#" cfsqltype="cf_sql_numeric"> 
			<cfif not arguments.showAll>
			and c.registrationstatus not in ('Not Requested','Not Required')
			</cfif>
		order by c.stateName
		</cfquery>
	    <cfreturn stData />
	</cffunction>

	<cffunction name="getProducDistributorsReportQuery" access="public" returntype="struct">
	    <cfargument name="clientID" type="string" required="yes">
		<cfargument name="StateList" type="string" default="">
		<cfargument name="reportType" type="string" default="byCompany">
	    <cfset var stData = structNew()>
        <cfquery name="stData.data" datasource="#variables.dsn#">
		select
			 c.company_name ClientName
			,d.distributorId
			,ifnull(d.distributorname,d.distributorId) distributorname
			,d.statecode
			,d.distRegStatus
			,d.submitted
			,d.approved
			,d.registrationstatus
			,p.productId
			,p.brandName
			,p.productName
			,p.liquorType
			,p.varietalClass
			,p.serialNo
			,p.ttbnumber
		from rpt_distrib_appt d
			,rpt_products p
			,ics_company c
		where d.productId = p.productId
		and d.clientId = c.company_id	
		and d.clientId = <cfqueryparam value="#arguments.clientID#" cfsqltype="cf_sql_varchar">
		<cfif structKeyExists(arguments,'StateList') and len(trim(arguments.stateList))>
		and d.stateCode in (<cfqueryparam value="#arguments.clientID#" cfsqltype="cf_sql_varchar" list="true">)
		</cfif> 	
		and p.isMaster = 1
		<cfif arguments.reportType eq 'byCompany'>
		order by d.distributorname, d.statecode, p.brandname, p.productName
		<cfelseif arguments.reportType eq 'byState'>
		order by d.statecode, d.distributorname, p.brandname, p.productName
		</cfif>	
		</cfquery>
	    <cfreturn stData />
	</cffunction>

	<cffunction name="getClientContactsQuery" access="public" output="false" returntype="struct">
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="SearchCriteria" type="string" default="">
		<cfargument name="start" default="1" required="no" />
		<cfargument name="end" default="100" required="no" />
		<cfargument name="canViewAllClients" type="boolean" required="true" default="false" />
		<cfscript>
            var Data = StructNew();
            var qList = "";
            Data['resultset'] = '';
            Data['success'] = true;
            Data['message'] = '';
        </cfscript>
        <cftry>
		<cfquery name="qList" datasource="#variables.dsn#">
		select SQL_CALC_FOUND_ROWS
	    		o.* 
		from (	
			select  client_idfk clientId
					,contact_Name contactName
					,contact_Email contactEmail
					,case 
						when contact_name is null then contact_email
					else concat(contact_Name, ' [', contact_email, ']') 
					end as displayName
					,null as companyName
			from ics_client_contacts
			where client_idfk = <cfqueryparam value="#arguments.clientID#" CFSQLType="cf_sql_varchar">	
			<cfif arguments.canViewAllClients>
			union
			select
				client_idfk clientId
				,concat (u.first_name, ' ', u.last_name) contactName
				,u.email contactEmail
				,concat(u.first_name, ' ', u.last_name, ' [', c.company_name, ']') displayName
				,c.company_name companyName
			from ics_users u,  ics_company c
			where u.client_idfk = c.company_id			
			</cfif>
		) o 
		where 0=0
		<cfif isDefined("arguments.SearchCriteria") AND len(trim(arguments.SearchCriteria))>
		and LOWER(CONCAT_WS(' ', trim(o.contactName), trim(o.contactEmail ), trim(o.companyName)  )) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#lcase(trim(arguments.SearchCriteria))#%">
	    </cfif>		
		order by contactName
		<cfif arguments.end neq 0>
		    LIMIT <cfqueryparam value="#arguments.start#" CFSQLType="cf_sql_numeric" />,<cfqueryparam value="#arguments.end#" CFSQLType="cf_sql_numeric" />	
		</cfif>
		</cfquery>		
		<cfcatch type="any">
				<cfset Data['success'] = false />
				<cfset Data['message'] = "There was a failure pulling the information from the database." />
			</cfcatch>
		</cftry>
		<cfif qList.recordcount>
            <cfquery name="qFoundRows" datasource="#variables.dsn#">
              SELECT found_rows() AS foundRows
            </cfquery>
        </cfif>
        <cfscript>
            Data['resultset'] = qList;
            // Add Found Rows to Paging
            if(qList.recordcount){
                Data['totalcount'] = qFoundRows.foundRows;
            } else {
                Data['totalcount'] = 0;
            }
            return Data;
        </cfscript>			
	</cffunction>
	
	<cffunction name="createClientContact" access="public" output="false" returntype="boolean">
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="contactEmail" type="string" required="true" />
		<cfargument name="contactName" type="string" required="false" default="" />
		<cfscript>
			var qCreate = "";
			if(not len(trim(arguments.contactName))) arguments.contactName = arguments.contactEmail;			
		</cfscript>
		<cftry>
			<cftransaction>
			<!--- We're just replacing the record --->	
			<cfquery name="qCreate" datasource="#variables.dsn#">
				delete from ics_client_contacts
				where client_idfk = <cfqueryparam value="#arguments.clientID#" CFSQLType="cf_sql_varchar">
				and contact_email = <cfqueryparam value="#arguments.contactEmail#" CFSQLType="cf_sql_varchar">
			</cfquery>	
			<cfquery name="qCreate" datasource="#variables.dsn#">
				INSERT INTO ics_client_contacts
					(
					 client_idfk
					,contact_Name
					,contact_Email
					)
				VALUES
					(
					<cfqueryparam value="#arguments.clientID#" CFSQLType="cf_sql_varchar" />
					,<cfqueryparam value="#arguments.contactName#" CFSQLType="cf_sql_varchar" null="#not len(arguments.contactName)#">
					,<cfqueryparam value="#arguments.contactEmail#" CFSQLType="cf_sql_varchar">
					)
			</cfquery>
			</cftransaction>
			<cfcatch type="database">
				<cfreturn false />
			</cfcatch>
		</cftry>
		<cfreturn true />
	</cffunction>


<!--- 	<cffunction name="getProducDistributorsReportQuery" access="public" returntype="struct">
	    <cfargument name="clientID" type="string" required="yes">
		<cfargument name="StateList" type="string" default="">
	    <cfset var stData = structNew()>
		 <cfstoredproc procedure="getComplSummary2" datasource="#variables.dsn#">   
		    <cfprocparam cfsqltype="cf_sql_varchar" value="#arguments.clientID#"> 
		    <cfprocparam cfsqltype="cf_sql_varchar" value="#arguments.StateList#"> 
			<cfprocresult name="stData.data" resultset="1">
			<cfprocresult name="stData.clientdata" resultset="2">
		  </cfstoredproc>
	    <cfreturn stData />
	</cffunction> --->
	
<!--- Version 1. Direct read to refresh tables. This is superseeded	<cffunction name="getFederalComplQuery" access="public" returntype="struct">
	    <cfargument name="clientID" type="string" required="yes">
	    <cfset var stData = structNew()>
	    <cfquery name="stData.data" datasource="#variables.dsn#">
		     select SQL_CALC_FOUND_ROWS 
		     	o.*
		     	,case o.certstatus
					when 'Pending' then
						case o.liquorType
							when 'Wine' then addWorkDays(o.submittaldate,25)
							when 'Distilled Spirit' then addWorkDays(o.submittaldate,40)
							when 'Distill' then addWorkDays(o.submittaldate,40)
							when 'Malt Beverage' then addWorkDays(o.submittaldate,9)
							else null
						end
					else null 
				end as estimatedApprovalDate
		     	from (		
	        select 
			     b.batfid productid
			    ,b.compid clientid
			    ,b.company clientname
			    ,b.brandname brandName
			    ,trim(b.itemname) productname
			    ,b.ltype liquorType
			    ,b.serial SerialNo
			    ,b.ics_cola_status certstatus
				,case
					when b.umamt = 0 then null
					else CONCAT_WS(' ', cast(cast(b.umamt as decimal(4, 1)) as char), b.umunit)  
				end as unitSize
				,trim(b.classtype) varietalClass	
			    ,m.submitdate submittalDate
				,m.appexpir expirationDate
				,m.appissue approvalDate
				,m.rejected rejecteddate
				,m.recdate receiveddate
					
			    ,b.atfid TTBNumber
			    ,null as CorrectionReqDate
			    ,null as qualification 
			    ,b.asignid assignedToID
			    ,b.asignname assignedToName
			    ,b.alcohol
			    ,b.vintage
				from batf b /* _full */	
						left join batf m on b.mbatfid = m.batfid
		    where 0=0
	        	
			and b.compid = <cfqueryparam value="#arguments.clientID#" cfsqltype="cf_sql_varchar">
		    
		    ) o 
	        
	       order by o.brandname, o.productname
	    </cfquery>
	    <cfreturn stData />
	</cffunction> --->
			
</cfcomponent>
			