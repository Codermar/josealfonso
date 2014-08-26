/**
 * App.ProductFCPanel
 *
 */

Ext.define('App.ProductFCPanel', {
    extend: 'Ext.Panel',
    alias: 'widget.productfcpanel',
    frame: false,
    title: 'Federal Compliance',
    tooltip: 'Find Federal Compliance Information',
    iconCls: 'icon-tab-state',
    bodyCls: 'x-ics-body-bg',
    layout: 'border',

    initComponent: function() {

        // these 2 allow the reuse of productstatesummarypanel grid stores
        this.pricePostingStoreId = 'gridFCPricePostingStore';
        this.distribAssignStoreId = 'gridFCDistribAppointmentStore';
        this.stateSummaryStoreId = 'gridFCStateSummaryStore';

        this.items = [{
            xtype: 'productgrid',
            store: new App.ProductFCStore({
                storeId: 'gridProductFCStore',
                pageSize: 100
            }),
            columnViews: App.ics.Util.federalComplianceViews,
            itemId: 'gridProductFC',
            region: 'center',
            split: true,
            groupField: 'brandname',
            remoteSort: true,
            pageSize: 100
        }, {
            xtype: 'productcompldetail',
            itemId: 'detailPanel',
            complianceGridTitle: App.i18n.stateComplianceText,
            region: 'east',
            pricePostingStoreId: this.pricePostingStoreId,
            distribAssignStoreId: this.distribAssignStoreId,
            stateSummaryStoreId: this.stateSummaryStoreId,
            showAllStatesButton: false,
            showSummaryPanel: true,
            collapsible: true,
            split: true,
            border: false,
            width: 290

        }];

        // call the superclass's initComponent implementation
        this.callParent();
    },

    initEvents: function() {
        // call the superclass's initEvents implementation
        this.callParent();

        // now add application specific events
        // notice we use the selectionmodel's rowselect event rather
        // than a click event from the grid to provide key navigation
        // as well as mouse navigation
        var productGridSm = this.getComponent('gridProductFC').getSelectionModel();
        ('selectionchange', function(sm, rs) {
            if (rs.length) {
                var detailPanel = Ext.getCmp('product-summary-panel');
                productTpl.overwrite(detailPanel.body, rs[0].data);
            }
        });
        productGridSm.on('selectionchange', this.onRowSelect, this);
    },

    onRowSelect: function(sm, rs) {

        if (rs.length) {

            var dp = this.getComponent('detailPanel'),
                data = rs[0].data;

            // loadGrids	
            dp.loadChildGrids(data.activecertid);
            dp.updateDetail(rs[0]);
            //dp.record = rs[0];

            var btns = dp.query('button');
            Ext.each(btns, function(btn, index) {
                btn.enable();
            });
        }

    }

});