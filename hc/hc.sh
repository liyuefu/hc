#!/usr/bin/env bash

#############USAGE###########################
#change  ORACLE_SID,ORACLE_BASE,$ORACLE_HOME
#./hc.sh
#input awr report arguments
#collect the .out files, log file, html file.
##############################################
source ./lib/hclib.sh
source ~/.bash_profile

export LANG=en_US.UTF-8
unset LC_ALL
export CONN="/ as sysdba"
export SHELL_PATH="./hcscripts"
export PYTHON24_PATH="./linux5/autodoc_linux5.py"
export PYTHON2_PATH="./linux6/autodoc_linux6.py"
export PYTHON3_PATH="./linux7/autodoc_linux7.py"

export SQL_SCNCHECK="$SHELL_PATH/scnhealthcheck.sql"
export SQL_RMANSIZE="$SHELL_PATH/rmansize.sql"
export LINUX_SHELL="$SHELL_PATH/linux.sh"
export AUTODOC_SQL_FILE="$SHELL_PATH/autodoc.sql"
export GET_IP_LISTS="$SHELL_PATH/getip.sh"

export current_date=$(date +%Y-%m-%d-%H%M)
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss';

run_autodoc_py() {
  #check python version
  python $SHELL_PATH/getver.py $TMPDIR
  PYTHON_VER=`cat $TMPDIR/pyver.txt`
  if [ "$PYTHON_VER" \> "3" ]
  then
      msg_info "$0 does not support python3, please create softlink of  python to  python2.6 or 2.7"
      exit 1
  elif [ "$PYTHON_VER" \> "2.7" ]
  then
  # RHEL 7.x, python 2.7.?
      if [ $DBVER_MAJOR == "10g" ];then
  # maybe it's Oracle 10g, copy 10g linux7 version cx_Oracle.so to here
        cp ./10g/python27/cx_Oracle.so ./linux7/cx_Oracle.so
      fi
      USING_PYTHON=$PYTHON3_PATH 
  elif [ "$PYTHON_VER" \> "2.6" ]
  then
  #copy 10g linux6 version cx_Oracle.so to here
      if [ "$DBVER_MAJOR"x == "10g"x ];then
        cp ./10g/python26/cx_Oracle.so ./linux6/cx_Oracle.so
      fi
      USING_PYTHON=$PYTHON2_PATH 
  else
  #python is under 2.6. using python 2.4
      if [ $DBVER_MAJOR == "10g" ];then
        cp ./10g/python24/cx_Oracle.so ./linux5/cx_Oracle.so
      fi
      msg_info "Python version:$PYTHON_VER. Try to using python version 2.4... "
      USING_PYTHON=$PYTHON24_PATH 
  fi;
  msg_info "Python version: $PYTHON_VER..."
  #create word docx
  msg_info "Creating autodoc: python $USING_PYTHON $AUTODOC_SQL_FILE $ORACLE_HOME $IP .."
  python $USING_PYTHON $AUTODOC_SQL_FILE $ORACLE_HOME $DBVER_DETAIL $IP
  msg_info "Run python autodoc done."

}

#copy all the tmpfile,html, docx to $TMPDIR,and wrap them.
wrap_output() {
  OUTPUT=./output
  if [ ! -d $OUTPUT/using_script ];then
    mkdir -p $OUTPUT/using_script
  fi
  OUTPUTNAME="output_`hostname`_"$IP"_"$DBNAME"_"$ORACLE_SID"_""$current_date.tar.gz"
  msg_info "Healthcheck for DBNAME: $DBNAME, ORACLE_SID: $ORACLE_SID is done.outputfile is :$OUTPUTNAME"

  cp hc.sh config.ini ${USING_PYTHON} README* $OUTPUT/using_script
  mv -f *.out alert*.log autodoc*.log *.html *.docx *.txt *.tmp *.sql $OUTPUT >/dev/null 2>&1

  if [ ! -d old ]; then
    mkdir old
  fi
  mv output_*.tar.gz old
  tar -zvcf $OUTPUTNAME $OUTPUT
}

#check config.ini
if [ ! -f "./config.ini" ];then
  msg_error "NO config.ini, please check it under hcscripts directory."
  exit
else
  msg_ok "config.ini ok"
  
fi

chmod +x ./hcscripts/*.sh

get_dbinfo $ORACLE_HOME $SHELL_PATH/getdbinfo.sql.model $TMPDIR/getdbinfo.sql

if grep "ORACLE" $TMPDIR/dbname.txt; then
  msg_error "Error! Oracle is not started,start oracle first, and then run hc.sh"
  exit 1
fi

DBNAME=`cat $TMPDIR/dbname.txt`
DBVER_MAJOR=`cat $TMPDIR/dbver_major.txt`
DBVER_DETAIL=`cat $TMPDIR/version.txt`

#get ip list
IP=$($GET_IP_LISTS)
if [ "$IP"x == x ]; then
  msg_error "getip failed"
  IP="127.0.0.1"
else
  msg_info "ip list is :$IP"
fi

# get alert file  path
if [ $DBVER_MAJOR == "10g" ]; then
  msg_info "using autodoc sql autodoc_10g.sql" 
  ALERT_PATH="$ORACLE_BASE/diag/$DBNAME/bdump"
  export AUTODOC_SQL_FILE="$SHELL_PATH/autodoc_10g.sql"
else
  ALERT_PATH=$(sqlplus -S / as sysdba <<EOF
set heading off;
set termout off;
set echo off;
select trim(value) from v\$diag_info where name='Diag Trace';
EOF
)
fi

ALERT_FILE=$ALERT_PATH/"alert*.log"

#check  bitcoin ransomeware.
check_botcoin $ORACLE_HOME "$TMPDIR/bitcoin300.out" $DBNAME $DBVER_MAJOR $ALERT_FILE

#check hidden parameters using.
check_hidden_para $ORACLE_HOME "$TMPDIR/check_hidden_para.out"

#async check.
check_async $ORACLE_HOME "$TMPDIR/asynccheck.out"

#get scn number
$ORACLE_HOME/bin/sqlplus -s $CONN <<EOF  >$TMPDIR/scn.txt
start $SQL_SCNCHECK
EOF

msg_info "Run linux check"
$LINUX_SHELL

if [ ! -f  $ALERT_FILE ];then
  msg_info "$ALERT_FILE NOT FOUND. PLEASE FIND IT YOURSELF"
else
  cp $ALERT_FILE .
  msg_info "cp alert file: $ALERT_FILE  done."
fi

tail -n 100000 $ALERT_FILE|grep "^ORA-\|Error" -C10 > dberr.txt

#run python script to create word report.
run_autodoc_py 

#get lsnrctl status
msg_info "Run lsnrctl status..."
lsnrctl status > $TMPDIR/lsnrctl.out

#get rman backup info
get_rman_info $ORACLE_HOME $CONN $SQL_RMANSIZE
#create awr rpt
create_awr_rpt $ORACLE_HOME
#collect all report and tmp files to output.
wrap_output

msg_info "Run hc.sh on $IP done."
