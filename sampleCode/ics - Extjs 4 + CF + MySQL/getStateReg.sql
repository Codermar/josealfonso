delimiter //
drop function IF EXISTS getStateReg //

create function getStateReg (
   p_productid int
  ,p_state char(2)
  ) 
returns int
LANGUAGE SQL
DETERMINISTIC

begin

	declare p_recid int;
	declare p_mbatfid int;
	declare p_statecode varchar(5);
	declare p_registrationstatus varchar(50);
	declare p_regStatusCode int;
	declare p_rank int;
	declare p_approved date;
	declare p_rejected date;
	declare p_expires date;
	declare p_submitted date;

	declare v_tmpstatus varchar(25);
	declare v_tmprank int;
	declare v_tmprecid int;
	declare v_submitted date;
	declare v_rejected date;
	declare v_approved date;
	declare v_notes varchar(500);

	declare iDone boolean;
	declare tmpIterator cursor for
		select 
		 tmp_recid
		,mbatfid
		,statecode 
		,registrationstatus
		,case registrationstatus
			when 'Approved' then 3
			when 'Pending' then 2
			when 'Rejected' then 1
		else 0
		end as regStatusCode
		,rank
		,approved
		,rejected
		,expires
		,submitted
		from tmp_compl 
		where placeholder <> 1
		and rank > 1
		and mbatfid = p_productid
		and statecode = p_state
		order by regStatusCode,submitted,rejected;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET iDone = 1;


	 -- debug  delete from tmp_x;


    SET iDone = 0;
    OPEN tmpIterator;
    lxIterator: LOOP
        FETCH tmpIterator INTO 
			 p_recid
			,p_mbatfid
			,p_statecode 
			,p_registrationstatus
			,p_regStatusCode
			,p_rank
			,p_approved
			,p_rejected
			,p_expires
            ,p_submitted;
              
        IF 1 = iDone THEN
            LEAVE lxIterator;
        END IF;

		if v_tmpstatus is null then
			set v_tmprecid = p_recid;
			set v_tmpstatus = p_registrationstatus;
			set v_submitted = p_submitted;
			set v_rejected = p_rejected;
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
