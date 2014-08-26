/**
 * ProductRegRequestForm.js
 */

Ext.define('App.product.ProductRegRequestForm', {
	extend: 'Ext.form.Panel',
	alias: 'widget.productregrequestform',
	readOnlyView: false,
	regRequest: {
		requestedStates: []
	},
	clientId: this.clientId || App.requestParams.clientId,
	emailOptions: {
		showOptions: 'Product Info',
		html: '',
		title: '',
		clientId: ''
	},

	initComponent: function() {

		var requiredTpl = '<span style="color:red;font-weight:bold" data-qtip="Required">*</span>';
		var me = this;

		me.clientId = App.requestParams.clientId;

		// set the data and dynamic columns
		// getStates sets up 
		//		me.columns
		//		me.currentConfigFields
		//		me.dynamicStates
		me.setRequestStoreOptions(me.regRequest);
		// prep the data
		me.requestData = me.setRequestedItemsData(me.regRequest);
		var requestForRegStore = me.setRequestStore({
			currentConfigFields: me.currentConfigFields,
			requestData: me.requestData
		});

		me.requestGrid = Ext.create('Ext.grid.Panel', {
			store: requestForRegStore,
			itemId: 'requestForRegGrid',
			columns: me.columns,
			viewConfig: {
				emptyText: '<div class="no-records-found-grid" style="padding: 20px; text-align:center;">' + App.i18n.msgNoRecordsFound + '</div>',
				deferEmptyText: false,

                scroll: true
			}
		});

		var config = {
			frame: true,
			border: false,
			api: {
				submit: registrationRequestService.sendRequestForRegistration
			},
			bodyPadding: '5 5 0',
			fieldDefaults: {
				msgTarget: 'side',
				labelWidth: 55
			},
			defaults: {
				anchor: '100%'
			},
			items: [{
				xtype: 'fieldset',
				title: App.i18n.requestedRegistrationDetailText,
				anchor: '100% 40%',
				collapsible: false,
				layout: 'anchor',
				items: [

					me.readOnlyView ? {
						xtype: 'displayfield',
						cls: 'x-ics-instructions',
						value: App.i18n.selectRequestFromGridText
					} : null, {
						xtype: 'textfield',
						name: 'requestSubjectLine',
						fieldLabel: App.i18n.subjectText,
						allowBlank: me.readOnlyview ? true : false,
						readOnly: me.readOnlyView,
						anchor: '100%'
					}, {
						xtype: 'textfield',
						name: 'requestorName',
						fieldLabel: App.i18n.myNameText,
						emptyText: App.i18n.myNameText,
						readOnly: me.readOnlyView,
						allowBlank: me.readOnlyview ? true : false,
						anchor: '100%'
					}, {
						xtype: 'fieldcontainer',
						combineErrors: true,
						layout: 'hbox',
						defaultType: 'checkbox',
						fieldLabel: App.i18n.myEmailText,
						defaults: {
							anchor: '100%',
							flex: 1
						},
						items: [{
							xtype: 'textfield',
							name: 'requestorEmail',
							emptyText: 'my@domain.com',
							readOnly: me.readOnlyView,
							allowBlank: me.readOnlyview ? true : false,
							vtype: 'email'
						}, {
							name: 'ccme',
							itemId: 'ccme',
							style: 'margin-left: 10px;',
							boxLabel: App.i18n.ccMeText,
							readOnly: me.readOnlyView,
							checked: true,
							inputValue: 1
						}]
					},
					me.additionalEmailInfo()
				]
			}, {
				xtype: 'fieldset',
				title: App.i18n.requestItemsText,
				anchor: '100% 60%',
				layout: 'fit',
				collapsible: false,
				collapsed: false,
				items: me.requestGrid
			}]
		};

		Ext.apply(this, config);
		this.callParent(arguments);

	},

	setRequestStoreOptions: function(regRequest) {
		var me = this;
		me.dynamicStates = [];
		me.currentConfigFields = [];
		me.columns = me.getFixedColumns();

		Ext.Object.each(regRequest.requestedStates, function(state) {
			me.dynamicStates.push({
				name: state,
				type: 'string'
			});
			me.columns.push({
				dataIndex: state,
				width: 70,
				text: state
			});
		});

		me.currentConfigFields = me.dynamicStates.concat(me.getFixedFields());
	},

	setRequestStore: function(config) {
		var me = this;

		return Ext.create('Ext.data.Store', {
			//storeId:'requestForRegStore',
			fields: config.currentConfigFields,
			data: config.requestData,
			proxy: {
				type: 'memory',
				reader: {
					type: 'json',
					root: 'items'
				}
			}
		});

	},

	setRequestedItemsData: function(regRequest) {

		var reqData = {
			items: [],
			requestedStates: regRequest.requestedStates
		};

		Ext.Object.each(regRequest.items, function(idx, itm) {

			var tmpItm = {
				id: itm.rec.activecertid,
				brandname: itm.rec.brandname,
				liquortype: itm.rec.liquortype,
				certstatus: itm.rec.certstatus,
				vintage: itm.rec.vintage,
				productname: itm.rec.productname,
				ttbnumber: itm.rec.ttbnumber,
				serialno: itm.rec.serialno,
				varietalclass: itm.rec.varietalclass,
				clientname: itm.rec.clientname,
				unitsize: itm.rec.unitsize,
				requestedStates: itm.requestedStates
			};

			Ext.Object.each(regRequest.requestedStates, function(state) {
				tmpItm[state] = Ext.Array.contains(itm.requestedStates, state) ? App.Format.formatStatusColor(App.i18n.requestedText) : '-';
				tmpItm.currentregstatus = itm.rec[state.toLowerCase() + 'registrationstatus'];
			});

			reqData.items.push(tmpItm);
		});

		return reqData;
	},

	listeners: {
		afterrender: function() {
			if (!this.readOnlyView) {
				this.loadData();
			}
		}
	},

	loadData: function() {
		var me = this,
			rpt = me.emailOptions,
			html = rpt.html,
			user = App.currentUser,
			form = me.getForm();

		var rec = Ext.create('App.RegRequestModel', {
			requestSubjectLine: '[ICS Requests] ' + rpt.title,
			requestorName: user.userFullName,
			requestorEmail: user.email,
			requestMessageByUser: App.i18n.defaultRequestForRegistrationMessageText
		});

		form.loadRecord(rec);
		form.activeRecord = rec;
	},


	getContactStore: function() {
		var me = this,
			rpt = me.emailOptions;

		var store = Ext.create('Ext.data.Store', {
			fields: ['contactName', 'contactEmail', 'displayName', 'companyName'],
			remoteSort: true,
			pageSize: 100,
			storeId: 'contactStore',
			proxy: {
				type: 'direct',
				directFn: reportService.getClientContacts, /// directFn is a quick reference
				extraParams: {
					clientid: me.clientId
				},
				reader: {
					type: 'cfquery',
					query: 'resultset',
					totalProperty: 'totalcount',
					successProperty: 'success',
					messageProperty: 'message'
				}
			}
		});
		return store;
	},

	additionalEmailInfo: function() {
		var me = this;
		var otherInfoOptions = {
			xtype: 'fieldset',
			flex: 1,
			title: App.i18n.requestForRegInstructionsTitleText,
			layout: 'anchor',
			border: 0,
			items: [{
				xtype: 'displayfield',
				cls: 'x-ics-instructions',
				value: App.i18n.requestForRegInstructionsText
			}]
		};

		return {
			xtype: 'container',
			layout: 'hbox',
			margin: '0 0 10',
			items: [{
					xtype: 'fieldset',
					flex: 1.3,
					title: App.i18n.additionalMessageText + ' (800 Chrs. Max.)',
					layout: 'anchor',
					border: 0,
					defaults: {
						hideEmptyLabel: false,
						labelWidth: 100,
						hideLabel: true
					},
					items: [{
						xtype: 'textarea',
						name: 'requestMessageByUser',
						readOnly: me.readOnlyView,
						hideLabel: true,
						height: 75,
						anchor: '100%',
						maxLength: 800
					}]
				}, {
					xtype: 'component',
					width: 5
				}, !me.readOnlyView ? otherInfoOptions : null,

			]
		};
	},

	processRequest: function() {

		var me = this,
			form = me.getForm(),
			v = form.getValues(),
			isValidated = false,
			validateMessage = App.i18n.yourFormIsIncompleteText,
			sendingMessageText = App.i18n.sendingMessageText,
			closeParentWin = function() {
				var win = me.up('window');
				if (win) {
					win.close()
				};
			};

		isValidated = form.isValid();

		if (isValidated) {

			// get the grid in html
			Ext.apply(Ext.ux.grid.GridPrinter, {
				openInWindow: false,
				stylesheetPath: 'resources/css/gridPrinter.css',
				mainTitle: App.i18n.requestedRegistrationsText,
				returnHtml: true,
				showHeader: false,
				includeCss: true
			});

			var requestGridHtml = Ext.ux.grid.GridPrinter.print(this.requestGrid);

			me.getForm().submit({
				params: {
					clientId: me.clientId,
					MessageBody: requestGridHtml,
					requestData: Ext.encode(me.requestData)
				},
				submitEmptyText: false,
				waitMsg: App.i18n.sendingMessageText,
				success: function(form, action) {

					// reload the underlying grid
					var grid = Ext.ComponentQuery.query('statecomplgrid')[0];
					grid.store.loadPage(1);
					grid.down('#requestForRegBtn').setDisabled(true);

					Ext.ux.Toast.msg(App.i18n.msgInfo, App.i18n.messageSentSuccessText, '', '');

					// reset the queue
					App.regRequest = {};
					App.hasNewRequest = true;

					closeParentWin();

				},
				failure: function(form, action) {

					if (action.result) {

						if (action.result.errortype && action.result.errortype === 'notAuthenticated') {
							//Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.authenticationErrorText, '', '');
						} else {

							var msg = action.result && action.result.errormessage ? action.result.errormessage : 'Unknown Error. Please try again.'
							msg = App.i18n.msgGenericServerErrorText + ' ' + msg;

							Ext.Msg.show({
								title: App.i18n.msgWarning,
								msg: msg,
								buttons: Ext.Msg.OK,
								icon: Ext.Msg.WARNING
							});

							closeParentWin();
						}

					}
				}
			});
		}
	},

	getFixedFields: function() {
		return [{
			name: 'id',
			type: 'int'
		}, {
			name: 'productname',
			type: 'string'
		}, {
			name: 'brandname',
			type: 'string'
		}, {
			name: 'liquortype',
			type: 'string'
		}, {
			name: 'varietalclass',
			type: 'string'
		}, {
			name: 'clientname',
			type: 'string'
		}, {
			name: 'certstatus',
			type: 'string'
		}, {
			name: 'unitsize',
			type: 'string'
		}, {
			name: 'certfilename',
			type: 'string'
		}, {
			name: 'ttbnumber',
			type: 'string'
		}, {
			name: 'serialno',
			type: 'string'
		}, {
			name: 'hidecola',
			type: 'boolean'
		}, {
			name: 'vintage',
			type: 'string'
		}, {
			name: 'alcoholpercent',
			type: 'string'
		}, {
			name: 'hidecorrectreq',
			type: 'boolean'
		}];
	},

	getFixedColumns: function() {
		return [{
			xtype: 'rownumberer',
			width: 30,
			menuDisabled: true,
			locked: true
		}, {
			dataIndex: 'brandname',
			text: App.i18n.brandNameText,
			width: 100,
			hidden: false,
			menuDisabled: true,
			locked: true
		}, {
			dataIndex: 'productname',
			text: App.i18n.itemDescriptionText,
			align: 'left',
			width: 200,
			locked: true,
			menuDisabled: true,
			renderer: App.Format.formatProduct
		}, {
			dataIndex: 'varietalclass',
			width: 70,
			menuDisabled: true,
			text: App.i18n.varietalClassText
		}, {
			dataIndex: 'liquortype',
			align: 'left',
			width: 75,
			menuDisabled: true,
			text: 'Type'
		}, {
			dataIndex: 'certstatus',
			text: App.i18n.colaStatusText,
			renderer: App.Format.formatStatusColor,
			menuDisabled: true,
			width: 85
		}, {
			dataIndex: 'vintage',
			width: 70,
			text: App.i18n.vintageText,
			menuDisabled: true,
			renderer: App.Format.formatYearForLockedGrid
		}, {
			dataIndex: 'ttbnumber',
			width: 80,
			menuDisabled: true,
			text: App.i18n.ttbNoText
		}, {
			dataIndex: 'serialno',
			width: 80,
			menuDisabled: true,
			text: App.i18n.serialNoText
		}, {
			dataIndex: 'currentregstatus',
			width: 100,
			menuDisabled: true,
			text: App.i18n.currentStateRegStatusText
		}, {
			dataIndex: 'clientname',
			width: 170,
			menuDisabled: true,
			text: App.i18n.clientNameText
		}, {
			dataIndex: 'id',
			header: App.i18n.mhwMasterIdText,
			width: 60,
			maxWidth: 90,
			sortable: true,
			menuDisabled: true
		}];
	}

});