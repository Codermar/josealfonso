package com.certain.location.service;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.certain.common.service.AbstractService;
import com.certain.location.dto.LocationDTO;
import com.certain.location.model.ui.LocationFilter;


public interface LocationService extends AbstractService<LocationDTO> {
	
	public List<LocationDTO> findBrandsAndChainsByAccountId(Long accountI);
	
	public Page<LocationDTO> findByFilter(LocationFilter filter, Pageable pageable);
	
	public void deleteSupplier(Long id);
	
	public void restoreSupplier(Long id);
	
	public LocationDTO findEventVenue(Long eventId);
	
}
