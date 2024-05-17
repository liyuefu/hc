set heading off
set echo off
set termout off
set linesize 20
spool /tmp/cluster.txt
select value from v$parameter where name = 'cluster_database';
spool off
host cat /tmp/cluster.txt |grep "TRUE" |wc -l  >/tmp/cluster1.txt
host rm /tmp/cluster.txt
exit


