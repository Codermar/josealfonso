/**
 * HROrgGrid
 *
 * @author   Jose Alfonso
 * 
 */

HROrgGrid = Ext.extend(Ext.grid.EditorGridPanel, {
 	 id: 'org-grid'
	,stripeRows:true
	,frame: false
    ,border: true
    ,clicksToEdit:1
	,loadMask: true
	,pageSize: 25 // coordinate the page limit
	,margins:'3px 3px 3px 3px'

    ,initComponent: function() {
		
		App.comp.orgType = 1;
		this.rowEditMode = 1;
		App.comp.managerID = App.requestParams.managerID;		
		this.canSave = App.comp.orgType != 2 && App.comp.access.currentAccess == 'CompEdit';
		
		this.gridAccess = {
			 canViewEquity: App.comp.access.ltiaccess == 'LTIAccess' || App.comp.isHRG == true
			,canViewSalicp: true
		};
 
 		// letter access
		if(App.requestParams.isAdmin == 1) { this.LettersEnabled = true; }
		else {
	 		if(App.comp.isHRG){ this.LettersEnabled = App.comp.compAccess.HRGLETTERENABLED; }
	 		else { this.LettersEnabled = App.comp.compAccess.MANAGERLETTERENABLED; }			
		}

		this.actions = new Ext.ux.grid.RowActions({
				  id: 'btn-actions'
				 ,header: App.i18n.actionsText
				 // ,tooltip: 'Actions' 
				 ,locked: true
				 ,actions:[	
						 {iconCls: 'icon-org', hideIndex: 'hideorg'}
						,{iconCls: 'icon-edit-record', qtip: App.i18n.employeeDetailText}
				// ,{iconCls: 'icon-promo', qtip: App.i18n.employeePromoWizardText, hideIndex: 'hidesalaryinput' }
						// ,{iconCls: 'icon-rec-merit', qtip: App.i18n.applyMeritRecommendationText}
						// testing out of range dialog ,{iconCls: 'icon-range-dialog-test', qtip: 'Out of range dialog test...'}
				]
		});
			
				
		if(App.requestParams.isAdmin == 1){
			this.actions.actions.push(
				{ iconCls: 'icon-audit', qtip: App.i18n.runEmpCompAuditText }
			);
		}
		
		this.view = new Ext.grid.GridView({
		     forceFit: false
		    ,ignoreAdd: true
		    ,emptyText: '<div class="ng-home-status" style="padding: 20px; text-align:center;">' + App.i18n.msgNoRecordsFound + '</div>'
		});
		
		// configure the grid
		Ext.apply(this, { 
			
			// buttons	
			//submitMgrButtons: this.canSave == true ? [{id: 'savebtn', text: App.i18n.saveText, iconCls:'icon-save', scope:this, handler:this.onSave }]  : []		
			submitMgrButtons: [{id: 'savebtn', text: App.i18n.saveText, iconCls:'icon-save', scope:this, handler:this.onSave, disabled: !this.canSave }] 		

			
		}); // eo Apply config grid

		// install actions event handler
		this.actions.on({
			 action: {fn:this.onRowAction, scope:this}
//			,beforeaction:function() {
//				Ext.ux.Toast.msg('Event: beforeaction', 'You can cancel the action by returning false from this event handler.');
//			}	
//			,beforegroupaction:function() {
//				Ext.ux.Toast.msg('Event: beforegroupaction', 'You can cancel the action by returning false from this event handler.');
//			}
//			,groupaction:function(grid, records, action, groupId) {
//				Ext.ux.Toast.msg('Event: groupaction', 'Group: <b>{0}</b>, action: <b>{1}</b>, records: <b>{2}</b>', groupId, action, records.length);
//			}				
		});
		
		this.store = App.data.orgStore;
		this.store.baseParams = {
				 managerid: App.comp.managerID
				,cycleid: App.requestParams.cycleID
				,orgtype: App.comp.orgType
				,searchcriteria: ''
				,userid: App.requestParams.userID
				,start:0
				,limit: this.pageSize	
		};
		
		var assignMenu = function(){
			if(Ext.isEmpty(App.comp.hrgMenu)) return '';
			else return {
							text: App.i18n.hrgAssignmentsText
						   ,iconCls:'icon-people-red'
						   ,menu: { 
						   		items: App.comp.hrgMenu 
							   ,listeners: {
									render: {fn: function(mnu){ 							
										Ext.each(mnu.items.items, function(a, idx) {
											if(a.managerid){
												a.addListener('click', handleAssignment.createCallback(this));
											}
										});	
										
									}, scope:this}
									
								}
						   }
						   
					}
		};
		
		var toggleSaveBtn = function(mode){
			var savebtn = Ext.getCmp('savebtn');
			if(savebtn) { 
				if(mode) { savebtn.enable(); }
				else { savebtn.disable(); }
			}
				
		};
		
		var handleAssignment = function(itm){
			var gp = this.HROrgGrid.prototype;
			var tb = Ext.getCmp('bc-tb');
			tb.add({
				 text: itm.text + ' (' + itm.type + ')'
				,id: 'tb-' + itm.managerid
	            ,cls: 'hr-hrg-tb'
				,iconCls: 'icon-breadcrumb-hrg'
	            ,handler: gp.handleBreadcrumbLink.createCallback(itm.managerid,itm.text)
			});
			tb.doLayout();
			itm.disable();
			
			// reset access to selected manager
			App.comp.access.manageraccess = itm.manageraccess;
			App.comp.access.ltiaccess = itm.ltiaccess;
			App.comp.access.hrgaccess = itm.hrgaccess;
			App.comp.access.currentAccess = App.comp.browseMode == 'HRG' ? itm.hrgaccess : itm.manageraccess;
			App.comp.access.hrgOwnOrgNoAccess = (itm.manageraccess == 'CompNoAccess' || itm.ltiaccess == 'LTINoAccess') ; // has to be false if the supported manager has access...
	
			if(App.comp.access.manageraccess == 'CompEdit') { toggleSaveBtn(true); } else { toggleSaveBtn(false); } 
			
	//console.log(App.comp.access.currentAccess,App.comp.access,'itm',itm);	
			
			var orgType = 1;
			var store = App.data.orgStore;
			
			if(App.comp.managerID != itm.managerid){
				store.load({
					params:{
						 managerid: itm.managerid
						,cycleid: App.requestParams.cycleID
						,orgtype: orgType
						,searchcriteria: ''
						,userid: App.requestParams.userID
						,start:0
						,limit: this.pageSize
					}
				});
				App.comp.orgType = orgType;
				App.comp.managerID = itm.managerid;
				App.comp.browseMode = 'HRG';
			}
			
			// refresh the budget grid
			var bg = Ext.getCmp('budget-org');
			if (bg) {
				bg.managerid = itm.managerid;
				bg.managername = itm.text;
				bg.cycleid = App.requestParams.cycleID;
			}	
			App.comp.service.reloadBudget();
			
		}
		
		var orgToolbar = new Ext.Toolbar({
			 id: 'org-tb'
			,layout: 'vbox'
			,border: false
			,height: 59
			,layoutConfig: {
				align: 'stretch'
			}
			,items: [
				{
					 xtype: 'toolbar'
					,enableOverflow: true
					,border: false
					//,cls: 'no-border' // it does not make it the last item it seems... so it does not override!
					,items: [ 
					
						App.i18n.searchText + ':'
						,' '		
						,new Ext.ux.form.SearchField({
			                 store: this.store // App.data.empSearchStore
			                ,width:200
							,hasSearch: false
							,id: 'emp-search-field'
							,onTrigger1Click : function(){
	
								if(this.hasSearch) {
									var grid = Ext.getCmp('org-grid');
									this.el.dom.value = '';
						            var o = {start: 0, limit: 25};
						            this.store.baseParams = this.store.baseParams || {};
						            this.store.baseParams[this.paramName] = "";		
									this.store.baseParams.searchcriteria = "";
									// return the orgtype previously set
									this.store.baseParams.orgtype = grid.orgType;
						           // this.store.reload({params:o});
								    this.triggers[0].hide();
						            this.hasSearch = false;
						        }
						    }
			            })
										
						,'->'
						,{
							 text: App.i18n.peopleViewText
				            ,id: 'btn-people-view'
							,tooltip: App.i18n.peopleViewHintText
							,scale: 'small'
							,iconCls: 'icon-people'
						    ,scope:this
							,menu: [ // TODO: get assignments data
									 {text: App.i18n.directReportsText, id: 'V-DR', handler:this.handleOrgView, scope: this, iconCls:'icon-people-orange', disabled: true}
									,{text: App.i18n.totalReportsText, id: 'V-TR', handler:this.handleOrgView, scope:this, iconCls:'icon-people-green'}
									,{text: App.i18n.dottedLineReportsText, id: 'V-DL', handler:this.handleOrgView, scope:this, iconCls:'icon-people-gray'}
									,'-'
									,assignMenu()	
								]	
							
				        }
						,{
				             split:true
				            ,text: App.i18n.budgetPanelText
				            ,tooltip: {text: App.i18n.budgetPanelTipText}
				            ,iconCls: 'icon-grid'
				            ,handler: this.moveBudget.createDelegate(this, [])
				            ,menu:{
				                id:'budget-menu',
				                cls: 'budget-menu',
				                width:110,
				                items: [
								{
				                     text: App.i18n.rightPanelText
				                    ,checked:false
				                    ,group:'rp-group'
				                    ,handler: this.moveBudget
									,scope:this
				                    ,iconCls:'preview-right'
				                }
								,{
				                     text: App.i18n.inWindowText
				                    ,checked:false
				                    ,group:'rp-group'
				                    ,handler:this.moveBudget
									,scope:this
				                    ,iconCls:'preview-window'
				                }
								,{
				                     text: App.i18n.hideText
				                    ,checked:false
				                    ,group:'rp-group'
				                    ,handler:this.moveBudget
				                    ,scope:this
				                    ,iconCls:'preview-hide'
				                }
								
								]
				            }
					    }
						
// removed per Bill 11/17							
//						,{
//							text: App.i18n.applyRecommendationText	//,id: 'btn-comp-view'
//							//,tooltip: ''
//							,id: 'rec-menu'
//							,iconCls: 'icon-grid'
//							,scope: this	//,handler:this.toggleView
//							,menu: [
//								 {id: 'btn-apply-merit-rec', text: App.i18n.applyMeritRecommendationText, scope:this, handler:this.applyRecommendation}
//								,{id: 'btn-apply-lumpsum-rec', text: App.i18n.applyLumpsumRecommendationText, scope:this, handler:this.applyRecommendation}
//								,{id: 'btn-apply-icp-rec', text: App.i18n.applyICPRecommendationText, scope:this, handler:this.applyRecommendation}
//								,{id: 'btn-apply-lti-rec', text: App.i18n.applyLTIRecommendationText, scope:this, handler:this.applyRecommendation}
//								]
//						}
						,{
				             text: App.i18n.compensationViewsText // App.i18n.gridViewsText
							,iconCls: 'icon-grid'
						   	,scope:this
							,tooltip: {text: App.i18n.gridViewsTipText}
							//,handler:this.toggleView
							,menu: [ 
//									,'-'
									 {id: 'btn-comp-summary', text: App.i18n.compSummaryText, scope:this, checkHandler: this.toggleView, checked: true, group: 'views'}
									,'-'
									,{id: 'btn-salplanning-summary', text: App.i18n.salaryPlanningSummaryText, scope:this, checkHandler:this.toggleView, checked: false, group: 'views'} 
									,{id: 'btn-icp-summary',text: App.i18n.icpPlanningSummaryText, scope:this, checkHandler:this.toggleView, checked: false, group: 'views'}
									,{id: 'btn-lti-summary', text: App.i18n.ltiPlanningSummaryText, scope:this, checkHandler:this.toggleView, checked: false, group: 'views', disabled: !this.gridAccess.canViewEquity}
								]	 
								
				        }
						,{
				             text: App.i18n.compLettersText
				            ,id: 'btn-ltrs'
							,tooltip: this.LettersEnabled == true ? App.i18n.compLettersHintText : App.i18n.compLettersDisabledHintText
							,iconCls: 'icon-pdf'
						   	,scope:this
							,handler:this.printLetters
							,disabled: !this.LettersEnabled
				        }			
//						,{
//				             text: App.i18n.goalsAndDialogsText
//				            ,id: 'btn-goals'
//							//,tooltip: App.i18n.goalsAndDialogsTipText
//							,iconCls: 'icon-grid'
//						   	,scope:this
//							,handler:this.toggleView
//							//,menu: [ {id: 'btn-gd-summary', text: App.i18n.goalsAndDialogsText, scope:this, handler:this.toggleView}]	 
//				        }
//						,{
//				             text: App.i18n.talentAssessmentText
//				            ,id: 'btn-ta'
//							//,tooltip: App.i18n.talentAssessmentTipText
//							,iconCls: 'icon-grid'
//						   	,scope:this
//							,handler:this.toggleView
//				        }

//						,{
//							 text: App.i18n.allText
//							,id: 'btn-all'
//							,tooltip: App.i18n.showAllColumnsTipText
//							,iconCls: 'icon-expand-members'
//							,scope: this
//							,handler: this.toggleView
//						}	
									
					]
				}
				,{
					 xtype: 'toolbar'
					//,hidden: true
					,id: 'bc-tb'
					,items: [

						 {xtype: 'tbtext', text: App.i18n.mgrPathText + ': ', iconCls: 'icon-org'} 
						,{ 
							 text: App.requestParams.managerName
							,id: App.requestParams.managerID
							,iconCls: 'icon-breadcrumb-right'
							,scale: 'small'
							,handler: this.handleBreadcrumbLink.createCallback(App.requestParams.managerID,App.requestParams.managerName)
						}
					]
				}
			]
		});	// eo orgToolBar
		
		//this.sm = new Ext.grid.RowSelectionModel({ singleSelect: true });
		this.sm = new Ext.grid.CheckboxSelectionModel();
		if(this.LettersEnabled) { var fixedCols = [this.sm,this.actions]; }
		else { var fixedCols = [this.actions]; }
		this.vc = App.org.columns.getViewableColumns(this.gridAccess,fixedCols);
		 
		
		// new Ext.grid.ColumnModel new Ext.ux.grid.LockingColumnModel
		this.cm = new Ext.grid.ColumnModel({
            defaults: {
                 width: 80
                ,sortable: false
				,menuDisabled: true
            }
            ,columns: this.vc
//		    ,listeners: {
//		        hiddenchange: function(cm, colIndex, hidden) {
//		            //saveConfig(colIndex, hidden);
//		        }
//		    }
			,isCellEditable: function(colidx, row, c , d ) {
				
					// identify the instantiated store
	       			var grid = Ext.getCmp('org-grid'); 
					var dstore = grid.store;
					var record = dstore.getAt(row);
					var col = this.getColumnAt(colidx);
					var salarycols = ['meritperc','meritamt','newftsalary','lumpsumamt','lumpsumperc'];
					var lticols = ['ltimodifier','grantamt'];
					var icpcols = ['icpindivmodifiernew','icpamount'];
			
				// find and apply the access to this record
				App.getRecordAccess(record);

//console.log('browsemode',App.comp.browseMode,'App.comp.access',App.comp.access,'record.access',record.access);

				if(record.get('orgtype') == 2 || record.isDisabled ) { return false; } 
				else{
					
					/** 
					 * determine if cel is editable 
					 */
					if(salarycols.toString().search(col.dataIndex) != -1 && record.get('salaryeligible') == 0 || record.access.currentAccess != 'CompEdit') {return false;}
					if(lticols.toString().search(col.dataIndex) != -1 && (record.get('ltieligible') == 0  || record.access.currentAccess != 'CompEdit' || App.comp.access.hrgOwnOrgNoAccess ) ) {return false;}		
					if(icpcols.toString().search(col.dataIndex) != -1 && record.get('icpeligible') == 0 || record.access.currentAccess != 'CompEdit') {return false;}
					else return Ext.grid.ColumnModel.prototype.isCellEditable.call(this, colidx, row);				
					
				}
            }			
        })
		
		this.toggleSaveItems = function(orgType){
			/// removed the recommendation menu enable/disable because menu is not shown as 11/17
			// var recMenu = Ext.getCmp('rec-menu');
			var saveBtn = Ext.getCmp('savebtn');
			if(orgType == 2){ 
				if (saveBtn) { saveBtn.disable(); } 
			} else { 
				if (saveBtn) { saveBtn.enable();}
			}
		};
				
        // {{{
        // hard coded (cannot be changed from outside)
        var config = {
			
			// define the grid store
			 store: this.store			
			,cm: this.cm
			,sm: this.sm
			,plugins:[this.actions] 
			,loadMask: true
			,view: this.view
// 			LockingGridView may have an issue with RowActions
//			,view: new Ext.ux.grid.LockingGridView({
//                 forceFit:false
//                ,enableRowBody:true
//                ,ignoreAdd: true
//                ,emptyText: '<div class="ng-home-status" style="padding: 20px; text-align:center;">' + App.i18n.msgNoRecordsFound + '</div>'
//            })
			,tbar: orgToolbar
            ,bbar: new Ext.PagingToolbar({
                 pageSize: this.pageSize
                ,store: this.store
                ,displayInfo: true
                ,displayMsg: 'Displaying {0} - {1} of {2}'
                ,emptyMsg: App.i18n.msgNoRecordsToDisplay
                ,items:[
                    '-'
					,{
	                     text: App.i18n.forceFitColumnsText
	                    ,iconCls: 'icon-grid'
	                    ,id: 'fit-toggle'
						,scope: this
	                    ,handler:function() {
		                   	
							var btn = Ext.getCmp('fit-toggle');
							var grid = Ext.getCmp('org-grid');	
							var cm = grid.getColumnModel();
							
							grid.view.forceFit = !grid.view.forceFit;

							if(grid.view.forceFit){
								grid.view.fitColumns(false, false);
							} else{
								cm.suspendEvents();
								// set column widths to 
								Ext.each(cm.config, function(col, index) {
									
									if (btn.id != 'btn-all' && col.id != 'btn-actions' && col.id != 'checker') {
										if (!col.defaultWidth) { col.defaultWidth = col.width;}
										cm.setColumnWidth(index,col.defaultWidth,true);			
									}
								}); // eo each	
								
								cm.resumeEvents();
								grid.view.updateAllColumnWidths();
								grid.view.refresh(true);
							}
							
							btn.setText(!grid.view.forceFit ? App.i18n.forceFitColumnsText :  App.i18n.removeForceFitText);
							
					    }
		             }
					,'->' // spacer
				    ,this.submitMgrButtons
					,'-'
                ]
            })
        };
 
        // apply config
        Ext.apply(this, config);
        Ext.apply(this.initialConfig, config);
		
        // call parent
        HROrgGrid.superclass.initComponent.apply(this, arguments);
 
        // after parent code here, e.g. install event handlers
 
    } // eo function initComponent

	,setViewMsg: function(currviewmsg){
		// change the view status message
		if(!currviewmsg) currviewmsg = App.i18n.compSummaryText;
		var currview = Ext.get('current-view-msg');
		if (currview) {
			if(App.access.manageraccess && App.comp.access.manageraccess == 'CompReadOnly') currviewmsg = currviewmsg + ' (Read Only)';
			currview.dom.innerHTML = currviewmsg;
		}		
	}
    
	,onRender:function() {
 
        // before parent code
 
        // call parent
        HROrgGrid.superclass.onRender.apply(this, arguments);
 
        // after parent code, e.g. install event handlers on rendered components
		// this.getGridEl().mask(App.i18n.msgLoadingDataText);
		
		// change the view status message
		this.setViewMsg();
		
		this.store.load({
			params:{
				 managerid: App.comp.managerID
				,cycleid: App.requestParams.cycleID
				,orgtype: App.comp.orgType
				,searchcriteria: ''
				,userid: App.requestParams.userID
				,start:0
				,limit: this.pageSize	
			}
		});	

		
    } // eo function onRender

	,listeners: { 
        validateedit: function(obj){
			var isValidEntry = obj.originalValue != null || !Ext.isEmpty(obj.value);
			if(isValidEntry){
				if(obj.originalValue != obj.value){
					comp.validateInput({
						 record: obj.record
						,field: obj.field
						,newvalue: obj.value
						,returndialog: true
						,recordbak: this.recordbak 
					});
				}				
			}
		}
//		afteredit: {fn: function(e){   
//			this.afterCompEdit(e.record);         
//        }, buffer:10}
		,beforeedit: function(e){	
			this.recordbak = e.record.copy(); // clone the record
		}
        // ,sortchange: ...    
        /*,resize: function(){
            alert('resize..');
        }*/
    } //eo listeners
    
	,onSave: function(btn,b){

		var myMask = new Ext.LoadMask(Ext.getBody(), {msg: App.i18n.msgSavingText });
		var gs = this.store;
		var refreshBudget = false;

		for (var i = 0; i < gs.getCount(); i++) {
		  	var r = gs.getAt(i);
		  	
		  	if (r.data.ismodified == 1) {
				// gs.save(r); // this was not working with ExtDirect...
		  		// mark for the budget refresh
				refreshBudget = true;
				var managerid = r.data.managerid;
				var cycleid = r.data.cycleid;

				myMask.show();
				App.comp.service.saveCompInput(r);
				var hideMask = function () {
			        //Ext.get('org-grid').remove();
					myMask.hide();
			    }
				// need to wait a bit for the grid to render
			    hideMask.defer(400);	
		  	}
		} // eo for
		
		if(refreshBudget){
			
			// I am doing a delay because the budget request sometimes goes faster than the save
	        var autoDelay = new Ext.util.DelayedTask(function() {
	            // refresh the budget grid 
				App.comp.service.reloadBudget(r.data.managerid,r.data.managername,r.data.cycleid);     
	        });
	        autoDelay.delay(700);
			
		}
		
	}
	
	,onRowAction:function(grid, record, action) {
	
		switch (action){
			case 'icon-edit-record': {
				
				this.openEmpTab(record); // this would be the full tab version
				// grid.getEl().mask(App.i18n.msgLoadingDataText, "ext-el-mask-msg x-mask-loading");
				
				// this to open only a comp panel
				//this.openCompPanel(record);
			break;}
			case 'icon-org':{
				this.drillDownOrg(grid, record);
			break;} 
			case 'icon-promo':{
				var promowin = new App.PromoWin({
					 title: App.i18n.promotionJobChangeText + ' - ' + record.data.employeename
					,record: record
				}).show();
			break;}	
			case 'icon-audit':{		
				
				App.runExcelReport({
					 cycleID: App.requestParams.cycleID
					,employeeID: record.data.employeeid
					,orgType: 0
					,report: 'empCompAudit'
					,reportFormat: 'Excel'
				});
						
			break;}
			default: {
				Ext.ux.Toast.msg('Event: action', 'You have clicked row: <b>{0}</b>, action: <b>{1}</b>', '', action);
			break; }
		}

	} // eo function onRowAction

 	,drillDownOrg: function(grid, record){
	
		var tb = Ext.getCmp('bc-tb');
			tb.add({
				 text: record.data.employeename
				,id: record.data.employeeid
	            ,iconCls: 'icon-breadcrumb-right'
	            ,handler: this.handleBreadcrumbLink.createCallback(record.data.employeeid,record.data.employeename)
			});
			tb.doLayout();

		App.comp.orgType = 1;
		App.comp.managerID = record.data.employeeid;
		grid.toggleSaveItems(1);
		
		Ext.getCmp('V-DR').disable();
		Ext.getCmp('V-TR').enable();
		Ext.getCmp('V-DL').enable();
		
	 // console.log('drillDownOrg: ', App.comp.managerID, App.comp.orgType);
		
		// we should clear the search as well
		var searchfield = Ext.getCmp('emp-search-field');
			searchfield.setValue('');
			
		// refresh the grid
		grid.store.load({
			params:{
				 managerid: record.data.employeeid
				,cycleid: record.data.cycleid
				,orgtype: 1
				,searchcriteria: ''
				,userid: App.requestParams.userID
				,start:0
				,limit: this.pageSize	
			}
		});	
		
		// refresh the budget grid
		var bg = Ext.getCmp('budget-org');
		if (bg) {
			bg.managerid = record.data.employeeid;
			bg.managername = record.data.employeename;
			bg.cycleid = record.data.cycleid;
		}	
		App.comp.service.reloadBudget();
				
	}

	// TODO: Find how to setup the page limit globally for the full HROrgGrid class
	,handleBreadcrumbLink: function(id,name){
        var tb = Ext.getCmp('bc-tb');
		var pos = tb.items.length;
		var bg = Ext.getCmp('budget-org');	
			bg.managerid = id;
			bg.managername = name;
		
		Ext.getCmp('V-DR').disable();
		Ext.getCmp('V-TR').enable();
		Ext.getCmp('V-DL').enable();
		
		tb.items.each(function(item,index){
			if(item.id === id){
				pos = index;
			}
			// remove trailing breadcrumb items
			if(index > pos ){
				
				// checking first if items in the hrg menu were disabled (this if employee had hrg assignment)
				if(!Ext.isEmpty(App.comp.hrgMenu) && item.id.length){
					// we now need to re-enable the toolbar item if it exists
					if(item.id.length != 0){
						var mid = item.id.split('-')[1],
							hrgmenu = Ext.getCmp('hrg-' + mid);
						if(hrgmenu){ hrgmenu.enable(); }						
					}	
				}
				
				// and remove the toolbar item
				this.remove(item);
	            item.destroy();
			} 
	      }, tb.items);
		
		App.comp.managerID = id;
		App.comp.orgType = 1;
		
	 	// console.log('handleBreadcrumbLink: App.comp.managerID', App.comp.managerID,App.comp.orgType);
		
		// TODO: check this...
		if(App.comp.managerID == App.requestParams.userID){
			App.comp.browseMode = 'Manager';
			// reset access to selected manager
			App.comp.access.manageraccess = App.comp.baseAccess.manageraccess;
			App.comp.access.ltiaccess = App.comp.baseAccess.ltiaccess;
			App.comp.access.hrgOwnOrgNoAccess = App.comp.baseAccess.hrgOwnOrgNoAccess;
		}
		  
		var grid = Ext.getCmp('org-grid');
			grid.toggleSaveItems(1);
			// and reload the grid  
			grid.store.load({
				params:{
					 managerid: id
					,cycleid: App.requestParams.cycleID
					,orgtype: 1
					,searchcriteria: ''
					,userid: App.requestParams.userID
					,start:0
					,limit: this.pageSize
				}
			});	
	
		// refresh the budget grid
		//App.comp.service.reloadBudget(id,name,App.requestParams.cycleID);
		
		// refresh the budget grid
		var bg = Ext.getCmp('budget-org');	
		if (bg) {
			bg.setTitle(App.i18n.budgetForText + ' ' + name);
			bg.store.load({
				params: {
					 managerid: id
					,cycleid: App.requestParams.cycleID
					,getequity: 1 // TODO: connect to security
					,showholdback: 0
				}
			});
		}	
    }
	
	,handleOrgView: function(btn){
		
		var reloadStore = true;
		var orgType = 1;
		
		this.rowEditMode = 1;
		
		/**
		 * TODO: instead of attempting to load the DL option, we could instead
		 * have a variable indicating if the manager has any and base the
		 * search on that.
		 */
		
		switch (btn.id){
			case 'V-DR':{
				orgType = 1;		
			break;}
			case 'V-TR':{
				orgType = 0;
			break;}
			case 'V-DL':{
				orgType = 2;
				this.rowEditMode = 0;
			break;}
			default: {
				reloadStore = false;
				Ext.ux.Toast.msg('Event: action', 'Option under development...', '', '');
			break;}
		}
		this.toggleSaveItems(orgType);
		this.store.baseParams.orgtype = orgType;
	
		Ext.getCmp('V-DR').enable();
		Ext.getCmp('V-TR').enable();
		Ext.getCmp('V-DL').enable();
		btn.disable();
	
		// console.log('handleOrgView: App.comp.managerID',App.comp.managerID,App.comp.orgType,btn,reloadStore,orgType);
		
		if(reloadStore && App.comp.orgType != orgType){	
			
			this.store.baseParams = {
					 managerid: App.comp.managerID
					,cycleid: App.requestParams.cycleID
					,orgtype: orgType
					,searchcriteria: ''
					,userid: App.requestParams.userID
					,start:0
					,limit: this.pageSize	
			};
			
			this.store.load({
				params:{
					 managerid: App.comp.managerID
					,cycleid: App.requestParams.cycleID
					,orgtype: orgType
					,searchcriteria: ''
					,userid: App.requestParams.userID
					,start:0
					,limit: this.pageSize
				}
			});
		}
		App.comp.orgType = orgType;
				
	}
	
	,toggleView: function(btn, checked){
		/**
		 * TODO: Implement security view on LTI
		 * 
		 */
		
		if(checked){
			
			var currviewmsg = App.i18n.compSummaryText;
			var aColumns = [];
			var cm = this.getColumnModel();
			var targetView = btn.id;
			var views = {	
				 fixedcolumns:  ['employeename','careerband']
				,compSummary: 			["employeename", "careerband", "contribution", "potential", "ftsalary", "recmeritinc", "meritperc", "promotionpercent", "adjustmentperc", "newftsalary", "percentthrurangenew", "icprecommendedinc", "icpamount", "ltirecommendedvalue", "grantamt"] 
				,salPlanningSummary: 	["employeename", "careerband", "contribution", "ftsalary", "percentthrurangecurr", "recmeritinc", "meritamt", "meritperc","lumpsumrecommendedinc", "promotionamt", "promotionpercent", "promotioneffectivedate", "lumpsumamt", "lumpsumperc", "adjustmentamt", "adjustmentperc","adjusteffectivedate", "newftsalary", "percentthrurangenew"] 
				,icpPlanningSummary: 	["employeename", "careerband", "contribution", "icpsalary", 'icptargetperc','icptargetamt','icpindivmodifier', 'icpcompanymodifier', "icprecommendedinc", "icpindivmodifiernew", "icpamount", 'icppercentofsalary']
				,equityPlanningSummary:	["employeename", "careerband", 'potential', 'newftsalary', 'targetgrant','ltirecommendedvalue', 'ltimodifier','grantamt','unvestedsharesvalue','unvestedamountaspercentofbase','unvestedamountnewpercent','unvestedsharesvaluenew']
				,goalsAndDialogs: ['goalprogress', "contribution"]
				,ta: ['contribution', "potential"]
			}	
			
			// setup the arrays for the views
			switch(btn.id){	
				case 'btn-comp-summary':{
					aColumns = views.compSummary;
					currviewmsg = App.i18n.compSummaryText;
				break;}
				case 'btn-salplanning-summary':{
					aColumns = views.salPlanningSummary;
					currviewmsg = App.i18n.salaryPlanningSummaryText;
				break;}
				case 'btn-icp-summary':{
					aColumns = views.icpPlanningSummary;
					currviewmsg = App.i18n.icpPlanningSummaryText;
				break;}		
				case 'btn-lti-summary':{
					aColumns = views.equityPlanningSummary;
					currviewmsg = App.i18n.ltiPlanningSummaryText;
				break;}	
				case 'btn-goals':{
					aColumns = aColumns.concat(views.fixedcolumns);
					aColumns = aColumns.concat(views.goalsAndDialogs);
					currviewmsg = App.i18n.goalsAndDialogsText;
				break;}
				case 'btn-dialogs':{
					aColumns = aColumns.concat(views.fixedcolumns);
					aColumns = aColumns.concat(views.goalsAndDialogs);
					currviewmsg = App.i18n.goalsAndDialogsText;
				break;}
				case 'btn-ta':{
					aColumns = aColumns.concat(views.fixedcolumns);
					aColumns = aColumns.concat(views.ta);
				break;}
				default: {
					aColumns = aColumns.concat(views.fixedcolumns);
				}
			}	
		
			if(btn.id == 'btn-all'){
				// force fit set to false because it may display weird
				this.view.forceFit = false;
				var tbtn = Ext.getCmp('fit-toggle');
					tbtn.setText(!this.view.forceFit ? App.i18n.forceFitColumnsText :  App.i18n.removeForceFitText);
			}	
			
			// change the view status message
			this.setViewMsg(currviewmsg);

			cm.suspendEvents();
			var viewWidth = 0;
			// set column visibility
			Ext.each(cm.config, function(col, index) {
	
			  	var idx = aColumns.indexOf(col.dataIndex);	

				if (btn.id != 'btn-all' && col.id != 'btn-actions' && col.id != 'checker' && idx === -1) {
					cm.setHidden(index, true);			
				} else {
					cm.setHidden(index, false);
				}
				if (!col.defaultWidth) { col.defaultWidth = col.width;}
				cm.setColumnWidth(index,col.width,true);				
			}); // eo each	

			
			cm.resumeEvents();
			this.view.refresh(true);
		
			if(this.view.forceFit){
				this.view.fitColumns(false, false);
			} 
					
		}// eo checked
		
	}
	
	,printLetters: function(){
		
		var sm = this.getSelectionModel();
	    var s = this.store;	
		var win;
		var processLetters = function(btn,format){
			var empToProcess = [];
			if(!format) format = 'PDF Format';
			
			if(btn == 'yes'){

				sm.each(function(record) {
					if(record.data.ltieligible == 1 || record.data.icpeligible == 1 || record.data.salaryeligible == 1){
						empToProcess.push(record.data.employeeid);
					}
				});	
				
				App.letterViewerWindow({
					 cycleID: App.requestParams.cycleID
					,employeeIDList: empToProcess.toString()
					,report: 'compLetters'
					,format: format
				});
			}
		}		
			
		if (sm.hasSelection()) {
			
			if(App.requestParams.isAdmin == 1 || App.comp.letterWordGenerate == 1){
	
		        if(!win){
		            win = new Ext.Window({
		                 layout:'fit'
		                ,width:400
		                ,height:105
		               	,modal: true
					   	,plain: true
						,closable: false
						,html: App.i18n.confirmLetterGenerateText
						,bodyStyle: 'font-size: 120%; text-align: center; padding: 5px;'
		                ,buttons: [ 
							{
						         text: App.i18n.pdfFormatText
						        ,id: 'mgr-ltr-format'
								,enableToggle: true
								,width: 100
						        ,toggleHandler: function(item, pressed){
									if(pressed){ this.setText(App.i18n.pdfFormatText);} else {this.setText(App.i18n.wordFormatText); }
								}
						        ,pressed: true
						    }
							,{
			                     text: App.i18n.cancelText
			                    ,handler: function(){
			                        win.hide();
			                    }
			                }
							,{
					             text: App.i18n.generateLettersText
								,id: 'mgr-ltr-print'
								,iconCls: 'icon-print-add'
								,scope:this
								,disabled: false
								,handler: function(){
									win.hide();
									var formatbtn = Ext.getCmp('mgr-ltr-format');
									processLetters('yes',formatbtn.text);	
								}
							}
						]
		            });
		        }
		        win.show(this);	
					
			} else {
				// Show a dialog using config options:
				Ext.Msg.show({
				    title: App.i18n.compLettersText
				   ,msg: App.i18n.confirmLetterGenerateText
				   ,buttons: Ext.Msg.YESNO
				   ,fn: processLetters
				   ,animEl: 'elId'
				   ,icon: Ext.MessageBox.QUESTION
				});						
				
			}
		
		
		} else {
			Ext.ux.Toast.msg(App.i18n.msgInfo, App.i18n.makeAnEmployeeSelectionText, '', '');
		}		
		
	} // eo printLetters
	
// apply rec not implemented on 2011 because of the potential complexity. Perhaps this could be part of the "draft mode" in 2012
//	,applyRecommendation: function(btn){
//		var item = btn.id.split('-');
//		var sm = this.getSelectionModel();
//	    var s = this.store;
//	    
//		if(sm.hasSelection()){
//			
//			// TODO: multiple selections cause only the last one to execute
//			
//	        sm.each(function(record) {
//				switch(item[2]){
//					case 'merit':{ 
//						if(record.data.salaryeligible == 1 && Ext.isEmpty(record.data.meritperc)){
//							comp.validateInput({
//								 record: record
//								,field: 'meritrecpush' // field.name
//								,newvalue: record.data.recmeritincperc
//								,returndialog: true
//								,isRecPush: true
//								,showHint: false
//							});	
//						}	
//					break;}
//					case 'lumpsum':{
//						if (record.data.salaryeligible == 1 && Ext.isEmpty(record.data.lumpsumperc)) {
//							comp.validateInput({
//								 record: record
//								,field: 'lumpsumrecpush' // field.name
//								,newvalue: record.data.lumpsumrecommendedperc
//								,returndialog: true
//								,isRecPush: true
//								,showHint: false
//							});
//						}
//					break;}
//					case 'lti':{ 
//						if (record.data.ltieligible == 1 && Ext.isEmpty(record.data.ltimodifier)) {
//							comp.validateInput({
//								 record: record
//								,field: 'ltirecpush' // field.name
//								,newvalue: record.data.ltirecommendedperc
//								,returndialog: true
//								,isRecPush: true
//								,showHint: false
//							});
//						}
//					break;}
//					case 'icp':{
//						if (record.data.icpeligible == 1 && Ext.isEmpty(record.data.icpindivmodifiernew)) {
//							comp.validateInput({
//								 record: record
//								,field: 'icprecpush' // field.name
//								,newvalue: record.data.icprecommendedincperc
//								,returndialog: true
//								,isRecPush: true
//								,showHint: false
//							});
//						}
//					break;}
//				}
//							
//	        }, this);	  
//			
//			Ext.ux.Toast.msg(App.i18n.msgInfo, App.i18n.msgSaveReminderText + '\n' + App.i18n.recommendationOnlyOnBlankText , '', '');
//			
//	    } else {
//			Ext.ux.Toast.msg(App.i18n.msgInfo, App.i18n.makeAnEmployeeSelectionText, '', '');
//		}
//	}
 	
	,handleEmpTabActivate: function(tab){
		var bwin = Ext.getCmp('budget-win');
		if (bwin && App.isBudgetInWin) {
			bwin.hide();
			App.restoreBudgetWin = true;
		}	
	}
	
	,openCompPanel: function(record){
		
		/**
		 * Simplified tab containing only the comp Panel
		 */
		
		var tabs = Ext.getCmp("main-tabs");
		 	//tabs.getEl().mask(App.i18n.msgLoadingDataText, "ext-el-mask-msg x-mask-loading");
		
		if(App.budgetLocation == 'win'){
			App.comp.service.handleBudgetDisplay('panel');
			App.restoreBudgetWin = true;
		}		
		
		var tabid = 'Tab-' + record.data.employeeid;
		if (!tabs.findById(tabid)) {
			
			// make the new tab. 
			var newTab = tabs.add({
					 id: tabid
					,title: record.data.employeename
					,employeeid: record.data.employeeid
					,iconCls: 'tab-emp'
					,layout: 'anchor'
					,plain: true
					,baseCls: 'home-emp-tab' // needs to go with plain = true in order to take effect
					,border: false
					,margins:'5 0 0 3'
					,closable: true
					,empRecordBak: record.copy()
					,items: { 	
							 xtype: 'hrcomppanel'
							,employeeid: record.data.employeeid
							,cycleid: 0
							,emprecord: record
							,iconCls: 'tab-comp'
							,autoScroll: true 
							,closable: true
							,anchor:'100% 100%'
                            ,width: tabs.getWidth() - 15
                            ,height: tabs.getHeight() - 40 
					}
					,listeners: {
						 activate: this.handleEmpTabActivate
						,beforeclose: {fn: function(tab){ 	

							if(record.data.ismodified == 1){
								
								Ext.MessageBox.confirm(
					                App.i18n.areYouSureText,
					                App.i18n.confirmTabCloseText 
					                ,function(btn){
					                    if(btn == "yes"){
											
											// reset the data
											Ext.apply(record,tab.empRecordBak);
											record.commit();	
										   	tab.destroy();
					                    }else {
											return false;}
					                }
					            );
								return false; // stop processing
							}						
						}, scope:this}
					}	
					
			}).show();
			//tabs.getEl().unmask(true);
        } else {
            var newTab = tabs.findById(tabid);
			//tabs.getEl().unmask(true);
        }
        tabs.setActiveTab(tabid);	
		// Find and load the employee form
		var form = Ext.getCmp('F-' + record.data.employeeid);
			if (form) {
				form.getForm().loadRecord(record);
				form.boundRecord = record;
				var returndialog = true;
				// install listener for apply recommendation
				Ext.select('.push-rec').addListener('click', App.comp.service.applyRecValues.createDelegate([this,form,record,returndialog]));
			}
	}

	,openEmpTab: function(record){
		/**
		 * Opens a tab panel with a series of tabs. This version
		 * would include the G&D etc. The issue seems to be the building speed.
		 * For the 2011 first release, we will not need the G&D related tabs
		 * Also, with this configuration, the form seems to be created multiple times after you close the tab
		 */
		
		if(App.budgetLocation == 'win'){
			App.comp.service.handleBudgetDisplay('panel');
			App.restoreBudgetWin = true;
		}
		
		var tabs = Ext.getCmp("main-tabs");
		//	tabs.getEl().mask(App.i18n.msgLoadingDataText, "ext-el-mask-msg x-mask-loading");
		var tabid = 'Tab-' + record.data.employeeid;
		var employeeid = record.data.employeeid;

		if (!tabs.findById(tabid)) {

				var allTabs = App.tabConfig.getTabs('org-view',record);
				
				// make the new tab. 
				var newTab = tabs.add({
						 id: tabid
						,title: record.data.employeename
						,employeeid: record.data.employeeid
						,iconCls: 'tab-emp'
						,xtype: 'tabpanel'
						//,plugins: new Ext.ux.TabCloseMenu()
						,tabPosition: 'bottom'
						,activeTab: 2 //0 // 2
						,plain: true
						,baseCls: 'home-emp-tab' // needs to go with plain = true in order to take effect
						,border: false
						,margins:'5 0 0 3'
						,closable: true
						,defaults: {
							autoScroll: true
						}
						,items: allTabs // this would bring all the tabs	
				}).show(); 	
               	
			}
			tabs.getEl().unmask(true);
	        tabs.setActiveTab(tabid);
						
		// Find and load the employee form
		var form = Ext.getCmp('F-' + record.data.employeeid);
			if (form) {
				form.getForm().loadRecord(record);
				form.boundRecord = record;
				// install listener for apply recommendation
				Ext.select('.push-rec').addListener('click', App.comp.service.applyRecValues.createDelegate([this,form,record]));
			}	
		
	} //eo openEmpTab
	
 	,moveBudget: function(m, pressed){

		if(!m){ // cycle if not picked from a menu item click
		
			if(App.budgetLocation == 'panel') { App.budgetLocation = 'win';}
			else if(App.budgetLocation == 'win'){ App.budgetLocation = 'hide';}
			else if(App.budgetLocation == 'hide'){ App.budgetLocation = 'panel';}
        }
		
		if(pressed){

            switch(m.text){
                case 'In Right Panel': {
					App.budgetLocation = 'panel';
				break;}
                case 'Hide': {
					App.budgetLocation = 'hide';
				break;}
				case 'In Window':{
					App.budgetLocation = 'win';
				break;}
            }
        }	

		App.comp.service.handleBudgetDisplay(App.budgetLocation);
			
	}	

    // any other added/overrided methods
	

}); // eo extend
// register xtype
Ext.reg('hrorggrid', HROrgGrid);
