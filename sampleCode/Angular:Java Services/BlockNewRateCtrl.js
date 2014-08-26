function BlockNewRateCtrl ($scope, $timeout, $location, BlockService, RoomNightService, i18nService, Page) {

	$scope.currDate = $scope.elm.date;
	$scope.tooltip = i18nService;

	$scope.saveNewRate = function() {

		if ($scope.blockDetailForm.$valid) {

			var saveObj = {
					housingBlockId: $scope.elm.housingBlockId,
		      		rate: $scope.blockDetailForm.defaultRate.$viewValue, 
		      		date: $scope.currDate, 
		      		inventory: $scope.blockDetailForm.defaultInventory.$viewValue, 
		      		originalInv: $scope.blockDetailForm.defaultOriginalInv.$viewValue
		    };

			RoomNightService.save(saveObj,
				function(response) {
					// refresh
					$location.path("/blocks/");
			});


		} else {
			showErrorMessage();
		}

	};

	function showErrorMessage() {
		var message = i18nAdapter.translate('accommodations.messages.roomNightInfoIncomplete');
		app.common.statusMessages.showError(message);
	}

}
