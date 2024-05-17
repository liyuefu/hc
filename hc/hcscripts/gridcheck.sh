#!/bin/bash
##############################################################################################
# 检查grid的状态，收集grid相关的配置文件，日志文件，运行状态
# 以grid 用户执行
# 作者: 李曰福
# 创建日期：2021.08.04 V0.1
# update: 2021.11.17. put hostname in tar filename, fixed bug no copy multipath.conf
# update: 2022.05.31. 增加ocrcheck, ocrconfig -showbackup,ocrconfig -local -showbackup,压缩包
#                     保存到/home/grid/gridcheck/目录下日期目录。用tee同时输出到屏幕和文件
##############################################################################################
source /home/grid/.bash_profile


#取得环境变量
WHOAMI=`whoami`
PMONASM=`ps -ef|grep asm_pmon  |grep -v grep | wc | awk '{print $1 }'`
HOSTNAME=`hostname`
TODAY=`date +%F`
GRID_LOG=$ORACLE_HOME/log/$HOSTNAME
WORK_DIR=/home/grid
INFO=[`date +'%Y-%m-%d %H:%M:%S'`]

#检查运行用户
if [ `whoami`  != 'grid' ]; then
	echo -e "\n${INFO}`date +%F' '%T`: Please run this script with grid user.\n"	
	exit 1;
fi

#检查数据库是否在运行
if [ $PMONASM -ne 1 ]; then
	echo -e "${ERROR} : Please make sure ASM is running.\n"
	exit 2;
fi


OUTPUTPATH="/tmp/gridcheck-$TODAY"
#创建目录output
if [ -d $OUTPUTPATH ]; then
	rm -rf $OUTPUTPATH;
	mkdir $OUTPUTPATH
else
	mkdir $OUTPUTPATH
fi

#复制配置文件
cp $ORACLE_HOME/gpnp/$HOSTNAME/profiles/peer/profile.xml  $OUTPUTPATH
if [ -f /etc/multipath.conf ];then
	cp /etc/multipath.conf $OUTPUTPATH
fi

UDEV_RULES=`grep -l -e grid /etc/udev/rules.d/*.rules | wc | awk  '{ print $1 }'`
if [ $UDEV_RULES -gt 0 ]; then
#	UDEV_RULES_FILE="/etc/udev/rules.d/` grep -l -e grid *.rules`"
	UDEV_RULES_FILE=` grep -l -e grid /etc/udev/rules.d/*.rules`
	cp $UDEV_RULES_FILE $OUTPUTPATH
fi


#复制日志文件
cd $GRID_LOG
cp alert`hostname`.log $OUTPUTPATH
cp gpnpd/gpnpd.log $OUTPUTPATH
cp gpnpd/gpnpdOUT.log $OUTPUTPATH
cp ohasd/ohasd.log $OUTPUTPATH
cp ohasd/ohasdOUT.log $OUTPUTPATH
cp crsd/crsd.log $OUTPUTPATH
cp crsd/crsdOUT.log $OUTPUTPATH
cp cssd/ocssd.log $OUTPUTPATH
cp cssd/cssdOUT.log $OUTPUTPATH
cp gipcd/gipcd.log $OUTPUTPATH
cp gipcd/gipcdOUT.log $OUTPUTPATH
cp ctssd/octssd.log $OUTPUTPATH
cp ctssd/ctssdOUT.log $OUTPUTPATH


#执行sql
cat > $OUTPUTPATH/asm.sql <<EOF
col path for a40
col name for a15
col compatibility for a15
col database_compatibility for a15
set linesize 150
spool $OUTPUTPATH/asm.log
create pfile='$OUTPUTPATH/asm.ora' from spfile;
select group_number,disk_number,path,name,state,total_mb,free_mb from v\$asm_disk order by 1,2;
select group_number,name,state,type,total_mb,free_mb,usable_file_mb,compatibility,database_compatibility from v\$asm_diskgroup order by 1;
spool off
exit;
EOF

sqlplus / as sysasm @$OUTPUTPATH/asm.sql


#执行检查命令
#检查ocr olr
echo -e "\n${INFO}: ocrcheck .\n" | tee  $OUTPUTPATH/ocrcheck.log
ocrcheck | tee -a $OUTPUTPATH/ocrcheck.log

echo -e "\n${INFO}: ocrconfig -showbackup .\n" | tee  $OUTPUTPATH/ocrconfig.log
ocrconfig -showbackup  | tee -a  $OUTPUTPATH/ocrconfig.log
echo -e "\n${INFO}: ocrconfig -local -showbackup .\n" | tee -a  $OUTPUTPATH/ocrconfig.log
ocrconfig -local -showbackup | tee -a  $OUTPUTPATH/ocrconfig.log

#检查voting disk
echo -e "\n${INFO}: crsctl query css votedisk.\n" | tee  $OUTPUTPATH/crsctl.log
crsctl query css votedisk | tee -a   $OUTPUTPATH/crsctl.log

echo -e "\n${INFO}: crsctl stat res -t.\n"  | tee -a  $OUTPUTPATH/crsctl.log
crsctl stat res -t | tee -a  $OUTPUTPATH/crsctl.log


echo -e "\n${INFO}: crsctl stat res -t -init.\n" | tee -a  $OUTPUTPATH/crsctl.log
crsctl stat res -t -init  | tee -a  $OUTPUTPATH/crsctl.log


echo -e "\n${INFO}: oifcfg getif.\n" | tee   $OUTPUTPATH/oifcfg.log
oifcfg getif | tee -a  $OUTPUTPATH/oifcfg.log

echo -e "\n${INFO}: oifcfg iflist -p -n. \n" | tee -a $OUTPUTPATH/oifcfg.log
oifcfg iflist -p -n  | tee -a  $OUTPUTPATH/oifcfg.log

echo -e "\n${INFO}: asmcmd lsdg. \n" | tee 	$OUTPUTPATH/lsdg.log
asmcmd lsdg | tee -a $OUTPUTPATH/lsdg.log

echo -e "\n${INFO}: cluvfy stage -post crsinst -n all -verbose. \n"	| tee  $OUTPUTPATH/cluvfy.log
cluvfy stage -post crsinst -n all -verbose | tee  $OUTPUTPATH/cluvfy.log

####

/bin/netstat -in | tee  $OUTPUTPATH/netstat.log

#打包output
mkdir -p $WORK_DIR/gridcheck/$TODAY
cd $OUTPUTPATH
tar cvzf $WORK_DIR/gridcheck/$TODAY/gridcheck-${HOSTNAME}-`date +'%Y-%m-%d-%H-%M-%S'`.tar.gz *
rm -rf $OUTPUTPATH
