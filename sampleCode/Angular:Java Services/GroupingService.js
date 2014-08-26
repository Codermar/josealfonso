'use strict';

app.services
	.service('GroupingService', function() {
	var me=this;
	this.grouping = '';	

	this.convertBlockData = function (packet){
		var nights = [],
			hasInactiveBlocks = false;

		_.each(packet.housingBlockDTOList,function (block,key){

			var blk = {
                blockName: block.hotelDTO.location.name + ' - ' + block.roomTypeDTO.code,
                roomTypeCode: block.roomTypeDTO.code,
                hotelName: block.hotelDTO.location.name,
                hotelIsActive: block.hotelDTO.location.active,
                roomTypeDTO: block.roomTypeDTO,
                blockIsActive: block.active,
                blockDTO: {
                  attendeeTypeIds: block.attendeeTypeIds,
                  showOnline: block.showOnline
                }            
	        };

           	// helper property for display
	        if(!block.active) { hasInactiveBlocks = true; }

			angular.forEach(block.wrapperNights, function(wnite, wkey){
				blk.inventoryTotal = wnite.inventory;
				blk.bookedTotal = wnite.booked;
				blk.remainingTotal = wnite.remaining;
				blk.utilizationTotal = wnite.blockUtilization;

				angular.forEach(wnite.hotelRoomNights,function(nite,key){
					nights.push(_.extend(nite, blk));
				});
			});

		});

		return { nights: nights, hasInactiveBlocks: hasInactiveBlocks };

	};

	// Sorts an array of objects "in place". (Meaning that the original array will be modified and nothing gets returned.)
	this.sortOn  = function (arr, prop) {
	    arr.sort (
	        function (a, b) {
	            if (a[prop] < b[prop]){
	                return -1;
	            } else if (a[prop] > b[prop]){
	                return 1;
	            } else {
	                return 0;   
	            }
	        }
	    );
	};

	this.groupBy = function(attribute,elmts,showInactiveBlocks) {

    	this.grouping = attribute;
    	var tmp = _.groupBy(elmts,function(elm,idx){ 
              elm.elmIndex = idx;
              return elm[attribute];
            } ),
	      index = 0,
	      groups = [];


		_.each(tmp,function(elm){

			var groupNites = {},
				blockActiveNites=0,
				blockInactiveNites=0;

			_.each(elm,function(nt){

				groupNites[nt.date] = groupNites[nt.date] || [];
				groupNites[nt.date].push(nt);
				
				if(nt.blockIsActive){
					blockActiveNites ++;
				} else {
					blockInactiveNites ++;
				}

			});

			groups.push({
				housingBlockId: elm[0].housingBlockId, 
				label: elm[0][attribute], 
				blockInactiveNites: blockInactiveNites,
				blockActiveNites: blockActiveNites,
				blockIsActive: elm[0].blockIsActive, 
				hotelIsActive: elm[0].hotelIsActive, 
				blockIndex: index, 
				groupNites: groupNites });

			index ++;

		});

		me.sortOn(groups,'label');

	 	return groups;
	};


	// parsing and preparing the data for the UI
	this.convertSubBlockData = function (packet){

	      var sbItems = _.pluck(packet.housingSubBlockDTOList, 'blockDTOs'),
	          subblocks = _.flatten(packet.housingSubBlockDTOList),
	          nights = [];
	      
	        // loop over subblock items
	        _.each(sbItems,function(block,idx) { 

	            var thisSb = subblocks[idx],
	               // nites = _.pluck(block,'hotelRoomNights'),
	                nites = _.pluck(block,'wrapperNights'),
	                addInfo = { // match the sb info
	                  eventId: subblocks[idx].eventId,
	                  subBlockId: subblocks[idx].id,
	                  subBlockLabel: subblocks[idx].subBlockLabel
	                };

		        _.each(nites,function(wrapNite,key){

		            var thisBlock = block[key];

						addInfo.blockName = thisBlock.hotelDTO.location.name + ' - ' + thisBlock.roomTypeDTO.code;
						addInfo.roomTypeCode = thisBlock.roomTypeDTO.code;
						addInfo.roomTypeId = thisBlock.roomTypeDTO.id;
						addInfo.capacity = thisBlock.roomTypeDTO.capacity;
						addInfo.hotelId = thisBlock.hotelDTO.id;
						addInfo.hotelName = thisBlock.hotelDTO.location.name;
						addInfo.blockIsActive = thisBlock.active;

		                _.each(wrapNite, function(nite) {
		              		var thisNite = {
		              			date: nite.date,
								availableInventory: nite.availableInventory,
								subblockAllocated: nite.subblockAllocated,
								subblockRemaining: nite.subblockRemaining,
								subblockBooked: nite.subblockBooked,
								subBlockUtilization: nite.subBlockUtilization
		              		}

		                    nights.push(_.extend(thisNite, addInfo));

		                });
		        });

	        });

	      return nights; 
	}; 

	this.groupSubBlocksBy = function(attribute,elmts) {
    	var tmp = _.groupBy(elmts,function(elm,idx){ 
              elm.elmIndex = idx;
              return elm[attribute];
            } ),
		    index = 0,
		    groups = [];

	    _.each(tmp,function(elm){
	      groups.push({subBlockId: elm[0].subBlockId, housingBlockId: elm[0].housingBlockId, label: elm[0][attribute], blockIsActive: elm[0].blockIsActive, subBlockIndex: index, groupElmts: elm });
	      index ++;
	    });

	    me.sortOn(groups,'label');
		return groups;
	};


/*
	New utilization by date report:

	The view should include the following columns:
	Date - should include one row per date included in all room blocks
	Inventory - should sum inventory for all inventory across all room blocks for that date
	Booked - should sum total booked across all room blocks for that date
	Remaining - should display the difference between the Inventory and Booked columns.
	Utilization - should display the utilization % calculated by dividing the booked value by the remaining value.
*/

	this.convertBlockDataForReport = function (blockDTOList){

	    var hotels = {},
	    	dateReport = {};

	    _.each(blockDTOList,function (block,key){

			angular.forEach(block.wrapperNights, function(wnite, wkey){

				dateReport[wnite.date] = dateReport[wnite.date] || {
					date: wnite.date,
					inventory: 0,
					blockUtilization: 0,
					booked: 0,
					remaining: 0
				};



                var hotelId = block.hotelDTO.id;


                // temporarily inject data
                //wnite.recCatReservations = injectTempData(wnite.date,hotelId);

                hotels[hotelId] = hotels[hotelId] || {
                        id: block.hotelDTO.id,
                        name: block.hotelDTO.location.name,
                        code: block.hotelDTO.location.code,
                        nites: {},
                        activeNightLength: 0,
                        blockIsActive: block.active,
                        showOnline: block.showOnline
                    };

                    if(block.active) {
                        // night summary (only active blocks)
                        dateReport[wnite.date].inventory = dateReport[wnite.date].inventory + parseInt(wnite.inventory);
                        dateReport[wnite.date].booked = dateReport[wnite.date].booked + parseFloat(wnite.booked);
                        dateReport[wnite.date].remaining = dateReport[wnite.date].remaining + parseFloat(wnite.remaining);
                    }


				    hotels[hotelId]["nites"][wnite.date] = hotels[hotelId]["nites"][wnite.date] || {
                                                                        date: wnite.date,
                                                                        rooms: [],
                                                                        attendees: [],
                                                                        availableInventory: wnite.availableInventory,
                                                                        blockUtilization: wnite.blockUtilization,
                                                                        booked: wnite.booked

                                                                    };

                    hotels[hotelId]["nites"][wnite.date][block.roomTypeDTO.code] = hotels[hotelId]["nites"][wnite.date][block.roomTypeDTO.code] || { roomTypeCount: 0, roomTypeCountAttendee: 0 };


                // report by attendee
                if(Object.keys(wnite.recCatReservations).length > 0) {

                     _.each(wnite.recCatReservations,function(att,key) {

                         hotels[hotelId]["nites"][wnite.date]["attendees"].push ({
                                                                            label: att.regCatLabel,
                                                                            roomType: block.roomTypeDTO.code,
                                                                            capacity: block.roomTypeDTO.capacity,
                                                                            inventory: parseInt(wnite.inventory),
                                                                            booked: att.bookedD,
                                                                            utilization: att.utilization,
                                                                            remaining: att.remaining
                                                                       });
                         hotels[hotelId]["nites"][wnite.date][block.roomTypeDTO.code].roomTypeCountAttendee ++;
                     });
                }



                // nites by room type (utilization by date report)
                if(wnite.hotelRoomNights.length > 0) {

				    _.each(wnite.hotelRoomNights,function(nite,key){
				        
				        nite.roomType = block.roomTypeDTO.code;
				        nite.roomTypeId = block.roomTypeDTO.id;

				        var roomUniqueCode = "RT-" + nite.roomTypeId + '-R' + nite.rate;

				        hotels[hotelId]["nites"][nite.date]["rooms"].push(nite);

				        if(nite.blockIsActive) { // helper property for the rendering
				        	hotels[hotelId].activeNightLength ++;
				        }
			        

				        hotels[hotelId]["nites"][nite.date][nite.roomType].roomTypeCount ++;			    

				    });
				}

			});
	    });

	    return { hotels: hotels,dateReport:dateReport };

	};
	
	this.convertSubBlockDataForReport = function (nites) {
     	var subblocks = {},
     		tmpCount = 1,
      		currHotel = "";

      angular.forEach(nites, function(nite, key){

        var sbId = nite.subBlockId,
        	rtKey = nite.hotelName + nite.roomTypeCode; 
        
        if(currHotel !== nite.hotelName) { tmpCount = 1; } else { tmpCount ++;}

        subblocks[sbId] = subblocks[sbId] || {
                id: sbId, 
                name: nite.subBlockLabel,
                nites: {}
            }; 

        subblocks[sbId]["nites"][nite.date] = subblocks[sbId]["nites"][nite.date] || { date: nite.date, blocks: {}, hotels: {} };
        subblocks[sbId]["nites"][nite.date]["blocks"][rtKey] = subblocks[sbId]["nites"][nite.date]["blocks"][rtKey] || nite;
        subblocks[sbId]["nites"][nite.date]["hotels"][nite.hotelName] = subblocks[sbId]["nites"][nite.date]["hotels"][nite.hotelName] || { hotelNightCount: 0 };
		subblocks[sbId]["nites"][nite.date]["hotels"][nite.hotelName].hotelNightCount ++;

      });

      return subblocks;
    };

});