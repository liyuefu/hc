#################################################
### update: 2020.10.29. change cpuinfo command. 
### update: 2020.11.09  test if inode used percent is number.
### update: 2021.02.01  get sysctl.conf,/proc/meminfo|grep Page, .bash_profile, id oracle
### update: 2021.06.02  change cpuinfo, add reboot.
### update: 2021.08.04   change iostat to iostat -x
### update: 2022.05.31   add vmstat,change iostat to iostat -xd
### update: 2023.03.20  get current day sar  sar -f /var/log/sa{day} .
### update: 2023.05.04  change sar to sar -A -f /var/log/sa{day}.to get more info.
### update: 2023.11.15  run ifconfig, remote the path .
#################################################
#!/bin/bash 
#EMAIL=''
function sysstat {
echo -e "
#####################################################################
    Health Check Report (CPU,Process,Disk Usage, Memory)
#####################################################################


Linux Version    : `cat /etc/redhat-release`
Hostname         : `hostname`
Kernel Version   : `uname -r`
Uptime           : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`
Last Reboot Time : `who -b | awk '{print $3,$4}'`


*********************************************************************
CPU 
*********************************************************************
"
echo -e ""
#cat /proc/cpuinfo
cpumodel=` grep  ^"model name" /proc/cpuinfo`
cpucnt=`grep -c ^"processor" /proc/cpuinfo `
cpumodelstr="CPU Family: "${cpumodel}
cpucntstr="CPU cnt: "${cpucnt}
echo $cpumodelstr
echo $cpucntstr


echo -e "
*********************************************************************
Process
*********************************************************************
=> CPU Load
`top b -n1 | head -5`

=> Top memory using processs/application

PID %MEM RSS COMMAND
`ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10`

=> Top CPU using process/application
`top b -n1 | head -17 | tail -11`

*********************************************************************
Disk Usage - > Threshold < 70 Normal > 70% Caution > 85 Unhealthy
*********************************************************************
"
echo " 

*********************************************************************"
echo "df -Pkh      "
df -Pkh

df -Pkh | grep -v 'Filesystem' > /tmp/df.status
#while read DISK
#do
#	LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
#	echo -e $LINE 
#	echo 
#done < /tmp/df.status

echo -e "

Heath Status"
echo
while read DISK
do
	USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
	if [ $USAGE -ge 85 ] 
	then
		STATUS='Unhealty'
	elif [ $USAGE -ge 70 ]
	then
		STATUS='Caution'
	else
		STATUS='Normal'
	fi
		
        LINE=`echo $DISK | awk '{print $1,"\t",$6}'`
        echo -ne $LINE "\t\t" $STATUS
        echo 
done < /tmp/df.status
rm /tmp/df.status

TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`
FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
USEDSWAP=`free -m | tail -1| awk '{print $3}'`
USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
FREESWAP=`free -m |  tail -1| awk '{print $4}'`
FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`

echo "
***************************************************************************
Disk inode - > Threshold < 70 Normal > 70% Caution > 85 Unhealthy
***************************************************************************
"
df -Pi 
df -Pi | grep -v 'Filesystem' > /tmp/df.status
#while read DISK
#do
#	LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
#	echo -e $LINE 
#	echo 
#done < /tmp/df.status
echo -e "

Heath Status"
echo
while read DISK
do
	USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
     if echo $USAGE | egrep -q '^[0-9]+$'; then
	if [ $USAGE -ge 85 ] 
	then
		STATUS='Unhealty'
	elif [ $USAGE -ge 70 ]
	then
		STATUS='Caution'
	else
		STATUS='Normal'
	fi
      else
		STATUS='N/A'
      fi
		
        LINE=`echo $DISK | awk '{print $1,"\t",$6}'`
        echo -ne $LINE "\t\t" $STATUS
        echo 
done < /tmp/df.status
rm /tmp/df.status


echo "
*********************************************************************"

echo -e " 
Memory 
*********************************************************************

=> Physical Memory

Total\tUsed\tFree\t%Free
${TOTALBC}GB\t${USEDBC}GB \t${FREEBC}GB\t$(($FREEMEM * 100 / $TOTALMEM  ))%

=> Swap Memory

Total\tUsed\tFree\t%Free
${TOTALSBC}GB\t${USEDSBC}GB\t${FREESBC}GB\t$(($FREESWAP * 100 / $TOTALSWAP  ))%
"
echo "
********************************************************************"
day=`date +%d`
echo "sar -A -f /var/log/sa/sa$day"
echo "
********************************************************************"
sar -A -f /var/log/sa/sa$day

echo " 

*********************************************************************"
echo "vmstat "
echo " 
*********************************************************************"
vmstat 2 4
echo " 

*********************************************************************"
echo " 

*********************************************************************"
echo "iostat "
echo " 
*********************************************************************"
iostat -dx 2 4
echo " 

*********************************************************************"
echo "cat /proc/meminfo|grep Page    "
echo " 
*********************************************************************"

cat /proc/meminfo|grep Page

echo "
*********************************************************************"
echo "cat /etc/fstab    "
echo " 
*********************************************************************"

cat /etc/fstab

echo "
*********************************************************************"
echo "cat /etc/hosts    "
echo " 
*********************************************************************"

cat /etc/hosts

echo "
*********************************************************************"
echo "cat /home/oracle/.bash_profile    "
echo " 
*********************************************************************"

cat /home/oracle/.bash_profile
echo "
*********************************************************************"
echo "cat /etc/sysctl.conf    "
echo " 
*********************************************************************"

cat /etc/sysctl.conf

echo " 
*********************************************************************"

if [ -f /etc/multipath.conf ]; then
echo "cat /etc/multipath.conf    "
echo " 
*********************************************************************"
  cat /etc/multipath.conf
else 
echo " 
*********************************************************************"
echo "no /etc/multipath.conf"
fi
echo " 
*********************************************************************"
echo "chkconfig or systemctl   "
echo " 

*********************************************************************"
if [ -f /usr/bin/systemctl ]; then 
  systemctl  list-units -t service --no-pager; 
else
  chkconfig;
fi

echo "
*********************************************************************"
echo "crontab -l     "
echo " 
*********************************************************************"

crontab -l

echo "
*********************************************************************"

echo " 

*********************************************************************"
echo "/etc/oratab     "
echo " 
*********************************************************************"

cat /etc/oratab
echo " 

*********************************************************************"
echo "id oracle     "
echo " 
*********************************************************************"

/usr/bin/id oracle

echo "
*********************************************************************"
echo "ifconfig   Network "
echo " 
*********************************************************************"
#/sbin/ifconfig 
# some systems ifconfig command is not in /sbin. so remote the path.
ifconfig
echo " 

*********************************************************************"
echo "cat /sys/kernel/mm/transparent_hugepage/enabled"
echo " 
*********************************************************************"
cat /sys/kernel/mm/transparent_hugepage/enabled
if test -f /sys/kernel/mm/redhat_transparent_hugepage/enabled; then
    echo "cat /sys/kernel/mm/redhat_transparent_hugepage/enabled"
    cat /sys/kernel/mm/redhat_transparent_hugepage/enabled
fi

echo "
*********************************************************************"
echo "last system reboot."
echo " 
*********************************************************************"
last reboot





}
#####################################################
######MAIN##########################################
#####################################################
export LANG=en_US.UTF-8

FILENAME="os_`hostname`_`date +%y%m%d`_`date +%H%M`.out"
sysstat > $FILENAME
echo -e "Reported file $FILENAME generated in current directory." $RESULT
if [ "$EMAIL" != '' ] 
then
	STATUS=`which mail`
	if [ "$?" != 0 ] 
	then
		echo "The program 'mail' is currently not installed."
	else
		cat $FILENAME | mail -s "$FILENAME" $EMAIL
	fi
fi
