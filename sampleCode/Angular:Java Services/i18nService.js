'use strict';

app.services
	.service('i18nService', function() {
		return {
			selectOne: i18nAdapter.translate('accommodations.selectOne.label'),
			hotelLabel: i18nAdapter.translate("accommodations.hotel.label"), 
			supplierLabel: i18nAdapter.translate("accommodations.supplier.label"), 
			roomTypeLabel: i18nAdapter.translate("accommodations.roomType.label"), 
			blockLabel: i18nAdapter.translate("accommodations.block.label"), 
			subBlockLabel: i18nAdapter.translate("accommodations.subBlock.label"), 
			nightLabel: i18nAdapter.translate("accommodations.night.label"), 
			addInventory: i18nAdapter.translate('accommodations.addInventory.title'),
			validInventory: i18nAdapter.translate('accommodations.validInventory.title'),
			validContractedInventory: i18nAdapter.translate('accommodations.validContractedInventory.title'),
			validRate: i18nAdapter.translate('accommodations.validRate.title'),
			addInventoryNewRate: i18nAdapter.translate('accommodations.addInventoryNewRate.title'), 
			exportToExcel: i18nAdapter.translate("common.excel.export.title"),
			hideInactive: i18nAdapter.translate("common.actions.hideInactive.value.default"),
			showInactive: i18nAdapter.translate("common.actions.showInactive.value.default")
		};
});
