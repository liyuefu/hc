#!/usr/bin/env bash
##backup listener log in trace and alert directory and compress them.
##clear audit files before KEEP_AUDIT_DAYS days.
##ver 2023.03.03.1017.

source ~/.bash_profile

export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
KEEP_AUDIT_DAYS=365
WORKDIR=$PWD
LISTENER_ALERT_PATH=$(dirname $(lsnrctl status | awk ' /^Listener Log File/  { print $4} '))
LISTENER_TRACE_PATH=$(dirname $LISTENER_ALERT_PATH)/trace
TODAY=$(date  +"%y-%m-%d_%H_%M_%S")
LOG_ENABLED="yes"

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
du -sh $AUDIT_PATH
