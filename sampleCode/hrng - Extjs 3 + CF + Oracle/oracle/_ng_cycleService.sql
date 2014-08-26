create or replace package ng_cycleService as

TYPE genRefCursor IS REF CURSOR;

procedure updateCycleInfoObj(
  p_CycleID number
);

end ng_cycleService;
/

create or replace package body ng_cycleService as

procedure updateCycleInfoObj(
  p_CycleID number
) is

  v_cycleInfo ngt_cycleInfo;

begin

    -- initialize
    v_cycleInfo := New ngt_cycleInfo(
           cached => 0
          ,CycleID => p_CycleID
          ,ForceLoad => 1);
      
     v_cycleInfo.save();

      
end updateCycleInfoObj;


end ng_cycleService;
/