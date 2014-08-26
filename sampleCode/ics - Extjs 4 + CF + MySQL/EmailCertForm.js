/**
*
* EmailBaseForm.js
*
**/

Ext.define('App.product.EmailCertForm', {
	extend: 'App.product.EmailBaseForm',
	alias: 'widget.emailcertform',
	readOnlyView: false,
	colaRequest: [],
	clientId: this.clienId || App.requestParams.clientId,
	emailOptions: {
		showOptions: 'Product Info',
		html: '',
		title: '',
		clientId: ''
	},
	sectionsConfig: {
		topFieldsetTitle: App.i18n.requestedRegistrationDetailText,
		bottomFieldsetTitle: App.i18n.requestItemsText
	},

	initComponent: function() {

		var requiredTpl = '<span style="color:red;font-weight:bold" data-qtip="Required">*</span>';
		var me = this;

		me.requestData = me.setRequestedItemsData(me.colaRequest);

		me.requestGrid = Ext.create('Ext.grid.Panel', {
			store: me.setRequestStore(),
			itemId: 'requestForColaGrid',
			columns: me.getFixedColumns(),
			anchor: '100% 100%',
			viewConfig: {
				emptyText: '<div class="no-records-found-grid" style="padding: 20px; text-align:center;">' + App.i18n.msgNoRecordsFound + '</div>',
				deferEmptyText: false
			}
		});

		var config = {
			frame: true,
			border: false,
			api: {
				submit: reportService.sendClientInfoMessage
			},
			items: [
				{
					xtype: 'textfield',
					name: 'subject',
					fieldLabel: App.i18n.subjectText,
					allowBlank: me.readOnlyview ? true : false,
					readOnly: me.readOnlyView,
					anchor: '100%'
				},			
				me.emailHeaderInfo(),
				{
					xtype: 'fieldset',
					flex: 1,
					title: App.i18n.additionalMessageText + ' (800 Chrs. Max.)',
					layout: 'anchor',
					collapsible: true,
					defaults: {
						anchor: '100%',
						hideEmptyLabel: false,
						labelWidth: 100,
						hideLabel: true
					},
					items: [{
						xtype: 'textarea',
						name: 'additionalMessage',
						hideLabel: true,
						height: 90,
						emptyText: App.i18n.defaultAdditionalMessageText,
						value: App.i18n.defaultAdditionalMessageText,
						maxLength: 800
					}]
				}, {
					xtype: 'fieldset',
					title: me.sectionsConfig.bottomFieldsetTitle,
					anchor: '100% 40%',
					layout: 'fit',
					collapsible: true,
					collapsed: false,
					items: me.requestGrid // me.getBottomFielsetItems()
				}]
		};


		Ext.apply(this, config);
		this.callParent(arguments);

	},

	listeners: {
		afterrender: function() {
			this.loadData();
		}
	},

	sendEmail: function () {
		var me=this; 

		me.getForm().submit({
			params: {
				MessageBody: App.i18n.colaAttachmentsMessage,
				isColaOnly: true,
				requestData: Ext.encode(me.requestData)
			},
			submitEmptyText: false,
			waitMsg: App.i18n.sendingMessageText,
			success: function(form, action) {
				Ext.ux.Toast.msg(App.i18n.msgInfo, App.i18n.messageSentSuccessText, '', '');
				// reload the contact store if needed
				if (me.getValues().saveRecipient === 1) {
					Ext.StoreMgr.lookup('contactStore').reload();
				}
			},
			failure: function(form, action) {

				if (action.result) {

					me.closeParentWin();

					var msg = action.result && action.result.errormessage ? action.result.errormessage : 'Unknown Error. Please try again.'
					msg = App.i18n.msgGenericServerErrorText + ' ' + msg;
					Ext.Msg.show({
						title: App.i18n.msgWarning,
						msg: msg,
						buttons: Ext.Msg.OK,
						icon: Ext.Msg.WARNING
					});
				}
			}
		});
	},

	setRequestStore: function(config) {
		var me = this;

		return Ext.create('Ext.data.Store', {
			storeId:'colaEmailItemStore',
			fields: me.getFixedFields(),
			data: me.requestData,
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
			items: []
		};

		Ext.Object.each(regRequest.items, function(idx, itm) {

			var tmpItm = {
				id: itm.activecertid,
				brandname: itm.brandname,
				liquortype: itm.liquortype,
				certstatus: itm.certstatus,
				vintage: itm.vintage,
				productname: itm.productname,
				ttbnumber: itm.ttbnumber,
				serialno: itm.serialno,
				varietalclass: itm.varietalclass,
				clientname: itm.clientname,
				unitsize: itm.unitsize,
				certfilename: itm.certfilename
			};

			reqData.items.push(tmpItm);
		});

		return reqData;
	},

	getBottomFielsetItems: function () {
		var me=this;
		return me.requestGrid;
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
			dataIndex: 'certfilename',
			text: App.i18n.certfilenameText,
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