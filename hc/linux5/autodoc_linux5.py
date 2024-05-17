#coding=utf-8
#!/usr/bin/env python
from docx import *
import codecs
from codecs import open
import re
import cx_Oracle
import subprocess
from datetime import date
import sys,os
reload(sys)
sys.setdefaultencoding("utf-8")

import commands
import ConfigParser

"""
Desc: check database status and create word document.
Env: RH5. Python2.4. Oracle 11.2.0.4
package needed :docx, cx_Oracle
files list: 1. autodoc.sql (database scripts). 2. autodoc.py(this script)

what this scirpt do
1. run sql script to collect database info.
2. run linux command to collect os info.
3. write information to doc.

to be finished by yourself:
4. add awr report performance info to doc.
5. analyze alert.log, awr report and other sql infomation to provide suggestions.
6. recreate "table of contents"
7. change title/client name, etc.

update record:
create: 2020.11.16 V1.3
update: 2020.11.17 V1.4.  
        1.correct fetch NLS_CHARACTER etc sequence error.
        2.save name with hostname_dbname_date
update: 2020.11.26 v20201126. 
        add try except in  subprocess linux command
update: 2020.12.19 v20201219
        fixed not working on linux6.6. put os info in table. add opatch info
update: 2021.09.02 v20210902. 
	fixed lspatch exception catch bug.
update: 2022.03.09. v20220309.
    fixed line 922,951, ...add  try .. exception for hardware information.
update: 2022.06.18. 简化了巡检总结,加上IP
update: 2022.12.21. getip. 自动获取IP)
"""


"""



#****************************This part create word doc.************************




create word document
put ur before Chinese  str
"""
PWD=os.getcwd()
#read config.ini

config = ConfigParser.ConfigParser()
config.read(PWD+"/config.ini")

try:
  client_name = config.get('client','client_name')
  client_app_name = config.get('client','client_app_name')
  client_app_db_name = config.get('client','client_app_db_name')
  client_dba_name = config.get('client','client_dba_name')
  disaster_recovery = config.get('client','disaster_recovery')
  lidao_tech_manager = config.get('lidao','lidao_tech_manager')
  lidao_sales_name = config.get('lidao','lidao_sales_name')
  lidao_engineer_name = config.get('lidao','lidao_engineer_name')
  lidao_header=config.get('lidao','lidao_header')
  lidao_copyright=config.get('lidao','lidao_copyright')
  lidao_name=config.get('lidao','lidao_name')
  lidao_address=config.get('lidao','lidao_address')
  lidao_tel=config.get('lidao','lidao_tel')
except:
  logging.error("read config.ini failed")
  print("read config.ini failed")


client_name = str(client_name).encode("utf-8").decode("utf-8")
client_app_name = str(client_app_name).encode("utf-8").decode("utf-8")
client_app_db_name = str(client_app_db_name).encode("utf-8").decode("utf-8")
client_dba_name = str(client_dba_name).encode("utf-8").decode("utf-8")
disaster_recovery = str(disaster_recovery).encode("utf-8").decode("utf-8")
lidao_tech_manager = str(lidao_tech_manager).encode("utf-8").decode("utf-8")
lidao_sales_name = str(lidao_sales_name).encode("utf-8").decode("utf-8")
lidao_engineer_name = str(lidao_engineer_name).encode("utf-8").decode("utf-8")
lidao_header = str(lidao_header).encode("utf-8").decode("utf-8")
lidao_copyright = str(lidao_copyright).encode("utf-8").decode("utf-8")
lidao_name = str(lidao_name).encode("utf-8").decode("utf-8")
lidao_address = str(lidao_address).encode("utf-8").decode("utf-8")
lidao_tel = str(lidao_tel).encode("utf-8").decode("utf-8")


GETIP=PWD+"/hcscripts/getip.sh"
logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',datefmt='%m-%d %H:%M',filename='/tmp/autodoc_linux5.log',filemode='w')
logging.info('starting autodoc_linux5.py now...')

# ip_address=""
# try:
#   res,ip_address=commands.getstatusoutput(GETIP)
#   logging.info(ip_address)
# except:
#   print("getip fail")
#   logging.error("getip fail")
# Create our properties, contenttypes, and other support files
filename = client_name + client_app_name
filename_end = ur"Oracle数据库健康检查报告"

#date of today
today=str(date.today())
sqlfilename=sys.argv[1]
oraclehome=sys.argv[2]
dbver2=sys.argv[3]
ip_address=sys.argv[4]

#get all os information. store in osinfo(
osinfo={'ver':[],'scn':[],'patch':[],'hostname':[],'uname':[],'vmstat':[],'iostat':[],'top':[],'topcpu':[],'topmem':[],'df':[],'dfinode':[],'dberr':[],'bitcoin300':[]}
try:
    ps = subprocess.Popen(['cat', '/etc/redhat-release'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    osinfo['ver'].append(output)
    ps = subprocess.Popen(['cat', '/tmp/scn.txt'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    for line in output.splitlines():
        if not(re.match("--",line)): 
            osinfo['scn'].append([line])
    
    opatch = oraclehome+'/OPatch/opatch'    
    try:
        if (dbver2 > "11.2.0.3.0"):
            ps = subprocess.Popen([opatch,' lspatches'],stdout=subprocess.PIPE)
        else:
            ps = subprocess.Popen([opatch,' lsinventory'],stdout=subprocess.PIPE)
        output = ps.communicate()[0]
        for line in output.splitlines():
            osinfo['patch'].append([line])
    except:
        print ("opatch  failed")

        
    # ps = subprocess.Popen([opatch,' lspatches'],stdout=subprocess.PIPE)
    # output = ps.communicate()[0]
    # if ps.returncode != 0:
    #     ps = subprocess.Popen([opatch,' lsinventory'],stdout=subprocess.PIPE)
    #     output = ps.communicate()[0]
    # for line in output.splitlines():
    #     osinfo['patch'].append([line])

    ps = subprocess.Popen(['/bin/hostname'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    hostname=''
    for line in output.splitlines():
        hostname=str(line)
    filename=filename+"_"+hostname
    osinfo['hostname'].append([hostname])

    ps = subprocess.Popen(['uname','-r'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    osinfo['uname'].append(output)

#    ps = subprocess.Popen(['vmstat','2','2'],stdout=subprocess.PIPE)
    ps = subprocess.Popen(['free','-m'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    vmstat=''
    for line in output.splitlines():
        osinfo['vmstat'].append([line]) 

    ps = subprocess.Popen(['iostat','2','2'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
#    osinfo['iostat'].append(output)
    iostat=''
    for line in output.splitlines():
        iostat = iostat + str(line)
        osinfo['iostat'].append([line]) 
#    osinfo['iostat'].append([iostat])
#    print(osinfo['iostat'])

    p1 = subprocess.Popen(['top', 'b', '-n1'],stdout=subprocess.PIPE)
    p2 = subprocess.Popen(['head', '-5'],stdin=p1.stdout,stdout=subprocess.PIPE)
    output = p2.communicate()[0]
#    osinfo['top'].append(output)
#    top=''
    for line in output.splitlines():
#        top = top + str(line)
        osinfo['top'].append([line])
#    osinfo['top'].append(top)

    p1 = subprocess.Popen(['ps','aux'],stdout=subprocess.PIPE)
    p2 = subprocess.Popen(['awk', '"{print $2, $4, $6, $11}"' ],stdin=p1.stdout,stdout=subprocess.PIPE)
    p3 = subprocess.Popen(['sort', '-k3rn' ],stdin=p2.stdout,stdout=subprocess.PIPE)
    p4 = subprocess.Popen(["head", "-n","10" ],stdin=p3.stdout,stdout=subprocess.PIPE)
    output = p4.communicate()[0]
    topcpu = ''
    for line in output.splitlines():
#        topcpu = topcpu + str(line)
        osinfo['topcpu'].append([line])
#    osinfo['topcpu'].append(topcpu)
#    print(osinfo['topcpu'])

#ps = subprocess.Popen(["top b -n1 | head -17 | tail -11"],stdout=subprocess.PIPE)
    p1 = subprocess.Popen(['top','b','-n1'],stdout=subprocess.PIPE)
    p2 = subprocess.Popen(['head','-17'],stdin=p1.stdout,stdout=subprocess.PIPE)
    p3 = subprocess.Popen(['tail', '-11' ],stdin=p2.stdout,stdout=subprocess.PIPE)
    output = p3.communicate()[0]
    topmem = ''
    for line in output.splitlines():
        osinfo['topmem'].append([line])
#        topmem = topmem + str(line)
#    osinfo['topmem'].append(topmem)
#    print(osinfo['topmem'])

    ps = subprocess.Popen(['df','-Ph'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    df = ''
    for line in output.splitlines():
        osinfo['df'].append([line])


    ps = subprocess.Popen(['tail','-n80','dberr.txt'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    for line in output.splitlines():
        osinfo['dberr'].append([line])

    ps = subprocess.Popen(['grep','YES','bitcoin300.out'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    for line in output.splitlines():
        osinfo['bitcoin300'].append([line])

    ps = subprocess.Popen(['df','-Pi'],stdout=subprocess.PIPE)
    output = ps.communicate()[0]
    dfinode = ''
    for line in output.splitlines():
#        dfinode = dfinode + str(line)
        osinfo['dfinode'].append([line])
#    osinfo['dfinode'].append(dfinode)

except:
    print('error osinfo')

#travel3={'China':{'cities_visited':['Shanghai','Beijing'],'total_visits':10},'Australia':{'cities_visited':['Mel','Syn'],'total_visits':12}}
#for c in travel3:
#    print(travel3[c])

title    = ur'利道软件 Oracle Document'
subject  = 'Database Health check'
creator  = 'liyuefu'
keywords = ['Oracle', 'health','check' ]
relationships = relationshiplist()
document = newdocument()
body = document.xpath('/w:document/w:body', namespaces=nsprefixes)[0]
coreprops = coreproperties(title=title, subject=subject, creator=creator, keywords=keywords)
appprops = appproperties()
contenttypes = contenttypes()
websettings = websettings()
wordrelationships = wordrelationships(relationships)
#head page
body.append(paragraph(ur"客户名称"))
body.append(paragraph(ur"应用系统"))
body.append(paragraph(ur"Oracle数据库健康检查报告 " ))
emptyline=20
while emptyline>0:
    body.append(paragraph("\n"))
    emptyline -=1;

"""
leader=[(ur"上海利道软件技术有限公司 ",'b'),(""),
        (ur"上海市北京东路 668号科技京城东27楼A3B3座 ","b"),(""),
        (ur"电话：（86-21）53083780 传真：（86-21）53083787",'iu')
        ]
"""
leader=[(ur"上海利道软件技术有限公司 ",'b')]
body.append(paragraph(leader))
body.append(paragraph(""))
leader=[(ur"上海市北京东路 668号科技京城东27楼A3B3座 ",'b')]
body.append(paragraph(leader))
body.append(paragraph(""))
leader=[(ur"电话：（86-21）53083780 传真：（86-21）53083787",'iu')]
body.append(paragraph(leader))

body.append(pagebreak(type='page', orient='portrait'))


#version control page
body.append(heading(ur'文档控制', 1))
body.append(heading(ur'修改记录', 2))
record=[[ur"日期",ur"作     者",ur"版本",ur"修 改 记 录"],[today,ur"工程师名字",ur"V1.0",ur"初始创建"]]
body.append(table(record,twunit='dxa',tblw=9000,borders={'all':{"sz": 10, "val": "single", "color": "#000000", "space": "0"}}))


body.append(heading(ur'审阅记录', 2))
record=[[ur"审   阅   人",ur" 职                      位"],[ur"王新兵",ur"技术总监"]]
body.append(table(record,twunit='dxa',tblw=9000,borders={'all':{"sz": 10, "val": "single", "color": "#000000", "space": "0"}}))


body.append(heading(ur'分发记录', 2))
record=[[ur"拷贝编号",ur" 姓    名",ur"单             位"],["1",ur"客户工程师名字",ur"客户名称"],["2",ur"利道技术部",ur"利道软件"]]
body.append(table(record,twunit='dxa',tblw=9000,borders={'all':{"sz": 10, "val": "single", "color": "#000000", "space": "0"}}))


#table of contents
body.append(pagebreak(type='page', orient='portrait'))

"""
get db basic info
#****************************This part create db basic info table .************************
"""
"""
connect to oracle  with / as sysdba
"""

#con = cx_Oracle.connect('sys','manager',mode=cx_Oracle.SYSDBA)
con = cx_Oracle.connect("/", mode = cx_Oracle.SYSDBA )
cur = con.cursor()

db_info=[[ur"参数名",ur"参数值"]]
#cluster or not
sql="select value from v$parameter where name = 'cluster_database'"
cur.execute(sql)
col1 = cur.fetchone()
cluster = [ur'是否RAC',str(col1[0])]

db_info.append(cluster)

#log_mode,flashback_on
sql="select log_mode,flashback_on from v$database"
cur.execute(sql)
col1,col2 = cur.fetchone()
log_mode = [ur'归档模式',str(col1)]
flashback_on=[ur'是否开启FLASHBACK',str(col2)]
db_info.append(log_mode)
db_info.append(flashback_on)

sql="select * from V$version"
cur.execute(sql)
result = cur.fetchone()
version = [ur'数据库版本',str(result[0])]

db_info.append(version)

sql="select name from v$database"
cur.execute(sql)
col1 = cur.fetchone()
dbname = [ur'数据库名(DB Name)',str(col1[0])]

db_info.append(dbname)

filename=filename+"_"+str(col1[0])

sql="select value from v$parameter where name = 'log_archive_dest_2'"
cur.execute(sql)
col1 = cur.fetchone()
standby = [ur'是否启用DG',str(col1[0])]

db_info.append(standby)

sql=" select count(*) from v$log"
cur.execute(sql)
col1=cur.fetchone()
logcnt=[ur'日志文件组数',str(col1[0])]

db_info.append(logcnt)

sql = "select distinct cnt from ( select group#,count(*) cnt from v$logfile group by group#) where rownum=1"
cur.execute(sql)
col1=cur.fetchone()
members=[ur'日志文件',str(col1[0])]

db_info.append(members)

sql="select  bytes/1024/1024 M from v$log where rownum=1"
cur.execute(sql)
col1=cur.fetchone()
logsize=[ur'日志大小(M)',str(col1[0])]

db_info.append(logsize)


sql="select  c.sum3 DMP_G ,a.sum1 RMAN_G,b.sum2 DATA_G from (SELECT ceil(SUM(BYTES)/1024/1024/1024) sum1 FROM DBA_segments ) a,(select ceil(sum(bytes)/1024/1024/1024) sum2 from v$datafile) b,(select ceil(sum(bytes)/1024/1024/1024) sum3 from dba_segments where segment_type not like 'INDEX%' and segment_type not in('ROLLBACK','CACHE','LOBINDEX','TYPE2 UNDO')) c "

cur.execute(sql)
col1,col2,col3=cur.fetchone()
dmp=str(col1)
rman=str(col2)
data=str(col3)
dmpsize=[ur'DMP文件大小(G)',dmp]
rmansize=[ur'RMAN备份大小(G)',rman]
datasize=[ur'DATA 数据文件大小(G)',data]
db_info.append(dmpsize)
db_info.append(rmansize)
db_info.append(datasize)

sql="select value$ from sys.props$ where name in('NLS_TERRITORY','NLS_LANGUAGE','NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET') order by name"
cur.execute(sql)
col1=cur.fetchone()
col2=cur.fetchone()
col3=cur.fetchone()
col4=cur.fetchone()
nls_char=['NLS_CHARACTERSET',str(col1[0])]
nls_lang=['NLS_LANGUAGE',str(col2[0])]
nls_nchar=['NLS_NCHAR_CHARACTERSET',str(col3[0])]
nls_terr=['NLS_TERRITORY',str(col4[0])]

db_info.append(nls_terr)
db_info.append(nls_lang)
db_info.append(nls_char)
db_info.append(nls_nchar)

#sql="select value from dba_hist_osstat where stat_name = 'NUM_CPUS' and rownum=1"
sql = "select value from v$parameter where name = 'cpu_count' and rownum=1"
cur.execute(sql)
col1=cur.fetchone()
try:
    num_cpus=[ur'CPU个数',str(col1[0])]
    db_info.append(num_cpus)
except:
    print("sql error")
    print(sql)

sql="select value/1024/1024/1024 from dba_hist_osstat where stat_name = 'PHYSICAL_MEMORY_BYTES' and rownum=1"
cur.execute(sql)
row=cur.fetchone()
try:
    col1=round(float(str(row[0])),1)
    ram_g=[ur'内存(G)',str(col1)]
    db_info.append(ram_g)
except:
    print("sql error")
    print(sql)
os=[ur'操作系统版本',osinfo['ver']]
db_info.append(os)


#ip=[ur"IP地址",ur"在此输入IP地址 "]
ip=[ur"IP地址", ip_address]
db_info.append(ip)

#body.append(table(db_info))
body.append(pagebreak(type='page', orient='portrait'))
body.append(heading(ur'一. 数据库基本信息', 1))
body.append(table(db_info,twunit='dxa',tblw=9000,borders={'all':{"sz": 10, "val": "single", "color": "#000000", "space": "0"}}))

body.append(pagebreak(type='page', orient='portrait'))

"""

#****************************This part create db detail .************************
"""

#service main content
body.append(heading(ur'二. 数据库巡检记录', 1))
db_check_record=[[ur"日期",ur"工程师",ur"客户工程师"]]
#history service record
sections=config.sections()
pattern='^date'
for section in sections:
  match = re.match(pattern,section)
  if match:
    his_date = config.get(section,'date')
    logging.info(his_date)
    first_time=[his_date,lidao_engineer_name,client_dba_name]
    db_check_record.append(first_time)


first_time=[today,lidao_engineer_name,client_dba_name]
db_check_record.append(first_time)

body.append(table(db_check_record,twunit='dxa',tblw=9000,borders={'all':{"sz": 10, "val": "single", "color": "#000000", "space": "0"}}))


body.append(heading(ur'三. 数据增长趋势', 1))
db_check_record=[[ur'日期',"DMP(G)","RMAN(G)","DATA(G)"]]

#read history data from config.ini
sections=config.sections()
pattern='^date'
for section in sections:
  match = re.match(pattern,section)
  if match:
    his_date = config.get(section,'date')
    his_dmp = config.get(section,'dmp')
    his_rman = config.get(section,'rman')
    his_data = config.get(section,'data')
    datagrow=[his_date,his_dmp,his_rman,his_data]
    db_check_record.append(datagrow)

datagrow=[today,dmp,rman,data]
db_check_record.append(datagrow)

#write check information into config.ini
date='date-'+today
try: 
    config.add_section(date)
    config.set(date,'date',today)
    config.set(date,'dmp',dmp)
    config.set(date,'rman',rman)
    config.set(date,'data',data)
    f=open((PWD+"/config.ini"),'w')
    config.write(f)
except:
    print("write check history record to config.ini failed.")
    logging.error("write check history record to config.ini failed.")
    
body.append(table(db_check_record,twunit='dxa',tblw=9000,borders={'all':{"sz": 10, "val": "single", "color": "#000000", "space": "0"}}))

body.append(pagebreak(type='page', orient='portrait'))


body.append(heading(ur'四. 数据库逐项检查', 1))


"""
sqllist: store the sql command from sqlfile.
sqldesclist: store the sql command desc from sqlfile.
"""
sqllist=ur""
sqldesclist=ur""

"""
#******************this part connect to db and fetch data and write to word doc*********************
read from sqlfile and store command/desc in sqllist/sqldesclist
"""
tmpstr=""
#with open(sqlfilename) as f:
f=open(sqlfilename)
for line in f:
    if line == '\n':
        continue
    if not(re.match("prompt",line) or re.match("--",line) or  re.match("exit",line) or
        re.match("col",line) or re.match("alter",line) or re.match("set",line) or re.match("spool",line)):
        sqllist = sqllist + line
    elif (re.match("prompt",line)):
        if (re.match("prompt \'[0-9]*,",line)):
            sqldesclist = sqldesclist + line[6:] +";";                
"""                
seperate sql script with ;and store in sqlcommand list
seperate sqldesc with ; and store in sqldesc list
"""
sqlcommand = sqllist.split(';')
sqldesc = sqldesclist.split(';')


"""
run every sql command in sqlcommand list.
write the sql output to doc in table.
"""

k=0
while (k < len(sqlcommand)-1 and k < len(sqldesc)-1):
    sql = sqlcommand[k]
    sqltext=sqldesc[k]
#    sql=" select name,value$ from sys.props$ where name in('NLS_TERRITORY','NLS_LANGUAGE','NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET')"    
    cur = con.cursor()
    logging.info("now runing sql...")
    logging.info(sql)
    try:
        cur.execute(sql)
    except:
          logging.error(sql)
          print "Execute error ."  
          onerow="    "
          print (sql)
          k=k+1
          continue
#fetch all rows
    try:
        result = cur.fetchall()
    except:
        logging.error(sql)
        print "fetchall fail"
#get column name
    col_names = [row[0] for row in cur.description or []]
    numcols=len(col_names)
    numrows=len(result)
    allrow=[col_names]
#fetch every row
    i=0
    while i< numrows:
        j=0
        newrow=[]
#change every column to str and sotre in newrow list
        while j<numcols:
            col=str(result[i][j])
            newrow.append(col)
            j=j+1
#put newrow list in allrow list tale is list of list
        allrow.append(newrow)
        newrow=[]
        i=i+1
#write sqldesc  to word .  write sqldata to word in table with grid format.
#    body.append(paragraph(sqltext))
    if (re.search("MAX OBJECT ID",sqltext)):
        body.append(heading(ur"1. 检查潜在的风险",2 ))
        body.append(paragraph("'1.1. SCN HEALTH CHECK",style='ListBullet'))
        infotable=[[ur"检查SCN "]]
        for line in osinfo['scn']:
            infotable.append([line])
        body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#000000", "space": "0"}}))

        body.append(paragraph(ur"'1.2. 比特币病毒检测",style='ListBullet'))
        infotable=[[ur"比特币病毒 "]]
        if (len(osinfo['bitcoin300'])>1):
            for line in osinfo['bitcoin300']:
                infotable.append([line])
                body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#000000", "space": "0"}}))
        else:
            infotable.append([ur'没有发现比特币病毒']);
            body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#000000", "space": "0"}}))

    elif (re.search("DB_NAME LOGMODE",sqltext)):
        body.append(heading(ur"2.数据库一览",2 ))
    elif (re.search("DB CONFIGURATION",sqltext)):
        body.append(heading(ur"3.数据库配置",2))
    elif (re.search("CONTROLFILE_LIST",sqltext)):
        body.append(heading(ur"4.数据库物理结构",2))
    elif (re.search("TABLESPACE FRAGMENT",sqltext)):
        body.append(heading(ur"5.表空间",2))
    elif (re.search("CHAINED TABLES",sqltext)):
        body.append(heading(ur"6.表/索引/约束/触发器",2))
    elif (re.search("USER INFO",sqltext)):
        body.append(heading(ur"7.用户定义",2))
    elif (re.search("DB STATS AUTO GATHER",sqltext)):
        body.append(heading(ur"8.统计信息自动收集",2))
    elif (re.search("DB  Block  Buffer  Hit Ratio",sqltext)):
        body.append(heading(ur"9.性能",2))
#print sql desc
#add try
    try:
        body.append(paragraph(sqltext, style='ListBullet'))
        body.append(table(allrow,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#000000", "space": "0"}}))
    except:
        print "body.append table error"
        print sqltext
    k=k+1

    if (re.search("DB VERSION",sqltext)):
        opatchtable=[[ur"数据库补丁信息"]]
        for line in osinfo['patch']:
            opatchtable.append(line)
        try: 
            body.append(table(opatchtable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#000000", "space": "0"}}))
        except:
            print "get patch info fail"
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))

        points = [ur'没有遭遇数据库管理软件bug. (这个版本是oracle 11gR2最终版本；Oracle对此版本的服务截止2020.12月,已经停止)']
        body.append(paragraph(points))

        points = [(ur'建议','bu')]
        body.append(paragraph(points))

        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("DB COMP STATUS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库组件状态都应该是VALID']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("NON-DEFAULT DB PARAMETERS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库参数设置不能为默认值，需要由资深dba进行具体优化处理',
                ur'此项没有标准得衡量标准，特定应用特定对待，能够满足应用需要得即为合理']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("DB RESOURCE LIMITS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points=[ur'MAX_UTILIZATION对应的值应该小于LIMIT_VALUE的值。']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("CONTROLFILE_SIZE",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points=[ur'控制文件采取2份以上的镜像。']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("ARCHIVELOG RUSH HOUR",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points=[ur'高峰时没有等待日志切换。']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("PASSWORD_LIFE_TIME",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'用户密码不存在180天有效期限制。']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        if (numrows>0):
        	points = [ur'检查用户密码是否将要过期,避免登录失败']
        else:
        	points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("CREATE SESSION AUDIT",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'如开启审计，不审计普通session 连接。']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [ur'关闭普通连接审计选项.']
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("AUDIT TRAIL",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'关闭审计,或者明确审计日志存放位置并定期清理.']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [ur'如果是db,检查system表空间的v$aud表,如果是os，经常检查审计日志目录:df-h,df -i']
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("RECYCLEBIN",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'回收站不能有太多未清空的表或索引.']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'定期purge recyclebin;清理回收站'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("LOGFILE",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'日志文件应该每组有2个以上成员']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果只有一个,建议增加'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("DATAFILE",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库文件的状态都为ONLINE.',
                ur'手动扩展表空间，不用自动扩展']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果使用自动扩展,监控文件系统空间或者磁盘组空间剩余情况'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("TEMPFILE",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'手动扩展临时表空间. 临时文件如果自动扩展，易在不良的大排序下极度消耗存储空间，造成目录填满或性能问题']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("INVALID DATA FILE",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'系统中不能存在数据文件损坏的情况']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("TABLESPACE FRAGMENT",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'应该使用本地表空间管理.如果使用字典表空间管理,碎片越少越好.']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'没有返回说明表空间都使用本地管理.'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("DISKGROUP MONITOR",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'磁盘组的空间剩余情况在文件系统中看不见,要经常关注.',ur'使用率高于80%时需要准备扩展空间。']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果磁盘组使用超过80%,建议扩展'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("TABLESPACE MONITOR",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'关闭自动扩展的表空间',ur'使用率达到或者超过80％应准备扩展空间']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("UNDO SEGMENT MONITOR",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'回滚段表空间使用率低于80％']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [ur'1.目前参数undo_management=auto 表明数据库处于回滚段自动管理模式下',
                            ur'2.只需要监控回滚表空间undo_tablespace=undotbs1的使用率即可',
                            ur'3.在回滚表空间使用率接近100％时及时添加数据文件']
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("UNDO SEGMENT RATIO",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'回滚空间等待应接近0']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [ur'1目前是自动管理回滚空间,wait应该接近0,否则应扩大回滚表空间']
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("BIG SEGMENT",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中比较大的segment要关注其增长原因和速度']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        points = [ur'关注其增长情况']
        body.append(paragraph(points))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("LARGE UNPARTITIONED TABS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'上述表都是较大的表，对于超过2G以上的表，数据有明显冷热特点的大表，我们建议对表进行分区.',
                    ur'从物理上将大表分成几个小的分区表，但在逻辑上还是一张表，对于应用透明。',
                    ur'这样做的好处是： 1，性能的提高，可以尽量控制数据访问的粒度； 2，对数据的可用性提高']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'建议跟应用开发沟通,分区大表'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("DB STATS AUTOTASK WINDOW",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'确认统计信息是按照应用需要,自动或者手动收集']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'根据应用对数据修改情况,定时主动/或者自动收集统计信息'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("AWR SNAPSHOT KEEP TIME",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'awr快照频率和保存时间,建议一小时一次,保留30天']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果保留时间少于30天,建议扩展到30天.'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("CHAINED TABLES",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中不存在行迁移或者行链接的表']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果有,建议导出导入或者移动表以消除行迁移或者行链接'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("NDEX LEVEL > 3",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中索引level不大于3']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'建议重建level大于3的索引'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("UNUSABLE INDEXES",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中不存在失效索引']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'建议重建失效索引或者删除'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("TABLE,INDEX IN SAME TABLESPACE",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中的表的数据和索引的数据应存放在各自专属表空间']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果有,建议将表和索引分开,便于日常维护'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("UNSYSTEM OBJ IN SYSTEM",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'系统表空间中不存放任何用户数据']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'建议将这些数据移动到用户表空间'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("INVALID CONSTRAINTS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中不存在失效约束']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'跟应用确认,如果需要,重建或者这些约束,如果不需要可以删除.'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("INVALID TRIGGERS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中不存在失效触发器']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'跟应用确认,如果需要,重建或者这些触发器,如果不需要可以删除.'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("INVALID OBJECTS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中不存在失效对象']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'跟应用确认,如果需要,重建或者这些对象,如果不需要可以删除.'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("USER INFO",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'数据库中不适用的用户状态为LOCK']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'对于上述开启的帐户确认是否应用需要的帐户，对于不使用的帐户建议lock或删除'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("SUPER USERS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'拥有数据库启停权限的用户只能是sys']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'上述用户拥有较高的管理角色权限，注意此类用户的密码控制'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("DBA PRIVS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'dba权限.拥有DBA权限的用户,是按照需求授予的']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'没有非需求用户被授予dba权限'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("SYS PRIVS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'sys权限.拥有SYS权限的用户,是按照需求授予的']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'没有非需求用户被授予dba权限'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
    elif (re.search("OBJECT PRIVS",sqltext)):
        points = [(ur'健康指标','bu')]
        body.append(paragraph(points))
        points = [ur'对象权限.数据库中的对象权限是按照需求授予的']
        body.append(paragraph(points))
        points = [(ur'建议','bu')]
        body.append(paragraph(points))
        body.append(paragraph(ur'如果存在不合理数据访问，需回收相应对象权限(限于文档大小,只列10条)'))
        points = [(ur'正常','bu')]
        body.append(paragraph(points))
body.append(pagebreak(type='page', orient='portrait'))
ostitle=ur"9. AWR报告"
body.append(heading(ostitle ,2))

body.append(pagebreak(type='page', orient='portrait'))
ostitle=ur"10. 告警日志"
body.append(heading(ostitle ,2))
infotable=[[ur"错误信息"]]
for line in osinfo['dberr']:
    infotable.append([line])
try:
    body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))
except:
    print(" add dberr FAIL")

"""
*******************This part get OS information ***************************
os information
"""
body.append(pagebreak(type='page', orient='portrait'))

#try:
#    for line in osinfo['hostname']:
#        body.append(paragraph(line))
#except:
#    print("hostname fail")

#hostname=str(line)
#filename=hostname+"_"+filename
ostitle=ur"五. "+hostname+ "  硬件信息"
body.append(heading(ostitle ,1))


osver=ur"1. OS版本"
body.append(heading(osver ,2))

infotable=[[ur"OS 版本信息"]]
for line in osinfo['ver']:
    infotable.append([line])
for line in osinfo['uname']:
    infotable.append([line])
try:
    body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#000000", "space": "0"}}))
except:
    print(" add ver uname FAIL")


meminfo=ur"2. 内存"
body.append(heading(meminfo ,2))

infotable=[[ur"内存 "]]
for line in osinfo['vmstat']:
    infotable.append([line])
try:
    body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))
except:
    print(" add vmstat FAIL")

meminfo=ur"3. 磁盘IO(iostat) "
body.append(heading(meminfo ,2))
infotable=[[ur"IOSTAT "]]
for line in osinfo['iostat']:
    infotable.append([line])
try:
    body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))
except:
    print(" add IOSTAT FAIL")
#output top cpu usage

ostitle=ur"六. "+hostname+ "  OS性能"
body.append(heading(ostitle ,1))
meminfo=ur"1. CPU当前LOAD"
body.append(heading(meminfo ,2))

infotable=[[ur"CPU LOAD "]]
for line in osinfo['top']:
    infotable.append([line])
body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))
meminfo=ur"2. CPU历史LOAD"
body.append(heading(meminfo ,2))
meminfo=ur"过去30天CPU LOAD前20,取自dba_hist_osstat"
body.append(paragraph(meminfo))

sql="select to_char(round(s.end_interval_time, 'hh24'), 'yyyy-mm-dd hh24') snap_time, os.instance_number,os.value \"CPU_LOAD(%)\" from dba_hist_snapshot s, dba_hist_osstat os where s.dbid = os.dbid and s.instance_number = os.instance_number and s.snap_id = os.snap_id and os.stat_name = 'LOAD' AND S.END_INTERVAL_TIME between sysdate-30 and sysdate and rownum <= 10 order by os.value desc ,to_char(trunc(s.end_interval_time, 'hh24'), 'yyyy-mm-dd hh24'), os.instance_number"
cur = con.cursor()
try:
    cur.execute(sql)
except Exception:
      print sql
      print "Execute error ."  
      onerow="    "
try:
    result = cur.fetchall()
except:
    print "execute fail"
    print sql
col_names = [row[0] for row in cur.description or []]
numcols=len(col_names)
numrows=len(result)
allrow=[col_names]
i=0
while i< numrows:
    j=0
    newrow=[]
    while j<numcols:
        col=str(result[i][j])
        newrow.append(col)
        j=j+1
    allrow.append(newrow)
    newrow=[]
    i=i+1

body.append(table(allrow,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))

#test  MEM usage top 10
#"ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10"
body.append(paragraph(""))

meminfo=ur"3. 内存占用top 10进程"
body.append(heading(meminfo ,2))

infotable=[[ur"top mem using process "]]
for line in osinfo['topmem']:
    infotable.append([line])
body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))
#test CPU usage top 10
#ps = subprocess.Popen(["top b -n1 | head -17 | tail -11"],stdout=subprocess.PIPE)
meminfo=ur"4. CPU 占用top 10进程"
body.append(heading(meminfo ,2))
infotable=[[ur"top cpu using process "]]
for line in osinfo['topcpu']:
    infotable.append([line])
body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))

# OS health check
points = [(ur'健康指标','bu')]
body.append(paragraph(points))

points = [ur'CPU使用率（LOAD）要长时间低于70％; ',ur'内存不出现使用虚拟内存的现象;  ',ur'IO WAIT 小于15％']
body.append(paragraph(points))

points = [(ur'建议','bu')]
body.append(paragraph(points))


osdk=ur"5. 磁盘使用率(df -Ph)"
body.append(heading(osdk ,2))

infotable=[[ur"df -Ph "]]
for line in osinfo['df']:
    infotable.append([line])
body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))

osdk=ur"6. inode使用情况df -Pi"
body.append(heading(osdk ,2))

infotable=[[ur"df -Pi "]]
for line in osinfo['dfinode']:
    infotable.append([line])
body.append(table(infotable,twunit='auto',tblw=9000,borders={'all':{"sz": 8, "val": "single", "color": "#FFFFFF", "space": "0"}}))
# OS health check
points = [(ur'健康指标','bu')]
body.append(paragraph(points))

points = [ur'数据库安装软件目录和数据文件存放目录使用率不超过70%;   ',ur'每个目录inode使用率不超过70%']
body.append(paragraph(points))

points = [(ur'建议','bu')]
body.append(paragraph(points))

body.append(pagebreak(type='page', orient='portrait'))
ostitle=ur"七. 总结和建议"
body.append(heading(ostitle ,1))

ostitle=ur"(一). 巡检总结"
body.append(heading(ostitle ,2))

sumall=ur"数据安全性: "
body.append(paragraph(sumall,style='ListBullet'))
body.append(paragraph(ur"*. 部署RMAN备份: "))
body.append(paragraph(ur"*. 部署数据泵导出: "))
body.append(paragraph(ur"*. 部署同步到灾备: "))
body.append(paragraph(ur"*. 部署dataguard: "))
sumall=ur"数据库稳定性: "
body.append(paragraph(sumall,style='ListBullet'))
body.append(paragraph(ur"数据库版本稳定. oracle 已经停止对11g支持。建议测试Oracle 19c."))
sumall=ur"数据库可用性: "
body.append(paragraph(sumall,style='ListBullet'))
body.append(paragraph(ur"*. 部署RAC: "))
body.append(paragraph(ur"*. 部署同步到灾备: "))
body.append(paragraph(ur"*. 部署dataguard: "))
sumall=ur"数据库性能: "
body.append(paragraph(sumall,style='ListBullet'))
body.append(paragraph(ur"数据库目前性能良好."))

ostitle=ur"(二）. 主要建议"
body.append(heading(ostitle ,2))
sumall=ur"数据安全性"
body.append(paragraph(sumall,style='ListBullet'))
body.append(paragraph(ur"*. 检查rman备份日志，确保备份成功，归档空间被清理；"))
body.append(paragraph(ur"*. 定期rman恢复测试，确保rman备份可用"))
body.append(paragraph(ur"*. 定期数据泵导入测试，确保备份可用."))
body.append(paragraph(ur"*. 定期DataGuard切换测试."))
body.append(paragraph(ur"*. 定期灾备库切换，确保它们在需要时可用"))


sumall=ur"数据库可用性"
body.append(paragraph(sumall,style='ListBullet'))
sumall=ur"数据库性能"
body.append(paragraph(sumall,style='ListBullet'))

################

#print(filename)
filename=filename+"_"+filename_end+"_"+today
savedocx(document, coreprops, appprops, contenttypes, websettings, wordrelationships, filename+'.docx')
print "done."

