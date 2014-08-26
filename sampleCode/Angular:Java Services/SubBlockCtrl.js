function SubBlockCtrl($scope, $routeParams, $timeout, $location, $filter, $modal, 
			SubBlockService, GroupingService, EventCurrencyService, StringFormatService, 
			i18nService, Page) {

	$scope.page = Page;
	$scope.radioModel = 'subBlockLabel';
	$scope.dataRowEdit = [];
	$scope.isCollapsed = true;
	$scope.groups = [];
	$scope.showAllocated = false;
	$scope.i18n = i18nService;
	angular.extend($scope.i18n, {

		subBlockAdd: i18nAdapter.translate('common.actions.add.title.withName', {name: $scope.i18n.subBlockLabel }),
		subBlockEdit: i18nAdapter.translate('common.actions.edit.title.withName', {name: $scope.i18n.subBlockLabel }),
		subBlockDelete: i18nAdapter.translate('common.actions.delete.title.withName', {name: $scope.i18n.subBlockLabel }),
		subBlockRestore: i18nAdapter.translate('common.actions.restore.title.withName', {name: $scope.i18n.subBlockLabel }),
		hideAllocated: i18nAdapter.translate("common.actions.hideAllocated.value.default"),
		showAllocated: i18nAdapter.translate("common.actions.showAllocated.value.default")
	});

	// if coming from external link (reports legacy page) change the default target tab
	if($routeParams.targetTab) $scope.radioModel = $routeParams.targetTab;

	EventCurrencyService.get({eventId: Page.eventId}, function(data){
		$scope.currencySymbol = data.currencyBean.symbol;
	});

	$scope.showDeleteOption = function (val,len){
		return (val === 0 || val === len-1) && $scope.radioModel === 'subBlockLabel';
	};
		
	$scope.getHeaderSpan = function(input) {
		if(input === 'date') { return 5; }
		else if(input === 'roomTypeCode') { return 4;}
		else { return 4; }
	};

	$scope.groupBy = function(attribute) {
		$scope.groups = GroupingService.groupSubBlocksBy(attribute, $scope.dataObj);
	};

	$scope.loaded = false;
	
	SubBlockService.query({ eventId: Page.eventId }, function(response) {
		var nites = GroupingService.convertSubBlockData(response);
		
		$scope.dataObj = nites; 
		// default grouping
		$scope.groupBy('subBlockLabel');
		$scope.subblockData = GroupingService.convertSubBlockDataForReport(nites);
		$scope.hasSubblockData = _.keys($scope.subblockData).length;
		$scope.loaded = true;
	});

	$scope.subBlockListSection = "/assets/angular/views/accommodation/subblock/list.html";
	$scope.reportViewSection = "/assets/angular/views/accommodation/subblock/util-report.html";



    // ui bootstrap modal
    var openSubBlockDialog = function (subBlockId) {
        Page.id = subBlockId;

        var modalInstance = $modal.open({
          templateUrl: '/assets/angular/views/accommodation/subblock/detail.html',
          controller: SubBlockDetailCtrl,
          size: 'lg',
          resolve: {
            items: function () {
              return Page.id;
            }
          }
        });

        modalInstance.result.then(function (reloadList) {
            if(reloadList) { $location.path("/blocks/"); }

        }, function () {
            // dismissed modal, refresh supplier list
        });

    };

	$scope.editSubBlock = function(subBlockId) {
		openSubBlockDialog(subBlockId);
	};

	$scope.addSubBlock = function() {
		openSubBlockDialog(0);
	};

	$scope.deleteSubBlock = function(subBlockIndex) {
		var confirmDelete = confirm(i18nAdapter.translate('accommodations.messages.deleteConfirmWarningSubBlock'));
		if(confirmDelete){
		    SubBlockService.remove({ id:  $scope.groups[subBlockIndex].subBlockId }, function(response) {
 				$scope.groups.splice(subBlockIndex, 1);
		    });		
		}
	};

	$scope.showRow = function (val){
		if(!$scope.showAllocated) { return true; }
		else { return val > 0; }
	};

	$scope.getCount = function (obj) {
		return Object.keys(obj).length;
	};

	// vars and method to aid in the rendering of subblock util table
	// Note: This function can only be used once per row so if showCel needs 
	// to be used on multiple columns, first use the function and then use the showCel var saved on $scope
	$scope.currColValue = "";
	$scope.showCel = true;
	$scope.getShowFlag = function (index,count,colValue) {
		var showCel = false,
			isNew = false;

		if(colValue !== $scope.currColValue) { $scope.currColValue = colValue; isNew = true; }

		if(index === 0) { 
			showCel = true;
		} else {
			
			if(count === 1) { showCel = true; }
			else {
				showCel = isNew ? true : false;
			}	
		}

		$scope.showCel = showCel;
		return showCel;

	};

	$scope.runReport = function (nite) {
		var url = '.././report/report.cfm?spec_type=hotel&subBlockOnly=true&fil_reg_is_registered=1&popup=1&hot_arrival_end=' +  $filter('date')(nite.date, 'yyyy-M-dd') + '&hot_departure_start=' + $filter('date')(nite.date, 'yyyy-M-dd');
		popup(url,'rptResults','940','580','false','false');
		return false;
	};

	$scope.url = '/svcs/accommodation/subblock/excelSubBlockReport.xls?eventId=' + Page.eventId;

	$scope.formatValue = StringFormatService.formatValue;
	$scope.parseFloatString = StringFormatService.parseFloatString;

}
