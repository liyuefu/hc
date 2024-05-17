set heading off
set echo off
set termout off
set linesize 100
spool /tmp/ver.txt
select rtrim(lower(banner)) from v$version;
spool off
host cat /tmp/ver.txt |grep '^oracle database'| awk '{ print $3}' >/tmp/dbver.txt
host cat /tmp/ver.txt |grep '^oracle database'| awk '{ print $7}' >/tmp/dbver2.txt
host rm /tmp/ver.txt
exit