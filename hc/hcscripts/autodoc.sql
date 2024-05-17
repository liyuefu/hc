--author：dabingruien@msn.com
--this health check script should be executed through sqlplus or through plsql developer
--the output should be opened through ultra edit32
--before execute this script ,pls modify the path of spool 
--change size M to G, lyf.2020.10.14,change the TABLESPAE MONITOR sql.
--add flashback_on for DB CONFIGURATION. ,change tablespace_name for a50, lyf. 2020.10.29
--add diskgroup free space check. 2020.11.1
--add maxsize of tempfile. 2020.11.2, correct max_pct_used error;column TRIGGERING_EVENT for a35
--2020.11.05 change col thread# format 9999999
--2020.11.16. change TABLESPACE MONITOR maxsize sum error.
--2021.01.31. change TABLESPACE MONITOR temp tablespace free error.
--2021.03.11. remove some useless sql statement. add pct used to DISKGROUP.
--2021.05.31. change the sql of busyday/rushour archivelog.
--add tablespace dayly usage , fetch 60 rows of tablespace.
--2021.06.01. fix tablespace grow bug.
--2021.06.03. busy day log round(..,2)
--2021.06.08. fix tablespace grow bug. only return 7 days growth.
--2022.09.30   fix invalid datafile时未判断dg. dg的都是read only. vmstat 执行4次,执行iosat4次,把旧的巡检放到old目录,把使用的脚本放入output/using_script
--2023.08.18  only get top 20 invalid objects . rownum<=20.

spool healthcheckoracle.out

set pagesize 9999
set linesize 250
set long 9999
set echo off
set termout off

alter session set nls_language=american;



prompt '*********************************************************************'
prompt '*****************************Top Danagers*******************************'
prompt '*********************************************************************'
prompt '1,MAX OBJECT ID:'
select case
         when max(obj#) >= 4000000000 then
          'Danger!!! Object id upper limit!'
         when max(obj#) >= 2000000000 then
          'Warning!!!Need checking the DDLs'
         Else
          'Good!'
       END "MAX OBJECT ID"
  from obj$; 

prompt
prompt

prompt '2,PASSWORD_LIFE_TIME 180:'
select distinct profile ||' ****** Resource name:PASSWORD_LIFE_TIME 180 !!!*****' 
  from dba_users
 where profile in (select profile
                     from dba_profiles
                    where resource_name = 'PASSWORD_LIFE_TIME'
                      and limit = '180');

prompt
prompt
prompt '3,CREATE SESSION AUDIT:'
select Audit_option || ' IS ENABLED!!!'
  from dba_stmt_audit_opts
 where audit_option = 'CREATE SESSION';

prompt '3,AUDIT TRAIL'
select name,value from v$parameter where name in ('audit_trail','audit_file_dest') order by name;

prompt
prompt
prompt '4,RECYCLEBIN:'
select case
         when count(1) >= 1000 then
          'Recyclebin need to purge!'
         Else
          'Good!'
       END "RECYCLEBIN"
  from dba_recyclebin;



prompt 
prompt
prompt '5,SYSDATE'
select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') check_date from dual;
prompt 
prompt
prompt '*********************************************************************'
prompt '****************************DB OUTLINE*******************************'
prompt '*********************************************************************'
prompt '6,DB_NAME LOGMODE:'
col instance_name format a10;
col db_name format a10;
--select b.log_mode,decode(a.name,'instance_name',a.value) instance_name,decode(a.name,'db_name',a.value) db_name 
--from v$parameter a,v$database b where a.name in('db_name','instance_name') ;
select name,log_mode from v$database ;
prompt
prompt
prompt '7,DB SIZE(G):'
select  c.sum3 "DMP size(G)",a.sum1 "RMAN BACKUPSET SIZE(G)",b.sum2 "DATAFILE SIZE(G)" from (SELECT ceil(SUM(BYTES)/1024/1024/1024) sum1 FROM DBA_segments ) a,(select ceil(sum(bytes)/1024/1024/1024) sum2 from v$datafile) b,(select ceil(sum(bytes)/1024/1024/1024) sum3 from dba_segments where segment_type not like 'INDEX%' and segment_type not in('ROLLBACK','CACHE','LOBINDEX','TYPE2 UNDO')) c ;
prompt
prompt
prompt '8,CHARACTSET AND NLS PARAMETERS:'
col value$ format a35;
col name format a35;
select name,value$ from sys.props$ where name in('NLS_TERRITORY','NLS_LANGUAGE','NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET');
prompt
prompt
prompt '9,COUNT OF TABLESPACE AND DATA OR TEMP FILE:'
select b.sum2 "CNT OF TABLESPACE",a.sum1 "CNT OF DATAFILE",c.sum3 "CNT OF TEMPFILE"  from (select count(1) sum1 from v$datafile) a, (select count(1) sum2 from v$tablespace )b ,(select count(1) sum3 from v$tempfile) c;
prompt
prompt
prompt '11,TOP IMPORTANT PARAMETERS:'
col value format a45;
col name format a35;
select name ,value from v$parameter where name 
in('pga_aggregate_target' ,'memory_target','memory_max_target','sga_target','sga_max_size','db_cache_size','db_2k_cache_size','db_4k_cache_size','db_8k_cache_size','db_16k_cache_size','db_32k_cache_size',
'shared_pool_size','large_pool_size','java_pool_size','log_buffer','sort_area_size','streams_pool_size','db_block_buffers','db_block_size','optimizer_mode','cursor_sharing','optimizer_index_cost_adj','optimizer_index_caching','db_file_multiblock_read_count','hash_join_enabled') order by name;
prompt '12,LICENSE:'
select * from v$license;
prompt
prompt
prompt '*********************************************************************'
prompt '********************* DB CONFIGURATION*******************************'
prompt '*********************************************************************'
prompt '******************************************'
prompt '*********************DB*******************'
prompt '******************************************'
prompt '13,DB CONFIGURATION:'
select DBID,NAME,CREATED,LOG_MODE,PROTECTION_MODE,FORCE_LOGGING,FLASHBACK_ON FROM V$DATABASE;
prompt
prompt
prompt '******************************************'
prompt '****************DB VERSION****************'
prompt '******************************************'
prompt '14,DB VERSION:'
select * from v$version;
prompt
prompt
prompt '******************************************'
prompt '***************COMP STATUS****************'
prompt '******************************************'
prompt '15,DB COMP STATUS:'
col comp_id format a10;
col comp_name format a35;
col version format a15;
col status format a8;
col modified format a30;
select comp_id,replace(comp_name,' ','.') comp_name,version,status,replace(replace(modified,' ',':'),'-','/') modified from dba_registry;
prompt
prompt
prompt '******************************************'
prompt '************NON-DEFAULT DB INIT PARAMETERS************'
prompt '******************************************'
prompt '16,NON-DEFAULT DB PARAMETERS:'
col value format a58;
col name format a30;
col trim(num) format a10;
select trim(num),name,value,ismodified,isadjusted from v$parameter where isdefault='FALSE' and name not like '%l_files';
prompt
prompt
prompt '******************************************'
prompt '************DB RESOURCE LIMITS************'
prompt '******************************************'
prompt '17,DB RESOURCE LIMITS:'
col RESOURCE_NAME format a30;
col CURRENT_UTILIZATION format a10;
col MAX_UTILIZATION format a10;
col INITIAL_ALLOCATION format a10;
col LIMIT_VALUE format a10;
select trim(RESOURCE_NAME) RESOURCE_NAME,trim(CURRENT_UTILIZATION) CURRENT_UTILIZATION,trim(MAX_UTILIZATION) MAX_UTILIZATION,trim(INITIAL_ALLOCATION) INITIAL_ALLOCATION,trim(LIMIT_VALUE) LIMIT_VALUE from v$resource_limit;
prompt
prompt
prompt '******************************************'
prompt '************Physical structure************'
prompt '******************************************' 
prompt '************************'
prompt '******CONTROLFILES*******'
prompt '************************'
prompt '18,CONTROLFILE_LIST'
col name format a60
select * from v$controlfile;

prompt '19,CONTROLFILE_SIZE:'
select type,record_size,records_total,records_used from v$controlfile_record_section;

prompt
prompt
prompt '************************'
prompt '********LOGFILE*********'
prompt '************************'
prompt '20,LOGFILE:'
col member format a70;
col thread# format a7;
col group# format a8;
select trim(a.thread#) thread#,trim(a.group#) group#,b.member member,a.status status,a.bytes/1024/1024 "size(M)" from v$log a,v$logfile b where a.group#=b.group#;
prompt
prompt
col thread# format 99;
prompt '21,ARCHIVELOG BUSY DAY: '
select * from (
SELECT A.DAY,A.Count#, Round(A.Count#*B.AVG#/1024/1024/1024,2) Daily_Log_Gb
FROM (
SELECT To_Char(First_Time,'YYYY-MM-DD') DAY, Count(1) Count#
FROM v$log_history
GROUP BY To_Char(First_Time,'YYYY-MM-DD')
) A,
(
SELECT
Avg(BYTES) AVG#,
Count(1) Count#,
Max(BYTES) Max_Bytes,
Min(BYTES) Min_Bytes
FROM v$log
) B 
order by Daily_Log_Gb desc
) 
where rownum < 10;
prompt
prompt
prompt '22,ARCHIVELOG RUSH HOUR:'
select * from (
select to_char(first_time,'yyyy/mm/dd hh24') "DAY",count(1) LOG_CNT from v$log_history group by to_char(first_time,'yyyy/mm/dd hh24') order by LOG_CNT desc, DAY desc
)
where rownum < 10;
prompt
prompt
prompt '************************'
prompt '*******DATAFILE*********'
prompt '************************'
prompt '23,DATAFILE:'
col tablespace_name format a25;
col file_id format a8;
col file_name format a60;
select trim(a.file_id) "FILE_ID",b.tablespace_name "TABLESPACE_NAME",b.status "TABLESPACE_STATUS",a.file_name "FILE_NAME",a.status "FILE_STATUS",ceil(a.bytes/1024/1024/1024) "FILE_SIZE(G)",a.AUTOEXTENSIBLE "AUTOEXTENSIBLE",ceil(a.MAXBYTES/1024/1024/1024) "MAX_SIZE(G)" from dba_data_files a,dba_tablespaces b where a.tablespace_name=b.tablespace_name  order by a.AUTOEXTENSIBLE desc,a.file_id;

prompt
prompt
prompt '************************'
prompt '********TEMPFILE********'
prompt '************************'
prompt '24,TEMPFILE:'
col tablespace_name format a25;
col file_id format a8;
select trim(a.file_id) "FILE_ID",b.tablespace_name "TABLESPACE_NAME",b.status "TABLESPACE_STATUS",a.file_name "FILE_NAME",a.status "FILE_STATUS",ceil(a.bytes/1024/1024/1024) "FILE_SIZE(G)",a.AUTOEXTENSIBLE "AUTOEXTENSIBLE",ceil(a.MAXBYTES/1024/1024/1024) "MAX_SIZE(G)" from dba_temp_files a,dba_tablespaces b where a.tablespace_name=b.tablespace_name  order by a.AUTOEXTENSIBLE desc,a.file_id;

prompt
prompt
prompt '************************'
prompt '****INVALID DATAFILE****'
prompt '************************'
prompt '25,INVALID DATA FILE:'
col file_id format a8;
col file_name format a45;
select trim(f.FILE#) "FILE_ID",f.name "FILE_NAME",f.status "STATUS",f.bytes/1024/1024/1024 "FILE_SIZE(G)",t.name tablespace_name from v$datafile f,v$tablespace t, v$database d where f.ts#=t.ts# and  (status<>'ONLINE'  AND status<>'SYSTEM' )or  (enabled<>'READ WRITE' and d.database_role = 'PRIMARY');

prompt
prompt
prompt '******************************************'
prompt '***************Tablespaces****************'
prompt '******************************************'
prompt '************************'
prompt '***TABLESPACE FRAGMENT**'
prompt '************************'
prompt '26,TABLESPACE FRAGMENT:'
select a.tablespace_name ,count(1) "AMOUNT OF FRAGMENT" from dba_free_space a,dba_tablespaces  b where a.tablespace_name=b.tablespace_name and b.EXTENT_MANAGEMENT='DICTIONARY' group by a.tablespace_name having count(1) >20 order by 2;
--prompt 'script of eliminating fragment'
-- select 'alter tablespace '||tablespace_name||' coalesce' from dba_tablespaces where EXTENT_MANAGEMENT='DICTIONARY';


prompt
prompt
prompt '************************'
prompt '***DISKGROUP MONITOR***'
prompt '************************'
prompt '27,DISKGROUP MONITOR:'
col name for a12
col pct_used for a10
--select name,state,type,total_mb,free_mb,usable_file_mb,offline_disks from v$asm_diskgroup;
select name,state,type,to_char(round(total_mb/1024,1),'9,999,999.99') total_Gb,
to_char(round(free_mb/1024,1),'9,999,999.99') free_Gb,
to_char(round((total_mb-free_mb)/total_mb*100,1))||'%' pct_used,
to_char(round(usable_file_mb/1024,1),'9,999,999.99') Ava_Gb,offline_disks 
from v$asm_diskgroup;


prompt
prompt
prompt '************************'
prompt '***TABLESPACE MONITOR***'
prompt '************************'
prompt '28,TABLESPACE MONITOR:'

col pct_used for a10
col name for a35
col pct_max_used for a12 
select (select decode(extent_management,'LOCAL','*',' ') from dba_tablespaces where tablespace_name = b.tablespace_name)
            || nvl(b.tablespace_name, nvl(a.tablespace_name,'UNKOWN')) name,
       to_char(round(Gbytes_alloc,2),'9,999,999.99') Total_Gb,
       to_char(round(Gbytes_alloc-nvl(Gbytes_free,0),2),'9,999,999.99') Used_Gb,
       to_char(round(nvl(Gbytes_free,0),2),'9,999,999.99') Free_Gb,
       to_char( NVL(ROUND(((Gbytes_alloc-nvl(Gbytes_free,0))/Gbytes_alloc)*100,1),0),999.9) ||'%' Pct_used,
       to_char(round(nvl(Gbytes_max,Gbytes_alloc),2),'9,999,999.99') Max_Gb,
       to_char(NVL(ROUND(decode(Gbytes_max, 0, 0, ((Gbytes_alloc-nvl(Gbytes_free,0))/Gbytes_max)*100),1),0),999.9)||'%' pct_max_used
from ( (select sum(bytes)/1024/1024/1024 Gbytes_free, tablespace_name
       from  sys.dba_free_space
       group by tablespace_name ) 
       union all 
       (select sum(free_space)/1024/1024/1024 Gbytes_free, tablespace_name
       from  sys.dba_temp_free_space
       group by tablespace_name )) a ,
     ( (select sum(bytes)/1024/1024/1024 Gbytes_alloc,
              sum(decode(maxbytes,0,bytes,maxbytes))/1024/1024/1024 Gbytes_max,
              tablespace_name
       from sys.dba_data_files
       group by tablespace_name) 
       union all
       (select sum(bytes)/1024/1024/1024 Gbytes_alloc,
              sum(decode(maxbytes,0,bytes,maxbytes))/1024/1024/1024 Gbytes_max,
              tablespace_name
       from sys.dba_temp_files
       group by tablespace_name )) b 
where a.tablespace_name (+) = b.tablespace_name order by pct_max_used desc;

prompt '29,TABLESPACE GROW:'
select a.snap_id,c.tablespace_name ts_name,
to_char(to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss'),'mm/dd hh24') snap_time ,
to_char(round(a.tablespace_size*c.block_size/1024/1024/1024,2),'9,999,999.99') Total_Gb,
to_char(round(a.tablespace_usedsize*c.block_size/1024/1024/1024,2),'9,999,999.99') Used_Gb,
to_char(round((a.tablespace_size - a.tablespace_usedsize)*c.block_size/1024/1024/1024,2),'9,999,999.99') Free_Gb,
to_char(round(a.tablespace_usedsize/a.tablespace_size*100,2),'999.99')||'%' Pct_used
from dba_hist_tbspc_space_usage a,
    (select tablespace_id,substr(rtime,1,10) rtime,max(snap_id) snap_id
        from dba_hist_tbspc_space_usage nb
        group by tablespace_id,substr(rtime,1,10)) b,
        dba_tablespaces c,
        v$tablespace d
where a.snap_id=b.snap_id and a.tablespace_id = b.tablespace_id and 
a.tablespace_id=d.ts# and d.name=c.tablespace_name and to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss') >= sysdate-7 
order by a.tablespace_id,to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss') desc;


prompt
prompt
prompt '******************************************'
prompt '****Tables/Indexes/Constraints/Triggers***'
prompt '******************************************'

prompt
prompt
prompt '************************'
prompt '*****CHAINED TABLES*****'
prompt '************************'
prompt '32,CHAINED TABLES:'
select owner,table_name,chain_cnt from dba_tables where chain_cnt>0 order by 3 desc;
prompt                                                              
prompt                                                              
prompt '************************'                                   
prompt '*>2G UNPARTITIONED TABS*'                                   
prompt '************************'                                   
prompt '33,LARGE UNPARTITIONED TABS:'
select /*+rule*/a.owner,a.segment_name,a.bytes "SIZE(G)" from (select round(sum(bytes)/1024/1024/1024) bytes,segment_name,owner from dba_segments group by segment_name ,owner having round(sum(bytes)/1024/1024/1024)>=2) a,dba_segments b,(select owner,table_name from dba_tables where partitioned='NO') c where a.segment_name=b.segment_name and a.owner=b.owner and b.segment_type='TABLE' and b.owner=c.owner and b.segment_name=c.table_name order by 3 desc; 
prompt
prompt
prompt '************************'
prompt '********Level>3*********'
prompt '************************'
prompt '34,INDEX LEVEL > 3:'
select owner,table_name,index_name,blevel from dba_indexes where blevel>3;
prompt
prompt
prompt '************************'
prompt '****UNUSABLE INDEXES****'
prompt '************************'
prompt '35,UNUSABLE INDEXES:'
col index_owner format a12;
col index_name format a30;
col index_type format a20;

select owner index_owner,
       index_name,
       index_type,
       'N/A' partition_name,
       'N/A' subpartition_name,
       status,
       table_name,
       tablespace_name
  from dba_indexes
 where status = 'UNUSABLE'
union all
select a.index_owner,
       a.index_name,
       b.index_type,
       a.partition_name,
       'N/A' subpartition_name,
       a.status,
       b.table_name,
       a.tablespace_name
  from dba_ind_partitions a, dba_indexes b
  where a.index_name = b.index_name
   and a.index_owner = b.owner
   and a. status = 'UNUSABLE'
union all
select a.index_owner,
       a.index_name,
       b.index_type,
       a.partition_name,
       a.subpartition_name,
       a.status,
       b.table_name,
       a.tablespace_name
  from dba_ind_subpartitions a, dba_indexes b
 where a.index_name = b.index_name
   and a.index_owner = b.owner
   and a. status = 'UNUSABLE';


prompt
prompt '************************'
prompt '*UNSYSTEM OBJ IN SYSTEM*'
prompt '************************'
prompt '37,UNSYSTEM OBJ IN SYSTEM:'
col tablespace_name format a25;
col segment_name format a40;
col owner format a20;
select owner,segment_name,replace(segment_type,' ','') segment_type,ceil(bytes/1024/1024/1024) "SIZE(G)",tablespace_name from dba_segments where tablespace_name='SYSTEM' and owner NOT in ('ORDSYS','WKSYS','WK_TEST','SYS','SYSTEM','SYSMAN','DBSNMP','ANONYMOUS','CTXSYS','OLAPSYS','WMSYS','OUTLN','XDB','CTXSYS','MDSYS','EXFSYS');
prompt
prompt
prompt '************************'
prompt '**INVALID CONSTRAINTS***'
prompt '************************'
prompt '38,INVALID CONSTRAINTS:'
select owner,constraint_name,constraint_type,table_name from dba_constraints where status='DISABLED' and owner NOT IN ('SYS','SYSTEM');
prompt
prompt
prompt '************************'
prompt '****INVALID TRIGGERS****'
prompt '************************'
prompt '39,INVALID TRIGGERS:'
column TRIGGERING_EVENT for a35
select OWNER,TRIGGER_NAME,TRIGGER_TYPE,replace(TRIGGERING_EVENT,' ','.') TRIGGERING_EVENT,replace(BASE_OBJECT_TYPE,' ','.') BASE_OBJECT_TYPE from dba_triggers where status='DISABLED' and owner NOT IN ('SYS','SYSTEM');
prompt
prompt
prompt '************************'
prompt '*****INVALID OBJECTS****'
prompt '************************'
prompt '40,INVALID OBJECTS:'
col owner format a15;
col object_name format a30;
col object_type format a20;
select owner,object_name,object_type from dba_objects where status='INVALID' and rownum<=20 ORDER BY OWNER;

prompt
prompt
prompt '******************************************'
prompt '*************User defination**************'
prompt '******************************************'
prompt '************************'
prompt '*******USER INFO********'
prompt '************************'
prompt '41,USER INFO:'
col username format a19;
col status format a18;
col temporary_tablespace format a20;
col profile format a20;
select username,replace(account_status,' ','') status,default_tablespace,temporary_tablespace,profile, initial_rsrc_consumer_group from dba_users where account_status='OPEN';
prompt
prompt
prompt '************************'
prompt '*******USER PROFILE********'
prompt '************************'
prompt '42,USER PROFILE:'
col limit format a12;
col profile format a22;
select profile,resource_name,resource_type,limit from dba_profiles;
prompt
prompt
prompt '************************'
prompt '******SUPPER USERS******'
prompt '************************'
prompt '43,SUPER USERS:'
col sysdba format a10
col sysoper format a10
select * from v$pwfile_users order by 1;
prompt
prompt
prompt '************************'
prompt '*******DBA PRIVS********'
prompt '************************'
prompt '44,DBA PRIVS:'
col GRANTEE format a19;
col GRANTED_ROLE format a20;
select a.* from dba_role_privs a ,dba_users b where b.username=a.grantee and b.account_status='OPEN' and a.granted_role in ('DBA','SYSDBA','SYSOPER','EXP_FULL_DATABASE','DELETE_CATALOG_ROLE') order by a.GRANTED_ROLE;
prompt '************************'
prompt '*******SYS PRIVS********'
prompt '************************'
prompt '45,SYS PRIVS:'
col GRANTEE format a30;
col privilege format a30;
select GRANTEE,replace(PRIVILEGE,' ','.') PRIVILEGE,ADMIN_OPTION from 
(select a.* from dba_sys_privs a,dba_users b where ((a.grantee=b.username and b.account_status='OPEN') ) and (a.privilege like '%ANY%' OR a.PRIVILEGE IN('ALTER SYSTEM','ALTER DATABASE','DROP USER')) and a.grantee not in ('SYS','SYSMAN','SYSTEM')
union
select a.* from dba_sys_privs a,dba_roles c where (a.grantee=c.role ) and (a.privilege like '%ANY%' OR a.PRIVILEGE IN('ALTER SYSTEM','ALTER DATABASE','DROP USER')) and a.grantee not in ('JAVADEBUGPRIV','OLAP_DBA','SCHEDULER_ADMIN','DBA','IMP_FULL_DATABASE','AQ_ADMINISTRATOR_ROLE','EXP_FULL_DATABASE','OEM_MONITOR') )
order by 1,2;
prompt
prompt
prompt '************************'
prompt '******OBJECT PRIVS******'
prompt '************************'
prompt '46,OBJECT PRIVS:'
col GRANTEE format a19;
col privilege format a30;
col table_owner format a15;
select * from (SELECT grantee,owner table_owner,table_name,privilege FROM DBA_TAB_PRIVS WHERE GRANTEE<>OWNER AND GRANTEE not in ('SYS','PUBLIC','SYSTEM','WMSYS','SYSMAN','DBSNMP') and GRANTEE NOT IN
(SELECT ROLE FROM DBA_ROLES) and grantee in(select username from dba_users where account_status='OPEN')) where rownum<10;
prompt
prompt
prompt '*********************************************************************'
prompt '*******AUTO STATISTICS GATHER,etc     *******************************'
prompt '*********************************************************************'


prompt '************************'
prompt '******DB STATISTICS*****'
prompt '************************'
prompt '47,DB STATS GATHER MODE:'
col stats_level format a20;
col gather_mode format a20;
select value stats_level,decode(value,'BASIC','NO','YES') gather_mode from v$parameter where name='statistics_level';


prompt '48,DB STATS AUTO GATHER:'
select client_name,status from dba_autotask_client;

prompt '**********AUTOTASK NEXT TIME WINDOW**********************************************************'
prompt '49, DB STATS AUTOTASK WINDOW:'
select window_name,window_next_time,autotask_status from dba_autotask_window_clients;

prompt '**********AWR SNAPSHOT KEEP TIME   **********************************************************'
prompt '50,AWR SNAPSHOT KEEP TIME:'
select
       extract( day from snap_interval) *24*60+
       extract( hour from snap_interval) *60+
       extract( minute from snap_interval ) "Snapshot Interval",
       (extract( day from retention) *24*60+
       extract( hour from retention) *60+
       extract( minute from retention ))/60/24 "Keep days"
from dba_hist_wr_control;



spool off
exit
