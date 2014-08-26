/**
 *
 * @class AnExtension
 * @extends Ext.grid.GridPanel
 */
App.comp.budget = Ext.extend(Ext.grid.GridPanel, {
 
    // soft config (can be changed from outside)
     border:true
 	,header: true
	,managerid: 0
	,cycleid: 0
	,getequity: 0
	,managername: 'Test'
	,gridlocation: 'org'
	,height: 147

    ,initComponent:function() {
       
		var budgetStore = new Ext.data.DirectStore({
			api				: {
								read	: Ext.ss['orgService'].getManagerBudget
							}
			,paramOrder		: 'managerid,cycleid,getequity,showholdback'
			,paramsAsHash	: false
			,reader			: new Ext.data.JsonReader({
								fields			: [
													 {id: 'item', name: 'item', mapping: 'ITEM', type: 'string'}
													,{name: 'merit', mapping: 'MERIT', type: 'float'}
													,{name: 'pa', mapping: 'PA', type: 'float'}
													,{name: 'salary', mapping: 'SALARY', type: 'float'}
													,{name: 'icp', mapping: 'ICP', type: 'float'}
													,{name: 'lti', mapping: 'LTI', type: 'float'}
												],
								// idProperty		: 'EID',
								root			: 'DATA',
								totalProperty	: 'RECORDCOUNT'
							})
			,remoteSort		: false

		});	   
		
		var columns = [
						 {id:'item', header: '', width: 100, sortable: false, dataIndex: 'item', menuDisabled: false }
						,{header: "Merit", width: 60, sortable: true, dataIndex: 'merit', renderer: App.format.roundedNumberColor, hidden: true }
						,{header: "Prom/Adj", width: 60, sortable: true, dataIndex: 'pa', renderer: App.format.roundedNumberColor, hidden: true}
						,{header: "Salary", width: 80, sortable: true, dataIndex: 'salary', renderer: App.format.roundedNumberColor}
				    	,{header: "ICP", width: 80, sortable: true, dataIndex: 'icp', renderer: App.format.roundedNumberColor}
			]
		
		// figure if we're to display the LTI section
		if (App.comp.access.ltiaccess === 'LTIAccess' || App.comp.isHRG == true ) {
			columns = columns.concat([{header: "LTI", width: 80, sortable: true, dataIndex: 'lti', renderer: App.format.roundedNumberColorLTI}]);
		}

        var config = {
        	 title: App.i18n.budgetForText + ' ' + this.managername
			,store: budgetStore
			,autoExpandColumn	: 'item'	
			,columns: columns
			,loadMask: true
			,region: 'center'
			,defaults: {
                 sortable: true
				,menuDisabled: true
            }
		};
 
        // apply config
        Ext.apply(this, config);
        Ext.apply(this.initialConfig, config);
        // }}}
 
        // call parent
        App.comp.budget.superclass.initComponent.apply(this, arguments);
 
        // after parent code here, e.g. install event handlers
 
    } // eo function initComponent

    ,onRender:function() {
 
        // before parent code
 
        // call parent
        App.comp.budget.superclass.onRender.apply(this, arguments);
 
 		this.store.load({
			params:{
				 managerid: this.managerid
				,cycleid: this.cycleid
				,getequity: this.getequity
				,showholdback: 0
			}
		});
        // after parent code, e.g. install event handlers on rendered components
 
    } // eo function onRender

 
    // any other added/overrided methods
}); // eo extend
 
// register xtype
Ext.reg('managerbudget', App.comp.budget); 
 
// eof