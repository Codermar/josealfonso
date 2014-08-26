set define off;
create or replace package ng_compProgReports AS

TYPE genRefCursor IS REF CURSOR;

PROCEDURE getManagerProgress ( 
   p_PlanningProgress IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2);
  
end ng_compProgReports;
/

create or replace package body ng_compProgReports AS

PROCEDURE getManagerProgress ( 
   p_PlanningProgress IN OUT genRefCursor
  ,p_ManagerID NUMBER
  ,p_CycleID   NUMBER
  ,p_ManagerName OUT nocopy VARCHAR2) is
  

cursor c_managers is
    select distinct d.eid, d.empname
    FROM hr_compOrg d 
    WHERE  d.cycleid = p_cycleID
      and d.managerid = p_Managerid
      and d.eid in (select t.managerid from hr_compOrg t where t.cycleid = p_cycleID);
      
cursor c_org(p_eid number) is
  select 
     d.eid
    ,d.managerid
    ,d.manager.empname managername
    ,0 as orgSeq
    ,d.compEmp.eligibility.isSalaryEligible SalaryEligible
    ,decode(d.compEmp.eligibility.isSalaryEligible,0,0, decode(d.compInput.MeritAmt,null,decode(d.compInput.LumpSumAmt,null,0,1),1) ) salarydone     
    ,d.compEmp.eligibility.isICPEligible icpeligible
    ,decode(d.compEmp.eligibility.isICPEligible,0,0,decode(d.compInput.ICPIndivModifier,null,0,1)) icpdone      
    ,d.compEmp.eligibility.isLTIEligible LTIEligible
    ,decode(d.compEmp.eligibility.isLTIEligible,0,0,decode(d.compInput.LTIGrantAmt,null,0,1)) ltidone /* by default if not elig, it's done */  
    FROM hr_compOrg d 
      WHERE   d.cycleid = p_cycleID 
        START WITH d.managerid = p_eid
        CONNECT BY PRIOR d.eid = d.managerid
          AND PRIOR d.cycleid = p_cycleID;

cursor c_myorg is
  select 
     d.eid
    ,d.managerid
    ,d.manager.empname managername
    ,0 as orgSeq
    ,d.compEmp.eligibility.isSalaryEligible SalaryEligible
    ,decode(d.compEmp.eligibility.isSalaryEligible,0,0, decode(d.compInput.MeritAmt,null,decode(d.compInput.LumpSumAmt,null,0,1),1) ) salarydone     
    ,d.compEmp.eligibility.isICPEligible icpeligible
    ,decode(d.compEmp.eligibility.isICPEligible,0,0,decode(d.compInput.ICPIndivModifier,null,0,1)) icpdone      
    ,d.compEmp.eligibility.isLTIEligible LTIEligible
    ,decode(d.compEmp.eligibility.isLTIEligible,0,0,decode(d.compInput.LTIGrantAmt,null,0,1)) ltidone /* by default if not elig, it's done */  
    FROM hr_compOrg d 
      WHERE   d.cycleid = p_cycleID 
      and d.managerid = p_managerid;
      
  v_seq number := 0;
  v_tmp int := 0;
  
begin

  delete from T_COMPPROG;
  
  for r in c_myorg loop
        if v_tmp = 0 then
          p_ManagerName := r.managername;
          v_tmp := 1;
        end if;
        Insert into T_COMPPROG (EID,MANAGERID,ORGNAME,ORGSEQ,SALARYELIGIBLE,SALARYDONE,ICPELIGIBLE,ICPDONE,LTIELIGIBLE,LTIDONE)
        values (r.eid,p_managerid,'Your Direct Reports',0,r.SalaryEligible,r.salarydone,r.icpeligible,r.icpdone,r.ltieligible,r.ltidone);
  end loop;
  
  for m in c_managers loop
    v_seq := v_seq + 1;
    for r in c_org(m.eid) loop
        --dbms_output.put_line('mgr:' || r.managername || ' ' || r.eid || ': sal: ' || r.salarydone || ' icp: ' || r.icpdone) ;
        Insert into T_COMPPROG (EID,MANAGERID,ORGNAME,ORGSEQ,SALARYELIGIBLE,SALARYDONE,ICPELIGIBLE,ICPDONE,LTIELIGIBLE,LTIDONE)
        values (r.eid,m.eid,m.empname,v_seq,r.SalaryEligible,r.salarydone,r.icpeligible,r.icpdone,r.ltieligible,r.ltidone);
    end loop;    
  end loop;

open p_PlanningProgress for 
select 
  o.orgseq
 ,o.orgname
 ,sum(o.SalaryEligible) SalaryEligible
 ,sum(o.salarydone) salarydone
 ,sum(o.icpeligible) icpeligible
 ,sum(o.icpdone) icpdone
 ,sum(o.LTIEligible) LTIEligible
 ,sum(o.ltidone) ltidone
from T_COMPPROG o
GROUP BY o.orgseq, o.orgname
union
select 1000 as orgseq
  ,'Totals' as orgname
  ,sum(o.SalaryEligible) SalaryEligible
  ,sum(o.salarydone) salarydone
  ,sum(o.icpeligible) icpeligible
  ,sum(o.icpdone) icpdone
  ,sum(o.LTIEligible) LTIEligible
  ,sum(o.ltidone) ltidone
from T_COMPPROG o GROUP BY 1000, 'Totals'
order by orgseq;

end getManagerProgress;
  
end ng_compProgReports;
/