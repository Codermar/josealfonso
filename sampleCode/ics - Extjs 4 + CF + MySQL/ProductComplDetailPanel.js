/**
 * ProductComplDetailPanel.js
 */

Ext.define('App.ProductComplDetailPanel', {
	extend: 'Ext.Panel',
	alias: 'widget.productcompldetail',

	title: App.i18n.complianceInfoText,
	pricePostingStoreId: 'gridFCPricePostingStore',
	distribAssignStoreId: 'gridFCDistribAppointmentStore',
	stateSummaryStoreId: 'gridFCStateSummaryStore',
	showAllStatesButton: false,
	showSummaryPanel: true,
	activeProductId: 0,
	activeProductName: '',

	initComponent: function() {

		var me = this;

		this.items = [];

		if (this.showSummaryPanel) {

			this.dockedItems = this.buildDockedItems();

			this.items.push({
				xtype: 'productsummarypanel',
				collapsible: false,
				height: 80,
				record: {},
				autoScroll: true
			});
		}



		if (this.canViewPricePosting()) {
			this.items = Ext.Array.merge(this.items, this.getBaseItems(), this.getPricePostingPanel());
		} else {
			this.items = Ext.Array.merge(this.items, this.getBaseItems());
		}


		var config = {
			layout: 'vbox',
			defaults: {
				width: '100%',
				border: true,
				margins: '1 1',
				collapsible: true,
				split: true
			},
			items: this.items
		};


		Ext.apply(this, config);

		this.callParent();
	},

	updateDetail: function(rec) {
		var data = rec.data,
			me = this;

		me.activeRecord = rec;

		var detail = this.down('.productsummarypanel');
		detail.updateDetail(data);
		this.activeProductName = data.brandname + ' - ' + data.productname;

	},

	canViewPricePosting: function() {
		// TODO: This may need to be reviewed. Only lot 18 and admins can have access
		return App.requestParams.clientId === 'SD' || App.admin;
	},

	loadChildGrids: function(productId, showAll) {

		this.activeProductId = productId;

		// find and Refresh the grid stores  
		var grids = this.query('.grid');

		Ext.Array.each(grids, function(grid, idx) {
			var store = grid.store,
				proxy = store.getProxy(),
				filterMsg = 'Loading info for ' + this.productName + '...';

			proxy.extraParams['productid'] = productId;
			proxy.extraParams['showAll'] = showAll;
			store.load();

		});
	},

	getBaseItems: function() {

		var items = [{
			title: App.i18n.stateComplianceText,
			xtype: 'statecomplsummarygrid',
			itemId: 'gridStateComplSummary', // if we need to retrieve it within this component using mgr
			layout: 'fit',
			iconCls: 'icon-tab',
			store: new App.StateComplSummaryStore({
				storeId: this.stateSummaryStoreId,
				extraParams: {
					showAll: 0
				}
			}),
			remoteSort: true,
			pageSize: 100,
			flex: 1,
			plugins: [{
				ptype: 'gridoutputtool',
				insertPosition: 2,
				previewText: false,
				exportText: false,
				showEmailIcon: false,
				headerButtons: [{
					text: App.i18n.showAllStatesText,
					xtype: 'button',
					cls: 'x-ics-btn-transp',
					tooltip: App.i18n.showAllStatesTooltipText,
					enableToggle: true,
					pressed: false,
					disabled: true,
					toggleHandler: this.showAllStates,
					scope: this
				}]

			}]
		}, {
			title: App.i18n.distributorAppointmentText,
			xtype: 'distribappointgrid',
			itemId: 'gridDistribAppoint',
			groupField: 'complgroup',
			iconCls: 'icon-tab',
			dockedItems: !this.showAllStatesButton ? [] : dockedItemsForGrids(),
			remoteSort: true,
			pageSize: 100,
			flex: 1,
			plugins: [{
				ptype: 'gridoutputtool',
				insertPosition: 2,
				previewText: false,
				exportText: false,
				showEmailIcon: false
			}]
		}

		];
		return items;
	},

	getPricePostingPanel: function() {
		return {
			title: App.i18n.pricePostingText,
			xtype: 'pricepostinggrid',
			itemId: 'gridPricePosting',
			collapsed: false,
			store: new App.PricePostingStore({
				storeId: this.pricePostingStoreId,
				pageSize: 75
			}),
			flex: 1,
			iconCls: 'icon-tab',
			split: true,
			plugins: [{
				ptype: 'gridoutputtool',
				insertPosition: 2,
				previewText: false,
				exportText: false,
				showEmailIcon: false
			}]
		};
	},

	buildDockedItemsX: function() {
		return [{
			dock: 'top',
			xtype: 'toolbar',
			itemId: 'complInfoToolbar',
			buttonAlign: 'center',
			scope: this,
			items: [' ']
		}];
	},

	buildDockedItems: function() {
		var me = this;

		function canView() {
			var rec = me.activeRecord,
				status = rec.get('certstatus');
			return (status === 'Approved');
		}

		return [{
			dock: 'top',
			xtype: 'toolbar',
			itemId: 'complInfoToolbar',
			buttonAlign: 'center',
			scope: this,
			items: [{
				text: App.i18n.viewColaText,
				tooltip: App.i18n.viewDetailTooltipText,
				iconCls: 'icon-pdf',
				disabled: true,
				handler: function() {
					if (canView()) {
						App.ics.Util.showProductDetail(me.activeRecord);
					} else {
						Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.colaCertNotAvailableForViewing, '', '');
					}
				}
			}, {
				text: App.i18n.complianceSummaryAbbrevText,
				tooltip: App.i18n.complianceSummaryTooltipText,
				iconCls: 'icon-print',
				disabled: true,
				handler: function() {
					if (canView()) {
						App.ics.Util.showComplianceSummaryReport(me.activeRecord);
					} else {
						Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.colaStatusPendingNoSummaryText, '', '');
					}
				}
			}, {
				text: App.i18n.emailText,
				tooltip: App.i18n.emailProductInfoTooltipText,
				iconCls: 'icon-email',
				disabled: true,
				handler: function() {
					var rec = me.activeRecord;
					if (canView()) {
						var title = rec.get('brandname') + ' ' + rec.get('productname');
						App.ics.Util.openEmailReportDialog({
							record: rec,
							title: title,
							reportName: 'None',
							activeProductName: title,
							showOptions: 'ProductReportOptions',
							html: App.i18n.emailPreviewInitialText,
							clientId: !App.admin ? App.requestParams.clientId : '96'
						});
					} else {
						Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.colaStatusPendingNoEmailText, '', '');
					}
				}
			}

			]
		}];
	},

	showAllStates: function(btn, pressed) {

		this.loadChildGrids(this.activeProductId, pressed);

		btn.pressed = pressed;
		btn.setText(btn.pressed ? App.i18n.hideText : App.i18n.showAllStatesText);
		// btn.setToolt

	}

});