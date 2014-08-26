/**
 * EmailBaseForm.js
 */

Ext.define('App.product.EmailBaseForm', {
	extend: 'Ext.form.Panel',
	alias: 'widget.emailbaseform',
	readOnlyView: false,
	regRequest: {
		requestedStates: []
	},
	clientId: this.clienId || App.requestParams.clientId,
	emailOptions: {
		showOptions: 'Product Info',
		html: '',
		title: '',
		clientId: ''
	},
	sectionsConfig: {
		topFieldsetTitle: 'Top Fieldset Title',
		bottomFieldsetTitle: 'Bottom Fielset Title'
	},

	initComponent: function() {

		var requiredTpl = '<span style="color:red;font-weight:bold" data-qtip="Required">*</span>';
		var me = this;

		me.clientId = App.requestParams.clientId;

		var config = {
			frame: true,
			border: false,
			bodyPadding: '5 5 0',
			fieldDefaults: {
				msgTarget: 'side',
				labelWidth: 55
			},
			defaults: {
				anchor: '100%'
			}
		};

		Ext.apply(this, config);
		this.callParent(arguments);

	},

	getReportFrame: function() {
		return this.down('#emailPreviewIFrame');
	},

	loadData: function() {
		var me = this,
			preview = me.getReportFrame(),
			rpt = me.emailOptions,
			html = rpt.html,
			doc = preview ? preview.getDocument() : null,
			user = App.currentUser,
			form = me.getForm();

		// put the first report	(EmailProdInfo only)
		if(preview) {		
			preview.update(html);

			me.addReport({
				name: rpt.reportName,
				body: Ext.clone(doc.body.innerHTML),
				included: rpt.reportName === 'None' || rpt.reportName === 'colaCert' ? false : true
			});

			if (rpt.reportName === 'colaCert') {
				me.down('#colaCert').setValue(true);
			}
		}	
		var msg = Ext.create('App.EmailReport', {
			subject: '[ICS Reporting] ' + rpt.title,
			userFullName: user.userFullName,
			userEmail: user.email
		});

		form.loadRecord(msg);
		form.activeRecord = msg;
	},

	getBottomFielsetItems: function() {
		var me = this;
		return {
			html: 'Placeholder.'
		};
	},

	getContactStore: function() {
		var me = this;

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

	onSendOptionChange: function(btn) {

		var me = this,
			ccme = me.down('#ccme'),
			rec = me.down('#recipientInfo'),
			jm = me.down('#justme');

		if (btn.name === 'justme') {

			if (btn.checked) {
				ccme.disable();
				rec.disable();
			} else {
				ccme.enable();
				rec.enable();
			}

		} else {

			if (btn.checked) {
				jm.disable();
			} else {
				jm.enable();
			}
		}
	},

	emailHeaderInfo: function() {

		var me = this;

		return {
			xtype: 'container',
			layout: 'hbox',
			anchor: '100%',
			items: [{
				xtype: 'fieldset',
				flex: 1,
				margin: '0 5 7 0',
				title: App.i18n.contactInfoText,
				defaultType: 'checkbox', // each item will be a checkbox
				layout: 'anchor',
				defaults: {
					anchor: '100%',
					hideEmptyLabel: false,
					labelWidth: 80
				},
				items: [{
					xtype: 'textfield',
					name: 'userFullName',
					fieldLabel: App.i18n.myNameText,
					emptyText: 'My Name',
					allowBlank: false
				}, {
					xtype: 'textfield',
					name: 'userEmail',
					fieldLabel: App.i18n.myEmailText,
					emptyText: 'my@domain.com',
					allowBlank: false,
					vtype: 'email'
				}, {
					xtype: 'fieldcontainer',
					combineErrors: true,
					layout: 'hbox',
					//margin: '0 0 10',
					defaultType: 'checkbox',
					hideLabel: true,
					defaults: {
						anchor: '100%',
						flex: 1,
						hideLabel: true
					},
					items: [{
						name: 'ccme',
						itemId: 'ccme',
						flex: 1,
						boxLabel: App.i18n.ccMeText,
						inputValue: 1,
						listeners: {
							change: me.onSendOptionChange,
							scope: me
						}
					}, {
						name: 'justme',
						itemId: 'justme',
						flex: 1,
						boxLabel: App.i18n.sendOnlyToMyselfText,
						inputValue: 1,
						listeners: {
							change: me.onSendOptionChange,
							scope: me
						}
					}]
				}]
			}, {
				xtype: 'fieldset',
				flex: 1,
				margin: '0 5 0 0',
				itemId: 'recipientInfo',
				title: App.i18n.recipientInfoText,
				layout: 'anchor',
				defaults: {
					anchor: '100%',
					hideEmptyLabel: false,
					labelWidth: 100
				},
				items: [{
					xtype: 'combobox',
					name: 'recipientEmail',
					fieldLabel: App.i18n.recipientsText,
					store: me.getContactStore(),
					itemId: 'recipientEmail',
					displayField: 'displayName',
					valueField: 'contactEmail',
					queryParam: 'searchCriteria',
					emptyText: App.i18n.searchContactsText + '...',
					typeAhead: false,
					hideTrigger: false,
					pageSize: 100,
					minChars: 2,
					listConfig: {
						loadingText: 'Searching...',
						emptyText: '<div class="no-client-found">No matching contacts found.</div>',

						// Custom rendering template for each item
						getInnerTpl: function() {
							return '<a class="search-item" href="#">' +
								'<div>{displayName}</div>' +
								'</a>';
						}
					}
				}, {
					xtype: 'fieldcontainer',
					fieldLabel: App.i18n.newRecipientEmailText,
					layout: 'hbox',
					combineErrors: true,
					defaultType: 'textfield',
					defaults: {
						hideLabel: 'true'
					},
					items: [{
						name: 'recipientNewName',
						flex: 2,
						emptyText: App.i18n.nameText,
						allowBlank: true
					}, {
						name: 'recipientNewEmail',
						flex: 3,
						margins: '0 0 0 6',
						emptyText: App.i18n.emailText,
						allowBlank: true,
						vtype: 'email'
					}]
				}, {
					xtype: 'checkbox',
					name: 'saveRecipient',
					hideLabel: true,
					boxLabel: App.i18n.saveRecipientEmailText,
					checked: false,
					inputValue: 1
				}]
			}]
		};
	},

	sendEmail: function () {
		// placeholder method. It does nothing in the base class
	},

	closeParentWin: function() {
		var me=this, 
			win = me.up('window');
		if (win) {
			win.close()
		};
	},

	processEmail: function() {

		var me = this,
			form = me.getForm(),
			v = form.getValues(),
			cb = me.down('#recipientEmail'),
			jm = me.down('#justme'),
			isValidated = false,
			validateMessage = App.i18n.yourFormIsIncompleteText,
			sendingMessageText = App.i18n.sendingMessageText;


		if (!me.hasDataSelected && me.xtype !== 'emailcertform') {

			Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.noDataSelectedText, '', '');
			isValidated = false;

		} else {

			if (Ext.isEmpty(cb.getValue()) && Ext.isEmpty(v.recipientNewEmail) && !jm.checked) {
				isValidated = false;
				validateMessage = App.i18n.recipientRequiredText;
			} else {
				isValidated = form.isValid();
			}
		}

		if (isValidated) {
			me.sendEmail();
		} else {
			Ext.ux.Toast.msg(App.i18n.msgWarning, validateMessage, '', '');
		}
	}
});