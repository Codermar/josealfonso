function ReportCtrl($scope, $timeout, $location, $routeParams, BlockService, GroupingService, StringFormatService, Page) {
	Page.statusMessageContainerId = "modal-status-message-container";
	$scope.page = Page;

	BlockService.query({ eventId: Page.eventId, isActive: 1 }, function(response) {
		
		    $scope.blocksDTOList = response.housingBlockDTOList;
    		$scope.hotelData = GroupingService.convertBlockDataForReport($scope.blocksDTOList);
	});

	$scope.exportToExcel = function () {

	};

	
	$scope.formatValue = StringFormatService.formatValue;

}