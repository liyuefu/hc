#!/usr/bin/env bash

declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source $DIR/lib/bsfl.sh
source $DIR/lib/ext_bsfl.sh


declare -x LOG_ENABLED="yes"
declare -x DEBUG="yes"
declare -x TMPDIR="$DIR"
declare -r TRUE=0
declare -r FALSE=1

#mkdir for temporary files used by autodg.
if [ ! -d $TMPDIR ]; then
  mkdir $TMPDIR
fi

####if not ends with / , output == ""
#### else  output != ""
check_path_ends_with_slash() {
  local parafile=$1

  #use sed to check if line end with / . / must be removed.
  slashline=$(sed -n '/\/$/p' $parafile)
#  echo $slashline
}

#### input a tmp file name $1, remove empty line and space, output text to a new text file $2.
get_one_row_data() {
  local tmpfile=$1
  newfile=$2
  if file_exists_and_not_empty $tmpfile; then
    grep -v ^$ $tmpfile |awk '{print $(NF)}' > $newfile
#    cat $newfile
  else
    echo ""
  fi
}

#### from all the datafile, get the data path ,unique them and save to newfile.
#### there maybe multiple rows
get_multiple_row_data() {
  local tmpfile=$1
  newfile=$2
  if file_exists_and_not_empty $tmpfile; then
    sed 's/\(.*\)\/.*/\1/' $tmpfile | sed '/^$/d' |sort -r|uniq > $newfile
    #取最后一个\前的所有字符, 最后一个\后的字符舍弃.然后去掉空行, 排序, 去重, 保存到newfile.
#    cat $newfile
  else
    echo ""
  fi
}

#### get diskgroup name from diskgroup filename. such as +data/asp/datafile/system01.dbf. return +data
get_diskgroup_name() {
  local tmpfile=$1
  newfile=$2
  awk -F'/' '{print $1}' $tmpfile | sort -r| uniq |grep -v ^$ > $newfile
#  cat $newfile
}


# get db_name, db_unique_name,domain, cluster etc.save to  tmpfile.
# $1: ORACLE_HOME
# $2 MODEL FILE absolute path
# $3 SQL FILE absolute path
# return : success 0, fail 1

get_dbinfo() {
local ORACLE_HOME=$1
local MODEL_FILE=$2
local SQL_FILE=$3
#sed  "s#TMPPATH#$TMPDIR#g" getdbinfo.sql.model >$TMPDIR/getdbinfo.sql
msg_info $MODEL_FILE $SQL_FILE
sed  "s#TMPPATH#$TMPDIR#g" $MODEL_FILE > $SQL_FILE
#get database info and save to TMPDIR
$ORACLE_HOME/bin/sqlplus -s / as sysdba @$SQL_FILE >/tmp/sqlplus.log 2>&1

if grep "ORACLE" $TMPDIR/dbname.tmp; then
  #oracle not started yet.
  msg_error "Primary ERROR: Oracle is not started,start oracle first"
  return 1
else
  format_dbinfo
  msg_ok "Get database info done."
  return 0
fi
}
#
#convert information from dbinfo to formatted txt file.
#
format_dbinfo(){
  get_one_row_data  $TMPDIR/dbname.tmp $TMPDIR/dbname.txt
  get_one_row_data  $TMPDIR/db_unique_name.tmp $TMPDIR/db_unique_name.txt
  get_one_row_data  $TMPDIR/cluster.tmp $TMPDIR/cluster.txt
  get_one_row_data  $TMPDIR/cluster_database_instances.tmp $TMPDIR/cluster_database_instances.txt
  get_one_row_data  $TMPDIR/domain.tmp $TMPDIR/domain.txt
  get_one_row_data  $TMPDIR/dbid.tmp $TMPDIR/dbid.txt
  get_one_row_data  $TMPDIR/version.tmp $TMPDIR/version.txt
  get_one_row_data  $TMPDIR/logsize.tmp $TMPDIR/logsize.txt
  get_multiple_row_data $TMPDIR/dbpath.tmp $TMPDIR/dbpath.txt
  get_multiple_row_data $TMPDIR/logpath.tmp $TMPDIR/logpath.txt
  cp $TMPDIR/logpath.txt $TMPDIR/addlogpath.txt

  cat $TMPDIR/banner.tmp |grep '^oracle database'| awk '{ print $3}' >$TMPDIR/dbver_major.txt
#  cat $TMPDIR/banner.tmp |grep '^oracle database'| awk '{ print $7}' >$TMPDIR/dbver_detail.txt
}

## can be used to : from primary datafile, makeup datafile convert string for primary and standby.
## can also be used to logfile 
#$1  pri_filename,contains all datafile/tempfile(/u02/oradata/orcl/system01.dbf).such as dbpath.tmp
#$2  string. dataguard datafile path, such as  '/u03/ordata/orcldg'
#$3  filename, contains primary's convert  string. '/u03/oradata/orcldg','/u02/oradata/orcl'
#$4  filename, contains dataguard's convert string. '/u02/oradata/orcl','/u03/orddata/orcldg'
makeup_file_convert() {
  local pri_filename=$1
  local dg_filepath=$2 
  pri_convert_path_file=$3
  dg_convert_path_file=$4

  file_exists_and_not_empty $pri_filename  || return $FALSE
#  cmd file_exists $pri_filename
  
  >pri_convert_path_file
  >dg_convert_path_file
  
  #remove duplicate line

  begin_str='"'
  middle_str='/","'
  end_str='/",'
  cat $pri_filename | while read pri_filepath
  do
    dg_add_path=${begin_str}${pri_filepath}${middle_str}${dg_filepath}${end_str}
    echo $dg_add_path>>$dg_convert_path_file
    pri_add_path=${begin_str}${dg_filepath}${middle_str}${pri_filepath}${end_str}
    echo $pri_add_path>>$pri_convert_path_file
  done
  return $TRUE
}

# convert from multiple line file into one line file
# can not put file_exists_and_not_empty in if [] . only call in this way:  file... &&, or  || . 
makeup_convert_oneline() {
  file_exists_and_not_empty  $1  || return $FALSE
  sed -n -e 'H;${x;s/\n//g;p;}' $1 > $2
  #this sed line put all the convert path into oneline. remove the newline characters.
  sed -i 's/,$//' $2
  #remove the last comma ,
  return $TRUE
}

#create awr report
#$1 ORACLE_HOME
create_awr_rpt() {
  msg_info "begin create_awr_rpt "
  ORACLE_HOME=$1
  m=`$ORACLE_HOME/bin/sqlplus -S <<EOF /nolog
  conn / as sysdba;
  set heading off;
  select max(snap_id) from dba_hist_snapshot;
EOF` 
  start=$((m-1))
  stop=$((m))

  $ORACLE_HOME/bin/sqlplus -S <<EOF /nolog >>$TMPDIR/awr_html.out
  conn / as sysdba
  @?/rdbms/admin/awrrpt.sql;
  html
  1
  ${start}
  ${stop}
  $ORACLE_SID.html
EOF
  # done
}

# get rman backup size.show rman backup info.
# $1: ORACLE_HOME, 
# $2: connect string 
# $3: the sql script to run.
get_rman_info() {
  local ORACLE_HOME=$1
  local CONN=$2
  local SQL_RMANSIZE=$3

  $ORACLE_HOME/bin/sqlplus -s $CONN <<EOF >$TMPDIR/rman.out
  archive log list;
  exit;
EOF
  rman  <<EOF >>$TMPDIR/rman.out
  connect  target /
  show all;
  list backup summary;
  list backup;
  report obsolete;
EOF

  msg_info "check rmansize info..."
  sqlplus -s $CONN <<EOF >$TMPDIR/rmansize.out
  start $SQL_RMANSIZE
EOF

}

# check bitcoin attach
# $1 ORACLE_HOME
# $1 output check result
# $2 dbname
# $3 db verision major, such as 10g,11g
# $4 alert file absolute path, such as /u01/app/oracle/diag/rdbms/admin/orcl/orcl/trace/alert.log
check_botcoin() {
  local CHECK_TIME=`date +%Y%m%d_%H%M`
  local ORACLE_HOME=$1
  local CHECK_FILE=$2
  local DBNAME=$3
  local DBVER=$4
  local ALERT_FILE=$5

  msg_info "check BIT_COIN_300DAYS ATTACK..."

  #DBVER=`cat /tmp/dbver.txt`

  # if [ ${DBVER} == '10g' ]; then
  #    DBNAME=`cat /tmp/dbname.txt`
  #    ALERT_PATH=$ORACLE_BASE/diag/rdbms/$DBNAME/$ORACLE_SID/trace
  # else
  #    ALERT_PATH=$(sqlplus -S / as sysdba <<EOF
  # set heading off;
  # set termout off;
  # set echo off;
  # select trim(value) from v\$diag_info where name='Diag Trace';
  # EOF
  # )
  # fi
  # ALERT_FILE=${ALERT_PATH}/alert_$ORACLE_SID.log

  $ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF > ${CHECK_FILE}
  !echo '(1):select statement for check attack dba_objects view'  
  COL OWNER FOR A20
  COL OBJECT_NAME FOR A80
  COL OBJECT_TYPE FOR A10
  COL SQL_STATMENT FOR A180
  SET LINE 200 PAGES 99
  SELECT OWNER, '"'||OBJECT_NAME||'"' OBJECT_NAME,OBJECT_TYPE,TO_CHAR(CREATED, 'YYYY-MM-DD HH24:MI:SS') CREATED
      FROM DBA_OBJECTS
      WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
      OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
      OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
      OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';
      
  !echo '(2):drop  statement for check attack dba_objects view' 
  SELECT '    DROP '||OBJECT_TYPE||' "'||OWNER||'"."'||OBJECT_NAME||'";' SQL_STATMENT
      FROM DBA_OBJECTS
      WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
      OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
      OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
      OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';

  !echo '(3):select statement for check attack dba_jobs view'
  COL LOG_USER FOR A20
  COL WHAT FOR A120
  SELECT JOB, LOG_USER, WHAT 
      FROM DBA_JOBS
      WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;
      
  !echo '(4):drop job  statement for check attack dba_jobs view'
  SELECT '    -- Logon with '||LOG_USER||CHR(10)||'    EXEC DBMS_JOB.BROKEN ('||JOB||', ''TRUE'')'||CHR(10)||'    EXEC DBMS_JOB.REMOVE('||JOB||')' SQL_STATMENT
    FROM DBA_JOBS
    WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;

  !echo '(5):check 300 day delete tab$'
  SELECT 'DROP PROCEDURE '||OWNER||'."'||OBJECT_NAME||'";' 
  FROM DBA_OBJECTS WHERE OBJECT_NAME ='DBMS_SUPPORT_DBMONITORP' 
  UNION ALL SELECT 'DROP TRIGGER '||OWNER||'."'||TRIGGER_NAME||'";' 
  FROM DBA_TRIGGERS WHERE TRIGGER_NAME ='DBMS_SUPPORT_DBMONITOR';

  EXIT;  
EOF

  value1=`grep -i "Hi buddy, your database was hacked by SQL RUSH Team, send 5 bitcoin to address" ${ALERT_FILE}|wc -l`
  value2=`grep -i "INTERNAL" ${CHECK_FILE}|wc -l`
  if [ $value1 -ge 1 ]
  then
     echo "YES bit attack database"
  elif [ $value2 -ge 1 ]
  then 
     echo "##########################################!!!!!!!!##################">>${CHECK_FILE}
     echo "!!!!!!!!!!!!!!!!YES bit attack database!!!!!!!!!!!!!!!!"
     echo "YES BITCOIN attack database!!!!!!!!!!!!!!">>${CHECK_FILE}
     echo "##########################################!!!!!!!!##################">>${CHECK_FILE}
  else
     echo "---------------------------------------"
     echo "NO bit attack database"
     echo "---------------------------------------">>${CHECK_FILE}
     echo "NO bit attack database">>${CHECK_FILE}

  fi
  #grep -i 'Hi buddy, your database was hacked by SQL RUSH Team, send 5 bitcoin to address' ${ALERT_FILE} >> ${CHECK_FILE}

  value=`grep -i "create or replace trigger DBMS_SUPPORT_DBMONITOR" $ORACLE_HOME/rdbms/admin/prvtsupp.plb|wc -l `
  if [ $value -ge 1 ]
  then
     echo "!!!!!!!!!!!!!!!!YES 300 day del \$tab attach database!!!!!!!!!!!!!"
     echo "##########################################!!!!!!!!##################"
     echo "##########################################!!!!!!!!##################">>${CHECK_FILE}
     echo "YES 300DAY del \$tab attach database!!!!!!!!!!!!!">>${CHECK_FILE}
     echo "change $ORACLE_HOME/rdbms/admin/prvtsupp.plb!!!!!">> ${CHECK_FILE} 
  else
     echo "---------------------------------------"
     echo "NO 300 day del \$tab attach database" 
     echo "---------------------------------------">>${CHECK_FILE}
     echo "NO 300 day del \$tab attach database" >>${CHECK_FILE}

  fi

}

# check hidden parameters set.
# $1 ORACLE_HOME
# $2 output file name
check_hidden_para() {
  msg_info "check hidden parameters..."

  ORACLE_HOME=$1
  OUTPUT_FILE=$2
  $ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF > $OUTPUT_FILE
  set linesize 150
  set pagesize 99
  set feedback off
  col name for a40
  col value for a20
  select x.ksppinm  name, y.ksppstvl  value, y.ksppstdf  isdefault, decode(bitand(y.ksppstvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE')  ismod, decode (bitand(y.ksppstvf,2),2,'TRUE','FALSE')     isadj from sys.x\$ksppi x, sys.x\$ksppcv y where x.inst_id = userenv('Instance') and y.inst_id = userenv('Instance') and x.indx = y.indx  and  x.ksppinm in ('_optimizer_use_feedback','_use_adaptive_log_file_sync','_optim_peek_user_binds','_optimizer_extended_cursor_sharing_rel','_optimizer_extended_cursor_sharing','_optimizer_adaptive_cursor_sharing','_in_memory_undo','_memory_imm_mode_without_autosga','_b_tree_bitmap_plans','_gc_policy_time')   order by translate(x.ksppinm, ' _', ' ');

  exit;
EOF

}
