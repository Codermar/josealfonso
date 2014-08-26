delimiter //
DROP PROCEDURE IF EXISTS loadAllStateCompl //

CREATE PROCEDURE loadAllStateCompl (pRunMode int)
begin


	declare p_id int(11);
	declare p_colaID int(11);
	declare p_clientID varchar(50);
	declare p_clientName varchar(125);
	declare p_brand varchar(75);
	declare p_prodname varchar(75);
	declare p_certstatus varchar(35);
	declare p_regstatus varchar(35);
	declare p_ltype varchar(35);
	declare p_varietal varchar(25);
	declare p_origin varchar(25);
	declare p_sku varchar(35);
	declare p_alcohol decimal;
	declare p_serialno varchar(35);
	declare p_unitSize varchar(25);
	declare p_ttbno varchar(25);
	declare p_certfilename varchar(50);
	declare p_vintage varchar(5);
	declare p_alcoholPercent decimal(5);
	declare p_blrno varchar(20);
	declare p_assignedToID varchar(5);

	declare v_count int;
	declare iDone boolean;

  declare cProds cursor for
	select 
		p.productId
		,p.clientId
		,p.clientName
		,p.activeCertId
		,pCase(p.BrandName) BrandName
		,p.productName
		,p.certStatus
		,p.liquorType
		,p.alcoholPercent
		,p.varietalClass
		,p.originType
		,null as sku
		,p.unitsize
		,p.ttbNumber
		,p.serialno
		,p.certfilename
		,p.vintage
		,p.alcoholPercent
		,p.assignedToID
		-- ,p.ClientSKU
	from rpt_products p
	where 0=0
	and p.isMaster = 1;
	-- and p.clientId = 'SD'; -- for testing

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET iDone = 1;


 -- TODO: Add unitsize


	call logEvent('Started loading state compliance records.',pRunMode);

	truncate table rpt_state_compl; -- Use truncate to reset the autoincrement

	set v_count = 0;
    set iDone = 0;
    open cProds;
	cIterator: LOOP
        FETCH cProds INTO 
				p_id
				,p_ClientID
				,p_clientName
				,p_colaID
				,p_brand
				,p_prodname
				,p_certstatus
				,p_ltype
				,p_alcohol
				,p_varietal
				,p_origin
				,p_sku
				,p_unitSize
				,p_ttbno
				,p_serialno
				,p_certfilename
				,p_vintage
				,p_alcoholPercent
				,p_assignedToID
              ;
              
        if 1 = iDone then leave cIterator; end if;

		insert into rpt_state_compl		
			select
				null
				,p_ClientID
				,s.state_code stateCode
				,s.state_name_txt StateName	
				,sr.batfid
				,sr.mbatfid	
				,p_certstatus
				,p_certfilename
				,getStatus(p_ltype,s.state_code,sr.cancelled,sr.rejected,sr.approved,sr.submitted,sr.expires,p_certstatus )
				,sr.cancelled
				,sr.rejected 
				,sr.expires 
				,sr.approved
				,sr.submitted
				,null -- estapprovaldate
				,p_brand
				,p_prodname
				,p_clientName
				,p_ltype
				,p_varietal
				,p_unitSize
				,p_serialno
				,p_ttbno
				,0
				,1
				,p_vintage
				,p_alcoholPercent
				,trim(sr.blrno)
				-- ,ifnull(trim(sr.asignid),p_assignedToID) 
				,sr.asignid
			from ics_state s
				left outer join complinc sr on s.state_code = sr.state
			where 0=0
				and sr.mbatfid = p_id
				and sr.stat != 'V'
				and sr.canRpt = 1
			union
			select
				null
				,p_ClientID
				,s.state_code stateCode, s.state_name_txt StateName
				,p_id,p_id
				,p_certstatus
				,p_certfilename
				,getStatus(p_ltype,s.state_code,null,null,null,null,null,p_certstatus )
				,null,null,null,null,null
				,null -- estapprovaldate
				,p_brand
				,p_prodname
				,p_clientName
				,p_ltype
				,p_varietal
				,p_unitSize
				,p_serialno
				,p_ttbno
				,1
				,1
				,p_vintage
				,p_alcoholPercent
				,null -- blrno
				,null -- ,p_assignedToID
			from ics_state s
				where s.state_code not in(select distinct state from complinc where mbatfid = p_id );
		
		


	end loop cIterator;
	close cProds;

	-- force control state records to not show (per Mike 4/12/2013)

	update rpt_state_compl
		set approved = null, submitted = null
	where substr(registrationstatus,1,13) = 'Control State';

	update rpt_state_compl
	set approved = null, submitted = null
	where substr(registrationstatus,1,18) = 'Price Posting Only';


	select count(1) into v_count from rpt_state_compl;

	call logEvent(concat_ws('','Finished loading state compliance records in rpt_state_compl: ', v_count, ' Records Loaded'),pRunMode);

end;
//
delimiter ;
