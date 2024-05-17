col username for a10
col event for a25
col program for a15
set linesize 100


exec dbms_workload_repository.create_snapshot();

SET ECHO OFF TERMOUT ON FEEDBACK OFF VERIFY OFF
SET SCAN ON PAGESIZE 9999
SET LONG 1000000 LINESIZE 180
COL recs FORMAT a145
VARIABLE tuning_task VARCHAR2(30)
--SET FEEDBACK ON VERIFY ON
--SET linesize 80


DECLARE
l_sql_id v$session.prev_sql_id%TYPE:='&input_sql_id';
BEGIN
:tuning_task := dbms_sqltune.create_tuning_task(
sql_id => l_sql_id,
task_name=>'&input_task_name');
dbms_sqltune.execute_tuning_task(:tuning_task);
END;
/

---查看调优报告
select dbms_sqltune.report_tuning_task(:tuning_task) as recs from dual;

