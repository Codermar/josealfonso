package com.certain.location.model.ui;

import java.io.Serializable;
import java.util.List;

import org.apache.commons.lang.builder.EqualsBuilder;
import org.apache.commons.lang.builder.HashCodeBuilder;
import org.springframework.web.bind.annotation.RequestParam;

import com.certain.common.dto.SearchFilter;

	public class LocationFilter extends SearchFilter implements Serializable {
		
		private static final long serialVersionUID = 1L;

		private List<Long> locationTypeList;
		private Long locationTypeId;
		
		
		public LocationFilter() { }

		public Long getLocationTypeId() {
			return locationTypeId;
		}

		public void setLocationTypeId(Long locationTypeId) {
			this.locationTypeId = locationTypeId;
		}

		public List<Long> getLocationTypeList() {
			return locationTypeList;
		}

		public void setLocationTypeList(List<Long> locationTypeList) {
			this.locationTypeList = locationTypeList;
		}
	
}
