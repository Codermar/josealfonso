create or replace
PACKAGE ng_globals AS


  -------------- constants ----------------
  const_TotalReports   CONSTANT  INTEGER  := 0;
  const_DirectReports  CONSTANT  INTEGER  := 1;
  const_DottedLine 	   CONSTANT INTEGER   := 2;
  const_Countries	   CONSTANT INTEGER	  := 3;
  const_managersOnly constant integer := 4;
  const_EmpList constant integer := 5;
  const_EmpLocations constant integer := 6;
  const_Regions constant integer := 7;

  const_search constant integer := 9;
  
  MeritCompTypeID CONSTANT INTEGER    := 1;
  PACompTypeID    CONSTANT INTEGER   := 2;
  ICPCompTypeID    CONSTANT INTEGER  := 3;
  PerfGrantCompTypeID CONSTANT INTEGER  := 10;

END ng_globals;
 