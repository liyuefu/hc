col comp_id format a10;
col comp_name format a35;
col version format a15;
col status format a8;
col modified format a30;
select comp_id,replace(comp_name,' ','.') comp_name,version,status,replace(replace(modified,' ',':'),'-','/') modified from dba_registry;
