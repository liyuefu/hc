################################################
#update: 2020.11.09 . v0.1. add rmansize sum
#update: 2020.12.1 v1201. change filename.add opatch. put linux6/linux7 together.
#update: 2020.12.13 v1213. add MALICE_CODE check;optach info;async check.
#update: 2020.12.19 V1219. fix linux6.6 os info error.
#update: 2021.01.19 V210119. fix autodoc_linux6.py line 516. body.append. with try catch.
#         SPACE MONITOR added 999,999,999.
#update: 2021.01.31 V210131. fix SPACE MONITOR temp tablespace free error.
#update: 2021.02.01 V210201. add rman show all. change linux7 linxoutput size to 10.
#update: 2021.02.05 v210205. add try for patch add to table; fix dbname lowercase.fix linux7 opatch error.
#update: 2021.03.08.v210308. check alert error save in dberr.txt.
#                            dbinfo change to 中文
#                            fix linux7 missing SCN information
#                            add bitcoin check to report.
#                            change filename.add alert error info.
#update:2021.03.11. remove some old sql. remove sql2,change table size to 6
#                   auto awr report. the past 2 hours data.
#update: 2021.04.10. correct one error. rman/dmp/datafile size in (G), not (M)
#update: 2021.04.22. add : check cluster database crf resource stopped/disabled.
#        add hclog to record hc.sh run process. change crf.txt to /tmp/crf.txt
#update: 2021.05.31. 1.fix archivelog busyday/rushhour sql error. 2. add tablespace grow info.
#update: 2021.06.01 fix tablespace grow bug,remove nouse script.change some comment.
#update: 2021.06.02. add reboot info in os.
#update: 2021.06.03. fixed some display format bug.
#update: 2021.06.08. fixed autodoc tbs growth bug. add parameter modification in oracle.sql
#update: 2021.06.20. change linux7 table title format.
#update: 2021.06.30. fix ifconfig path error.
#update: 2021.08.04. add gridcheck.sh.(run with grid user, upload /home/grid/gridcheck*.tar.gz )
#update: 2021.09.02. fix lspatches bug
#update: 2021.11.17. fix getdbname on dg missing alert.log(get db_unique_name instead of name); 
#                    add hostname to gridcheck filename. 
#                    change to use function write_log.
#                    save awr output to awr_html.out file.no print to screen.
#update: 2022.05.31  . 查看隐含参数.linux.sh查看chkconfig、systemctl,vmstat.grid.sh增加查询ocr,olr备份。
##################
##################
#ver: 2022.06.13  . 客户信息放在config.ini, 巡检日期写入config.ini,只支持linux7的python2.7
#ver: 2022.06.14  . linux6. 用changeclient.sh直接修改python代码.
#ver: 2022.06.15.  fixed LINUXSHELL不执行 bug
#ver: 2022.06.18.  IP,disaster_recovery 从config.ini读取或者修改. 简化巡检总结.
#ver: 2022.06.20   增加purgeLogs(perl脚本, Doc ID 2081655.1). 直接以root执行,清理30天前日志. 或者--help.
#                  linux6的changeclient.sh 加上-i.bak 备份. 数据库类型(生产库/历史库等).
#ver: 2022.06.30   purgelog 需要root权限.可以修改,把判断非root的exit去掉.  修复了changeclient.sh单引号字符串错误.
#ver: 2022.07.15   更新了fullbak.sh为 fullbak_qh.sh 在备份前检查archivelog.防止因为已经删除的
#ver: 2022.09.30   fix invalid datafile时未判断dg. dg的都是read only. vmstat 执行4次,执行iosat4次,把旧的巡检放到old目录,把使用的脚本放入output/using_script
#归档日志导致备份失败.一般发生在首次备份时.
#ver: 2022.11.14   去掉了show_space.sql ,避免误会修改数据库.
#ver: 2022.12.21.  fix 19c 在linux7 执行730行报错.因为v$pwfile_users 表增加到16个字段,超过了原来的12个. 修改为最多20个,自动获取IP,显示CPU_LOAD(%)
#ver: 2023.01.31.  hc.sh注释了LINUX_SHELL.改为不注释
#ver: 2023.02.17  add support for Linux5.自带lxml, 使用相对路径.
#ver: 2023.03.01  linux5/linux6/linux7都从healthcheck/config.ini读取配置文件.并把巡检记录和数据增长趋势写入config.ini
#ver: 2023.04.28   一个服务器多个实例时,只取当前.bash_profie设置的ORACLE_SID,生成它的awr报告.其它实例不生成.
#ver: 2023.04.29  取alert日志时,使用grep "^ORA-\|Error" -C10. 避免取一般的error信息.
#ver: 2023.05.04  把config.ini复制到output,取数据库小版本号dbver2,传入python脚本.判断opatch 参数.
#                 10g,alert日志位置取$ORACLE_BASE/admin/dbname/bdump
#ver: 2023.05.18  unset LC_ALL
#ver: 2023.11.15. fix get_ip.sh, ifconfig not in /sbin. remove oracle.sql.

###############################################

#############USAGE###########################
#change  ORACLE_SID,ORACLE_BASE,$ORACLE_HOME
#./hc.sh
#input awr report arguments
#collect the .out files, log file, html file.
##############################################

export INFO='\033[0;34mINFO: \033[0m'
#export ERROR='\033[1;31mERROR: \033[0m'
#export SUCCESS='\033[1;32mSUCCESS: \033[0m'

#export ORACLE_BASE=/u01/app/oracle
#export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4
#export ORACLE_SID=orcl
source ~/.bash_profile
export LANG=en_US.UTF-8
unset LC_ALL
export CONN="/ as sysdba"
#export SHELL_PATH="/home/oracle/scripts/healthcheck/hcscripts"
#export PYTHON2_PATH="/home/oracle/scripts/healthcheck/linux6/autodoc_linux6.py"
#export PYTHON3_PATH="/home/oracle/scripts/healthcheck/linux7/autodoc_linux7.py"
export SHELL_PATH="./hcscripts"
export PYTHON24_PATH="./linux5/autodoc_linux5.py"
export PYTHON2_PATH="./linux6/autodoc_linux6.py"
export PYTHON3_PATH="./linux7/autodoc_linux7.py"

#export SQL_FILE1="$SHELL_PATH/health_check_lyf_20201116.sql"
export SQL_FILE2="$SHELL_PATH/oracle.sql"
export SQL_FILE3="$SHELL_PATH/getdbname.sql"
export SQL_FILE4="$SHELL_PATH/scnhealthcheck.sql"
export SQL_FILE5="$SHELL_PATH/checkcluster.sql"
export SQL_DBVER="$SHELL_PATH/getdbver.sql"
export SQL_RMANSIZE="$SHELL_PATH/rmansize.sql"
export LINUX_SHELL="$SHELL_PATH/linux.sh"
export CHECK_BITCOIN="$SHELL_PATH/check_bitcoin_300day.sh"
export AUTODOC_SQL_FILE="$SHELL_PATH/autodoc.sql"
export GET_IP_LISTS="$SHELL_PATH/getip.sh"

export current_date=$(date +%Y-%m-%d-%H%M)
export LOG_FILE="hc_$current_date.LOG"
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss';

function write_log()
{
  now_time='['$(date +"%Y-%m-%d %H:%M:%S")']'
  echo -e "\n${INFO}`date +%F' '%T`: $1 "
  echo -e "\n`date +%F' '%T`: $1 " >> ${LOG_FILE}
}

touch $LOG_FILE
write_log "Now start Oracle database healthcheck."
write_log "Getting db_name,dbver..."
chmod +x ./hcscripts/*.sh
sqlplus -s $CONN <<EOF 
start $SQL_FILE3
EOF
sqlplus -s $CONN <<EOF 
start $SQL_DBVER
EOF

if [ ! -f "./config.ini" ];then
    write_log "NO config.ini, please check it under hcscripts directory."
    exit
fi

if grep "ORACLE" /tmp/dbname.txt; then
  write_log "ERROR !!!! Oracle is not started,start oracle first"
  exit
fi

DBNAME=`cat /tmp/dbname.txt`
write_log "db name is : $DBNAME"

DBVER=`cat /tmp/dbver.txt`
DBVER2=`cat /tmp/dbver2.txt`
IP=$($GET_IP_LISTS)
if [ "$IP"x == x ]; then
  write_log "getip failed"
  IP="127.0.0.1"
else
  write_log "ip list is :$IP"
fi
write_log "db ver is: $DBVER"
if [ $DBVER == "10g" ]; then
  write_log "using autodoc sql autodoc_10g.sql" 
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

# write_log "check if cluster database with ora.crf resource enabled."
# sqlplus -s $CONN <<EOF 
# start $SQL_FILE5
# EOF

# if [ `cat /tmp/cluster1.txt` == '1' ];then
#   write_log "this is a cluster database.now check ora.crf. please make sure oracle can run  crsctl command. Otherwise please run ./hcscripts/check_crf.sh with grid user later. "
#   ./hcscripts/check_crf.sh
#   if [ $? ];then
#      write_log  "please run ./hcscripts/check_crf.sh with grid user when hc.sh is finished."
#   elif [ `cat crf2.txt` != '0' ];then
#     write_log " please stop and disable ctf.crf maybe use lots of space. please run the next 2 commands as root,and check again" 
#     write_log "# <GI_HOME>/bin/crsctl stop res ora.crf -init" 
#     write_log "# <GI_HOME>/bin/crsctl modify res ora.crf -attr ENABLED=0 -init"
#     rm -f crf2.txt
#   else 
#     write_log "ora.crf has been disabled and stopped. it's OK。" 
#     rm -f crf2.txt
#   fi 
#   if [ -f /tmp/cluster1.txt ];then
#     rm -f /tmp/cluster1.txt
#   fi
# fi

write_log "check BIT_COIN_300DAYS ATTACK..."
$CHECK_BITCOIN

write_log "check hidden parameters..."
./hcscripts/check_hidden_para.sh

#async check.

sqlplus -s $CONN <<EOF >asynccheck.out
col name for a60
col value for a10
col asynch_io for a10
select name, value from v\$parameter where name in ('filesystemio_options','disk_asynch_io') order by name;
SELECT NAME,ASYNCH_IO FROM V\$DATAFILE F,V\$IOSTAT_FILE I
WHERE F.FILE#=I.FILE_NO
AND FILETYPE_NAME='Data File';
EOF

write_log "check aio async..."
write_log "cat /proc/sys/fs/aio-max-nr">> asynccheck.out
cat /proc/sys/fs/aio-max-nr >> asynccheck.out
write_log "cat /proc/sys/fs/aio-nr">> asynccheck.out
cat /proc/sys/fs/aio-nr >>asynccheck.out

#get scn number
sqlplus -s $CONN <<EOF 
start $SQL_FILE4
EOF
touch /tmp/scn.txt
if [ ! -f $AUTODOC_SQL_FILE ];then
    write_log "NO autodoc.sql, please check it under hcscripts directory."
    exit
fi
write_log "RUN linux check now..."
$LINUX_SHELL

if [ $DBVER != "10g" ]; then
  ALERT_FILE=$ALERT_PATH/"alert*.log"
else
  ALERT_FILE="$ORACLE_BASE/admin/$DBNAME/bdump/alert*.log"
fi

if [ ! -f  $ALERT_FILE ];then
  write_log "$ALERT_FILE NOT FOUND. PLEASE FIND IT YOURSELF"
else
  cp $ALERT_FILE .
  write_log "cp alert file: $ALERT_FILE  done."
fi

write_log "check alert error message in dberr.txt..."
tail -n 100000 $ALERT_FILE|grep "^ORA-\|Error" -C10 > dberr.txt


#check python version
python $SHELL_PATH/getver.py
PYTHON_VER=`cat /tmp/pyver.txt`
if [ "$PYTHON_VER" \> "3" ]
then
    write_log "not support python3, please ln -s  python to  python2.6 or 2.7"
    exit
elif [ "$PYTHON_VER" \> "2.7" ]
then
#copy 10g linux7 version cx_Oracle.so to here
    if [ $DBVER == "10g" ];then
      cp ./10g/python27/cx_Oracle.so ./linux7/cx_Oracle.so
    fi
    write_log "Using Python $PYTHON_VER..."
    USING_PYTHON=$PYTHON3_PATH 
elif [ "$PYTHON_VER" \> "2.6" ]
then
#copy 10g linux6 version cx_Oracle.so to here
    if [ "$DBVER"x == "10g"x ];then
      cp ./10g/python26/cx_Oracle.so ./linux6/cx_Oracle.so
    fi
    write_log "Using Python $PYTHON_VER..."
    USING_PYTHON=$PYTHON2_PATH 
else
#python is under 2.6. using python 2.4
    if [ $DBVER == "10g" ];then
      cp ./10g/python24/cx_Oracle.so ./linux5/cx_Oracle.so
    fi
    write_log "Python version:$PYTHON_VER. Try to using python version 2.4... "
    USING_PYTHON=$PYTHON24_PATH 
fi;
#create word docx
write_log "Now creating autodoc: python $USING_PYTHON $AUTODOC_SQL_FILE $ORACLE_HOME $IP .."
#python -m pdb $USING_PYTHON $AUTODOC_SQL_FILE $ORACLE_HOME
python $USING_PYTHON $AUTODOC_SQL_FILE $ORACLE_HOME $DBVER2 $IP
write_log "run python autodoc done."
#echo "runing  oracle sql script1 ..."
#sqlplus -s $CONN <<EOF 
#start $SQL_FILE1
#EOF

#no need to run this sql. 2023.11.15.
# write_log "runing  oracle sql script2 ..."
# sqlplus -s $CONN <<EOF 
# start $SQL_FILE2
# EOF

write_log "oracle crontab job..."
crontab -l


write_log "run lsnrctl status..."
lsnrctl status > lsnrctl.out

write_log "check rman backup info.."

sqlplus -s $CONN <<EOF >rman.out
archive log list;
exit;
EOF
rman  <<EOF >>rman.out
connect  target /
show all;
list backup summary;
list backup;
report obsolete;
EOF

write_log "check rmansize info..."
sqlplus -s $CONN <<EOF
start $SQL_RMANSIZE
EOF


write_log "run awrrpt now..."
#sqlplus  $CONN @$ORACLE_HOME/rdbms/admin/awrrpt.sql
# for i in $(ps aux|awk '{print $11}' | grep "ora_pmon");
# do 
# export ORACLE_SID=${i:9}
# echo -e "ORACLE_SID is \033[32m $ORACLE_SID \033[0m"
# sleep 5
m=`$ORACLE_HOME/bin/sqlplus -S <<EOF /nolog
conn / as sysdba;
set heading off;
select max(snap_id) from dba_hist_snapshot;
EOF`
start=$((m-1))
stop=$((m))

$ORACLE_HOME/bin/sqlplus -S <<EOF /nolog >>awr_html.out
conn / as sysdba
@?/rdbms/admin/awrrpt.sql;
html
1
${start}
${stop}
$ORACLE_SID.html
EOF
# done


write_log "Moving all output log docx html to output directory..."
rm -rf output
mkdir -p output/using_script
write_log "Healthcheck for DBNAME: $DBNAME, ORACLE_SID: $ORACLE_SID is done."
OUTPUTNAME="output_`hostname`_"$IP"_"$DBNAME"_"$ORACLE_SID"_""$current_date.tar.gz"
write_log "The outputname is:  $OUTPUTNAME"
cp hc.sh config.ini ${USING_PYTHON} README* output/using_script
mv -f *.out *.log *.html *.docx dberr.txt hc_*.LOG  output >/dev/null 2>&1

if [ -d old ]; then
  mv output_*.tar.gz old
else
  mkdir old
  mv output_*.tar.gz old
fi
tar -zvcf $OUTPUTNAME output
