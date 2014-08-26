<cfscript>

  /** Router.cfm
    * This version adapted to using coldSpring factory
    */

  function processRequest(){
     var reqOutput = '';
     var reqPacket = '';
     var requests = '';
     var thisReq = arrayNew(1);;
     var tmp = '';
     var jsonPacket = structNew();
     var result = '';
     var sortstr = ' '; 
     var idx = '';
     var sidx = '';
     var thisSort = ' ';
     var args = '';

     try {
       		reqPacket = deserializeJSON( toString( getHttpRequestData().content ) );
     	
          } catch ( any e ) {
        
           jsonPacket = structNew();
           jsonPacket[ 'type' ] = 'exception';
           jsonPacket[ 'tid' ] = 1;
           jsonPacket[ 'action' ] = 'none';
           jsonPacket[ 'message' ] = 'Invalid call to router. ' & e.message;
           jsonPacket[ 'where' ] = e.tagContext[ 1 ].line;
           jsonPacket[ 'StackTrace' ] = e.StackTrace;    
           reqPacket = jsonPacket;  
     }
     
     if (NOT isArray( reqPacket )){
         tmp = reqPacket;
         requests = arrayNew( 1 );   
         requests[ 1 ] = tmp;
     } else { requests = reqPacket; }  
           	
     for (idx=1;idx LTE arrayLen( requests ); idx=idx+1){
         // reset
         thisReq = requests[ idx ];
         sortstr = '';
  
         if(not StructKeyExists(thisReq, 'data') ) { thisReq['data'] = arrayNew(1); }
        
         if( isArray(thisReq.data) and arraylen(thisReq.data) and isStruct(thisReq.data[1]) ){
                  
             if(StructKeyExists(thisReq.data[1], 'sort') and isArray(thisReq.data[1].sort)){
                          
                 thisReq.data[1].sortRef = thisReq.data[1].sort;
                          
                 for (sidx=1;sidx LTE arrayLen( thisReq.data[1].sort ); sidx=sidx+1){  
                     thisSort = thisReq.data[1].sort[ sidx ];
                     sortstr = sortstr & thisSort.property & ' ' & iif(not listfindnocase('asc,desc',thisSort.direction),de('ASC'),de(thisSort.direction)) & iif(sidx neq arraylen(thisReq.data[1].sort),de(', '),de(' '));
                 } 
                 thisReq.data[1].sort = sortstr; 
             }
             args = thisReq.data[1];    
                        
         } else { args = thisReq.data; }
         
         thisReq.data = args;
   
    
         try {
             
             result = application.ExtDirect.invokeCall( thisReq );
         
         } catch ( any e ) {
              
             
             jsonPacket = structNew();
             jsonPacket[ 'type' ] = 'exception';
             jsonPacket[ 'tid' ] = thisReq[ 'tId' ];
             jsonPacket[ 'action' ] = thisReq[ 'action' ];
             jsonPacket[ 'message' ] = e.message;
             jsonPacket[ 'where' ] = e.tagContext[ 1 ].line;
             
             getpagecontext().getcfoutput().clearall();
             Writeoutput(serializeJson( jsonPacket ));
             abort;
         }

         if(IsStruct(result) AND StructKeyExists(result, 'name') AND StructKeyExists(result, 'result')){
             thisReq[ 'name' ] = result.name;
             thisReq[ 'result' ] = result;
         } else {
             thisReq[ 'result' ] = result;
         }

     }
          
     getpagecontext().getcfoutput().clearall();
     WriteOutput(serializeJson( requests ));
    // return reqOutput;
 }	
	
  function processFormRequest(){
    var output = '';	
	var _rq = structNew(); 
	
	_rq[ 'jsonPacket' ] = structNew();
	
	_rq.jsonPacket['tid'] = form.extTID;
	_rq.jsonPacket['action'] = form.extAction;
	_rq.jsonPacket['method'] = form.extMethod;
	_rq.jsonPacket['type'] = 'rpc';
	
	try {
		
		_rq.invokeArgs = {
			action = form.extAction,
			method = form.extMethod,
			data = form,
			type = 'rpc',
			tid = form.extTID
		};
	
		_rq.result = application.ExtDirect.invokeCall( _rq.invokeArgs );
		
	} catch ( any e ) {
		_rq.jsonPacket[ 'type' ] = 'exception';
		_rq.jsonPacket[ 'tid' ] = form.extTID;
		_rq.jsonPacket[ 'action' ] = form.extAction;
		_rq.jsonPacket[ 'message' ] = e.message;
		_rq.jsonPacket[ 'where' ] = e.tagContext[ 1 ].line;
		
		getpagecontext().getcfoutput().clearall();
		Writeoutput(serializeJson( _rq.jsonPacket ));
		abort;
	}
	_rq.jsonPacket[ 'result' ] = _rq.result;
	json = serializeJson( _rq.jsonPacket );
	
	if(form.extUpload){
		savecontent variable="output" { WriteOutput("<html><body><textarea>#json#</textarea></body></html>"); }
	} else {
		output = json;
	}
	getpagecontext().getcfoutput().clearall();
	Writeoutput(output);
  }
  
  ////////////// process request //////////////////////////
	if(Not StructIsEmpty(FORM)){ 
		processFormRequest();
	} else { // Must have been JSON posted in form body 
		processRequest();		
	}

</cfscript>
