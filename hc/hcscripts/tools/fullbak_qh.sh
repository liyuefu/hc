#!/bin/sh
#单机或者运行时间较短的RAC都可以使用，运行较长时间的RAC建议使用fullrac.sh
#需要修改的参数1. RMANBAK. rman备份存放目录 
#2. ORACLE_SID, ORACLE_HOME
#3.备份恢复窗口,缺省1天
#version v2021-07-17,create
#version v2021-08-07,在backup database前加入crosscheck。避免因删除了未备份的归档日志导致rman备份失败。去掉了cumulative参数。
#一般用户可以直接引用.bash_profile,不需要设置ORACLE_SID,ORACLE_HOME

source ~/.bash_profile


#export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4
#export ORACLE_SID=orcl
export RMANBAK=/u02/rmanbackup
export RECO_DAY=3


export DATE=`date +%Y-%m-%d`
export LOGFILE=$RMANBAK/logs/rman_full_`date +%Y-%m-%d-%H%M`.log
export CMDFILE=/tmp/fullbak.rcv

if [ ! -d $RMANBAK ]; then
    mkdir $RMANBAK
fi

if [ ! -d $RMANBAK/logs ]; then
    mkdir $RMANBAK/logs
fi

cat > $CMDFILE <<EOF
connect target /
run{
CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$RMANBAK/auto_%T_%F.%d';
configure RETENTION POLICY TO recovery window of $RECO_DAY days;
allocate channel ch00 device type disk;
allocate channel ch01 device type disk;
allocate channel ch02 device type disk;
allocate channel ch03 device type disk;


crosscheck copy;
crosscheck backup;
crosscheck archivelog all;

delete noprompt expired archivelog all;
delete noprompt expired backup;
report obsolete;
delete noprompt obsolete;

backup as compressed backupset incremental level 0 database format '$RMANBAK/full_%T_%u_%p.%d' tag='FULLDB-$DATE'
plus archivelog format '$RMANBAK/arch_%T_%u_%p.%d' tag='ARCH-$DATE' delete all input ;

backup current controlfile format '$RMANBAK/ctl_%T_%u.%d' tag='CTL-$DATE' ;

crosscheck copy;
crosscheck backup;
crosscheck archivelog all;

delete noprompt expired archivelog all;
delete noprompt expired backup;
report obsolete;
delete noprompt obsolete;

delete noprompt force copy completed before 'sysdate-8';
delete noprompt force archivelog all completed before 'sysdate-8' ;
delete noprompt force backupset completed before 'sysdate-8' ;
release channel ch00;
release channel ch01;
release channel ch02;
release channel ch03;
}
EOF

########################################################################

echo "started backup at : "`date +%Y%m%d-%H%M` >> $LOGFILE
echo "---------------------------------------------------">>$LOGFILE
$ORACLE_HOME/bin/rman  @$CMDFILE log $LOGFILE append
echo "---------------------------------------------------">>$LOGFILE
echo "finished backup at: "`date +%Y%m%d-%H%M` >> $LOGFILE


