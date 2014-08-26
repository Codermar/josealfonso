'use strict';

app.services
	.factory('SupplierService', function($resource) { 
		return $resource('/svcs/locations/:path/:id', { id: '@id', path: '@path' }, {
			query: { method:'GET', params: { accountId: '@accountId' }, isArray: false },
			remove: { method:'DELETE', params: { accountId: '@accountId' } },
			restore: { method:'PUT', params: { accountId: '@accountId', path: 'restore' } }
		});
	});

function Location(accountId) {
	this.id = null;
	this.isPreferred = false;
	this.chainId = null;
	this.brandId = null;
	this.type = {
		id: null,
		name: null,
		notes: null
	};
	this.numberOfRooms = null;
	this.largestMeetingSpace = null;
	this.totalMeetingSpace = null;
	this.numberOfMeetingRooms = null;
	this.code = "";
	this.desc = "";
	this.directions = "";
	this.email = "";
	this.fax = "";
	this.imgAttributes = "";
	this.imgSrc = "";
	this.active = true;
	this.hotel = false;
	this.label = "";
	this.name = "";
	this.notes = "";
	this.phone = "";
	this.tollfree = "";
	this.url = "";
	this.accountId = accountId;
	this.address = {
		id: null,
		city: null,
		country: null,
		intlState: null,
		line1: null,
		line2: null,
		line3: null,
		line4: null,
		postalCode: null,
		state: null
	};
}

function Hotel(accountId) {
	this.id = 0;
	this.info = null;
	this.location = new Location(accountId);
}

function SupplierFilter(accountId, term, page, limit) {
	this.accountId = accountId;
	this.active = true;

	if (term != null && term != undefined && term > 0) {
		this.term = term;
	}

	if (page != null && page != undefined && page > 0) {
		this.page = page;
	}
	
	if (limit != null && limit != undefined && limit > 0) {
		this.limit = limit;
	}
}
