package com.certain.location.service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.certain.common.dto.SearchFilter;
import com.certain.common.service.AbstractService;
import com.certain.location.dto.LocationTypeDTO;


public interface LocationTypeService extends AbstractService<LocationTypeDTO> {
	
	public Page<LocationTypeDTO> findLocationTypeByFilter(SearchFilter filter, Pageable pageable);
	
}
