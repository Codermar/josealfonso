package com.certain.location.service;

import static com.certain.accommodation.util.HousingErrorMessages.HOTEL_DELETE_ERROR_MSG;
import static com.certain.accommodation.util.HousingErrorMessages.SUPPLIER_EDIT_NON_HOTEL_ERROR_MSG;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.certain.accommodation.dao.HotelsToRoomTypeDAO;
import com.certain.accommodation.dto.AddressDTO;
import com.certain.common.exception.NotFoundException;
import com.certain.common.service.AbstractServiceImpl;
import com.certain.location.dao.LocationDAO;
import com.certain.location.dao.LocationTypeDAO;
import com.certain.location.dto.LocationDTO;
import com.certain.location.dto.LocationTypeDTO;
import com.certain.location.model.ui.LocationFilter;
import com.certain.register123.api.ValidationException;
import com.certain.register123.model.Address;
import com.certain.register123.model.HotelsToRoomType;
import com.certain.register123.model.Location;
import com.certain.register123.repositories.AddressRepository;

@Service
@Transactional
public class LocationServiceImpl extends AbstractServiceImpl<LocationDTO, Location> implements LocationService {

	protected static final Sort LOCATIONNAME_ASC_SORT = new Sort(Sort.Direction.ASC, "name");
	private LocationDAO locationDAO;
	private AddressRepository addressRepository;
	@Autowired private HotelsToRoomTypeDAO hotelsToRoomTypeDAO;
	
	
	@Autowired
	public LocationServiceImpl(LocationDAO locationDAO, AddressRepository addressRepository, HotelsToRoomTypeDAO hotelsToRoomTypeDAO, LocationTypeDAO locationTypeDAO) {
		this.locationDAO = locationDAO;
		this.hotelsToRoomTypeDAO = hotelsToRoomTypeDAO;
		this.addressRepository = addressRepository;
	}
	
	@Override
	public LocationDTO update(LocationDTO dto) {
		if(dto.getHotel() == null || !dto.getHotel()){
			List<HotelsToRoomType> blockList = hotelsToRoomTypeDAO.findByHotelLocationIdAndActive(dto.getId(), true);
			if(blockList != null && blockList.size() > 0){
				List<String> validationErrors = new ArrayList<String>();
				validationErrors.add(SUPPLIER_EDIT_NON_HOTEL_ERROR_MSG);
				throw new ValidationException(null, validationErrors);
			}
		}
		return getDTOForEntity(locationDAO.save(updateEntity(getEntityForUpdate(dto), dto)));
	}

	public LocationDTO create(LocationDTO dto) {
		validateForCreate(dto);

		return getDTOForEntity(locationDAO.save(updateEntity(new Location(), dto)));
	}	
	
	public LocationDTO getDTOForEntity(Location entity) {
		return new LocationDTO(entity);
	}

	public LocationDAO getDAO() {
		return this.locationDAO;
	}

	public List<LocationDTO> findBrandsAndChainsByAccountId(Long accountId) {
		return getDTOsForEntities(locationDAO.findBrandsAndChainsByAccountId(accountId));
	}
	
	@SuppressWarnings("null")
	public Page<LocationDTO> findByFilter(LocationFilter filter, Pageable pageable) {
		
		if(filter != null) {
	
			if(filter.getAccountId() != null) {
				
				if(filter.getTerm() != null) {

					return findByAccountIdAndNameContainingAndActive(filter.getAccountId(), filter.getTerm(), filter.getActive(), pageable);

				} else if(filter.getLocationTypeList() != null) {			
					// System.out.println("----getLocationTypeList----" + filter.getLocationTypeList());		
					return findByAccountIdAndTypeIdListAndActive(filter.getAccountId(), filter.getLocationTypeList(), filter.getActive(), pageable);
					
				} else if(filter.getLocationTypeId() != null) {
					
					return findByAccountIdAndTypeIdAndActive(filter.getAccountId(), filter.getLocationTypeId(), filter.getActive(), pageable);
				} 
				else {
					return findLocationsByAccountIdAndActive(filter.getAccountId(), filter.getActive(), pageable);	
				}				
			}
			
		} else {
			// TODO: filter would be null here so maybe we can extract the accountId by the session.
			return findLocationsByAccountIdAndActive(filter.getAccountId(), null, pageable);
		}
		return null;
		
	}
	
	private Page<LocationDTO> findByAccountIdAndTypeIdListAndActive(Long accountId, List<Long> locationTypeList, Boolean active, Pageable pageable) {
		Page<Location> pagedResponse;
		
		if(active == null) {
			pagedResponse = locationDAO.findByAccountIdAndTypeId(accountId, locationTypeList, pageable);
		} else {
			pagedResponse = locationDAO.findByAccountIdAndTypeIdAndActive(accountId, locationTypeList, active, pageable);
		}
		return convertEntityPageToDTOPage(pagedResponse,pageable);
	}
	
	private Page<LocationDTO> findByAccountIdAndTypeIdAndActive(Long accountId, Long locationTypeId, Boolean active, Pageable pageable) {
		Page<Location> pagedResponse;
		
		if(active == null) {
			pagedResponse = locationDAO.findByAccountIdAndTypeId(accountId, locationTypeId, pageable);
		} else {
			pagedResponse = locationDAO.findByAccountIdAndTypeIdAndActive(accountId, locationTypeId, active, pageable);
		}
		return convertEntityPageToDTOPage(pagedResponse,pageable);	
	}

	private Page<LocationDTO> findByAccountIdAndNameContainingAndActive(Long accountId, String name, Boolean active, Pageable pageable) {
		Page<Location> pagedResponse;
		
		if(active == null){
			pagedResponse = locationDAO.findByAccountIdAndNameContaining(accountId, name, pageable);
		} else {
			pagedResponse = locationDAO.findByAccountIdAndNameContainingAndActive(accountId, name, active ,pageable);		

		}
		return convertEntityPageToDTOPage(pagedResponse,pageable);
	}

	private Page<LocationDTO> findLocationsByAccountIdAndActive(Long accountId, Boolean active, Pageable pageable) {
		PageRequest pageRequest = new PageRequest(pageable.getPageNumber(), 
				pageable.getPageSize(), LOCATIONNAME_ASC_SORT);
		if(active == null){
			return convertEntityPageToDTOPage(locationDAO.findByAccountId(accountId, pageRequest), pageable);
		} else {
			return convertEntityPageToDTOPage(locationDAO.findByAccountIdAndActive(accountId, active, pageRequest), pageable);
		}
	}
	
	public void deleteSupplier(Long id) {
		List<HotelsToRoomType> blockList = hotelsToRoomTypeDAO.findByHotelLocationIdAndActive(id, true);
		if(blockList != null && blockList.size() > 0){
			List<String> validationErrors = new ArrayList<String>();
			validationErrors.add(HOTEL_DELETE_ERROR_MSG);
			throw new ValidationException(null, validationErrors);
		}
		updateLocationIsActive(id,false);
	}
	
	public void restoreSupplier(Long id) {
		updateLocationIsActive(id,true);
	}
	
	private void updateLocationIsActive(Long id, Boolean active) {
		Location location = locationDAO.findOne(id);
		
		if(location != null){
			location.setActive(active);
			locationDAO.save(location);
		}	
	}
	
	private Location updateEntity(Location entity, LocationDTO dto) {
		
		entity.setId(dto.getId());
		entity.setAccountId(dto.getAccountId());
		entity.setCode(dto.getCode());
		entity.setName(dto.getName());
		entity.setDesc(dto.getDesc());
		entity.setDirections(dto.getDirections());
		entity.setEmail(dto.getEmail());
		entity.setFax(dto.getFax());
		entity.setImgAttributes(dto.getImgAttributes());
		entity.setImgSrc(dto.getImgSrc());
		entity.setActive(dto.getActive());
		entity.setIsPreferred(dto.getIsPreferred());
		entity.setHotel(dto.getHotel());
		entity.setLabel(dto.getLabel());
		entity.setNotes(dto.getNotes());
		entity.setPhone(dto.getPhone());
		entity.setTollfree(dto.getTollfree());
		entity.setUrl(dto.getUrl());

		if(dto.getType() != null){
			
			LocationTypeDTO locationTypeDTO = dto.getType();
			entity.setType(locationTypeDTO.convertDTOToModel());
			
		} else {
			throw new NotFoundException("Supplier Type cannot be blank.");
		}
		
		if(dto.getAddress() != null) {
			
			AddressDTO addressDTO = dto.getAddress();
			Address address;
			
			if(addressDTO.getId() != null) {
				address = addressRepository.findById(addressDTO.getId());
			} else {
				address = new Address();
			}		
			
			address.setId(addressDTO.getId());
			address.setLine1(addressDTO.getLine1());
			address.setLine2(addressDTO.getLine2());
			address.setLine3(addressDTO.getLine3());
			address.setLine4(addressDTO.getLine4());
			address.setCity(addressDTO.getCity());
			address.setCountry(addressDTO.getCountry());
			address.setState(addressDTO.getState());
			address.setIntlState(addressDTO.getIntlState());
			address.setPostalCode(addressDTO.getPostalCode());

			entity.setAddress(addressRepository.merge(address));
			
		}
		
		entity.setNumberOfMeetingRooms(dto.getNumberOfMeetingRooms());
		entity.setNumberOfRooms(dto.getNumberOfRooms());
		entity.setTotalMeetingSpace(dto.getTotalMeetingSpace());
		entity.setLargestMeetingSpace(dto.getLargestMeetingSpace());
		entity.setBrandId(dto.getBrandId());
		entity.setChainId(dto.getChainId());
		entity.setThirdPartyId(dto.getThirdPartyId());

		return entity;
	}
	
    public LocationDTO findEventVenue(Long eventId) {
        return getDTOForEntity(locationDAO.findEventVenue(eventId));
    }
		
}
