#!/bin/bash
#this script sould be run as grid with $GRID_HOME set.
#check if RAC ora.crf resource is enabled and started.
#it should be stopped and disabled. ref:Doc ID 1589394.1
#created: lyf. 2021.04.22


source ~/.bash_profile
echo "oracle_home is : " $ORACLE_HOME
echo "oracle_sid is : "$ORACLE_SID
echo "path is : "$PATH

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "now check ora.crf service...."
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
crsctl stat res -t -init
if [ $? != '0' ]; then
  echo "please run with grid user ."
  exit 1;
fi
crsctl stat res -t -init |grep -A1 ora.crf > /tmp/crf.txt
grep "ONLINE"  /tmp/crf.txt | wc -l > /tmp/crf2.txt
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
if [ `cat /tmp/crf2.txt` != '0' ];then
  echo " please stop and disable ctf.crf maybe use lots of space. please run the next 2 commands as root,and check again"
  echo "# <GI_HOME>/bin/crsctl stop res ora.crf -init"
  echo "# <GI_HOME>/bin/crsctl modify res ora.crf -attr ENABLED=0 -init"
else
  echo "ora.crf has been disabled and stopped. it's OK。"
fi
rm -f /tmp/crf.txt 
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
