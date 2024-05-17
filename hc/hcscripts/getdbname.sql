set heading off
set echo off
set termout off
set linesize 20
spool /tmp/db.txt
select trim(value) from v$parameter where name = 'db_name';
spool off
spool /tmp/db_unique.txt
select trim(value) from v$parameter where name = 'db_unique_name';
spool off
host cat /tmp/db.txt |grep -v ^$| awk '{ print $(NF)}' >/tmp/dbname.txt
host rm /tmp/db.txt
host cat /tmp/db_unique.txt |grep -v ^$| awk '{ print $(NF)}' >/tmp/db_unique_name.txt
host rm /tmp/db_unique.txt
exit