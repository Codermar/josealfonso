package com.certain.location.controller;

import java.util.List;

import javax.annotation.Resource;
import javax.validation.Valid;

import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;

import com.certain.common.controller.AbstractController;
import com.certain.common.controller.view.PagedRequest;
import com.certain.common.controller.view.PagedResponse;
import com.certain.location.dto.LocationDTO;
import com.certain.location.model.ui.LocationFilter;
import com.certain.location.service.LocationService;

@Controller
@RequestMapping(value="/locations")
public class LocationController extends AbstractController {
	private static final Logger LOG = LogManager.getLogger(LocationController.class);
	@Resource private LocationService locationService;

	@RequestMapping(method = RequestMethod.GET)
	public PagedResponse<LocationDTO> getPage(@ModelAttribute("filter") LocationFilter filter, PagedRequest pagedRequest) {
		return new PagedResponse<LocationDTO>(locationService.findByFilter(filter,pagedRequest));
	}

	@RequestMapping(value = "/getBrandsAndChains", method = RequestMethod.GET)
	public List<LocationDTO> getBrandsAndChains(@RequestParam(value = "accountId" , required = true) Long accountId) {
		return locationService.findBrandsAndChainsByAccountId(accountId);
	}

	@RequestMapping(method = RequestMethod.POST)
	public LocationDTO create(@Valid @RequestBody LocationDTO dto) {
		return locationService.create(dto);
	}

	@RequestMapping(value = "/{id}", method = RequestMethod.GET)
	public LocationDTO get(@PathVariable Long id, @RequestParam Long accountId) {
		return id != null ? locationService.findById(id) : new LocationDTO();
	}

	@RequestMapping(value = "/{id}", method = {RequestMethod.POST, RequestMethod.PUT})
	public LocationDTO update(@Valid @RequestBody LocationDTO dto) {
		return locationService.update(dto);
	}
	
	@ResponseStatus(HttpStatus.OK)
	@RequestMapping(value = "/{id}", method = RequestMethod.DELETE)
	public void delete(@PathVariable Long id, @RequestParam Long accountId) {
		locationService.deleteSupplier(id);
	}

	@RequestMapping(value = "/restore/{id}", method = RequestMethod.PUT)
	public void restore(@PathVariable Long id) {
		locationService.restoreSupplier(id);
	}
	
    @RequestMapping(value = "/findEventVenue/{id}", method = RequestMethod.GET)
    public LocationDTO findEventVenue(@PathVariable Long id) {
        LocationDTO location = locationService.findEventVenue(id);
        return location;
    }
}