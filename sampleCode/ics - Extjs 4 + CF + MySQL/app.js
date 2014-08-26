/**!
 *
 */

Ext.tip.QuickTipManager.init();

Ext.application({
	name: 'ICS',

	launch: function() {
        var me=this;

		Ext.app.REMOTING_API.enableBuffer = 100;
		Ext.direct.Manager.addProvider(Ext.app.REMOTING_API);

		Ext.create('Ext.container.Viewport', {
			layout: 'border',
			items: [{
				xtype: 'box',
				region: 'north',
				el: 'header-div',
				height: 62
			}, {
				xtype: 'icsnav',
				title: App.i18n.icsNavigationText,
				region: 'west',
				split: true, // enable resizing
				collapsible: true,
				margins: '0 0 3 3',
				width: 180,
				minSize: 100,
				maxSize: 250
			}, {
				xtype: 'icsmaintabpanel',
				region: 'center',
				margins: '0 3 3 0',
				itemId: 'icsMainTabPanel'
			}]
		});

		if (App.clients) {
            this.clientSearchCbo = new App.clients.ClientSearchCombo({
				renderTo: 'client-search',
				id: 'client-search-cbo',
                width: 225
			});
			new App.clients.ClientSearchMode({
				renderTo: 'client-filter-mode',
				id: 'client-search-filter-mode',
				width: 285
			});
		}

		var showWiki = function() {
			var src = 'https://sites.google.com/site/mhwltdics/user-guide/reporting-in-ics';
			App.ics.Util.showIcsWikiTab("https://sites.google.com/site/mhwltdics/user-guide/reporting-in-ics");
		};

		// ICS User Notification on screen
		// TODO: Make this so admins can manage it from the UI instead of hardcoded here...
		var e = Ext.Date.parseDate('07/10/2013', 'd/m/Y'),
			d = new Date(),
			tree = Ext.ComponentQuery.query('#support-tree')[0];

		if (!App.admin && !App.requestParams.isLocalhost) {
			
			if(e > d) {
				App.ui.currentNotify = App.i18n.newFeatureAnnounceText //App.i18n.newFeedbackOptionText; 

				// do the toast notify
				App.ics.Util.showNotification(App.ui.currentNotify, 3500);

				// add the notify to the Feedback/Support Tree
				tree.getRootNode().appendChild({
					text: App.i18n.NotificationText,
					id: 'notify-node',
					leaf: true,
					cls: 'folder',
					iconCls: 'icon-info'
				});
			}
		}

		// append the request for reg node
		tree.getRootNode().appendChild({
			text: App.i18n.requestedRegistrationsText,
			id: 'req-reg-node',
			leaf: true,
			cls: 'folder',
			iconCls: 'icon-docs'
		});
	}

});