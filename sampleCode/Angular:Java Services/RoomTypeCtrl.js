function RoomTypeCtrl($scope, $timeout, modalDialog, $routeParams, $location, RoomTypeService, i18nService, Page) {
  $scope.page = Page;
  $scope.roomTypeRowEdit = [];
  $scope.loaded = false;
  $scope.showInactiveRoomTypes = false;
  $scope.inactiveRoomTypes = 0;
  $scope.i18n = i18nService;
  angular.extend($scope.i18n, {
    roomTypeAdd: i18nAdapter.translate('common.actions.add.title.withName', {name: $scope.i18n.roomTypeLabel }),
    roomTypeSave: i18nAdapter.translate('common.actions.save.title.withName', {name: $scope.i18n.roomTypeLabel }),
    roomTypeEdit: i18nAdapter.translate('common.actions.edit.title.withName', {name: $scope.i18n.roomTypeLabel }),
    roomTypeCancel: i18nAdapter.translate('common.actions.cancel.title.withName', {name: $scope.i18n.roomTypeLabel }),
    roomTypeDelete: i18nAdapter.translate('common.actions.delete.title.withName', {name: $scope.i18n.roomTypeLabel }),
    roomTypeRestore: i18nAdapter.translate('common.actions.restore.title.withName', {name: $scope.i18n.roomTypeLabel })
  });

  RoomTypeService.query({ accountId: Page.accountId }, function(response) {
    var keepGoing = true;
    $scope.roomTypes = response.roomTypeDTOList;
    angular.forEach($scope.roomTypes, function(item, idx){
        if(!item.active ){
          $scope.inactiveRoomTypes++;
        }
    });
    $scope.roomTypes.push(getBlankRoomTypeRecord());
    $scope.loaded = true;
  });
  
  $scope.showSupplierTab = $routeParams.targetTab === 'supplier';

  $scope.getSupplierListView = function() {
    $location.path("/supplier");
  };


  $scope.editRoomType = function(index) {
    $scope.roomTypeRowEdit[index] = true;
  };

  var setItemActiveProperty = function (matchId,mode) {
      var arr = $scope.roomTypes;
      for(var idx in arr) {
        if(arr[idx].id === matchId) {
          $scope.roomTypes[idx].active = mode;
          break;
        }
      }
  };

  $scope.deleteRoomType = function(roomType,index) {
    RoomTypeService.remove({ id: roomType.id }, function(response) {
      setItemActiveProperty(roomType.id,false);
      $scope.inactiveRoomTypes++;
    });
  };

  $scope.restoreRoomType = function(roomType,index) {
    RoomTypeService.restore({ id: roomType.id, path: 'restore' }, function(response) {
      setItemActiveProperty(roomType.id,true);
      $scope.inactiveRoomTypes--;
    }); 
  };


  $scope.saveRoomType = function(roomTypeToSave,index) {

    var isEdit = (roomTypeToSave.id > 0);

    if (validateData(roomTypeToSave)) {

      var confirmCodeChange = roomTypeToSave.codeIsChanging && roomTypeToSave.havingHousingBlock, 
          promptMsg = i18nAdapter.translate('accommodations.messages.roomTypeCodeChangeWarning');

      var saveRoomType = function () {

        RoomTypeService.save({
            id: roomTypeToSave.id,
            accountId: Page.accountId,
            code: roomTypeToSave.code,
            name: roomTypeToSave.name,
            capacity: roomTypeToSave.capacity},
          function(data) {
              var refIndex = isEdit ? index : $scope.roomTypes.length-1;

              $scope.roomTypes[refIndex] = data.roomTypeDTO;
              $scope.roomTypeRowEdit[refIndex] = false;

              if(!isEdit){
                $scope.roomTypes.push(getBlankRoomTypeRecord());
              }
        });  
      };

      if(confirmCodeChange) {
          if (modalDialog.confirm(promptMsg) === true) {
            saveRoomType();
          }
      } else {
        saveRoomType();
      }
    }

  };

  $scope.onCodeChange = function(index) {
    $scope.roomTypes[index].codeIsChanging = true;
  };

  $scope.cancelRoomTypeEdit = function(roomType,index) {

    if(roomType.id !== 0){      
      RoomTypeService.get({ id: roomType.id, accountId: Page.accountId }, function(data) {

        for(var idx in $scope.roomTypes) { // with the possibility of inactive blocks in the array, we don't really know the actual array index value...
          if($scope.roomTypes[idx].id === roomType.id) {
            $scope.roomTypes[idx] = data.roomTypeDTO;
            break;
          }
        }
      });

      $scope.roomTypeRowEdit[index] = false;

    } else {
      $scope.roomTypes.splice($scope.roomTypes.length-1,1);
      $scope.roomTypes.push(getBlankRoomTypeRecord());
    }

  };


  $scope.getRowClass = function(isActive) {
    return isActive ? '' : 'inactive-row';
  };

  function validateData(r) {
    var message = "";
    
    var validate = function(elm) {
      if(elm && elm.length > 0) { return true; } 
      else { return false; }
    };

    if (!validate(r.code) && !validate(r.name) && (!r.capacity > 0)) {
      message = i18nAdapter.translate('accommodations.messages.roomTypeValidationMessage')
    } else if (!validate(r.code) && !validate(r.name) ) {
      message = i18nAdapter.translate('accommodations.messages.roomTypeCodeAndDescValidationMessage')
    } else if (!validate(r.code) && (!r.capacity > 0)) {
      message = i18nAdapter.translate('accommodations.messages.roomTypeCodeAndOccuValidationMessage')
    } else if (!validate(r.name) && (!r.capacity > 0)) {
      message = i18nAdapter.translate('accommodations.messages.roomTypeDescAndOccuValidationMessage')
    } else if (!validate(r.code)) {
      message = i18nAdapter.translate('accommodations.roomType.codeValidation'); 
    } else if (!validate(r.name)) {
      message = i18nAdapter.translate('accommodations.roomType.descriptionValidation');
    } else if (!r.capacity > 0) {
      message = i18nAdapter.translate('accommodations.roomType.occupancyValidation');;
    } 
    if(message.length){ 
      app.common.statusMessages.showError(message);
      return false;
    } else { return true; }
  }

  function getBlankRoomTypeRecord () {
    return {id:0,accountId: Page.accountId ,capacity:"",code:"",active:true,name:""};
  }
}
