--author¿dabingruien@msn.com
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
--2021.06.08. add parameter modification history


spool oracle_rac_healthcheck.out

set pagesize 9999
set linesize 999
set long 9999
set echo off
set termout off

alter session set nls_language=american;


prompt '*********************************************************************'
prompt '*****************************Top Danagers*******************************'
prompt '*********************************************************************'
prompt '1,Object id upper limit:'
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
select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') check_date from dual;
prompt 
prompt
prompt '*********************************************************************'
prompt '****************************DB OUTLINE*******************************'
prompt '*********************************************************************'
prompt '1,DB NAME:'
col instance_name format a10;
col db_name format a10;
select name db_name,log_mode,PROTECTION_LEVEL,CREATED from v$database;
prompt
prompt
prompt '2,DB SIZE(G):'
select  c.sum3 "DMP size(G)",a.sum1 "RMAN BACKUPSET SIZE(G)",b.sum2 "DATAFILE SIZE(G)" from (SELECT ceil(SUM(BYTES)/1024/1024/1024) sum1 FROM DBA_segments ) a,(select ceil(sum(bytes)/1024/1024/1024) sum2 from v$datafile) b,(select ceil(sum(bytes)/1024/1024/1024) sum3 from dba_segments where segment_type not like 'INDEX%' and segment_type not in('ROLLBACK','CACHE','LOBINDEX','TYPE2 UNDO')) c ;
prompt
prompt
prompt '3,CHARACTSET AND NLS PARAMETERS:'
col value$ format a35;
col name format a35;
select name,value$ from sys.props$ where name in('NLS_TERRITORY','NLS_LANGUAGE','NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET');
prompt
prompt
prompt '4,COUNT OF TABLESPACE AND DATAFILE:'
select b.sum2 "CNT OF TABLESPACE",a.sum1 "CNT OF DATAFILE",c.sum3 "CNT OF TEMPFILE" from (select count(1) sum1 from v$datafile) a, (select count(1) sum2 from v$tablespace )b, (select count(1) sum3 from v$tempfile) c ;
prompt
prompt
prompt '5,TOP PARAMETERS:'
col value format a45;
col name format a35;
select trim(INST_ID) inst_id,name ,value from gv$parameter where name 
in('cpu_count' ,'sga_target','db_cache_size','db_2k_cache_size','db_4k_cache_size','db_8k_cache_size','db_16k_cache_size','db_32k_cache_size',
'shared_pool_size','large_pool_size','java_pool_size','log_buffer','pga_aggregate_target','sort_area_size','db_block_buffers','db_block_size','optimizer_mode','cursor_sharing','optimizer_index_cost_adj','optimizer_index_caching','db_file_multiblock_read_count','hash_join_enabled');
prompt
prompt
prompt '6,SYSTEM WAIT STATS:'
select * from gv$waitstat order by time;
prompt
prompt
prompt '8,SESSION STATS:'
col inst_id format 99;
--col inst_id format a10;
select a.inst_id inst_id,a.sum1 "CURRENT CNT OF SESSIONS", b.sum2 "CONCURRENT SESSIONS"  from (select inst_id, count(*) sum1  from gv$session     where username is not null   group by inst_id) a,       (select inst_id, count(*) sum2     from gv$session   where username is not null and status = 'ACTIVE'  group by inst_id) b  where a.inst_id=b.inst_id order by 1;
select * from gv$license;
prompt
prompt
prompt '*********************************************************************'
prompt '********************* DB CONFIGURATION*******************************'
prompt '*********************************************************************'
prompt '******************************************'
prompt '*********************DB*******************'
prompt '******************************************'
select DBID,NAME,CREATED,LOG_MODE,PROTECTION_MODE,FORCE_LOGGING,FLASHBACK_ON FROM V$DATABASE;
prompt
prompt
prompt '******************************************'
prompt '****************DB VERSION****************'
prompt '******************************************'
select * from v$version;
prompt
prompt
prompt '******************************************'
prompt '***************COMP STATUS****************'
prompt '******************************************'
col comp_id format a10;
col comp_name format a35;
col version format a15;
col status format a8;
col modified format a30;
select comp_id,replace(comp_name,' ','.') comp_name,version,status,replace(replace(modified,' ',':'),'-','/') modified from dba_registry;
prompt
prompt
prompt '******************************************'
prompt '************DB INIT PARAMETERS************'
prompt '******************************************'
col value format a58;
col name format a30;
col trim(num) format a10;
select trim(inst_id) inst_id,trim(num),name,replace(value,' ','') value,ismodified,isadjusted from gv$parameter where isdefault='FALSE' order by 1,2;
prompt
prompt

prompt '******************************************'
prompt '************DB INIT PARAMETERS MODIFY HISTORY************'
prompt '******************************************'
WITH all_parameters AS
 (SELECT snap_id,
         dbid,
         instance_number,
         parameter_name,
         value,
         isdefault,
         ismodified,
         lag(value) OVER(PARTITION BY dbid, instance_number, parameter_hash ORDER BY snap_id) prior_value
    FROM dba_hist_parameter)
SELECT TO_CHAR(s.begin_interval_time, 'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(s.end_interval_time, 'YYYY-MM-DD HH24:MI') end_time,
       p.snap_id,
       p.dbid,
       p.instance_number,
       p.parameter_name,
       p.value,
       p.isdefault,
       p.ismodified,
       p.prior_value
  FROM all_parameters p, dba_hist_snapshot s
 WHERE p.value != p.prior_value
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number
 ORDER BY s.begin_interval_time DESC,
          p.dbid,
          p.instance_number,
          p.parameter_name;

prompt
prompt
prompt '******************************************'
prompt '************DB RESOURCE LIMITS************'
prompt '******************************************'
col RESOURCE_NAME format a30;
col CURRENT_UTILIZATION format a10;
col MAX_UTILIZATION format a10;
col INITIAL_ALLOCATION format a10;
col LIMIT_VALUE format a10;
 select trim(inst_id) inst_id,trim(RESOURCE_NAME) RESOURCE_NAME,trim(CURRENT_UTILIZATION) CURRENT_UTILIZATION,trim(MAX_UTILIZATION) MAX_UTILIZATION,trim(INITIAL_ALLOCATION) INITIAL_ALLOCATION,trim(LIMIT_VALUE) LIMIT_VALUE from gv$resource_limit;
prompt
prompt
prompt '******************************************'
prompt '************Physical structure************'
prompt '******************************************' 
prompt '************************'
prompt '******CONTROLFILE*******'
prompt '************************'
col name format a60
select status,name from v$controlfile;
select type,record_size,records_total,records_used from v$controlfile_record_section;

prompt
prompt
prompt '************************'
prompt '********LOGFILE*********'
prompt '************************'
col member format a70;
col thread# format a7
col group# format a8;
select trim(a.thread#) thread#,trim(a.group#) group#,b.member member,a.status status,a.bytes/1024/1024 "size(M)" from v$log a,v$logfile b where a.group#=b.group#;
prompt
prompt
col thread# format 999 
prompt 'ARCHIVELOG STATUS:'
select a.f_time "DATE",
       a.thread#,
       ceil(sum(a.blocks * a.block_size) / 1024 / 1024 / 1024) "ARCHIVELOGS PER DAY(G)",
       ceil(sum(a.blocks * a.block_size) / 1024 / 1024 / 24) "ARCHIVELOGS PER HOUR(M)"
  from (select distinct sequence#,
                        thread#,
                        blocks,
                        block_size,
                        to_char(first_time, 'yyyy/mm/dd') f_time
          from v$archived_log) a
 group by a.f_time, a.thread#
 order by 3 desc;
prompt
prompt
COL THREAD# OFF;
select to_char(first_time,'yyyy/mm/dd hh24') "DATE",thread#,count(1) "ARCHIVELOGS OF RUSH HOUR" from v$log_history where trunc(first_time) in (select d_time from (select max(count(1)) m_arch from v$log_history group by trunc(first_time)) a,(select trunc(first_time) d_time,count(1) d_arch from v$log_history group by trunc(first_time)) b where a.m_arch=b.d_arch) group by to_char(first_time,'yyyy/mm/dd hh24'),thread# order by 3 desc ,thread#,1 ;
prompt
prompt
prompt '************************'
prompt '*******DATAFILE*********'
prompt '************************'
col tablespace_name format a25;
col file_id format a8;
col file_name format a60;
select trim(a.file_id) "FILE_ID",b.tablespace_name "TABLESPACE_NAME",b.status "TABLESPACE_STATUS",a.file_name "FILE_NAME",a.status "FILE_STATUS",ceil(a.bytes/1024/1024/1024) "FILE_SIZE(G)",a.AUTOEXTENSIBLE "AUTOEXTENSIBLE",ceil(a.MAXBYTES/1024/1024/1024) "MAX_SIZE(G)" from dba_data_files a,dba_tablespaces b where a.tablespace_name=b.tablespace_name  order by a.AUTOEXTENSIBLE desc,a.file_id;

prompt
prompt
prompt '************************'
prompt '********TEMPFILE********'
prompt '************************'
col tablespace_name format a25;
col file_id format a8;
select trim(a.file_id) "FILE_ID",b.tablespace_name "TABLESPACE_NAME",b.status "TABLESPACE_STATUS",a.file_name "FILE_NAME",a.status "FILE_STATUS",ceil(a.bytes/1024/1024/1024) "FILE_SIZE(G)",a.AUTOEXTENSIBLE "AUTOEXTENSIBLE",ceil(a.MAXBYTES/1024/1024/1024) "MAX_SIZE(G)" from dba_temp_files a,dba_tablespaces b where a.tablespace_name=b.tablespace_name  order by a.AUTOEXTENSIBLE desc,a.file_id;

prompt
prompt
prompt '************************'
prompt '****INVALID DATAFILE****'
prompt '************************'
col file_id format a8;
col file_name format a45;
--select trim(f.FILE#) "FILE_ID",f.name "FILE_NAME",f.status "STATUS",f.bytes/1024/1024/1024 "FILE_SIZE(G)",t.name tablespace_name from v$datafile f,v$tablespace t where f.ts#=t.ts# and  (status<>'ONLINE'  AND status<>'SYSTEM' )or  enabled<>'READ WRITE';
select trim(f.FILE#) "FILE_ID",f.name "FILE_NAME",f.status "STATUS",f.bytes/1024/1024/1024 "FILE_SIZE(G)",t.name tablespace_name from v$datafile f,v$tablespace t, v$database d where f.ts#=t.ts# and  (status<>'ONLINE'  AND status<>'SYSTEM' )or  (enabled<>'READ WRITE' and d.database_role = 'PRIMARY');


prompt
prompt
prompt '******************************************'
prompt '***************Tablespaces****************'
prompt '******************************************'
prompt '************************'
prompt '***TABLESPACE FRAGMENT**'
prompt '************************'
select a.tablespace_name ,count(1) "AMOUNT OF FRAGMENT" from dba_free_space a,dba_tablespaces  b where a.tablespace_name=b.tablespace_name and b.EXTENT_MANAGEMENT='DICTIONARY' group by a.tablespace_name having count(1) >20 order by 2;
prompt 'script of eliminating fragment'
select 'alter tablespace '||tablespace_name||' coalesce;' from dba_tablespaces where EXTENT_MANAGEMENT='DICTIONARY';


prompt
prompt
prompt '************************'
prompt '***DISKGROUP MONITOR***'
prompt '************************'
col name for a12

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
select * from (
select a.snap_id,c.tablespace_name ts_name,to_char(to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss'),'mm/dd hh24') snap_time ,
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
where a.snap_id=b.snap_id and a.tablespace_id = b.tablespace_id and a.tablespace_id=d.ts# and d.name=c.tablespace_name
        and to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss') >= sysdate-30 and c.contents='PERMANENT'
order by a.tablespace_id,to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss') desc) where rownum <= 60;


prompt
prompt
prompt '************************'
prompt '*****BIG SEGMENTS ******'
prompt '************************'
col owner format a20;
col segment_name format a35;
col partition_name format a35;
col segment_type format a15;
col tablespace_name format a20;

select owner,segment_name,partition_name,segment_type,tablespace_name,trunc(bytes/1024/1024) sizeM,sysdate v_date  from dba_segments where trunc(bytes/1024/1024)>100 order by 6 desc ;

prompt
prompt
prompt '******************************************'
prompt '************Rollback Segments*************'
prompt '******************************************'
prompt '************************'
prompt '**UNDO SEGMENT MONITOR**'
prompt '************************'

col usn format a8;
col name format a25
select trim(a.usn) usn, a.name, b.status,b.xacts, (b.rssize+8192)/1024/1024 Ssize, b.extents, b.optsize/1024/1024 OPT,b.hwmsize/1024/1024 HWM,b.aveactive/1024/1024 AVE from v$rollname a, v$rollstat b where a.usn<>0 and a.usn=b.usn  order by 1;
select sum(gets),sum(waits),sum(waits)/sum(gets)*100 ratio from v$rollstat ;

prompt
prompt
prompt '******************************************'
prompt '****Tables/Indexes/Constraints/Triggers***'
prompt '******************************************'
prompt '************************'
prompt '******DB STATISTICS*****'
prompt '************************'
col stats_level format a20;
col gather_mode format a20;
select value stats_level,decode(value,'BASIC','NO','YES') gather_mode from v$parameter where name='statistics_level';

prompt '*********************************************************************'
prompt '*******AUTO STATISTICS GATHER,etc     *******************************'
prompt '*********************************************************************'
select client_name,status from dba_autotask_client;

prompt '**********AUTOTASK NEXT TIME WINDOW**********************************************************'
select window_name,window_next_time,autotask_status from dba_autotask_window_clients;

prompt '**********AWR SNAPSHOT KEEP TIME   **********************************************************'
select
       extract( day from snap_interval) *24*60+
       extract( hour from snap_interval) *60+
       extract( minute from snap_interval ) "Snapshot Interval",
       (extract( day from retention) *24*60+
       extract( hour from retention) *60+
       extract( minute from retention ))/60/24 "Keep days"
from dba_hist_wr_control;


prompt
prompt '************************'
prompt '*****CHAINED TABLES*****'
prompt '************************'
select owner,table_name,chain_cnt from dba_tables where chain_cnt>0 order by 3 desc;
prompt                                                              
prompt                                                              
prompt '************************'                                   
prompt '*>2G UNPARTITIONED TABS*'                                   
prompt '************************'                                   
select /*+rule*/a.owner,a.segment_name,a.bytes "SIZE(G)" from (select round(sum(bytes)/1024/1024/1024) bytes,segment_name,owner from dba_segments group by segment_name ,owner having round(sum(bytes)/1024/1024/1024)>=2) a,dba_segments b,(select owner,table_name from dba_tables where partitioned='NO') c where a.segment_name=b.segment_name and a.owner=b.owner and b.segment_type='TABLE' and b.owner=c.owner and b.segment_name=c.table_name order by 3 desc; 
prompt
prompt
prompt '************************'
prompt '********Level>3*********'
prompt '************************'
select owner,table_name,index_name,blevel from dba_indexes where blevel>3;
prompt
prompt
prompt '************************'
prompt '****UNUSABLE INDEXES****'
prompt '************************'
col index_owner format a12;
col index_name format a30;
col index_type format a20;
select owner index_owner,      index_name,index_type, 'N/A' partition_name,status ,table_name, tablespace_name from dba_indexes where status='UNUSABLE'
union all
select a.index_owner,          a.index_name,b.index_type,      a.partition_name, a.status ,        b.table_name, a.tablespace_name from dba_ind_partitions a, dba_indexes b where a.index_name=b.index_name and a.index_owner=b.owner and a.status='UNUSABLE';
prompt
prompt
prompt '************************'
prompt '**TAB,IDX IN SAME SPACE*'
prompt '************************'
select tab.owner,tab.table_name,idx.index_name,tab.tablespace_name from dba_tables tab,dba_indexes idx where tab.owner=idx.table_owner and tab.table_name=idx.table_name and tab.tablespace_name=idx.tablespace_name and tab.owner not in('WKSYS','WK_TEST','EXFSYS','SYS','SYSTEM','SYSMAN','DBSNMP','ANONYMOUS','CTXSYS','OLAPSYS','WMSYS','OUTLN','XDB','CTXSYS','MDSYS') and rownum<101;
prompt
prompt
prompt '************************'
prompt '*UNSYSTEM OBJ IN SYSTEM*'
prompt '************************'
col tablespace_name format a25;
col segment_name format a40;
col owner format a20;
select owner,segment_name,replace(segment_type,' ','') segment_type,ceil(bytes/1024/1024/1024) "SIZE(G)",tablespace_name from dba_segments where tablespace_name='SYSTEM' and owner NOT in ('ORDSYS','WKSYS','WK_TEST','SYS','SYSTEM','SYSMAN','DBSNMP','ANONYMOUS','CTXSYS','OLAPSYS','WMSYS','OUTLN','XDB','CTXSYS','MDSYS','EXFSYS');
prompt
prompt
prompt '************************'
prompt '**INVALID CONSTRAINTS***'
prompt '************************'
select owner,constraint_name,constraint_type,table_name from dba_constraints where status='DISABLED' and owner NOT IN ('SYS','SYSTEM');
prompt
prompt
prompt '************************'
prompt '****INVALID TRIGGERS****'
prompt '************************'
column TRIGGERING_EVENT for a35
select OWNER,TRIGGER_NAME,TRIGGER_TYPE,replace(TRIGGERING_EVENT,' ','.') TRIGGERING_EVENT,replace(BASE_OBJECT_TYPE,' ','.') BASE_OBJECT_TYPE from dba_triggers where status='DISABLED' and owner NOT IN ('SYS','SYSTEM');
prompt
prompt
prompt '************************'
prompt '*****INVALID OBJECTS****'
prompt '************************'
col owner format a15;
col object_name format a30;
col object_type format a20;
select owner,object_name,object_type from dba_objects where status='INVALID' ORDER BY OWNER;

prompt
prompt
prompt '******************************************'
prompt '*************User defination**************'
prompt '******************************************'
prompt '************************'
prompt '*******USER INFO********'
prompt '************************'
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
col limit format a12;
col profile format a22;
select profile,resource_name,resource_type,limit from dba_profiles;
prompt
prompt
prompt '************************'
prompt '******SUPPER USERS******'
prompt '************************'
col sysdba format a10
col sysoper format a10
select * from v$pwfile_users order by 1;
prompt
prompt
prompt '************************'
prompt '*******DBA PRIVS********'
prompt '************************'
col GRANTEE format a19;
col GRANTED_ROLE format a20;
select a.* from dba_role_privs a ,dba_users b where b.username=a.grantee and b.account_status='OPEN' and a.granted_role in ('DBA','SYSDBA','SYSOPER','EXP_FULL_DATABASE','DELETE_CATALOG_ROLE') order by a.GRANTED_ROLE;
prompt '************************'
prompt '*******SYS PRIVS********'
prompt '************************'
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
col GRANTEE format a19;
col privilege format a30;
col table_owner format a15;
SELECT grantee,owner table_owner,table_name,privilege FROM DBA_TAB_PRIVS WHERE GRANTEE<>OWNER AND GRANTEE not in ('SYS','PUBLIC','SYSTEM','WMSYS') and GRANTEE NOT IN
(SELECT ROLE FROM DBA_ROLES) and grantee in(select username from dba_users where account_status='OPEN');
prompt
prompt
prompt
prompt
prompt '*********************************************************************'
prompt '*************************PERFORMANCE VIEW****************************'
prompt '*********************************************************************'
prompt
prompt '1,DATAFILE I/O:'
col name for a55
select substr(a.file#,1,2) "#", substr(a.name,1,50) "name",a.status,a.bytes/1024/1024 MBytes,b.phyrds,b.phywrts from v$datafile a,v$filestat b where a.file#=b.file# order by phywrts;

prompt '2,DB  Block  Buffer  Hit Ratio(Hit Ratio>95)'
select trim(a.inst_id) inst_id,a.value "physical reads",b.value "consistent gets",c.value "db block gets",100-a.value/(b.value+c.value)*100 "Hit Ratio" from gv$sysstat a,gv$sysstat b,gv$sysstat c where a.name='physical reads' and b.name='consistent gets' and c.name='db block gets'  and a.inst_id=b.inst_id and b.inst_id=c.inst_id order by 1;

prompt '3,Shared  Pool  Size  Execution Hit  Ratio(Lib hit Ratio>95 )'
SELECT trim(inst_id) inst_id,SUM(PINS) "EXECUTIONS", SUM(RELOADS) "CACHE MISSES WHILE EXECUTING",(1-sum(reloads)/sum(pins))*100 "Lib hit Ratio"  FROM gV$LIBRARYCACHE group by inst_id;

prompt '4,Shared  Pool  Size   Dictionary Hit Ratio (DIC hit Ratio>95 )'
SELECT trim(inst_id) inst_id,SUM(GETS) "DICTIONARY GETS",SUM(GETMISSES) "DICTIONARY CACHE GET MISSES",(1-sum(getmisses)/(sum(gets)+sum(getmisses)))*100 "DIC hit Ratio"  FROM gV$ROWCACHE group by inst_id;

prompt '5,ratio1<1,ratio2<1'
col name format a20;
SELECT trim(inst_id) inst_id,name, gets, misses, immediate_gets, immediate_misses, Decode(gets,0,0,misses/gets*100) ratio1, Decode(immediate_gets+immediate_misses,0,0, immediate_misses/(immediate_gets+immediate_misses)*100) ratio2 FROM gv$latch WHERE name IN ('redo allocation', 'redo copy'); 

prompt '6, ROLLSTAT'
col segment_name format a25;
select rb.segment_name,rb.INITIAL_EXTENT,rb.NEXT_EXTENT,rb.MIN_EXTENTS,rb.MAX_EXTENTS,rs.optsize,rb.tablespace_name,rs.status,ds.bytes/1024/1024 from dba_rollback_segs rb,v$rollstat rs,dba_segments ds where rb.segment_id=rs.usn and rb.segment_name=ds.segment_name;

prompt '7, TOP EVENT'
col event format a35;
SELECT trim(inst_id) inst_id,SEQ#,EVENT,SECONDS_IN_WAIT FROM gV$SESSION_WAIT WHERE EVENT NOT LIKE 'rdbms%' and event not like 'SQL%' order by 4;
SELECT trim(inst_id) inst_id,SEQ#,EVENT,SECONDS_IN_WAIT FROM gV$SESSION_WAIT WHERE EVENT NOT LIKE 'rdbms%' and event not like 'SQL%' order by 4;
SELECT trim(inst_id) inst_id,SEQ#,EVENT,SECONDS_IN_WAIT FROM gV$SESSION_WAIT WHERE EVENT NOT LIKE 'rdbms%' and event not like 'SQL%' order by 4;
SELECT trim(inst_id) inst_id,SEQ#,EVENT,SECONDS_IN_WAIT FROM gV$SESSION_WAIT WHERE EVENT NOT LIKE 'rdbms%' and event not like 'SQL%' order by 4;
SELECT trim(inst_id) inst_id,SEQ#,EVENT,SECONDS_IN_WAIT FROM gV$SESSION_WAIT WHERE EVENT NOT LIKE 'rdbms%' and event not like 'SQL%' order by 4;


prompt '8,LONGOPS OBJECTS'
select target,opname,count(*) cnt from v$session_longops group by target,opname order by cnt desc;

spool off
exit
