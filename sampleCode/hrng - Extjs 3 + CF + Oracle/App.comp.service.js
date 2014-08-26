/**
 * App.comp.service.js
 * Functions to assist the main application
 * 
 */

App.comp.service = Ext.apply({}, {
	 
	 getOrgGrid: function(){
	 	return Ext.getCmp('org-grid');
	 }

	// Note this is the same function present in comp.validateInput
	,isIncreaseOutOfRange: function(item,value,record){
		var v = {invalidrange: false, value: value};
		var rd = record.data;
		/**
		 * NOTE: This routine is repeated in the comp.validateInput.js file, any change must be syncronized.
		 * The guidelines will be set as + / - percentage of the pre-populated recommendation.  For merit we will use x%.  
		 * Therefore, if an entry is x% below or x% above the recommended value it will be considered out of range and 
		 * will require a justification.  
		 * 
		 * As part of modifying the merit amount, we need to validate if we're overriding other lumpsum input
		 */		
		switch (item){
			case 'merit':{
				v.recommended = rd.recmeritincperc;
				v.threshold = rd.salaryincwarningthreshold;
			break;}
			case 'lumpsum':{
				v.recommended = rd.lumpsumrecommendedperc;
				v.threshold = rd.salaryincwarningthreshold;				
			break;}
			case 'lti':{
				v.recommended = rd.ltirecommendedperc;
				v.threshold = rd.ltiincwarningthreshold;					
			break;}
			case 'icp':{
				v.recommended = rd.icprecommendedincperc;
				v.threshold = rd.icpincwarningthreshold;				
			break;}
		}
	
		var percofchange = value / v.recommended * 100;
		
		if(item == 'icp'){
			v.min = Math.floor(v.recommended * (100 - v.threshold) / 100);
			v.max = Ext.util.Format.round(v.recommended * (100 + v.threshold) / 100,0);
		} else {	
			v.min = Ext.util.Format.round(v.recommended,1) * (100 - v.threshold) / 100;
			v.max = Ext.util.Format.round(v.recommended,1) * (100 + v.threshold) / 100;
		}
			
		if(!Ext.isEmpty(value)){
			if(percofchange > 100) {
				v.invalidrange = Ext.util.Format.round(value,1) > Ext.util.Format.round(v.max,1);
			} else if(percofchange < 100){
				v.invalidrange = Ext.util.Format.round(value,1) < Ext.util.Format.round(v.min,1);
			}		
		} else {v.invalidrange = false;}	
		return v;
	}
	
	,updateCompFormInfo: function(record,form){
		// Utility function to update the form and summary in the employee comp panel
		// by default use the worksheet form
		if(!form) form = Ext.getCmp('F-' + record.data.employeeid);
		if (form) {
			// update last modified string
			var dt = new Date();
			record.data.lastmodifiedbystring = App.requestParams.employeeName + ' on ' +  Ext.util.Format.date(dt,'d-M-Y g:i:s A');
			record.commit();
			form.getForm().loadRecord(record);
			
			// update new LTI values if applicable 
			var ltinp = Ext.get('LTINP-' + record.data.employeeid),
				ltina = Ext.get('LTINA-' + record.data.employeeid);
			
			if (ltinp) { ltinp.dom.innerHTML = App.format.renderDisplayField(App.i18n.percentOfBaseSalaryText, App.format.formatPercent(record.data.unvestedamountnewpercent)); }
			if (ltina) { ltina.dom.innerHTML = App.format.renderDisplayField(App.i18n.amountText, App.format.roundedNumber(record.data.unvestedsharesvaluenew)); }
		}	
		var summary = Ext.getCmp('Summary-' + record.data.employeeid);
		if(summary) summary.update(comp.ws.sections.salicpSummary(record.data));
	}
 
	,applyRecValues: function(e,btn,target){
		/*
		 * This is called by events attached to form input elements
		 * When this function calls the push functions, it needs
		 * to tell them to check for override.
		 */	
		 	
		// check the event's getTarget method which will 
	    // return a reference to any matching element within the range
	    // of bubbling (the second param is the range).  the true param 
	    // is to return a full Ext.Element instead of a DOM node
		target = e.getTarget('.push-rec', 5, true);  
	    if(target){
	        // if target is non-null, you know a matching el was found
		    var item = target.id.split('-');
			//var grid = this[0];
			var form = this[1];
			var record = this[2];
			var returndialog = this[3];
			var reload = false;
	
			switch(item[0]){
				case 'merit':{
					comp.validateInput({
						 record: record
						,field: 'meritrecpush' // field.name
						,newvalue: record.data.recmeritincperc
						,returndialog: returndialog
						,isRecPush: true
					});
				break;}
				case 'lumpsum':{
					comp.validateInput({
						 record: record
						,field: 'lumpsumrecpush' // field.name
						,newvalue: record.data.lumpsumrecommendedperc
						,returndialog: returndialog
						,isRecPush: true
					});
				break;}
				case 'lti':{
					comp.validateInput({
						 record: record
						,field: 'ltirecpush' // field.name
						,newvalue: record.data.ltirecommendedperc
						,returndialog: returndialog
						,isRecPush: true
					});
				break;}
				case 'icp':{
					comp.validateInput({
						 record: record
						,field: 'icprecpush' // field.name
						,newvalue: record.data.icprecommendedincperc
						,returndialog: returndialog
						,isRecPush: true
					});
				break;}
			}
		
		}
	} 
	
	,pushMeritOnGrid: function(val,rowIndex){		
		var store = App.comp.service.getOrgGrid().store;
		var record = store.getAt(rowIndex);
		var grid = Ext.get('org-grid');		
		comp.validateInput({
			 record: record
			,field: 'meritrecpush' // field.name
			,newvalue: record.data.recmeritincperc
			,returndialog: true
			,isRecPush: true
		});			
	}
	
	,pushRecLTIOnGrid: function(val,rowIndex){
		var store = App.comp.service.getOrgGrid().store;
		var record = store.getAt(rowIndex);
		comp.validateInput({
			 record: record
			,field: 'ltirecpush' // field.name
			,newvalue: record.data.ltirecommendedperc
			,returndialog: true
			,isRecPush: true
		});
	}	

	,pushRecICPOnGrid: function(val,rowIndex){
		var store = App.comp.service.getOrgGrid().store;
		var record = store.getAt(rowIndex);
		comp.validateInput({
			 record: record
			,field: 'icprecpush' // field.name
			,newvalue: record.data.icprecommendedincperc
			,returndialog: true
			,isRecPush: true
		});
	}
		
	,pushLumpSumOnGrid: function(val,rowIndex){
		var store = App.comp.service.getOrgGrid().store;
		var record = store.getAt(rowIndex);
		comp.validateInput({
			 record: record
			,field: 'lumpsumrecpush' // field.name
			,newvalue: record.data.lumpsumrecommendedperc
			,returndialog: true
			,isRecPush: true
		});	
	}
		
	,saveCompInput: function(record){
		var r = record
			dt = new Date();
		
		var conn = new Ext.data.Connection();
			conn.request({
				 url: App.requestParams.cfcPath + '/event.cfc'
				,method: 'POST' 
				,params: {
					 method: 'handleAjaxEvent'
					,event: 'orgService.saveCompInput'
					,employeeid: r.data.employeeid
					,cycleid: r.data.cycleid
					,MeritAmt: r.data.meritamt
			        ,MeritPerc: r.data.meritperc
			        ,MeritOutsideRangeJust: r.data.meritoutsiderangejust
			        ,LumpSumAmt: r.data.lumpsumamt
			        ,LumpSumPerc: r.data.lumpsumperc
					,LumpSumOutsideRangeJust: r.data.lumpsumoutsiderangejust
			        ,AdjustmentAmt: r.data.adjustmentamt
			        ,AdjustmentPerc: r.data.adjustmentperc
			        ,AdjustmentReason: r.data.adjustmentreason
			       	,AdjEffectiveDate: r.data.adjusteffectivedate
			        ,AdjustmentOutsideRangeJust: r.data.adjustmentoutsiderangejust
			        ,NewJobCode: r.data.newjobcode
			        ,NewJobJustification: r.data.newjobjustification
			        ,PromotionAmt: r.data.promotionamt
			        ,PromotionPerc: r.data.promotionpercent
			        ,PromotionEffectiveDate: r.data.promotioneffectivedate
					,PromotionOutsideRangeJust: r.data.promotionoutsiderangejust
			        ,ICPAward: r.data.icpamount
			        ,ICPIndivModifier: r.data.icpindivmodifiernew
			        ,ICPOutsideRangeJust: r.data.icpoutsiderangejust
			        ,LTIGrantTarget: r.data.targetgrant
			        ,LTIGrantAmt: r.data.grantamt
			        ,LTGrantModifier: r.data.ltimodifier
			        ,LTIGrantOutSideRangeJust: r.data.ltigrantoutsiderangejust
			        ,LTIReceived: r.data.ltireceived
			        ,SalICPComments: r.data.salicpcomments
			        ,EquityComments: r.data.equitycomments
					,lastModifiedByID: App.requestParams.userID
					,lastModifiedOnBehalfOfID: r.data.managerid
				}
				,success: function(resp, opt){
					record.data.ismodified = 0;
					r.commit();
					// gs.reload();
					// myMask.hide();
				}
				,failure: function(resp, opt){
					// myMask.hide();
					// e.record.reject();
					Ext.Msg.alert('There was a problem saving your record. Please try again.')
				}
			}); // eo conn.request		
	}
	
	,handleBudgetDisplay: function(location){
		var preview = Ext.getCmp('preview');
		var budgetgrid = Ext.getCmp('budget-org');
        var right = Ext.getCmp('right-preview');
		var bwin = Ext.getCmp('budget-win');
		var items = Ext.menu.MenuMgr.get('budget-menu').items.items;
        var r = items[0], w = items[1], h = items[2];

		App.budgetLocation = location;

		switch (location){
			case 'panel':{
				if(bwin) bwin.hide();     
				preview.items.add(budgetgrid);		
				right.add(preview);
                right.show().expand();
                right.ownerCt.doLayout();			
				App.isBudgetInWin = false;		
			break;}
			case 'win':{
				
				if(App.isBudgetInWin){		
					App.comp.service.handleBudgetDisplay('panel');
				} else {
					right.hide();
					right.ownerCt.doLayout();
					if(!bwin){
						var bwin = new Ext.Window({
							 id: 'budget-win'
							,title: '&nbsp;'
							,width: 355
							,autoHeight: true
							,layout:'fit'
							,modal:false
							,border: false
							,closable: false
							,resizable: true
							,closeAction: 'hide'
							,items: budgetgrid
							});
					}
					bwin.show();
					App.isBudgetInWin = true;					
				}	
			break;}
			case 'hide':{
				preview.ownerCt.hide();
				if(bwin) bwin.hide();
                preview.ownerCt.ownerCt.doLayout();
				Ext.ux.Toast.msg(App.i18n.msgInfo, App.i18n.budgetHiddenHintText, '', '');
				App.isBudgetInWin = false;
			break;}				
		}
	}
	
	,budgetTools: [
		{
			 id:'refresh'
			,on:{
                click: function(){
					var budgetgrid = Ext.getCmp('budget-org');
                    	budgetgrid.store.reload();
				}
            }	
		}
		,{
			 id:'maximize'
			,handler: function(){
				App.comp.service.handleBudgetDisplay(App.budgetLocation == 'win' ? 'panel' : 'win');
			}
		}
		,{
	        id:'minimize',
	        handler: function(){
				App.isBudgetHidden = !App.isBudgetHidden;
				if(App.isBudgetHidden){
					var right = Ext.getCmp('right-preview');
					if(right) right.collapse();
				} else {
					App.comp.service.handleBudgetDisplay('panel');
				}
	        }
	    }
		,{
	        id:'close',
	        handler: function(e, target, panel){
	           App.comp.service.handleBudgetDisplay('hide');
	        }
	}]
	
	,reloadOpenBudgets: function(){
		// look for additional budgets displaying
		Ext.each(App.managerList, function(item, index) {
		  
			// look for additional budgets displaying
			var bg = Ext.getCmp('budget-' + item + '-org');
			if(bg){	
				bg.setTitle( App.i18n.budgetForText + ' ' + bg.managername);
				bg.store.load({
					params:{
						 managerid: bg.managerid
						,cycleid: bg.cycleid
						,getequity: 1 // TODO: connect to security
						,showholdback: 0
					}
				});
				
			}		  
		});		
	}
	
	,reloadBudget: function (managerid,managername,cycleid){
		// refresh the budget grid (main panel)
		var bg = Ext.getCmp('budget-org');	

		if(bg) {	
			if(!managerid) managerid = bg.managerid;
			if(!managername) managername = bg.managername;
			if(!cycleid) cycleid = bg.cycleid;
		
			if(bg){	
				bg.setTitle( App.i18n.budgetForText + ' ' + managername);
				bg.store.load({
					params:{
						 managerid: managerid
						,cycleid: cycleid
						,getequity: 1 // TODO: connect to security
						,showholdback: 0
					}
				});
				
			}
		}	
		// other open budgets
		App.comp.service.reloadOpenBudgets();
	}	
});     