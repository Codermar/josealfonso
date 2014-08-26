package com.certain.location.dao;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.certain.common.dao.AbstractDAO;
import com.certain.register123.model.Location;

public interface LocationDAO extends AbstractDAO<Location> {

	public Page<Location> findByAccountId(Long accountId, Pageable pageable);

	public Page<Location> findByAccountIdAndActive(Long accountId, Boolean active, Pageable pageable);

	public Page<Location> findByTypeIdAndActive(Long locationTypeId, Boolean active, Pageable pageable);

	public Page<Location> findByAccountIdAndNameContaining(	Long accountId, String name, Pageable pageable);

	public Page<Location> findByAccountIdAndNameContainingAndActive(Long accountId, String name, Boolean active, Pageable pageable);

	@Query("select a from Location a "
			+ "where a.type.id in (:locationTypeList) and accountId = :accountId")	
	public Page<Location> findByAccountIdAndTypeId(@Param("accountId") Long accountId, @Param("locationTypeList") List<Long> locationTypeList, Pageable pageable);

	@Query("select a from Location a "
			+ "where a.type.id in (:locationTypeList) and accountId = :accountId "
			+ "and a.active = :active ")	
	public Page<Location> findByAccountIdAndTypeIdAndActive(@Param("accountId") Long accountId, @Param("locationTypeList") List<Long> locationTypeList, @Param("active") Boolean active, Pageable pageable);
	
	public Page<Location> findByAccountIdAndTypeId(Long accountId,Long locationTypeId, Pageable pageable);

	public Page<Location> findByAccountIdAndTypeIdAndActive(Long accountId,Long locationTypeId, Boolean active, Pageable pageable);

	@Query("select a from Location a "
	+ "where a.type.id in (2,3) and accountId = :accountId")	
	public List<Location> findBrandsAndChainsByAccountId(@Param("accountId") Long accountId);
	
    @Query("select a from Location a, Event e where e.location.id = a.id and e.id = :eventId")
    public Location findEventVenue(@Param("eventId") Long eventId);
	
}
