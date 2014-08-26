
function SupplierEventVenueCtrl ($scope, $routeParams, $filter, $http, $timeout, $location, $modal,
                                  Page, i18nService, CFDataService, SupplierCFDataService ) {

    $scope.showDetail = $routeParams.showDetail;
    Page.locationId = parseInt($routeParams.locationId);
    $scope.venueSupplierList = [];
    $scope.selectedVenue = [];
	$scope.i18n = i18nService;
 	angular.extend($scope.i18n, {
        manageSuppliersTooltip: i18nAdapter.translate("accommodations.venue.manageSuppliers")

    });
    $scope.hasPrimary = Page.locationId > 0;

    var getSuppliers = function() {

        SupplierCFDataService.getVenuesByAccountId({
            accountId: Page.accountId

        }, function (response) {
            $scope.venueSupplierList = response.data;

            if($scope.venueSupplierList.length > 0) {
                angular.forEach($scope.venueSupplierList,function(item,idx){
                    if(item.locationId === Page.locationId ) {
                        $scope.selectedVenue = item;
                    }
                });
            }
        });
    };

    getSuppliers();

    $scope.venueSelectConfig = {
        multiple:false,
        placeholder: $scope.i18n.selectOne,
        data: function() {
            return { results: $scope.venueSupplierList };
        },
        id: function(data) { return data.locationId},
        formatResult: function(data) { return data.locationName },
        formatSelection: function(data) { return data.locationName }
    };


    $scope.setAsPrimary = function () {

        SupplierCFDataService.setEventPrimaryVenue({
            eventId: Page.eventId,
            locationId: $scope.selectedVenue.locationId

        }, function (response) {
//            if(response.success) {
//                var message = "The primary venue has been set!";
//                 app.common.statusMessages.showSuccess(message);
//            }
        });
    };


    $scope.open = function () {

        var modalInstance = $modal.open({
          templateUrl: 'myModalContent.html',
          controller: ModalInstanceCtrl,
          size: 'lg',
          resolve: {
            items: function () {
              return Page.locationId;
            }
          }
        });

        modalInstance.result.then(function (selectedItem) {

        }, function () {
            // dismissed modal, refresh supplier list
            getSuppliers();
        });

    };

    var ModalInstanceCtrl = function ($scope, $modalInstance, items) {

      $scope.supplierSection = "/assets/angular/views/supplier/index.html";

      $scope.cancel = function () {
        $modalInstance.dismiss('cancel');
      };

    };

}