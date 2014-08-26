package com.certain.location.dto;

import java.io.Serializable;

import javax.validation.constraints.Size;

import com.certain.accommodation.dto.AddressDTO;
import com.certain.common.dto.BaseDTO;
import com.certain.register123.model.Location;
import com.certain.location.dto.LocationTypeDTO;

public class LocationDTO extends BaseDTO implements Serializable{

	private static final long serialVersionUID = 1L;

	private Long id;
	@Size(max=100,message="Unique Code field must up to 100 characters long.")
	private String code;
	private LocationTypeDTO type;
	@Size(max=2000,message="Description is limited to 2000 characters.")
	private String desc;
	@Size(max=1000,message="Directions are limited to 1000 characters.")
	private String directions;
	@Size(max=100,message="Email field must be up to 100 characters long.")
	private String email;
	@Size(max=25,message="Fax field must be up to 25 characters long.")
	private String fax;
	// @Size(max=255,message="")
	private String imgAttributes;
	@Size(max=255,message="Image source field is limited to 255 characters.")
	private String imgSrc;
	private Boolean active = new Boolean(true);
	private Boolean isPreferred;
	private Boolean hotel = new Boolean(true);
	//@Size(max=250,message="Label field is limited to 250 characters.")
	private String label;
	@Size(max=100,message="Name field is limited to 100 characters.")
	private String name;
	@Size(max=2000,message="Notes field is limited to 1000 characters.")
	private String notes;
	@Size(max=25,message="Phone field is limited to 25 characters.")
	private String phone;
	@Size(max=25,message="Phone field is limited to 25 characters.")
	private String tollfree;
	@Size(max=255,message="URL field is limited to 255 characters.")
	private String url;
	private Long  accountId;
	private AddressDTO address;
	private Long numberOfMeetingRooms;
	private Long numberOfRooms;
	private Long totalMeetingSpace;
	private Long largestMeetingSpace;
	private Long brandId;
	private Long chainId;
	private Long thirdPartyId;
	
	public LocationDTO(){
		
	}
	
	public LocationDTO(Location model){
		if(model != null){
			this.id = model.getId();
			this.code = model.getCode();
			this.type = new LocationTypeDTO(model.getType());
			this.desc = model.getDesc();
			this.directions = model.getDirections();
			this.email = model.getEmail();
			this.fax = model.getFax();
			this.imgAttributes = model.getImgAttributes();
			this.imgSrc = model.getImgSrc();
			this.active = model.isActive();
			this.isPreferred = model.getIsPreferred();
			this.hotel = model.isHotel();
			this.label = model.getLabel();
			this.name = model.getName();
			this.notes = model.getNotes();
			this.phone = model.getPhone();
			this.tollfree = model.getTollfree();
			this.url = model.getUrl();
			this.accountId = model.getAccountId();
			this.address = new AddressDTO(model.getAddress());
			this.numberOfMeetingRooms = model.getNumberOfMeetingRooms();
			this.numberOfRooms = model.getNumberOfRooms();
			this.totalMeetingSpace = model.getTotalMeetingSpace();
			this.largestMeetingSpace = model.getLargestMeetingSpace();
			this.brandId = model.getBrandId();
			this.chainId = model.getChainId();
			this.thirdPartyId = model.getThirdPartyId();
			
		} else {
		    this.id = 0l;
		}
	}
	
	public Location convertDTOToModel(){
		Location model = new Location();
		
		if(this.id != null){
			model.setId(this.id);
		}
		model.setCode(this.code);
		
		if(this.type != null){
			model.setType(this.type.convertDTOToModel());
		}
		model.setDesc(this.desc);
		model.setDirections(this.directions);
		model.setEmail(this.email);
		model.setFax(this.fax);
		model.setImgAttributes(this.imgAttributes);
		model.setImgSrc(this.imgSrc);
		model.setActive(this.active);
		model.setIsPreferred(this.isPreferred);
		model.setHotel(this.hotel);
		model.setLabel(this.label);
		model.setName(this.name);
		model.setNotes(this.notes);
		model.setPhone(this.phone);
		model.setTollfree(this.tollfree);
		model.setUrl(this.url);
//		if(model.getAccount() != null){
//			this.accountId = model.getAccount().getId();
//		}
		if(this.address != null){
			model.setAddress(this.address.convertDTOToModel());
		}
		model.setNumberOfMeetingRooms(this.numberOfMeetingRooms);
		model.setNumberOfRooms(this.numberOfRooms);
		model.setTotalMeetingSpace(this.totalMeetingSpace);
		model.setLargestMeetingSpace(this.largestMeetingSpace);
		model.setBrandId(this.brandId);
		model.setChainId(this.chainId);
		model.setThirdPartyId(this.thirdPartyId);
		
		return model;
	}
	
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}

	
	public String getDesc() {
		return desc;
	}

	public void setDesc(String desc) {
		this.desc = desc;
	}

	public String getDirections() {
		return directions;
	}

	public void setDirections(String directions) {
		this.directions = directions;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getFax() {
		return fax;
	}

	public void setFax(String fax) {
		this.fax = fax;
	}

	public String getImgAttributes() {
		return imgAttributes;
	}

	public void setImgAttributes(String imgAttributes) {
		this.imgAttributes = imgAttributes;
	}

	public String getImgSrc() {
		return imgSrc;
	}

	public void setImgSrc(String imgSrc) {
		this.imgSrc = imgSrc;
	}

	public Boolean getActive() {
		return active;
	}

	public void setActive(Boolean active) {
		this.active = active;
	}

	public Boolean getIsPreferred() {
		return isPreferred;
	}

	public void setIsPreferred(Boolean isPreferred) {
		this.isPreferred = isPreferred;
	}

	public Boolean getHotel() {
		return hotel;
	}

	public void setHotel(Boolean hotel) {
		this.hotel = hotel;
	}

	public String getLabel() {
		return label;
	}

	public void setLabel(String label) {
		this.label = label;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getNotes() {
		return notes;
	}

	public void setNotes(String notes) {
		this.notes = notes;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getTollfree() {
		return tollfree;
	}

	public void setTollfree(String tollfree) {
		this.tollfree = tollfree;
	}

	public String getUrl() {
		return url;
	}

	public void setUrl(String url) {
		this.url = url;
	}

	public Long getAccountId() {
		return accountId;
	}

	public void setAccountId(Long accountId) {
		this.accountId = accountId;
	}

	public AddressDTO getAddress() {
		return address;
	}

	public void setAddress(AddressDTO address) {
		this.address = address;
	}

	public LocationTypeDTO getType() {
		return type;
	}

	public void setType(LocationTypeDTO locationType) {
		this.type = locationType;
	}

	public Long getNumberOfMeetingRooms() {
		return numberOfMeetingRooms;
	}

	public void setNumberOfMeetingRooms(Long numberOfMeetingRooms) {
		this.numberOfMeetingRooms = numberOfMeetingRooms;
	}

	public Long getNumberOfRooms() {
		return numberOfRooms;
	}

	public void setNumberOfRooms(Long numberOfRooms) {
		this.numberOfRooms = numberOfRooms;
	}

	public Long getTotalMeetingSpace() {
		return totalMeetingSpace;
	}

	public void setTotalMeetingSpace(Long totalMeetingSpace) {
		this.totalMeetingSpace = totalMeetingSpace;
	}

	public Long getLargestMeetingSpace() {
		return largestMeetingSpace;
	}

	public void setLargestMeetingSpace(Long largestMeetingSpace) {
		this.largestMeetingSpace = largestMeetingSpace;
	}

	public Long getBrandId() {
		return brandId;
	}

	public void setBrandId(Long brandId) {
		this.brandId = brandId;
	}

	public Long getChainId() {
		return chainId;
	}

	public void setChainId(Long chainId) {
		this.chainId = chainId;
	}

	public Long getThirdPartyId() {
		return thirdPartyId;
	}

	public void setThirdPartyId(Long thirdPartyId) {
		this.thirdPartyId = thirdPartyId;
	}
	
	
}
