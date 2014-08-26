package com.certain.location.dto;

import java.io.Serializable;

import javax.validation.constraints.Size;

import com.certain.common.dto.BaseDTO;
import com.certain.register123.model.LocationType;

public class LocationTypeDTO extends BaseDTO implements Serializable {

	private static final long serialVersionUID = 1L;

	private Long id;
	@Size(max=100)
	private String name;
	@Size(max=2000)
	private String notes;

	
	public LocationTypeDTO(){ }

	public LocationTypeDTO(LocationType model){
		if(model != null){
			this.id = model.getId();
			this.name = model.getName();
			this.notes = model.getNotes();
		}
	}
	
	public LocationType convertDTOToModel(){
		LocationType model = new LocationType();
		
		if(this.id != null){
			model.setId(this.id);
		}
		model.setName(this.name);
		model.setNotes(this.notes);
		
		return model;
	}
	
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return this.name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getNotes() {
		return this.notes;
	}

	public void setNotes(String notes) {
		this.notes = notes;
	}	
	
}
