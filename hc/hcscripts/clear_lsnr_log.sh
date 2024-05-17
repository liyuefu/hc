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

echo "$TODAY clear listener logs: $LISTENER_ALERT_PATH, $LISTENER_TRACE_PATH. "

cd $LISTENER_ALERT_PATH
ls log_*.xml >/dev/null 2>/dev/null && mkdir  bak_$TODAY && mv log_*.xml bak_$TODAY && tar czf bak_$TODAY.tar.gz bak_$TODAY
if [ $? -eq 0 ]; then
    rm -rf bak_$TODAY
    MSG="compress xml log done."
else

    MSG="no xml log to compress. or compress xml log failed."
fi
cd $WORKDIR;echo "$MSG"

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
du -sh $(dirname $LISTENER_ALERT_PATH)
