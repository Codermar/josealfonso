delimiter //
drop function IF EXISTS getRollupReg //

create function getRollupReg (
	 p_productid int
	,p_state char(2)
	,p_certstatus varchar(25)
	,p_liquorType varchar(25)
  ) 
returns int
LANGUAGE SQL
DETERMINISTIC

begin

	declare p_recid int;
	declare p_mbatfid int;
	declare p_statecode varchar(5);
	declare p_registrationstatus varchar(50);
	declare p_tmp varchar(50);
	declare p_regStatusCode int;
	declare p_rank int;
	declare p_approved date;
	declare p_rejected date;
	declare p_cancelled date;
	declare p_expires date;
	declare p_submitted date;

	declare v_tmpstatus varchar(25);
	declare v_tmprank int;
	declare v_tmprecid int;
	declare v_submitted date;
	declare v_rejected date;
	declare v_cancelled date;
	declare v_expires date;
	declare v_approved date;
	declare v_notes varchar(500);

	declare iDone boolean;
	declare tmpIterator cursor for
	select o.*
		,case o.rs
			when 'Approved'  then 5
			when 'Approved/Price Posting Required' then 5
			when 'Pending' then 4
			when 'Rejected' then 3
			when 'Expired' then 2
		else 0
		end as regStatusCode
		,case 
			when substr(o.rs,1,8) = 'Approved' then 'Approved'
			else o.rs
		end as registrationstatus
	from (
		select 
		 compliid
		,mbatfid
		,state
		,getStatus(p_liquorType,sr.state,sr.cancelled,sr.rejected,sr.approved,sr.submitted,sr.expires,p_certstatus ) rs
		,approved
		,rejected
		,cancelled
		,expires
		,submitted
		from complinc sr 
		where sr.mbatfid = p_productId
		and sr.state = p_state
	) o 
	order by regStatusCode desc,submitted,rejected;



	DECLARE CONTINUE HANDLER FOR NOT FOUND SET iDone = 1;


	 -- debug  delete from tmp_x;


    SET iDone = 0;
    OPEN tmpIterator;
    lxIterator: LOOP
        FETCH tmpIterator INTO 
			 p_recid
			,p_mbatfid
			,p_statecode 		
			,p_tmp
			,p_approved
			,p_rejected
			,p_cancelled
			,p_expires
            ,p_submitted
			,p_regStatusCode
			,p_registrationstatus;
              
        IF 1 = iDone THEN
            LEAVE lxIterator;
        END IF;

		if v_tmpstatus is null then
			set v_tmprecid = p_recid;
			set v_tmpstatus = p_registrationstatus;
			set v_submitted = p_submitted;
			set v_rejected = p_rejected;
			set v_cancelled = p_cancelled;
			set v_expires = p_expires;
			set v_approved = p_approved;
		end if;

		if p_registrationstatus = 'Pending' and v_tmpstatus <> 'Approved' then
			
			if v_tmpstatus = 'Rejected' then

				if v_submitted is null or (p_submitted > v_submitted and p_submitted > v_rejected) then
			
				-- set v_notes = CONCAT('reset at rej', ': ', p_submitted, ' v_sub:',v_submitted, ' v_rej:', v_rejected, ' comp1:', p_submitted > v_submitted, ' comp2:', p_submitted > v_rejected ) ;
			
				set v_submitted = p_submitted;
					set v_tmprecid = p_recid;
					set v_tmpstatus = 'Pending';
					set v_rejected = p_rejected;
				end if;
				
			else
				if v_submitted is null or p_submitted > v_submitted then
					set v_submitted = p_submitted;
					set v_tmprecid = p_recid;
					set v_tmpstatus = 'Pending';
				end if;
				-- set v_rejected = p_rejected;			
			end if;

		end if;


		if p_registrationstatus = 'Rejected' then -- and v_tmpstatus <> 'Approved'

			if v_rejected is null or p_rejected > v_rejected then 
				set v_rejected = p_rejected; 
			end if;

			if v_rejected > v_submitted and v_rejected > v_approved then
				set v_rejected = p_rejected;
				set v_tmprecid = p_recid;
				set v_tmpstatus = 'Rejected';
			end if;

		end if;

		if p_registrationstatus = 'Approved' and p_approved > v_rejected then
			set v_tmprecid = p_recid;
			set v_tmpstatus = 'Approved';
			set v_submitted = p_submitted;
			set v_approved = p_approved;
			set v_expires = p_expires;
		end if;

		-- if cancelled
		if p_registrationstatus = 'Cancelled' then

			if v_cancelled is null or p_cancelled > v_cancelled then 
				set v_cancelled = p_cancelled; 
			end if;

			if v_cancelled > v_submitted and v_cancelled > v_approved then
				set v_cancelled = p_cancelled;
				set v_tmprecid = p_recid;
				set v_tmpstatus = 'Cancelled';
			end if;

		end if;

		if p_registrationstatus = 'Approved' and p_approved > v_cancelled then
			set v_tmprecid = p_recid;
			set v_tmpstatus = 'Approved';
			set v_submitted = p_submitted;
			set v_approved = p_approved;
			set v_expires = p_expires;
		end if;

		-- finally, if the registration has expired, then it should override an approved one
		if p_registrationstatus = 'Approved' and (v_expires < current_date()) = 1 then

		-- set v_notes = CONCAT('reset at expires', ': ', p_expires, ' v_exp:', v_expires, ' test: ', v_expires < current_date() );

			set v_tmprecid = p_recid;
			set v_tmpstatus = 'Expired';
			set v_submitted = p_submitted;
			set v_approved = p_approved;
			set v_expires = p_expires;
		end if;
 
/* debug
		insert into tmp_x
			select 
			 p_recid
			,v_tmprecid
			,v_tmpstatus
			,null 
			,v_rejected
			,null 
			,v_approved
			,v_submitted
			,v_notes;
 */

    END LOOP lxIterator;
    CLOSE tmpIterator; 

return v_tmprecid;

end;
//
delimiter ;
