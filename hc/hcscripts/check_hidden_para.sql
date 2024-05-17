set linesize 120
set feedback off
col name for a35
col value for a20
select x.ksppinm  name, y.ksppstvl  value, y.ksppstdf  isdefault, decode(bitand(y.ksppstvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE')  ismod, decode (bitand(y.ksppstvf,2),2,'TRUE','FALSE')     isadj from sys.x$ksppi x, sys.x$ksppcv y where x.inst_id = userenv('Instance') and y.inst_id = userenv('Instance') and x.indx = y.indx  and  x.ksppinm = '&1'  order by translate(x.ksppinm, ' _', ' ');
exit;

