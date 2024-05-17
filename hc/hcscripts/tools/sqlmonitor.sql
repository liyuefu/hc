undefine sqlid
set trimspool on
set pages 0
set linesize 1000
set long 100000
set longchunksize 100000
spool sqlmon_&&sqlid..html
select dbms_sqltune.report_sql_monitor(type=>'active',sql_Id=>'&sqlid') from dual;
spool off


