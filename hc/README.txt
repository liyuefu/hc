# 运行这个脚本需要python-lxml
# yum install python-lxml
#以oracle用户使用,步骤如下
#mkdir -p /home/oracle/scripts/healthcheck
#cd /home/oracle/scripts/healthcheck
# tar zxvf hc_2021.11.17.tar.gz 
# ./hc.sh
#以grid用户执行，步骤如下
#su - grid
#cd cp /home/oracle/scripts/healthcheck/hcscripts/gridcheck.sh  /home/grid
#./gridcheck.sh,结果保存到/home/grid/gridcheck目录下当天日期目录
#退出grid，把/home/grid/gridcheck*.tar.gz 上传。
#在hcscripts下增加了tools,sqltune.sql, fullbak.sh(rman备份脚本)，coe_xfr_sql_profile.sql脚本,sqlmonitor.sql
##################
#ver: 20211129  . hcscripts下增加了checkstats.sql, sqlplus / as sysdba @checkstats, 输入hr, employees,查看表，索引，字段的统计信息
##################
##################
#ver: 2022.01.21  . 在hc.sh, linux.sh设置export LANG=en_US.UTF-8
##################
##################
#ver: 2022.03.09  . 922行等读取硬件信息后添加到表格，加try捕获异常。
##################
##################
#ver: 2022.05.31  . 查看隐含参数.linux.sh查看chkconfig、systemctl,vmstat; grid.sh增加查询ocr,olr备份。
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
#ver: 2023.02.17  add support for Linux5. 把lxml包放入各个linux目录下, 使用相对路径.取消了必须放在/home/oracle/scripts/healthcheck的要求
#ver: 2023.03.01   linux6,linux5版本支持读取配置文件config.ini, 读取巡检记录, 数据增长趋势. 最新巡检记录和数据写入config.ini.
IP自动读取, 不从配置文件读取. tar包名字加入IP, docx名字不加入IP
#ver: 2023.03.03  增加了清理侦听日志和audit日志的脚本hcscripts/clear_lsnr_aud_log.sh,没有加在hc.sh,单独执行.执行的日志在hcscripts下.
#ver: 2023.03.14. fix  清理日志的bug. 不使用库文件.
#ver: 2023.03.20. OS检查取sar日志/var/log/sa/
#ver: 2023.04.13. fix linux6 dox文档没有数据库名.
#ver: 2023.04.14. 优化清除侦听/审计日志.
                   rac grid: clear_grid_lsnr_scan1_aud_log.sh
                    rac oracle: clear_aud_log.sh ,因为oracle用户没有起侦听.
#                 单机 oracle用户: clear_oracle_lsnr_aud_log.sh
#ver: 2023.04.28.  fix clear*sh 脚本中临时文件保存在/tmp, 用grid用户生成的临时文件,oracle不能覆盖.改为
#                 保存在当前目录.并且执行完成删除.
#ver: 2023.05.04 linux.os 把sar 加上-A,取所有信息. hc.sh 
#把config.ini复制到output,加入10g支持.取得版本号dbver2.txt. 传入python脚本.判断运行opatch参数
#如果10g,从$ORACLE_BASE/admin/dbname/bdump下取alert文件.
#ver: 2023.07.18
取消把config.ini移动到output.(导致下次还要从output复制出来)
autodoc_linux7.py ,755行报错. 是前一个sql执行失败导致.增加
        logging.error(reason)
        启用python的日志模块,日志文件保存在当前目录
        logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',datefmt='%m-%d %H:%M',filename='./autodoc_linux7.log',filemode='w')
#update: 在RHEL8上也可以运行. 需要先安装python2. yum install -y python2. cd /usr/bin; ln -s python2.7 python. 即可.
#ver: 2023.11.15. fix get_ip.sh, ifconfig not in /sbin. remove oracle.sql.


###################

#说明：
cpu load是snap 这个时间点得CPU的load，不是两个时间内的平均值，而是一个即时值。单位是%。
https://www.cnblogs.com/likingzi/p/6397071.html 提供的计算，可供参考。
