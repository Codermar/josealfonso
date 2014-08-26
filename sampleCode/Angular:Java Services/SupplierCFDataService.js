'use strict';

app.services
	.service('SupplierCFDataService', function($filter, $http, CFDataService) {


	this.getVenuesByAccountId = function (params,callback) {
       var data = [];

        $http({
            method: 'GET',
            url: '/ajax/userAjax/router.cfc',
            params: {
                method: 'r',
                a: 'accommodation.getVenuesByAccountId',
                accountId: params.accountId,
                locationId: params.locationId
                }
            }).
        success(function(rsp, status, headers, config) {
           rsp = CFDataService.serializeCFQueryData(rsp.response);
           callback(rsp,status,headers,config);
        });

       return data;
    };

    this.setEventPrimaryVenue = function( params, callback ) {

        $http({
            method: 'POST',
            url: '/ajax/userAjax/router.cfc',
            params: {
                method: 'r',
                a: 'accommodation.setEventPrimaryVenue',
                eventId: params.eventId,
                locationId: params.locationId
                }
            }).
        success(function(rsp, status, headers, config) {
           callback(rsp,status,headers,config);
        });
    }

});
