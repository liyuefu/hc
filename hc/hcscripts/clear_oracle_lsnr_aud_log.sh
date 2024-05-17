#!/usr/bin/env bash
##backup listener log in trace and alert directory and compress them.
##clear audit files before KEEP_AUDIT_DAYS days.
##ver 2023.03.03.1017.

source ~/.bash_profile

export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
KEEP_AUDIT_DAYS=365
WORKDIR=$PWD

if [ ! -f "/tmp/dbver.txt" ]; then
  sqlplus -s $CONN <<EOF 
start "./hcscripts/getdbver.sql"
EOF
fi

DBVER=`cat /tmp/dbver.txt`
LISTENER_ALERT_PATH=$(dirname $(lsnrctl status | awk ' /^Listener Log File/  { print $4} '))

if [ $DBVER = "10g" ]; then
  LISTENER_TRACE_PATH=$(dirname $LISTENER_ALERT_PATH)/log
else
  LISTENER_TRACE_PATH=$(dirname $LISTENER_ALERT_PATH)/trace
fi

TODAY=$(date  +"%y-%m-%d_%H_%M_%S")
LOG_ENABLED="yes"

echo "$TODAY clear listener logs: $LISTENER_ALERT_PATH, $LISTENER_TRACE_PATH. "
if [ $DBVER != "10g" ]; then
  cd $LISTENER_ALERT_PATH
  ls log_*.xml >/dev/null 2>/dev/null && mkdir  bak_$TODAY && mv log_*.xml bak_$TODAY && tar czf bak_$TODAY.tar.gz bak_$TODAY
  if [ $? -eq 0 ]; then
      rm -rf bak_$TODAY
      MSG="compress xml log done."
  else
      MSG="no xml log to compress. or compress xml log failed."
  fi
  cd $WORKDIR;echo "$MSG"
fi

cd $LISTENER_TRACE_PATH
cp listener.log  bak_$TODAY.log
if [ $? -eq  0 ]; then
    > listener.log
    gzip bak_$TODAY.log
    MSG=" compress listener.log done"
else
    MSG="cp listener.log failed. "
fi

cd $WORKDIR;echo "$MSG"

#delete audit files KEEP_AUDIT_DAYS days ago
#get adump path
sqlplus -s / as sysdba <<EOF >/dev/null
set heading off
set echo off
spool ./tmp_audit.txt
select value from v\$parameter where name = 'audit_file_dest';
spool off
EOF
ORA_ERR=$(grep ORA- ./tmp_audit.txt | wc | awk '{print $1}')
if [ $ORA_ERR -gt 0 ]; then
  echo "Oracle not started? please check it." 
  AUDIT_PATH=$ORACLE_BASE/admin/$ORACLE_SID*
else
  AUDIT_PATH=$(sed  -e '/^$/d' -e 's/^[ \t]*//g' -e 's/[ \t]*$//g' ./tmp_audit.txt) 
fi
echo "Now delete audit files $KEEP_AUDIT_DAYS days ago from directory: $AUDIT_PATH"

find $AUDIT_PATH -name "*.aud" -ctime +$KEEP_AUDIT_DAYS -delete && echo "delete audit done"
echo "clear listener log, audit file done"
rm ./tmp_audit.txt
du -sh $(dirname $LISTENER_ALERT_PATH)
du -sh $AUDIT_PATH
