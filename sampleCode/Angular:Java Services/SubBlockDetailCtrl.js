function SubBlockDetailCtrl($scope, $timeout, $modalInstance, $location, $routeParams, BlockService, SubBlockService, EventCurrencyService, StringFormatService, Page) {

	$scope.page = Page;
	$scope.isNew = Page.id === 0;
	$scope.blockOptions = [];
	//$scope.selectedItems = [];
	$scope.availableBlocks = [];
	$scope.loaded = false;
	$scope.reloadList = false;
	$scope.subBlockInfo = {
		subBlockLabel: ""
		// description: ""
	};

	function init() {

		// load currency
		EventCurrencyService.get({eventId: Page.eventId}, function(data){
			$scope.currencySymbol = data.currencyBean.symbol;
		});	
		
		BlockService.query({ eventId: Page.eventId, isActive: 1 }, function(response) {
			var blockData = response.housingBlockDTOList;

			angular.forEach(blockData, function(wnite, wkey){
				if (wnite.wrapperNights.length !== 0) {	
					$scope.availableBlocks.push(wnite);
					$scope.blockOptions.push({id: wnite.id, text: wnite.blockName });	
				}
			});	

			if (Page.id > 0) {

				SubBlockService.get({ id: Page.id, eventId: Page.eventId }, function(response) {
					var subBlockData = response.housingSubBlockDTO,
						selectedBlocks = [];

					$scope.subBlockInfo = {
						id: subBlockData.id,
						subBlockLabel: subBlockData.subBlockLabel
						//description: subBlockData.description
					};

					if(subBlockData.blockDTOs.length){	
						angular.forEach(subBlockData.blockDTOs, function(blk, key){
							angular.forEach($scope.availableBlocks, function(ablk, key){
								if(blk.id === ablk.id){
									// replace room nites with data extracted from the subBlockData
									$scope.availableBlocks[key].wrapperNights = blk.wrapperNights;
								}
							});
							
							var blockName = blk.hotelDTO.location.name + ' - ' + blk.roomTypeDTO.code;
							selectedBlocks.push({id: blk.id, text:  blockName});
						});
					}		
					$scope.subBlockInfo.selectedItems = selectedBlocks;
				});
			}
			$scope.loaded = true;
		});
	}

	$scope.blockSelectConfig = {
		multiple:true,
		placeholder: i18nAdapter.translate('accommodations.block.selectHint'),
		data: $scope.blockOptions
	};

	$scope.formatValue = StringFormatService.formatValue;

	$scope.saveSubBlock = function(saveAndNew){

		var tmpBlocks = [],
			message = "";

		if(!$scope.subBlockDetailForm.subBlockLabel.$valid) {
			message = i18nAdapter.translate('accommodations.subBlock.nameRequired');
		}

		if ($scope.subBlockInfo.selectedItems === null) {
			message = message + i18nAdapter.translate('accommodations.messages.oneBlockRequiredWarning'); 
		}

		if (message.length === 0) {

			$scope.reloadList = true;

			angular.forEach($scope.subBlockInfo.selectedItems, function(blk, key){
				angular.forEach($scope.availableBlocks, function(ablk, key){
					if(parseInt(blk.id) === parseInt(ablk.id)){
						tmpBlocks.push(ablk);
					}
				});
			});

			var subBlockToSave = {
				eventId : $scope.availableBlocks[0].eventId,
				blockDTOs : tmpBlocks,
				subBlockLabel : $scope.subBlockDetailForm.subBlockLabel.$viewValue
				//subBlockDescription: $scope.subBlockDetailForm.subBlockDescription
			}

			if(Page.id !== 0) {
				subBlockToSave.id = Page.id;
			}

			SubBlockService.save(subBlockToSave,
			function(response) {
				if(saveAndNew){

					$scope.SubblockInfo = response.housingSubBlockDTO;
					Page.id = 0;
					$scope.isNew = true;
					$scope.subBlockInfo = {
						subBlockLabel: ""
						// description: ""
					};
					$scope.reloadList = true;

				} else {								
					$location.path("/subblocks/");
				}

			});	

			
		} else {
				app.common.statusMessages.showError(message,Page);
		}

	};

	$scope.close = function() {
		Page.statusMessageContainerId = "";
		if($scope.reloadList) { $location.path("/subblocks/"); }
		$modalInstance.close();
	};


	init();

}