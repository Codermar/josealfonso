function BlockDetailCtrl(
		$scope, $routeParams, $timeout, $modalInstance, $location, $filter,
		BlockService, RoomTypeService, HotelService, EventCurrencyService, RegCategoryService, 
		i18nService, Page ) {

	$scope.page = Page;
	$scope.isNew = Page.id === 0;
	$scope.showBlockHeader = false;
	$scope.reloadList = false;	
	$scope.havingTestRegBooking = false;
	$scope.i18n = i18nService;
	angular.extend($scope.i18n, {
		occupancy: i18nAdapter.translate('accommodations.occupancy.label')
	});


	function init(){

		// load currency
		EventCurrencyService.get({eventId: Page.eventId}, function(data){
			$scope.currencySymbol = data.currencyBean.symbol;
		});	
		
		$scope.notAllowedAttendeeTypeList = [];
		$scope.allowedAttendeeTypeList = [];
		$scope.regCategories = [];


		RegCategoryService.get({eventId: Page.eventId}, function(data){
			angular.forEach(data.idNameDTOList, function(itm, key){
				$scope.regCategories.push({id: itm.id, name: itm.name, drag: true });
			});
            $scope.allowedAttendeeTypeList = $scope.regCategories;
		});


		if (Page.id > 0) {

			$scope.hotelSelectConfig = { data: [] };
			$scope.roomTypeSelectConfig = { data: [] };

			BlockService.get({ id: Page.id, eventId: Page.eventId }, function(response) {

				$scope.blockInfo = response.housingBlockDTO;
				var attendeeTypeList = response.housingBlockDTO.attendeeTypes;

				if(attendeeTypeList.length > 0){

					angular.forEach(attendeeTypeList, function(itm, key){
						$scope.notAllowedAttendeeTypeList.push({id:itm.id,name:itm.name,drag:true});

						angular.forEach($scope.allowedAttendeeTypeList, function(obj, okey){
							if(itm.id === obj.id){
								$scope.allowedAttendeeTypeList.splice(okey, 1);
							}
						});	
						
					});

				}
				$scope.showBlockHeader = true;
			});	


		} else {

			$scope.allowedAttendeeTypeList = $scope.regCategories;

			HotelService.query({ accountId: Page.accountId, page: 1, limit: 1000 }, function(response) {
				$scope.hotels = response.hotelDTOList;
			});

			RoomTypeService.get({ accountId: Page.accountId, isActive: true }, function(response) {
				$scope.roomTypes = response.roomTypeDTOList;		
			});


			$scope.blockInfo = { 
				eventId: Page.eventId,
				active: true,
				showOnline: true
				
			};
		}

	}
	
	$scope.hotelSelectConfig = {
		multiple:false,
		placeholder: $scope.i18n.selectOne,
		data: function() {
			return { results: $scope.hotels };
		},
		formatResult: function(hotel) { return hotel.location.name + ' (' + angular.uppercase(hotel.location.code) + ') ' },
		formatSelection: function(hotel) { return hotel.location.name + ' (' + angular.uppercase(hotel.location.code) + ') ' }
	};	

	$scope.roomTypeSelectConfig = {
		multiple:false,
		placeholder: $scope.i18n.selectOne,
		data: function() {
			return { results: $scope.roomTypes };
		},
		formatResult: function(roomType) {return roomType.code + ' - ' + roomType.name  + ' [ ' + $scope.i18n.occupancy + ' ' + roomType.capacity + ']' },	
		formatSelection: function(roomType) {return roomType.code + ' - ' + roomType.name  + ' [ ' + $scope.i18n.occupancy + ' ' + roomType.capacity + ']' }	
	};

	var getValidationErrorString = function (field){
		var msg = "";
		switch (field){
			case "hotel": msg = i18nAdapter.translate('accommodations.hotel.label'); break;
			case "rate": msg = i18nAdapter.translate('accommodations.rate.numericRateValidation'); break;
			case "defaultOriginalInv": msg = i18nAdapter.translate('accommodations.contracted.label'); break;
			case "inventory": msg = i18nAdapter.translate('accommodations.roomInventory.label'); break;
			case "roomType": msg = i18nAdapter.translate('accommodations.roomType.label'); break;
			case "startDate": msg = i18nAdapter.translate('accommodations.startDate.label'); break;
			case "endDate": msg = i18nAdapter.translate('accommodations.endDate.label'); break;

			default: msg = field;
		}
		return msg;
	};

	var validateBlock = function (valObj){
		var message = "",
			valid = true;

		angular.forEach(valObj, function(valid, field){
			if(!valid){
				message = message + (message.length ? ', ' : ' ') + getValidationErrorString(field);
			}
		});

		if(message.length){	
			message = i18nAdapter.translate('accommodations.messages.checkFieldsWarningMessage') + message + '.';
			app.common.statusMessages.showError(message,Page);
			valid = false;
		}
		return valid;
	};


	$scope.saveBlock = function(saveAndNew) {

	    var form = $scope.blockDetailForm;
		var startDate = form.startDate.$modelValue || $scope.blockInfo.startDate,
			endDate = form.endDate.$modelValue || $scope.blockInfo.endDate;

			// need to reset the field values here
			form.startDate.$setViewValue(startDate);
			form.endDate.$setViewValue(endDate);
        	startDate =  $filter('date')($scope.blockInfo.startDate, 'MM/dd/yyyy');
			endDate =  $filter('date')($scope.blockInfo.endDate, 'MM/dd/yyyy');

		var isValid = validateBlock({
			inventory: form.defaultInventory.$valid,
			rate: form.defaultRate.$valid,
			defaultOriginalInv: form.defaultOriginalInv.$valid,
			hotel: form.hotel.$valid,
			roomType: form.roomType.$valid,
			startDate: form.startDate.$valid,
			endDate: form.endDate.$valid
		});

		if($scope.blockInfo.defaultRate<0 || $scope.blockInfo.defaultRate>9999){

			message = i18nAdapter.translate('accommodations.messages.roomRateValidationError');	

			app.common.statusMessages.showError(message,Page);
			isValid = false;
		}

		var saveBlock = function(deleteBookingByTestAttendees) {
				
			var blockToSave = {
				eventId: Page.eventId,
				hotelDTO: { id: $scope.blockInfo.hotelDTO.id },
				roomTypeDTO: { id: $scope.blockInfo.roomTypeDTO.id },
				startDate: startDate,
				endDate: endDate,
				defaultRate: $scope.blockInfo.defaultRate,
				defaultInventory: $scope.blockInfo.defaultInventory,
				showOnline: $scope.blockInfo.showOnline,
				defaultOriginalInv: $scope.blockInfo.defaultOriginalInv,
				overwriteUpdate: $scope.blockInfo.overwriteUpdate,
				smokeAvailable: $scope.blockInfo.smokeAvailable,
				active: $scope.blockInfo.active,
				attendeeTypes: [],
				deleteBookingByTestAttendees: deleteBookingByTestAttendees
			};

			angular.forEach($scope.notAllowedAttendeeTypeList, function(itm, key){
				blockToSave.attendeeTypes.push({id: itm.id });
			});

			if(!$scope.isNew) {
				blockToSave.id = $scope.blockInfo.id;
			}

			BlockService.save(blockToSave,
					function(response) {

						$scope.reloadList = true;
						
						if(saveAndNew){

							$scope.blockInfo = response.housingBlockDTO;
							Page.id = 0;
							$scope.isNew = true;
							$scope.blockInfo.id = 0;
							$scope.blockInfo.hotelDTO.id = "";
							$scope.blockInfo.roomTypeDTO.id = "";
							$scope.blockInfo.startDate = "";
							$scope.blockInfo.endDate = "";
							$scope.blockInfo.defaultRate = "";
							$scope.blockInfo.defaultOriginalInv = "";

						} else {
                            $modalInstance.close(true);
							//$location.path("/blocks/");
						}
					});
		
		};

		if (isValid) {
			saveBlock(false); // save without deleteBookingByTestAttendees
		}

	};

	function showErrorMessage() {
		var message = i18nAdapter.translate('accommodations.messages.blockFormIncomplete');	
		app.common.statusMessages.showError(message,Page);
	}

	$scope.close = function() {
		$modalInstance.close($scope.reloadList);
	};

	$scope.inventoryLabelClass = "requiredNot";
	
	 $scope.changeInventoryLabelClass = function(){
		 if($scope.blockInfo.overwriteUpdate){
			 $scope.inventoryLabelClass = "required";
		 }
		 else{
			 $scope.inventoryLabelClass = "requiredNot";
		 }
	};
	 
	$scope.integerval=/^\d*$/;
	
	init();
};
