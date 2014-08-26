<cfcomponent name="reportService" ExtDirect="true">

<!--- DOC:

	1. reportService.handleReport() gets called with the request arguments
	2. handleReport() will figure the report requested and call the appropriate service.
	 	Note: Each report call validates the arguments passed before calling the service

	Process to add reports:
	* Make a registry entry for the report
	* Add a service entry to the appServices.xml if necessary (this will allow this service to call them from the coldspring serviceFactory)
	* Make sure this service (reportService) has the ability to access the service that the report maybe calling. (i.e This file should have a set and get corresponding method to access the service)

	* Then we need to have a renderer for the report registered, create and place the renderer template in the path specified

 --->

    <cfscript>


        public reportService function init() {

            variables.data = "No data returned from report!";
            variables.reports = structNew();
            //// Report Registration ////
            // Each report that runs in this application must have a registration entry in the init method.

            // Note the name of the report key and the name of the cfm template should always be the same to keep things simple.

            registerReport(
                key = 'stateComplSummary'
                    ,rpt = createReport(
                    reportTitle = 'State Compliance Summary Report'
                        ,template = 'reports/stateComplSummary.cfm'
                        ,reqParams = 'clientID,productID'
                        ,resultType = 'struct'
                        ,orientation = 'portrait'
                        ,serviceName = 'icsReportsGateway'
                        ,methodName = 'getStateComplianceSummaryQuery'
                        ,status = 'Ready'
                        )
                    );

            registerReport(
                key = 'prodRegistration'
                    ,rpt = createReport(
                    reportTitle = 'State Product Compliance Report'
                        ,template = 'reports/prodRegistration.cfm'
                        ,templatePDF = 'reports/prodRegistrationPDF.cfm'
                        ,renderingMethod = 'getProdDistributorsReport'
                        ,reqParams = 'clientID,productID'
                        ,resultType = 'struct'
                        ,orientation = 'landscape'
                        ,serviceName = 'productService'
                        ,methodName = 'getProducRegistrationReportQuery'
                        ,status = 'Ready'
                        )
                    );

            registerReport(
                key = 'prodDistributors'
                    ,rpt = createReport(
                    reportTitle = 'Product Distributors By Distributor Report'
                        ,template = 'reports/prodDistributors.cfm'
                        ,reqParams = 'clientID'
                        ,resultType = 'struct'
                        ,orientation = 'portrait'
                        ,serviceName = 'icsReportsGateway'
                        ,methodName = 'getProducDistributorsReportQuery'
                        ,status = 'Ready'
                        )
                    );

            registerReport(
                key = 'prodDistributorsByState'
                    ,rpt = createReport(
                    reportTitle = 'Product Distributors By State Report'
                        ,template = 'reports/prodDistributorsByState.cfm'
                        ,reqParams = 'clientID'
                        ,resultType = 'struct'
                        ,orientation = 'portrait'
                        ,serviceName = 'icsReportsGateway'
                        ,methodName = 'getProducDistributorsReportQuery'
                        ,status = 'dev'
                        )
                    );

            registerReport(
                key = 'fedCompl'
                    ,rpt = createReport(
                    reportTitle = 'Federal Compliance Report'
                        ,template = 'reports/fedCompl.cfm'
                        ,reqParams = 'clientID'
                        ,resultType = 'struct'
                        ,orientation = 'landscape'
                        ,serviceName = 'productService'
                        ,methodName = 'getProducList'
                        ,status = 'Ready'
                        )
                    );

            registerReport(
                key = 'prodEstApproval'
                    ,rpt = createReport(
                    reportTitle = 'Pending Registrations Estimated Approval Report'
                        ,template = 'reports/prodEstApproval.cfm'
                        ,reqParams = 'clientID'
                        ,resultType = 'struct'
                        ,orientation = 'landscape'
                        ,serviceName = 'productService'
                        ,methodName = 'getPendingEstimatedApproval'
                        ,status = 'Ready'
                        )
                    );

            registerReport(
                key = 'productsWithNoDistrib'
                    ,rpt = createReport(
                    reportTitle = 'Products Requiring Distributor Appointment Report'
                        ,template = 'reports/productsWithNoDistrib.cfm'
                        ,reqParams = 'clientID'
                        ,resultType = 'struct'
                        ,orientation = 'landscape'
                        ,serviceName = 'productService'
                        ,methodName = 'productsWithNoDistrib'
                        ,status = 'Ready'
                        )
                    );

            registerReport(
                key = 'icsFeedback'
                    ,rpt = createReport(
                    reportTitle = 'ICS Feedback Report'
                        ,template = 'reports/icsFeedback.cfm'
                        ,reqParams = ''
                        ,resultType = 'struct'
                        ,orientation = 'portrait'
                        ,serviceName = 'icsService'
                        ,methodName = 'getIcsFeedback'
                        ,status = 'Ready'
                        )
                    );

            return this;
        }

        private struct function createReport(){
            var rpt = structNew();
            StructAppend(rpt,arguments);
            return rpt ;
        }

        function registerReport(key,rpt){
            variables.reports[key] = rpt;
        }

        function getRegisteredReports(){
            return variables.reports;
        }

        function getRegisteredReportByKey(key){
            return variables.reports[key];
        }

        // helper function for pagination
        function getPages(totalCount,limit){
            var loop = '';
            var tmp = structNew();
            var start = 1;
            var _st = StructNew();

            _st.limit = arguments.limit;
            _st.fractions = ceiling(arguments.totalCount/arguments.limit);
            _st.totalCount = arguments.totalCount;

            _st.arr = ArrayNew(1);
            loop = 1;
            while (loop LE _st.fractions) {

                tmp = structNew();

                if(loop eq 1) {
                    tmp.start = 1;
                    tmp.end = arguments.limit;
                } else {

                    tmp.start = start;
                    tmp.end = tmp.start + arguments.limit;
                    start=start+1;
                }

                if(not tmp.start gt totalCount)
                    _st.arr[loop] = tmp;

                loop = loop + 1;
                start = start+arguments.limit;
            }

            return _st;
        }

        public any function setReportData( required string data ){
            variables['data'] = arguments.data;
        }
        public any function getReportData(){
            return variables['data'];
        }

        public string function formatAnswer(required str){
            if(not(len(trim(arguments.str)))) return '<span class="no-answer">(No Answer)</span>';
            else return str;
        }
    </cfscript>


    <cffunction name="seticsReportsGateway" access="public" returntype="void" output="false" hint="I set the icsReportsGateway.">
        <cfargument name="icsReportsGateway" type="any" required="true" hint="icsReportsGateway" />
        <cfset variables['icsReportsGateway'] = arguments.icsReportsGateway />
    </cffunction>
    <cffunction name="geticsReportsGateway" access="public" returntype="any" output="false" hint="I return the icsReportsGateway.">
        <cfreturn variables['icsReportsGateway'] />
    </cffunction>

    <cffunction name="setproductService" access="public" returntype="void" output="false" hint="I set the productService.">
        <cfargument name="productService" type="any" required="true" hint="productService" />
        <cfset variables['productService'] = arguments.productService />
    </cffunction>
    <cffunction name="getproductService" access="public" returntype="any" output="false" hint="I return the productService.">
        <cfreturn variables['productService'] />
    </cffunction>

    <cffunction name="setGoogleDriveService" access="public" returntype="void" output="false" hint="I set the googleDriveService.">
        <cfargument name="googleDriveService" type="any" required="true" hint="googleDriveService" />
        <cfset variables['googleDriveService'] = arguments.googleDriveService />
    </cffunction>
    <cffunction name="getGoogleDriveService" access="public" returntype="any" output="false" hint="I return the googleDriveService.">
        <cfreturn variables['googleDriveService'] />
    </cffunction>

    <cffunction name="setIcsService" access="public" returntype="void" output="false">
        <cfargument name="IcsService" type="any" required="true" hint="icsService" />
        <cfset variables['IcsService'] = arguments.IcsService />
    </cffunction>
    <cffunction name="getIcsService" access="public" returntype="any" output="false">
        <cfreturn variables['IcsService'] />
    </cffunction>

    <cffunction name="setUtils" access="public" returntype="void" output="false">
        <cfargument name="Utils" type="any" required="true" hint="Utils" />
        <cfset variables['Utils'] = arguments.Utils />
    </cffunction>
    <cffunction name="getUtils" access="public" returntype="any" output="false">
        <cfreturn variables['Utils'] />
    </cffunction>

    <cfscript>

        public void function handleReport(required struct rd ){

            var	rpt = {
                report = arguments.rd.report
                ,errors = ""
                ,content = "No content returned on this report."
                ,data = structNew()
            };

            var srvc = "";
            var utils = getUtils();
            var rptContent = {};

            // rd is the request data
            if(not structKeyExists(rd,"report")){
                variables.data = "Error: No report specified!";
            } else {

                StructAppend(rpt, arguments.rd);

                rd.accessList = utils.getClientAccessIdList();
                rd.isAdmin = utils.isAdmin();

                rd.canViewAll= utils.canViewAllClients();
                rd.found = listFindNoCase(utils.getClientAccessIdList(), rd.clientId);
                // check that user is able to run the report for the requested company
                arguments.rd.canViewReport = iif(utils.isAdmin() ||  utils.canViewAllClients(), de('true'), listFindNoCase(utils.getClientAccessIdList(), rd.clientId));


                if (Not StructKeyExists(variables.reports, arguments.rd.report)) {
                    variables.data = "Error: Report #arguments.rd.report# is not registered!";
                } else {


                    rpt = getRegisteredReportByKey(arguments.rd.report);

                    rpt.hasPDFTemplate = structKeyExists(rpt, 'templatePDF');

                }

                if(!arguments.rd.canViewReport){
                    rpt.error = "You do not have permissions to run this report.";
                } else {

                    rpt.error = '';

                    if (arguments.rd.report eq 'rptstatus') {
                        rpt.content = getReportStatus();
                    } else {


                        // start the actual report run
                        rpt.canViewReport = arguments.rd.canViewReport;
                        rpt.clientId = rd.clientId;


                        //rpt.validate = validateReportParams(req=rpt.reqParams,check=arguments.rd);

                        // reports return either string content or data (assumed as a structure of elements like queries etc.)
                        srvc = variables[rpt.serviceName];

                        rptContent = callService(srvc, rpt.methodName, arguments.rd);

                        if (rpt.resultType eq "string") {
                            rpt.content = rptContent;
                        } else {

                            if(isStruct(rptContent)) {
                                // Note that the data from the service call is appended to the rpt struct overriding any matching keys.
                                StructAppend(rpt, rptContent, true);
                            }
                        }


                    /* // TODO: Something was wrong with the param validate...
                    if(NOT rpt.validate.invalid){
                    } else {
                        rpt.error = 'Cannot process report. Invalid params.';
                    }
                    */
                    }
                }
            }

            // now set the data for the instance
            variables.data = rpt;
        }

    </cfscript>


    <cffunction name="generateReport" access="public" returntype="any" hint="handles HTML Generation of reports.">
        <cfscript>

            var sToReturn = '';
            var rpt = getReportData();
            var hasTemplate = false;

            if(!isStruct(variables.data)){
                return '<div style="margin: 5px; padding: 10px; color: red;">' & variables.data & '</div>';
            }

            if(!structKeyExists(rpt,'output')) {rpt.output = "screen"; }

            if(structKeyExists(rpt,'report') && rpt.report == 'rptstatus'){
                return rpt.content;
            } else {
                if(not isdefined("rpt.reportTitle")) rpt.reportTitle = 'ReportTitle not specified.';
                hasTemplate = isDefined("rpt.template") AND len(trim(getFilefromPath(rpt.template)));
                if(not hasTemplate)  rpt.error = 'Template Name for "#rpt.reportTitle#" is blank';
            }
        </cfscript>

        <cfif structKeyExists(rpt,'error') and len(trim(rpt.error))>
            <cfset sToReturn = '<div style="margin: 1px; border: 1px dotted;  padding: 5px; color: red;">Error: #rpt.error#</div>' />
            <cfelse>

            <cftry>
                <!--- If the output is PDF and it's produced by an external template, return the output of it. Note that we need to have a common var name --->
                <cfif rpt.output eq 'pdf' and rpt.hasPDFTemplate>
                    <cfset reportVarName = 'sToReturn' />
                    <cfinclude template="#application.config.viewsRoot#/#rpt.templatePDF#">
                    <cfreturn sToReturn />
                <cfelse>
                    <cfsavecontent variable="sToReturn">
                        <!--- rendering template --->
                        <cfinclude template="#application.config.viewsRoot#/#rpt.template#">
                    </cfsavecontent>
                </cfif>

                <cfcatch type="missinginclude">
                    <cfreturn '<div style="color:red;">Generate Report Error:<br>Template Name for "#rpt.reportTitle#" not found. Could not find template <b>#rpt.template#</b></div>' />
                </cfcatch>
            </cftry>

        </cfif>
        <cfreturn sToReturn />
    </cffunction>

    <cffunction name="validateReportParams" access="private" output="false" returntype="struct">
        <cfargument name="req" type="string" required="true" />
        <cfargument name="check" type="struct" required="true" />
        <cfscript>
            var px = "";
            var st = structNew();
            st.invalid = 'No';
        </cfscript>
        <cfloop index="px" list="#arguments.req#">
            <cfscript>
                exists = StructKeyExists(arguments.check,px);
                st[px] = exists;
                if(not exists) st.invalid = 'Yes';
            </cfscript>
        </cfloop>
        <cfscript>
            if(st.invalid){
                st.error = "Missing parameters in report call.";
            }
            return st;
        </cfscript>
    </cffunction>

    <cffunction name="getReportStatus" access="public" returntype="string" hint="Report Status">
        <cfset var sToReturn = "">
        <cfsavecontent variable="sToReturn">
            <cfdump var="#variables.reports#" label="reports registration dump">
        </cfsavecontent>
        <cfreturn sToReturn />
    </cffunction>

    <cffunction name="callService" access="private" output="false" hint="Executes a component.">
        <cfargument name="cfc" />
        <cfargument name="method" />
        <cfargument name="args" />
        <cfset var result = "">
        <cfif structKeyExists(arguments.cfc,arguments.method)>
            <cftry>
                    <cfinvoke component="#arguments.cfc#"
                            method="#arguments.method#"
                            argumentcollection="#arguments.args#"
                            returnvariable="result" />
                <cfcatch type="any">
                    <cfrethrow />
                </cfcatch>
            </cftry>
        </cfif>
        <cfreturn result />
    </cffunction>

    <cffunction name="getMergedColaInfo" access="public" output="false" returntype="struct" ExtDirect="true">
        <cfargument name="clientId" type="string" required="true" />
        <cfargument name="itemList" type="string" required="true" />
        <cfscript>
            var _mergeFileName = listGetAt(session.userInfo.username,1,'@') & "-merged.pdf";
            var _targetMergeDir = application.config.appPhysicalDir & 'temp/files';
            var _targetMergeFile = _targetMergeDir & '/' & _mergeFileName;
            var _url =  application.config.appRootURL & 'temp/files/';
            var _mergeFileUrl = _url & _mergeFileName;
            var result = {};
            var _file = '';
            var _files = [];
            var _fileList = '';
            var _dir = 'ram:///';
            var _ds = getgoogleDriveService();
            var idx = '';
            var _list = '';

            if(!DirectoryExists(_targetMergeDir)) {
                DirectoryCreate(_targetMergeDir);
            }

            _canViewAllClients = getUtils().canViewAllClients();

            if(not _canViewAllClients and not len(trim(arguments.clientId)) or arguments.clientId neq session.UserInfo.clientId) arguments.clientId = session.UserInfo.clientId;


            try {

                cleanRamDir();

                _fileList = ListChangeDelims(arguments.itemList, ',', ':');

                for (idx = 1; idx <= listLen(_fileList); idx++) {

                    _list = _ds.getDocumentList(doctype = 'pdf', search = listGetAt(_fileList, idx));
                    _file = _ds.getSourceURL(_list.sourceURL[1]);

                    arrayAppend(_files,
                    {
                        fileName = _list.title[1],
                        file = _file
                    });

                    fileWrite(_dir & "/" & _list.title[1], _file);
                }

                mergeFiles(directory=_dir,destination=_targetMergeFile);

				result['success'] = true;
                result['data'] = {
                    "mergeFileUrl" = _mergeFileUrl
                };

            } catch (any e) {
                result['success'] = false;
                result['message'] = 'Error: ' & e.message & e.detail;
            }

            return result;
        </cfscript>

    </cffunction>

    <cffunction name="cleanRamDir" returntype="void">
        <cfscript>
            var files = '';
            var directories = '';
        </cfscript>

        <cfdirectory name="files" action="list" directory="ram://" recurse="true" type="file" />

        <!--- Loop over all the files on our RAM drive. --->
        <cfloop query="files">
            <!--- Delete the file. --->
            <cffile action="delete" file="#files.directory#/#files.name#" />
        </cfloop>

        <!--- Gather all the directories on the virtual file sytsem. --->
        <cfdirectory name="directories" action="list" directory="ram://" recurse="true" type="dir" />

        <!--- Loop over all the directories on our RAM drive. --->
        <cfloop query="directories">
            <!--- Delete the direcory. --->
            <cfdirectory action="delete" directory="#directories.directory#/#directories.name#" />
        </cfloop>

    </cffunction>

    <cffunction name="mergeFiles" returntype="void">
        <cfargument name="directory" type="string" required="true" />
        <cfargument name="destination" type="string" required="true" />
         <!--- merge the files in ram to the physical directory --->
        <cfpdf action="merge" directory="#arguments.directory#" order="name" ascending="yes" destination="#arguments.destination#" overwrite="yes">
    </cffunction>

    <cffunction name="getClientContacts" access="public" output="false" returntype="struct" ExtDirect="true">
        <cfargument name="clientID" type="string" required="true" />
        <cfargument name="SearchCriteria" type="string" default="">
        <cfargument name="start" type="string" required="true" default="0" />
        <cfargument name="limit" type="string" required="true" default="100" />
        <cfscript>
            var paging = getUtils().getPagingSetup(start=arguments.start,limit=arguments.limit);
            var canViewAllClients = getUtils().canViewAllClients();
            return geticsReportsGateway().getClientContactsQuery(
                     clientId=arguments.clientId
                    ,canViewAllClients=canViewAllClients
                    ,SearchCriteria=arguments.SearchCriteria
                    ,start=paging.start
                    ,end=paging.limit
            );
        </cfscript>
    </cffunction>

    <cffunction name="sendClientInfoMessage" access="public" output="false" returntype="struct" ExtDirect="true" ExtFormHandler="true">
        <cfargument name="recipientEmail" type="string" required="false" default="" />
        <cfargument name="subject" type="string" required="false" default="" />
        <cfargument name="MessageBody" type="string" required="true" default="" />
        <cfargument name="outputType" type="string" required="true" default="html" />
        <cfargument name="AdditionalMessage" type="string" required="false" default="" />
        <cfargument name="clientID" type="string" required="false" default="" />
        <cfargument name="recipientNewEmail" type="string" required="false" default="" />
        <cfargument name="recipientNewName" type="string" required="false" default="" />
        <cfargument name="userEmail" type="string" required="false" default="" />
        <cfargument name="ccme" type="boolean" required="false" default="0" />
        <cfargument name="justme" type="boolean" required="false" default="0" />
        <cfargument name="saveRecipient" type="boolean" required="false" default="0" />
        <cfargument name="colaCert" type="boolean" required="false" default="0" />
        <cfargument name="isColaOnly" type="boolean" required="false" default="false" />
        <cfargument name="colaCertFileName" type="string" required="false" default="" />
        <cfargument name="requestData" type="string" required="false" default="" />
        <cfscript>
            var result =  structNew();
                result['success'] = true;
                result['message'] = 'Message Sent Successfully.';
            var _emailBody = "";
            var _rptBody = "";
            var _isDev = application.Environment eq "localhost";
            var _idx = '';
            var _doc = "";
            var certFileContent = "";
            var certFileNotFound = false;
            var _docService = "";
            var _svrInfo = structNew();

            _svrInfo.emailList = arguments.recipientEmail;
            _svrInfo.ccList = "";
            var _requestData = [];
            var _hasColaAttachments = len(trim(arguments.requestData));

            if(_hasColaAttachments){

                _requestData = DeserializeJSON(arguments.requestData).items;
                _docService = getgoogleDriveService();

                for(_idx=1; _idx <= ArrayLen(_requestData); _idx++){

                    _requestData[_idx].certFileContent = "";

                    _doc = _docService.getPDFFileInfo(search=_requestData[_idx].certfilename);

                    if(_doc.data.found){
                        _requestData[_idx].certFileContent = _docService.getSourceURL(_doc.data.sourceURL);
                    }
                    _requestData[_idx].certFileFound = isBinary(_requestData[_idx].certFileContent);
                }
            }


            if(arguments.justme){

                _svrInfo.emailList = arguments.userEmail;

            } else {

                if(len(trim(arguments.recipientNewEmail))){
                    _svrInfo.emailList = listAppend(_svrInfo.emailList,arguments.recipientNewEmail);
                }

                if(arguments.ccme){
                    _svrInfo.ccList = listAppend(_svrInfo.ccList,arguments.userEmail);
                }

            }

            // debug ref
            _svrInfo.emailListOrig = _svrInfo.emailList;
            _svrInfo.ccListOrig = _svrInfo.ccList;



            if(arguments.colaCert and len(trim(arguments.colaCertFileName))){
                // get the COLA cert
                _docService = getGoogleDriveService();
                doc = _docService.getPDFFileInfo(search=arguments.colaCertFileName);

                if(_doc.data.found){
                    certFileContent = _docService.getSourceURL(_doc.data.sourceURL);
                } else {
                    certFileNotFound = true;
                }
            }


            if(arguments.saveRecipient and len(trim(arguments.recipientNewEmail))){
                    geticsReportsGateway().createClientContact(
                    clientID=arguments.clientID
                        ,contactEmail=arguments.recipientNewEmail
                        ,contactName=arguments.recipientNewName
                        );
            }


            // for development, replace the email list
            if(_isDev) {
                _svrInfo.emailList = 'jgalfonso@me.com';
                _svrInfo.ccList = '';
            }

        </cfscript>

        <cftry>

            <cfsavecontent variable="_emailBody"><cfoutput>
                <div class="grayDescBox">
                    This is a report generated by #application.config.siteName# by MHW Ltd. and sent to you by <b>#arguments.userFullName#</b>.
                <cfif structKeyExists(arguments,"AdditionalMessage") and len(trim(arguments.AdditionalMessage))>
                        <p><b>The sender also wrote:</b> #AdditionalMessage#</p>
                </cfif>
                </div>

                <cfif len(trim(arguments.MessageBody))>#arguments.MessageBody#</cfif>
                <cfif _hasColaAttachments>#renderColaCertSummary(_requestData)#</cfif>

                <div class="grayDescBox">
                #application.config.privacyStament#<br>
                #application.config.privacyDisclaimer#
                </div>
            </cfoutput></cfsavecontent>

            <!--- we also want the content converted to PDF so it can be attached --->
            <cfif not arguments.isColaOnly>
                <cfdocument name="_rptBody" format="PDF" fontembed="no"
                        orientation="landscape"
                        marginleft="0.45"
                        marginright="0.15"><cfoutput>
                    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
                    <html class="x-ux-grid-printer">
                    <head>
                        <title></title>
                    <style type="text/css">
                    <cfinclude template="/ics/resources/css/_reports.css">
                    ##cert-attach-notice {display: none;}
                    </style>
                    </head>
                    <body class="x-ux-grid-printer-body">
                    #_emailBody#
                    </body></html>
                </cfoutput></cfdocument>
            </cfif>

            <cfmail type="html"
                    from="ICS Reporting <#application.notifyemail#>"
                    subject="#arguments.subject# - #dateFormat(now(), 'mm/dd/yyyy')#"
                    to="#_svrInfo.emailList#"
                    cc="#_svrInfo.ccList#">
                <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
                <html class="x-ux-grid-printer">
                <head>
                    <title></title>
                <style type="text/css">
						<cfinclude template="/ics/resources/css/gridPrinter.css">
						<cfinclude template="/ics/resources/css/_reports.css">
					</style>
            </head>
            <body class="x-ux-grid-printer-body">

                <cfif certFileNotFound>
                    <div style="color:red;border:1px solid red; padding: 5px;">The COLA Certificate file was not found. Please contact MHW Ltd.</div>
                </cfif>
                #_emailBody#
                <cfif _isDev>
                    <hr>
                    Debug Info:<br>
                    emailList: #_svrInfo.emailListOrig# <br>
                ccList = #_svrInfo.ccListOrig# <br>
                </cfif>
                </body></html>

                <cfif not arguments.isColaOnly>
                    <cfmailparam
                            file="ICSReport_#dateFormat(now(), 'mm-dd-yyyy')#.pdf"
                            type="application/pdf"
                            content="#_rptBody#" />
                </cfif>
                <cfif not certFileNotFound and isBinary(certFileContent)>
                    <cfmailparam file="COLACertificate.pdf" type="application/pdf" content="#certFileContent#" />
                </cfif>
                <cfif _hasColaAttachments>
                    <cfloop from="1" to="#arrayLen(_requestData)#" index="local.idx">
                        <cfif isBinary(_requestData[local.idx].certFileContent)>
                            <cfmailparam file="COLACertificate.pdf" type="application/pdf" content="#_requestData[local.idx].certFileContent#" />
                        </cfif>
                    </cfloop>
                </cfif>
            </cfmail>

            <cfcatch type="any">
                <cfscript>
                    result['success'] = false;
                    result['errortype'] = "SendMessageError";
                    result['errormessage'] = cfcatch.Message & cfcatch.detail;
                    result['errorcomponent'] = 'reportService';
                    result['errormethod'] = 'sendClientInfoMessage';
                </cfscript>
            </cfcatch>
        </cftry>

        <cfreturn result />
    </cffunction>

    <cffunction name="renderColaCertSummary" returntype="string">
        <cfargument name="productInfo" type="array" required="yes">
        <cfsavecontent variable="local.sToReturn"><cfoutput>
            <h2></h2>
            <table class="TableWrapBorder" cellpadding="0" width="100%" border="0" cellspacing="0">
                <tr>
                    <td class="rpt-table-hdr">Brand Name</td>
                    <td class="rpt-table-hdr">Item Description</td>
                    <td class="rpt-table-hdr">Varietal</td>
                    <td class="rpt-table-hdr">Liquor Type</td>
                    <td class="rpt-table-hdr">COLA Status</td>
                    <td class="rpt-table-hdr">TTB Number</td>
                    <td class="rpt-table-hdr">Serial Number</td>
                    <td class="rpt-table-hdr">File Found</td>
                </tr>
            <cfloop from="1" to="#arrayLen(arguments.productInfo)#" index="local.idx">
                    <tr>
                    <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].brandName#</td>
                <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].productname#</td>
                <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].varietalclass#</td>
                <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].liquorType#</td>
                <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].certstatus#</td>
                <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].ttbnumber#</td>
                <td class="rpt-data-cel left" align="left">#arguments.productInfo[local.idx].serialno#</td>
                <td class="rpt-data-cel left" align="left">#YesNoFormat(arguments.productInfo[local.idx].certFileFound)#</td>
                </tr>
            </cfloop>
            </table>
        </cfoutput></cfsavecontent>
        <cfreturn local.sToReturn />
    </cffunction>

<!--- /// report rendering specific methods /// --->
    <cffunction name="renderNonRegStatesSection" returntype="string">
        <cfargument name="query" type="query" required="yes">
        <cfargument name="startrow" type="numeric" required="yes">
        <cfargument name="endrow" type="numeric" required="yes">
        <cfset var sToReturn = ''>
        <cfsavecontent variable="sToReturn"><cfoutput>
            <table class="TableWrapBorder" cellpadding="0" width="100%" border="0" cellspacing="0">
                <tr>
                    <td class="rpt-table-hdr">State</td>
                    <td class="rpt-table-hdr">Liquor Type</td>
                    <td class="rpt-table-hdr">Brand Registration</td>
                    <td class="rpt-table-hdr">Auto Apprvl.</td>
                    <td class="rpt-table-hdr">Price Posting</td>
                    <td class="rpt-table-hdr">Distrib. Appoint.</td>
                </tr>
            <cfloop query="arguments.query" startrow="#startrow#" endrow="#arguments.endrow#">
                    <tr>
                    <td class="rpt-data-cel left" align="left">#stateCode#</td>
                <td class="rpt-data-cel left" align="left">#liquorType#</td>
                <td class="rpt-data-cel left" align="left">#BrandRegist#</td>
                <td class="rpt-data-cel left" align="left">#AutoApproval#</td>
                <td class="rpt-data-cel left" align="left">#PricePostingReq#</td>
                <td class="rpt-data-cel left" align="left">#distrApptReq#</td>
                </tr>
            </cfloop>
            </table>
        </cfoutput></cfsavecontent>
        <cfreturn sToReturn />
    </cffunction>

    <cffunction name="renderRequiredRegistrations" returntype="string">
        <cfargument name="query" type="query" required="yes">
        <cfargument name="startrow" type="numeric" required="yes">
        <cfargument name="endrow" type="numeric" required="yes">
        <cfargument name="reqStatesList" type="string" required="yes">
        <cfset var sToReturn = ''>
        <cfsavecontent variable="sToReturn"><cfoutput>
            <table class="TableWrapBorder" cellpadding="0" border="0" width="100%" cellspacing="0">
            <tr>
                <td class="rpt-table-hdr" align="left" width="500">Brand/Product</td>
                <cfloop list="#arguments.reqStatesList#" index="st">
                    <td class="rpt-table-hdr">#st#</td>
                </cfloop>
            </tr>
            <cfloop query="arguments.query" startrow="#arguments.startRow#" endrow="#arguments.endRow#">
                    <tr>
                        <!--- TODO: alcoholPercent could be used for spirits if liquorType = Destilled Spirit --->
                        <td class="rpt-data-cel left" align="left" style="font-size:10px;"><b>#request.capFirstTitle(brandname)#</b><br>#productname#</td>

                    <cfloop list="#reqStatesList#" index="st">
                        <cfset ro = request.getStateStatusCode(arguments.query[lcase(st) & 'registrationstatus'][currentrow]) />
                            <td class="#ro.cls# #ro.cellcls# rpt-data-cel">#ro.code#
                            <cfif len(ro.code) eq 'U'><br>
                                #ro.status#</cfif>
                            </td>
                    </cfloop>
                    </tr>
            </cfloop>
            </table>
        </cfoutput></cfsavecontent>
        <cfreturn sToReturn />
    </cffunction>

    <cffunction name="getPDF" access="public" returntype="any" hint="produce pdf content">
        <cfscript>

            var _report = '';
            // TODO: It's  little disturbing that CF would not find this var within the cfdocument tag if it's not global
            _rpt = getReportData();

            if(not structKeyExists(_rpt,'orientation')) _rpt['orientation'] = 'landscape';

            if(not structKeyExists(_rpt,'CompanyName')){
                _rpt.CompanyName = '';
            }
            // cfdocument seems only able to do inline formatting in the header and footers! :-(
            // These are helper styles for the pdf generating template
            _rpt.styles = {
                header = 'font-size: .9em; font-family: Arial, Sans Serif, Helvetica;border-bottom:1px solid gray;padding:0 0 7px;margin-bottom:15px;'
                ,footer = 'font-size: .6em; font-family: Arial, Sans Serif, Helvetica;border-top: 1px solid gray;color:gray;padding-top:2px;'
                ,h1 = 'font-size: 1.2em; font-family: Arial, Sans Serif, Helvetica;font-weight: bold; margin-top: 10px;'
                ,paging = 'font-size: 12px; font-family: Arial, Sans Serif, Helvetica;'
            };

        </cfscript>

        <cfdocument name="_report" format="PDF" localUrl="true"
                orientation="#_rpt.orientation#"
                marginleft="0.45"
                marginright="0.25"
                marginTop="0.5"
                scale="95"><cfoutput>

            <cfdocumentitem type="header" evalAtPrint="true">
                <div style="#_rpt.styles.header#" align="right">Page #cfdocument.currentpagenumber# of #cfdocument.totalpagecount#
                    <br>
                <cfif cfdocument.currentpagenumber gt 1>#_rpt.reportTitle# <cfif len(_rpt.CompanyName)>for #_rpt.CompanyName#</cfif> - </cfif>#application.config.siteName#
                </div>
            </cfdocumentitem>

            <cfdocumentitem type="footer" evalAtPrint="true">
                <div style="#_rpt.styles.footer#">#application.config.privacyStament#</div>
            </cfdocumentitem>

            <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
            <html><head><title></title>
            <style type="text/css">
            <cfinclude template="#application.config.viewsRoot#/reports/_reports.css">
            ##cert-attach-notice {display: none;}
            ##rpt-hdr td {margin-bottom:7px;padding-bottom:7px;}
            body {margin:0 0 0 0;}
            </style>
            </head>
            <body>
            <!--- header #getReportHeader(_rpt)#	 --->
            <!--- /// Main report content /// --->
            #generateReport()#
            </body></html>

        </cfoutput></cfdocument>
        <cfreturn _report />
    </cffunction>

    <cffunction name="getReportHeader" access="public" returntype="string">
        <cfscript>
            var sToReturn = '';
            var rpt = getReportData();
            if(not structKeyExists(rpt,'CompanyName')){
                rpt.CompanyName = '';
            }
        </cfscript>
        <cfsavecontent variable="sToReturn"><cfoutput>
            <table id="rpt-hdr" width="100%" border="0" cellspacing="0" cellpadding="0" style="border-bottom: 1px solid gray;margin-top: -10px;">
            <tr>
            <td width="8%" valign="bottom"><img src="#application.config.imagesPath#/mhw/mhwlogo-header.gif" border="0" width="90"></td>
        <td valign="bottom" align="right" width="62%">
        <div class="PageTitle">#rpt.reportTitle# <cfif len(rpt.CompanyName)>for #rpt.CompanyName#</cfif></div>
        </td>
        <td width="20%" valign="bottom" align="right">Date: #dateformat(now(),'mm/dd/yyyy')#</td>
        </tr>
        </table>
        </cfoutput></cfsavecontent>
        <cfreturn sToReturn />
    </cffunction>

    <cffunction name="renderNonRegStates" access="public" returntype="string">
        <cfargument name="NoRegStatesQuery" type="query" required="yes">
        <cfscript>
            var sToReturn = '';
            var _ct = arguments.NoRegStatesQuery.recordcount;
            var _splitAt = int(_ct/2)+1;
        </cfscript>
        <cfsavecontent variable="sToReturn"><cfoutput>
            <div class="PageSubTitle">Non-Registration States</div>
            <div class='title-comment'>(Applies to all of your products in the listed states)</div>
            <cfif _splitAt gt 15>
                <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>

                <td width="49%" valign="top">#renderNonRegStatesSection(arguments.NoRegStatesQuery,1,_splitAt)#</td>
                <td width="2%">&nbsp;</td>
            <td width="49%" valign="top">#renderNonRegStatesSection(arguments.NoRegStatesQuery,_splitAt+1,_ct)#</td>
            </tr>
            </table>
                <cfelse>
                <div style="width:500px;">#renderNonRegStatesSection(arguments.NoRegStatesQuery,1,_ct)#</div>
            </cfif>
        </cfoutput></cfsavecontent>
        <cfreturn sToReturn />
    </cffunction>

    <cffunction name="getRequiredStatesSectionHeader" access="public" returntype="string">
        <cfscript>
            var sToReturn = '';
            var st = '';
            var rpt = getReportData();
        </cfscript>
        <cfsavecontent variable="sToReturn"><cfoutput>
            <table width="100%">
            <tr>
            <td valign="bottom" align="left">
                <div class="PageSubTitle">Required States Registration Status:</div>
            <div class="gray left">#rpt.data.rptdata.recordcount# records.</div>
        </td>
        <td align="right">
        <table class="TableWrapBorder" cellpadding="0" border="0" width="650" cellspacing="0">
        <tr><td class="rpt-data-cel small" style="font-weight: bold; vertical-align: middle;">Code Key:</td>
            <cfloop index="st" list="Approved,Approved/Price Posting Req.,Pending,Pending/Price Posting Req.,Price Posting Only,Expired,Expired COLA,Rejected,Cancelled,Not Requested,Not Required,Control State (Broker/Dist)">
                <cfset so = request.getStateStatusCode(st) /> <!--- TODO: Status code function is in a different scope, consider bringing it here or move it to utils --->
                    <td class="#so.cls# rpt-data-cel small center"><div align="center"><b>#so.code#:</b><br />#st#</div></td>
            </cfloop>
            </tr></table>
            </td>
            </tr>
            </table>
        </cfoutput></cfsavecontent>
        <cfreturn sToReturn />
    </cffunction>

</cfcomponent>

