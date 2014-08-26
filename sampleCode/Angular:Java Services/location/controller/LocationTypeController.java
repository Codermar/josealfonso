package com.certain.location.controller;

import javax.annotation.Resource;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.certain.common.controller.AbstractController;
import com.certain.common.controller.view.PagedRequest;
import com.certain.common.controller.view.PagedResponse;
import com.certain.common.dto.SearchFilter;
import com.certain.location.service.LocationTypeService;
import com.certain.location.dto.LocationTypeDTO;

@Controller
@RequestMapping(value = "/location_types")
public class LocationTypeController extends AbstractController {
	
	@Autowired private LocationTypeService locationTypeService;
	
    @RequestMapping(method = RequestMethod.GET)
    public PagedResponse<LocationTypeDTO> getAirports(
            @ModelAttribute("filter") SearchFilter searchFilter, PagedRequest pagedRequest) {
        return new PagedResponse<LocationTypeDTO>(locationTypeService.findLocationTypeByFilter(searchFilter, pagedRequest));
    }	
	
}