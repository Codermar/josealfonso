function BlockCtrl(
		$scope, $window, $q, $routeParams, $timeout, $location, $modal, $filter, 
		BlockService, RoomNightService, GroupingService, StringFormatService, EventCurrencyService, 
		i18nService, Page ) {

	$scope.page = Page;
	$scope.radioModel = 'blockName';
	$scope.dataRowEdit = [];
	$scope.isCollapsed = true;
	$scope.groups = [];
	$scope.showInactiveBlocks = false;
	$scope.hasInactiveBlocks = false;
	$scope.loaded = false;
	
	$scope.i18n = i18nService;
	angular.extend($scope.i18n, {

		blockAdd: i18nAdapter.translate('common.actions.add.title.withName', {name: $scope.i18n.blockLabel }),
		blockEdit: i18nAdapter.translate('common.actions.edit.title.withName', {name: $scope.i18n.blockLabel }),
		blockDelete: i18nAdapter.translate('common.actions.delete.title.withName', {name: $scope.i18n.blockLabel }),
		blockRestore: i18nAdapter.translate('common.actions.restore.title.withName', {name: $scope.i18n.blockLabel }),
		
		nightEdit: i18nAdapter.translate('common.actions.edit.title.withName', {name: $scope.i18n.nightLabel }),
		nightSave:i18nAdapter.translate('common.actions.save.title.withName', {name: $scope.i18n.nightLabel }),
		nightCancel: i18nAdapter.translate('common.actions.cancel.title.withName', {name: $scope.i18n.nightLabel }),
		nightDelete: i18nAdapter.translate('common.actions.delete.title.withName', {name: $scope.i18n.nightLabel }),
		nightRestore: i18nAdapter.translate('common.actions.restore.title.withName', {name: $scope.i18n.nightLabel })

	});

	// if coming from external link (reports legacy page) change the default target tab
	if($routeParams.targetTab) $scope.radioModel = $routeParams.targetTab;

	EventCurrencyService.get({eventId: Page.eventId}, function(data){
		$scope.currencySymbol = data.currencyBean.symbol;
	});	

	$scope.groupBy = function(attribute) {
		$scope.groups = GroupingService.groupBy(attribute, $scope.dataObj,$scope.showInactiveBlocks);
	};

	$scope.groupHotels = function(groupBy){

		BlockService.query({ eventId: Page.eventId, isActive: -1 }, function(response) {

			var convertedData = GroupingService.convertBlockData(response);
			$scope.dataObj = convertedData.nights;
			$scope.hasInactiveBlocks = convertedData.hasInactiveBlocks;
			$scope.groupBy(groupBy);
			var reportData = GroupingService.convertBlockDataForReport(response.housingBlockDTOList);
			$scope.hotelData = reportData.hotels;
			$scope.hasHotelData = _.keys($scope.hotelData).length; // Object.keys not working on ie 8
			$scope.dateReport = reportData.dateReport;
			$scope.hasDateReportData = _.keys($scope.dateReport).length; // Object.keys not working on ie 8

			$scope.loaded = true;
		});
	}

	// default grouping
	$scope.groupHotels('blockName');

	$scope.blockListSection = "/assets/angular/views/accommodation/block/list.html";
	$scope.reportViewSection = "/assets/angular/views/accommodation/block/util-report.html";
	$scope.reportViewSectionByDate = "/assets/angular/views/accommodation/block/util-report-by-date.html";
	$scope.reportViewByAttendee = "/assets/angular/views/accommodation/block/util-report-by-attendee.html";

	$scope.editBlock = function(index) {
		openBlockDialog($scope.groups[index].housingBlockId);
	};

	$scope.addBlock = function() {
		openBlockDialog(0);
	};

    // ui bootstrap modal
    var openBlockDialog = function (blockId) {
        Page.id = blockId;

        var modalInstance = $modal.open({
          templateUrl: '/assets/angular/views/accommodation/block/detail.html',
          controller: BlockDetailCtrl,
          size: 'lg',
          resolve: {
            items: function () {
              return Page.locationId;
            }
          }
        });

        modalInstance.result.then(function (reloadList) {
            if(reloadList) { $location.path("/blocks/"); }

        }, function () {
            // dismissed modal, refresh supplier list
        });

    };


	$scope.deleteBlock = function(index) {
		var confirmDelete = confirm(i18nAdapter.translate('accommodations.messages.deleteConfirmWarning'));
		if(confirmDelete){
		    BlockService.remove({ id:  $scope.groups[index].housingBlockId }, function(response) {
 				$scope.groups[index].blockIsActive = false;
 				$scope.groupHotels('blockName'); // only needed to keep consistency in display
		    });		
		}
	};

	$scope.restoreBlock = function(index){
		var inactiveHotelMessageTxt = i18nAdapter.translate('accommodations.messages.blockRestoreWarning');
		if(!$scope.groups[index].hotelIsActive){
			app.common.statusMessages.showError(inactiveHotelMessageTxt);
		} else {				
		    BlockService.restore({ id:  $scope.groups[index].housingBlockId, path: 'restore' }, function(response) {
				$scope.groups[index].blockIsActive = true;
				$scope.groupHotels('blockName'); // only needed to keep consistency in display
		    });	
		}
	};

	function showErrorMessage() {
		var message = i18nAdapter.translate('accommodations.messages.blockInfoIncompleteWarning');
		app.common.statusMessages.showError(message);
	}

	$scope.getViewRowSpan = function (nlen,skipCol) {
		if($scope.radioModel === 'date' || $scope.radioModel === 'roomTypeCode'){
			return 1;
		} else if( $scope.radioModel === 'hotelName' && skipCol) {
			return 1;
		} else {
			return nlen;
		}
	};

	$scope.getRowShowStatus = function (isFirstRow,skipCol) {
		if($scope.radioModel === 'date' || $scope.radioModel === 'roomTypeCode'){
			return true;
		} else if( $scope.radioModel === 'hotelName' && skipCol) {
			return true;
		} else {
			return isFirstRow;
		}
	};

	$scope.getObjCount = function (obj) {
		return _.keys(obj).length;
	};
	
	$scope.getHeaderDisplayVis = function (hotel) {
		if($scope.showInactiveBlocks) {
			return $scope.getObjCount(hotel.nites) > 0;
		} else {
			return hotel.activeNightLength > 0;
		}
	};

	$scope.getGroupVis = function (group) {
		if($scope.showInactiveBlocks) {
			return group.blockInactiveNites + group.blockActiveNites > 0;
		} else {
			return group.blockActiveNites > 0;
		}
	};
	
	$scope.getRowClass = function(isActive) {
		return isActive ? '' : 'inactive-row';
	};

	$scope.showDeleteOption = function (val,len){
		return (val === 0 || val === len-1) && $scope.radioModel === 'blockName';
	};

	$scope.getHeaderSpan = function(input) {
	   return input === 'blockName' ? 4 : 3;
	};

	$scope.getTooltipString = function(val,type) {
		return str = 'Total ' + type + ': ' + val;
	};

	// vars and method to aid in the rendering of block util table
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

	$scope.runReport = function (room,hotel) {
		// LEGACYREF: 
		var url = '.././report/report.cfm?spec_type=hotel&flgIsNewSearch=1&hot_id=' + hotel.id + '&hot_room_type_id=' + room.roomTypeId + '&fil_reg_is_registered=1&popup=1&hot_arrival_end=' +  $filter('date')(room.date, 'yyyy-M-dd') + '&hot_departure_start=' + $filter('date')(room.date, 'yyyy-M-dd');
		popup(url,'rptResults','940','580','false','false');
		return false;
	};
	
	$scope.url = '/svcs/accommodation/block/excelBlockReport.xls?eventId=' + Page.eventId;
	$scope.formatValue = StringFormatService.formatValue;
	$scope.parseFloatString = StringFormatService.parseFloatString;
	$scope.integerval=/^\d*$/;

	// experimental
	// function addMenuLinks() {
	// 	var nav = jQuery("#sub-nav");
	// 		nav.append('<li class="pipe">|</li>');
	// 		nav.append('<li><a href="#/testview">Test View</a></li>');
	// 		nav.append('<li><a href="#/subblocks">Test Subblock</a></li>');
	// }	

	//addMenuLinks();
	
};
