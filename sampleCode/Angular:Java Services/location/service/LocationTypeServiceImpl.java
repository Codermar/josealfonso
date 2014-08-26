package com.certain.location.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import com.certain.common.dto.SearchFilter;
import com.certain.common.service.AbstractServiceImpl;
import com.certain.location.dao.LocationTypeDAO;
import com.certain.location.dto.LocationTypeDTO;
import com.certain.register123.model.LocationType;


@Service
@Transactional
public class LocationTypeServiceImpl extends AbstractServiceImpl<LocationTypeDTO, LocationType> implements LocationTypeService {

	protected static final Sort TYPENAME_ASC_SORT = new Sort(Sort.Direction.ASC, "name");
	private LocationTypeDAO locationTypeDAO;
	
	@Autowired
	public LocationTypeServiceImpl(LocationTypeDAO locationTypeDAO) {
		this.locationTypeDAO = locationTypeDAO;
	}
	
	
	public LocationTypeDTO update(LocationTypeDTO dto) {
		LocationType entity = getEntityForUpdate(dto);

		return getDTOForEntity(locationTypeDAO.save(entity));
	}

	public LocationTypeDTO create(LocationTypeDTO dto) {
		validateForCreate(dto);

		LocationType entity = new LocationType();

		locationTypeDAO.save(entity);

		return getDTOForEntity(entity);
	}
	
	public LocationTypeDTO getDTOForEntity(LocationType entity) {
		return new LocationTypeDTO(entity);
	}

	public LocationTypeDAO getDAO() {
		return this.locationTypeDAO;
	}

	public Page<LocationTypeDTO> findLocationTypeByFilter(SearchFilter filter, Pageable pageable) {
		
//		if(filter != null){
//			
//		} else {
//			return findAll(pageable);
//		}
//		return null;
		return convertEntityPageToDTOPage(locationTypeDAO.findAll(pageable),pageable);
	}
	
	
//	private Page<LocationTypeDTO> findAll(Pageable pageable) {
//		PageRequest pageRequest = new PageRequest(pageable.getPageNumber(), pageable.getPageSize(), TYPENAME_ASC_SORT);
//		return convertEntityPageToDTOPage(locationTypeDAO.findAll(pageable), pageable);
//	}


	public Page<LocationTypeDTO> findLocationsByFilter(SearchFilter filter, Pageable pageable) {
		
//		if(filter != null) {
//			if(filter.getAccountId() != null) {
//				
//				if(filter.getActive() == null) {
//					return findLocationTypeByAccountIdAndActive(filter.getAccountId(), null, pageable);
//				} else {
//					return findLocationTypeByAccountIdAndActive(filter.getAccountId(), filter.getActive(), pageable);
//				}			
//			}
//		} else {
//			return findLocationTypeByAccountIdAndActive(filter.getAccountId(), null, pageable);
//		}
		return null;
		
	}



//	private Page<LocationTypeDTO> findLocationsByAccountIdAndActive(Long accountId, Boolean active, Pageable pageable) {
//		PageRequest pageRequest = new PageRequest(pageable.getPageNumber(), pageable.getPageSize(), LOCATIONNAME_ASC_SORT);
//		if(active == null){
//			return convertEntityPageToDTOPage(locationTypeDAO.findByAccountId(accountId, pageRequest), pageable);
//		} else {
//			return convertEntityPageToDTOPage(locationTypeDAO.findByAccountIdAndActive(accountId, active, pageRequest), pageable);
//		}
//	}

		
}
