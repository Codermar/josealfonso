component output="false" accessors=true {

    //property name="userID" type="string" getter="true" setter="true" default="";
    // property string userID;
    property string UserName;
    property string FirstName;
    property string MI;
    property string LastName;
    property string Email;
    property string Password;
    property string Created;
    property string Permissions;
    property numeric IsActive;
    property string ClientId;
    property string ClientName;
    property string ClientAccessIdList;
    
    public function init( 
         required string UserName
        //,string UserName = ''
        ,string FirstName = ''
        ,string mi = ''
        ,string LastName = ''
        ,string Email = ''
        ,string Password = ''
        ,string Created = ''
        ,string Permissions = 'User'
        ,numeric IsActive = 1
        ,string ClientId = ''
        ,string ClientName = ''
        ,string ClientAccessIdList
    ) {
        //this.setUserID(arguments.UserID);
        this.setUserName(arguments.UserName);
        this.setFirstName(arguments.FirstName);
        this.setMI(arguments.mi);
        this.setLastName(arguments.LastName);
        this.setEmail(arguments.Email);
        this.setPassword(arguments.Password);
        this.setCreated(arguments.Created);
        //if(listFindNoCase(arguments.permissions,'Admin') and not listFindNoCase(arguments.permissions,'canViewAllClients')) { arguments.permissions = ListAppend(arguments.permissions,'canViewAllClients'); } 
        this.setPermissions(arguments.Permissions);
        this.setIsActive(arguments.IsActive);
        this.setClientId(arguments.ClientId);
        this.setClientName(arguments.ClientName);
        this.setclientAccessIdList(arguments.ClientAccessIdList);
        return this;
    }
   

	public void function setMemento( struct memento ){
	    var i="";
	    var md = getMetaData( this );
	    
	    for( i=1;i<=arrayLen( md.properties );i++ ){
	        if ( structKeyExists( arguments.memento,md.properties[i]["name"] ) )
	            variables[md.properties[i]["name"]] = arguments.memento[md.properties[i]["name"]];
	    }
	}

	struct function getMemento() { 
	  var properties = {}; 
	   
	  for (local.md = getMetaData(this); 
	       structKeyExists(md, "extends"); 
	       md = md.extends)  { 
	       
	    if (structKeyExists(md, "properties"))  { 
	      for (local.i = 1; i <= arrayLen(md.properties); i++) { 
	        local.pName = md.properties[i].name; 
	        local.properties[pName]  = structKeyExists(variables, pName) ? variables[pName] : ""; 
	      } 
	    } 
	  } 
	   
	  return properties; 
	}
    
} 