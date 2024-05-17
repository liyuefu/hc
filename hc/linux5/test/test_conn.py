#!/usr/bin/env python

from docx import *
import cx_Oracle
import csv
import codecs
from codecs import open


con = cx_Oracle.connect('lyf/lyf')
cur = con.cursor()
#sql = "select b.log_mode,decode(a.name,'instance_name',a.value) instance_name,decode(a.name,'db_name',a.value) db_name from v$parameter a,v$database b where a.name in('db_name','instance_name') "

sql = 'select table_name from user_tables where rownum < 3 order by 1'
cur.execute(sql)
"""
for i in xrange(cur.rowcount):
    a, b = cur.fetchone()
    print a, b
"""
"""
result = cur.fetchmany()
while result:
    for  a,b,c in result:
        print a,b,c
    result = cur.fetchmany()
"""
result = cur.fetchall()
col_names = [row[0] for row in cur.description or []]
allrow=[col_names]
while result:
    cnt=len(result)
    newrow=[]
    i=0
    while i<cnt:
        col=str(result[i])
        newrow.append(col)
        i=i+1
    allrow.append(newrow)
    result = cur.fetchmany()
print allrow
"""
for a, b in cur.fetchall():
    print a, b
"""

