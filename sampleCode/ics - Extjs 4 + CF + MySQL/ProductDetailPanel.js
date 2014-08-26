/**
 * ProductDetailPanel
 *
 * Creates a panel that combines compliance information and the COLA viewer
 * Intended to be opened in individual tabs
 *
 */

Ext.define('App.ProductDetailPanel', {
	extend: 'Ext.Panel',
	alias: 'widget.productdetailpanel',
	activeRecord: {},

	initComponent: function() {

		var me = this;

		var config = {
			layout: 'border',
			items: [this.createComplInfo(), this.createColaViewer()]
		};

		Ext.apply(this, config);

		this.callParent(arguments);
	},

	initEvents: function() {
		// call the superclass's initEvents implementation
		this.callParent();

	},

	listeners: {
		afterrender: function() {
			this.loadData();
		}
	},

	loadData: function() {
		var rec = this.activeRecord;

		// TODO: should probably check on the record here...
		this.productName = rec.get('brandname') + ' - ' + rec.get('productname');
		var productId = rec.get('activecertid');

		var productComplPanel = this.down('#productComplPanel');
		productComplPanel.setTitle(this.productName);

		var prodSummary = this.down('#productSummaryInfo');
		prodSummary.updateDetail(rec.data);
		prodSummary.setTitle(App.i18n.colaInfoText);

		this.loadColaCertDoc(rec);

		// load the related grids		
		productComplPanel.loadChildGrids(productId, false);
		productComplPanel.activeProductName = this.productName;

	},


	loadColaCertDoc: function(rec) {

		var activeColaFileName = rec.get('certfilename').split('.')[0];
		var viewerIFrame = this.viewerIFrame;

		if (rec.get('certstatus') === 'Pending' || Ext.isEmpty(activeColaFileName)) {
			Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.colaStatusPendingText, '', '');
		} else {
			// this will make a call to the google service to get the file info    
			googleDriveService.getPDFFileInfo(activeColaFileName, function(resp, e) {
				if (resp.success) {
					if (resp.data.found === 0) {
						Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.colaFileNotFoundText, '', '');
					} else {
						viewerIFrame.setSrc(resp.data.url);
					}
				} else {
					Ext.ux.Toast.msg(App.i18n.msgWarning, App.i18n.errorRetrievingCOLA, '', '');
				}
			});
		}

	},

	createComplInfo: function() {

		var me = this;

		this.west = Ext.create('widget.productcompldetail', {
			region: 'west',
			//title: false
			itemId: 'productComplPanel',
			margins: '0 3',
			collapsible: true,
			showSummaryPanel: false,
			collapsed: true,
			split: true, // enable resizing
			flex: 2,
			listeners: {
				expand: function(panel, fn) {

					var prodSummary = me.down('#productSummaryInfo');
					prodSummary.setTitle(App.i18n.colaInfoText);
					this.setTitle(me.productName);
				},
				collapse: function(panel, fn) {
					var prodSummary = me.down('#productSummaryInfo');
					prodSummary.setTitle(App.i18n.colaInfoText + ': ' + me.productName);
					this.setTitle(App.i18n.complianceInfoText);
				}
			}
		});
		return this.west;
	},

	createColaViewer: function() {

		this.viewerIFrame = Ext.create('Ext.ux.SimpleIFrame', {
			border: true,
			src: 'about:blank',
			anchor: '100% 90%',
			flex: 9
		});

		this.colaViewer = Ext.create('Ext.panel.Panel', {
		region: 'center',
		//title: App.i18n.colaInfoText
		border: false,
		flex: 3,
		layout: 'anchor',
		anchor: '100% 100%',
		items: [{
				xtype: 'productsummarypanel',
				itemId: 'productSummaryInfo',
				title: App.i18n.colaInfoText,
				border: true,
				collapsible: false,
				padding: '1 0',
				flex: 1,
				plugins: [{
					ptype: 'headericons',
					insertPosition: 2,
					headerButtons: [{
						tooltip: App.i18n.emailTooltip,
						text: App.i18n.emailText,
						xtype: 'button',
						targetAction: 'email-report',
						iconCls: 'icon-email',
						cls: 'x-ics-btn-transp',
						scope: this,
						handler: function() {

							App.ics.Util.openEmailReportDialog({
								record: this.activeRecord,
								title: this.productName,
								reportName: 'colaCert',
								activeProductName: this.productName,
								showOptions: 'ProductReportOptions',
								html: App.i18n.emailPreviewInitialText,
								clientId: !App.admin ? App.requestParams.clientId : '96'
							});
						}
					}]
				}],
				tplMarkup: [
					'<div class="ics-prod-summary">',
					'{varietalclass} by: {brandname} - {clientname}<br/>',
					'COLA: {certstatus} - Serial No: {serialno} TTB No: {ttbnumber}</div>']
			},
			this.viewerIFrame]
		});
		return this.colaViewer;
	}
});