 
function SupplierCtrl( 
		$scope, $routeParams, $timeout, $location, $filter,
			SupplierService, LocationTypeService, i18nService, Page ) { 

	$scope.page = Page;
	$scope.recordsPerPage = 15;
	$scope.meta = new Meta($scope.recordsPerPage);
	$scope.loaded = false;
	$scope.radioModel = 'listView';
	$scope.locationTypes = [];
	$scope.showInactive = false;
	$scope.supplierTypeCheckModel = {};
	$scope.supplierTypeIdRadio = '';
    $scope.selectorMode = $routeParams.selectorMode;
    $scope.supplierFilter = new SupplierFilter(parseInt(Page.accountId), "", 1, $scope.meta.limit);
    $scope.dialogMode = Page.properties.dialog || false;
	$scope.viewName = $location.url().substring(1,9) === 'supplier' ? 'supplier' : 'hotel';

	var viewLabel = $scope.viewName  + 'Label';
	
	$scope.$watch('radioModel',function(){
		$scope.tableCssClasses = $scope.radioModel !== 'reportView' ? 'table table-hover tablesorter' : 'table-report';
	});

	$scope.i18n = i18nService;
	angular.extend($scope.i18n, {
		listTitleLabel: i18nAdapter.translate("accommodations." + $scope.viewName + ".plural"),
		nameLabel: i18nAdapter.translate("accommodations." + $scope.viewName + ".name"),
		importTooltip: i18nAdapter.translate("accommodations." + $scope.viewName + ".importSectionTitle"),
		detailTitleLabel: i18nAdapter.translate('common.actions.add.title.withName', {name: $scope.i18n[viewLabel] }),	
		addLabel: i18nAdapter.translate('common.actions.add.title.withName', {name: $scope.i18n[viewLabel] }),
		editLabel: i18nAdapter.translate('common.actions.edit.title.withName', {name: $scope.i18n[viewLabel] }),
		deleteLabel: i18nAdapter.translate('common.actions.delete.title.withName', {name: $scope.i18n[viewLabel] }),
		restoreLabel: i18nAdapter.translate('common.actions.restore.title.withName', {name: $scope.i18n[viewLabel] }),
		importLabel: i18nAdapter.translate('common.actions.import.title.withName', {name: $scope.i18n[viewLabel] })
	});

	$scope.loadSuppliers = function(supplierFilter){	
		SupplierService.get(supplierFilter, function(response) {
			$scope.suppliers = response.data;
			$scope.meta.limit = response.meta.limit;
			$scope.meta.pageCount = response.meta.pageCount;
			$scope.loaded = true;
		});
	};

	if($scope.viewName === 'hotel') {
		$scope.supplierFilter.locationTypeId = 1;
	} else {
		$scope.locationTypes = LocationTypeService.get();		
	}
	$scope.loadSuppliers($scope.supplierFilter);

	$scope.toggleActive = function() {
		$scope.loaded = false;
		if($scope.findSupplie && $scope.findSupplier.length !==0) {
			$scope.supplierFilter.term = $scope.findSupplier;			
		}		
		$scope.supplierFilter.active = !$scope.showInactive ? null : true;
		$scope.loadSuppliers($scope.supplierFilter);
	};


	$scope.supplierFilter.locationTypeList = [];

	$scope.filterByType = function(id) {
		$scope.loaded = false;
		$scope.supplierFilter.locationTypeList = _.union($scope.supplierFilter.locationTypeList,[id]);
        $scope.loadSuppliers($scope.supplierFilter);
	}

	$scope.searchSupplier = function(){
		$scope.loaded = false;
		$scope.supplierFilter.term = $scope.findSupplier;
		$scope.loadSuppliers($scope.supplierFilter);				
	};

	$scope.$watch('meta.page', function(){
		if($scope.loaded){
			$scope.loaded = false;
			$scope.supplierFilter.page = $scope.meta.page;
			$scope.loadSuppliers($scope.supplierFilter);	
		}
	});

	$scope.resetPerPageRecords = function() {
		$scope.supplierFilter.limit = $scope.recordsPerPage;
		$scope.loaded = false;
		$scope.loadSuppliers($scope.supplierFilter);	
	};

	$scope.listSection = "/assets/angular/views/supplier/list.html";
	//$scope.reportViewSection = "/assets/angular/views/supplier/supplier-report.html"; // reusing same as list for now...
	$scope.reportViewSection = "/assets/angular/views/supplier/list.html";

	$scope.addSupplier = function(regId){
		$location.path("/supplier/0");
	};

	$scope.editSupplier = function(index){
		var locationId = $scope.suppliers[index].id;
			$location.path("/supplier/" + locationId );
	};

    $scope.getEventVenue = function (locationId) {
        $location.path("/supplier/event_venue/" + locationId );
    }
	$scope.deleteSupplier = function(index) {
		var locationId = $scope.suppliers[index].id,
			confirmDelete = confirm(i18nAdapter.translate('accommodations.messages.deleteSupplierConfirmWarning'));

		if(confirmDelete){
		    SupplierService.remove({ id: locationId, accountId: Page.accountId }, function(response) {
 				$scope.suppliers[index].active = false;
		    });		
		}
	};

	$scope.restoreSupplier = function(index) {
		SupplierService.restore({ id: $scope.suppliers[index].id, path: 'restore' } , function(response) {
			$scope.suppliers[index].active = true; 
    	});
	};

	$scope.importSupplier = function() {
		$location.path("/import");
	};

	$scope.showRoomTypes = function() {
		$location.path("/roomtypes/supplier");
	};

	$scope.getRowClass = function(isActive) {
		return isActive ? '' : 'inactive-row';
	};
	$scope.getReportHeaderClass = function() {
		return $scope.viewName ==='reportView' ? 'report-view-tr' : '';
	};

    $scope.importSupplierLegacy = function () {
        popup('.././suppliers/index.cfm?varPage=import&PKsupID=0&popup=1&legacyCall=true','Supplier', 900, 650, 0, 0);
    };

    $scope.close = function () {
       if($scope.dialogMode) {
           $scope.dialogMode.close();
       }
    };

	// experimental
	// function addMenuLinks() {
	// 	var nav = jQuery("#sub-nav");
	// 		//nav.append('<li class="pipe">|</li>');
	// 		nav.append('<li id="supplier-link"><a href="#/hotel2">Hotel v1</a></li>');
	// }	

	// if(jQuery('#supplier-link').length === 0){
	// 	addMenuLinks();
	// }

}