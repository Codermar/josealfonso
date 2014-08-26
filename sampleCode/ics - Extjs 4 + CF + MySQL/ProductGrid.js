/**
 * App.ProductGrid
 *
 */

Ext.define('App.ProductGrid', {
	extend: 'Ext.grid.Panel',
	alias: 'widget.productgrid',
	title: App.i18n.federalComplianceText,
	header: false,
	forceFit: false,
	loadMask: true,
	multiSelect: true,
	selModel: {
		pruneRemoved: false
	},
	pageSize: 100,

	emptyTextMessage: App.i18n.msgNoRecordsFound,
	columnViews: App.ics.Util.federalComplianceViews,

	initComponent: function() {

		var me = this;

		me.viewConfig = {
			emptyText: '<div class="no-records-found-grid">' + me.emptyTextMessage + '</div>',
			trackOver: false,
			deferEmptyText: false
		};

		App.colaRequest = App.colaRequest || [];

		var config = {
			columns: Ext.Array.insert(me.getFixedColumns(), 1, [App.ics.Util.getProductActionsColum()]),
			dockedItems: [
				me.getTopToolbar(),
				App.ics.Util.createReportsToolbar(), {
					xtype: 'toolbar',
					dock: 'bottom',
					itemId: 'paging-tb',
					items: [{
							xtype: 'pagingtoolbar',
							store: me.store,
							pageSize: me.store.pageSize,
							border: false,
							displayInfo: true,
							displayMsg: App.i18n.productsText + ' {0} - {1} of {2}',
							emptyMsg: App.i18n.noProductsToDisplayText
						}
						, '->', {
							xtype: 'button',
							text: App.i18n.previewColaText,
							itemId: 'previewColaBtn',
							tooltip: App.i18n.previewSelectedProductColaTooltipText,
							iconCls: 'icon-pdf',
							disabled: true,
							handler: function() {
								App.ics.Util.showColaPreview();
							}
						}, {
							xtype: 'button',
							text: App.i18n.emailColaText,
							itemId: 'emailColaBtn',
							tooltip: App.i18n.emailSelectedProductColaTooltipText,
							iconCls: 'icon-queue',
							disabled: true,
							handler: function() {
								App.ics.Util.getCOLAEmailWin(App.colaRequest);
							}
						}
					]
				}
			]

		}; // config

		// apply config
		Ext.apply(this, config);

		// finally call the superclasses implementation
		this.callParent();
	}, // eo initComponent


	listeners: {
		beforerender: function() {
			var me = this;
			if (!App.ics.Util.isAdminView() && !me.store.isLoading()) {
				me.store.loadPage(1);
			}
		},
// JGA Note: I removed this event because I am not sure what it is really supposed to be doing
//		select: function(cb, rec) {
//			var btns = this.query('#paging-tb button');
//			Ext.each(btns, function(btn, idx) {
//				if (cb.getCount()) {
//					btn.enable();
//				} else {
//					btn.disable();
//				}
//			});
//		},
        cellclick: function(g,r,c,e) {
            // prevent rowselect event on the checkbox column
            if(c === 2) {
                return false;
            }
        }
	},

	renderCheckSel: function(val, m, r, rowIndex, colIndex, store, gridView) {
		var prodId = r.get('activecertid');
		var getCheckedVal = function(prodId) {
			var isChecked = false;
			var itemQ = App.colaRequest;

			if (!itemQ || Ext.Object.isEmpty(itemQ)) {
				isChecked = false;
			} else {
				isChecked = itemQ.items[prodId] ? true : false;
			}
			return isChecked ? 'checked' : '';
		};

		if (!r.get('hidecola')) {

			return '<input type="checkbox" data-qtip="' + App.i18n.emailColaText + '" ' + getCheckedVal(prodId) + ' value="' + prodId + '" onClick="App.ics.Util.setColaRequestedItem(this,' + rowIndex + ',' + r.get('activecertid') + ');">';

		} else {
			return '';
		}
	},

	setView: function(btn, item) {

		var me = this,
			currviewmsg = App.i18n.productSummaryText,
			currView,
			views = me.columnViews,
			viewDef,
			filterString,
			productFCGridColumns = me.getFixedColumns();

		var setViewConfig = function(targetView) {
			var view = [],
				viewDef;

			var getViewDef = function(target) {
				var t = views[target];
				if (t.appendColumns) {
					t.columns = t.columns.concat(views.fixedCols);
				}
				return t;
			};

			viewDef = getViewDef(targetView);
			filterString = viewDef.filterString;

			Ext.each(App.ics.Util.productFCGridColumns, function(col, index) {
				var idx,
					skip;

				idx = Ext.Array.indexOf(viewDef.columns, col.dataIndex); //indexOf has bugs in IE8... use Ext Array                    
				skip = (col.xtype !== 'actioncolumn' && col.xtype !== 'rownumberer' && col.dataIndex !== '' && col.id !== 'checker' && idx === -1);

				if (!skip) {
					view.push(col);
				}
			});
			return view;
		};


		// this.cachedViewConfig will save the definition of the views so we don't keep recreating them.
		var cv = this.cachedViewConfig; // shortcut

		if (!cv[item.targetView]) {
			if (item.targetView === 'all') {
				cv[item.targetView] = App.ics.Util.productFCGridColumns;
			} else {
				cv[item.targetView] = setViewConfig(item.targetView);
			}
		}

		Ext.suspendLayouts();
		grid.reconfigure(grid.store, cv[item.targetView]);
		Ext.resumeLayouts(true);

		// additional status filtering
		if (filterString) {

			proxy = this.store.getProxy();

			proxy.extraParams['searchcriteria'] = filterString;

			var btns = this.query('toolbar button');
			btns[1].enable();

			me.showFilteredMsg(true,filterString);
			me.store.loadPage(1);

		}

	},

	showFilteredMsg: function(show, msg) {
		var msgDiv = Ext.get('fed-filter-msg-div');
		if (show) {
			msgDiv.update(App.i18n.filteredByText + ': ' + msg || '').show();
		} else {
			msgDiv.hide();
		}
	},

	getTopToolbar: function() {
		var me = this;

		return Ext.create('Ext.toolbar.Toolbar', {
			layout: {
				overflowHandler: 'Menu'
			},
			dock: 'top',
			cls: 'ics-prt-toolbar',
			border: false,
			enableOverflow: true,
			plugins: [{
				ptype: 'gridoutputtool',
				buttonsDisabled: false,
				showPreviewIcon: true,
				showExportIcon: true,
				showEmailIcon: true,
				previewText: false,
				previewToooltip: App.i18n.showInTabText,
				exportText: false,
				exportTooltip: App.i18n.excelExportTooltipText,
				emailText: false,
				emailTooltip: App.i18n.emailInformationTooltipText
			}],
			items: [{
					width: 275,
					//fieldLabel: App.i18n.productSearchText,
					//labelWidth: 90,
					xtype: 'searchfield',
					store: me.store,
					paramName: 'searchcriteria',
					emptyText: App.i18n.productSearchText + '...',
					onTrigger2Click: me.onSearchTrigger2Click
				}, {
					xtype: 'cycle',
					text: App.i18n.productdataViewsText,
					prependText: App.i18n.viewText,
					tooltip: {
						text: App.i18n.productDataTipText
					},
					showText: true,
					scope: me,
					changeHandler: me.setView,
					menu: {
						items: [{
							targetView: 'prodSummary',
							text: App.i18n.mhwProdSummaryText,
							checked: true,
							group: 'views',
							iconCls: 'prod-summary'
						}, {
							targetView: 'clientProductSummary',
							text: App.i18n.clientProductSummaryText,
							checked: false,
							group: 'views',
							iconCls: 'prod-summary'
						}, {
							targetView: 'complianceSummary',
							text: App.i18n.complianceFieldsText,
							checked: false,
							group: 'views',
							iconCls: 'fedcompl-summary'
						}, {
							targetView: 'approvedView',
							text: App.i18n.approvedText,
							checked: false,
							group: 'views',
							iconCls: 'rejected-view'
						}, {
							targetView: 'rejectedView',
							text: App.i18n.rejectedText,
							checked: false,
							group: 'views',
							iconCls: 'rejected-view'
						}, {
							targetView: 'pendingView',
							text: App.i18n.pendingText,
							checked: false,
							group: 'views',
							iconCls: 'under-review'
						}, {
							targetView: 'expiredView',
							text: App.i18n.expiredText,
							checked: false,
							group: 'views',
							iconCls: 'under-review'
						}, {
							targetView: 'underReview',
							text: App.i18n.underReviewText,
							checked: false,
							group: 'views',
							iconCls: 'under-review'
						}, {
							targetView: 'byImporter',
							text: App.i18n.byImporterText,
							checked: false,
							group: 'views',
							iconCls: 'rejected-view'
						}, {
							targetView: 'all',
							text: App.i18n.viewAllText,
							checked: false,
							group: 'views',
							iconCls: 'under-review'
						}]
					}
				}, '-', {
					text: App.i18n.clearProductFilterData,
					xtype: 'clearsearchbutton',
					itemId: 'clearSearchBtn',
					disabled: true,
					scope: me
				}, 
				'<div id="fed-filter-msg-div" class="red bold" style="display:none;"></div>',
				'->'

			]
		});
	},

	onSearchTrigger2Click: function() {
		var me = this,
			store = me.store,
			proxy = store.getProxy(),
			value = me.getValue();

        me.hasFiltersApplied = value.length > 0;

        if (value.length < 1) {
            me.onTrigger1Click();
			return;
		}

		proxy.extraParams['searchcriteria'] = value; // me.paramName
		proxy.extraParams['isMaster'] = 0; // search on all products
		proxy.extraParams['searchModeAll'] = App.currentUser.searchModeAll;

		me.store.loadPage(1);

		me.hasSearch = true;
		me.triggerEl.item(0).setDisplayed('block');
		var btn = Ext.ComponentQuery.query('.clearsearchbutton')[0];
		btn.enable();
	},

	getFixedColumns: function() {

		var me = this;

		return [{
				xtype: 'rownumberer',
				width: 28,
				locked: true
			},

			// App.ics.Util.getProductActionsColum() // TODO: why can't I do this here?...

			// { dataIndex: 'hidecola', width: 80, text: 'hidecola', groupable: false, hidden: false }
			{
				dataIndex: 'mbatfid',
				width: 30,
				locked: true,
				sortable: false,
				menuDisabled: true,
                hideable: false,
				resizable: false,
				renderer: me.renderCheckSel
			}, {
				dataIndex: 'brandname',
				text: App.i18n.brandNameText,
				width: 80,
				hidden: false,
				locked: true
			},
			// , renderer: App.Format.formatProduct // TODO: check... this wraps the group row... (having the selected grouped column with custom format caused this)
			{
				dataIndex: 'productname',
				text: App.i18n.productText,
				width: 200,
				renderer: App.Format.formatProduct,
				locked: true
			}, {
				dataIndex: 'productid',
				header: App.i18n.mhwIdText,
				width: 50,
				maxWidth: 50,
				sortable: true,
				menuDisabled: false,
				resizable: false,
				hidden: true,
				locked: true
			}, {
				dataIndex: 'activecertid',
				header: App.i18n.mhwMasterIdText,
				width: 50,
				maxWidth: 50,
				hidden: true,
				sortable: true,
				menuDisabled: false,
				resizable: false,
				locked: true
			}, {
				dataIndex: 'unitsize',
				width: 70,
				text: App.i18n.unitSizeText,
				groupable: false,
				hidden: true
			}, {
				dataIndex: 'vintage',
				width: 70,
				text: App.i18n.vintageText,
				renderer: App.Format.formatYearForLockedGrid
			}, {
				dataIndex: 'alcoholpercent',
				width: 70,
				text: App.i18n.alcoholPercentText,
				hidden: true
			}, {
				dataIndex: 'varietalclass',
				width: 70,
				text: App.i18n.varietalClassText,
				hidden: true
			}, {
				dataIndex: 'liquortype',
				align: 'left',
				width: 75,
				text: 'Type'
			}, {
				dataIndex: 'certstatus',
				align: 'left',
				width: 85,
				text: App.i18n.colaStatusText,
				renderer: App.Format.formatStatusColor,
				hidden: false
			}, {
				dataIndex: 'ttbnumber',
				width: 80,
				text: App.i18n.ttbNoText,
				groupable: false
			}, {
				dataIndex: 'serialno',
				width: 80,
				text: App.i18n.serialNoText
			}, {
				dataIndex: 'clientname',
				align: 'left',
				width: 120,
				text: App.i18n.clientnameText,
				hidden: false
			}, {
				dataIndex: 'clientsku',
				width: 60,
				text: App.i18n.clientSKUText,
				groupable: false,
				hidden: true
			}, {
				dataIndex: 'clientproductname',
				width: 90,
				text: App.i18n.clientProductNameText,
				groupable: false,
				hidden: true
			}, {
				dataIndex: 'submittaldate',
				width: 75,
				text: App.i18n.submittedText,
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: true,
				filter: true
			}, {
				dataIndex: 'estimatedapprovaldate',
				width: 75,
				text: App.i18n.estimatedApprovalText,
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: true
			}, {
				dataIndex: 'approvaldate',
				width: 75,
				text: App.i18n.approvedText,
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: false
			}, {
				dataIndex: 'expirationdate',
				width: 75,
				text: App.i18n.expiresText,
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: false
			}, {
				dataIndex: 'cancelleddate',
				width: 75,
				text: App.i18n.cancelledText,
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: true
			}, {
				dataIndex: 'receiveddate',
				width: 75,
				text: App.i18n.receivedText,
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: true
			}, {
				dataIndex: 'rejecteddate',
				width: 75,
				text: 'Rejected Date',
				renderer: Ext.util.Format.dateRenderer('m/d/Y'),
				hidden: true,
				filter: true
			}, {
				dataIndex: 'specialistname',
				width: 90,
				text: App.i18n.specialistNameText,
				hidden: true
			}, {
				dataIndex: 'underreviewnotes',
				width: 120,
				text: App.i18n.underReviewNotesText,
				hidden: true
			}, {
				dataIndex: 'certfilename',
				width: 80,
				text: App.i18n.certfilenameText,
				groupable: false,
				hidden: true
			}
		];
	}

});
