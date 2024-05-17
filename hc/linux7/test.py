##coding=utf-8
#!/usr/bin/env python
from docx import *
from docx.shared import Pt
from docx.oxml.ns import qn
from docx.oxml.ns import nsdecls
from docx.oxml import parse_xml
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.text import WD_ALIGN_PARAGRAPH,WD_LINE_SPACING
from docx.enum.text import WD_TAB_ALIGNMENT
from docx.shared import Inches #支持修改图片大小的库
from docx.shared import RGBColor#设置字体
import codecs
from codecs import open
import re
import cx_Oracle
import subprocess
from datetime import date
from configobj import ConfigObj
import sys
reload(sys)
sys.setdefaultencoding("utf-8")
sqlfilename=sys.argv[1]
oraclehome=sys.argv[2]
jpgfilepath="/home/oracle/scripts/healthcheck/hcscripts/"
"""
Desc: check database status and create word document.
Env: RH6. Python2.6. Oracle 11.2.0.4
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
update: 2020.11.19. rewrite for linux7
update: 2020.11.26. add try except for subprocess linux command
update: 2020.11.27. add font change.
update: 2021.02.01  change linuxoutput format to size 10
update: 2021.06.20. change table first row color
update: 2021.09.02 v20210902.
        fixed lspatch exception catch bug.
update: 2022.06.13. v0220613 red config info from config.ini.

"""

##########################read config.ini##############################
cfg=ConfigObj("/home/oracle/scripts/healthcheck/config.ini",encoding='UTF-8')
client_name=cfg['client']['client_name']
client_app_name=cfg['client']['client_app_name']
client_app_db_name=cfg['client']['client_app_db_name']
client_dba_name=cfg['client']['client_dba_name']

lidao_tech_manager=cfg['lidao']['lidao_tech_manager']
lidao_sales_name=cfg['lidao']['lidao_sales_name']
lidao_engineer_name=cfg['lidao']['lidao_engineer_name']
lidao_header=cfg['lidao']['lidao_header']
lidao_copyright=cfg['lidao']['lidao_copyright']
lidao_name=cfg['lidao']['lidao_name']
lidao_address=cfg['lidao']['lidao_address']
lidao_tel=cfg['lidao']['lidao_tel']

hc_1=cfg['healthcheck_record']['date1']
hc_2=cfg['healthcheck_record']['date2']

#add hc record
today=str(date.today())
cfg['healthcheck_record']['3'] = today
cfg.write()

