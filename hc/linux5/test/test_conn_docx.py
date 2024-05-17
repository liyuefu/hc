#!/usr/bin/env python


from docx import *
import cx_Oracle
import csv
import codecs
from codecs import open

con = cx_Oracle.connect('lyf/lyf')
cur = con.cursor()

sqlfile = "1.sql"
#sql = open(sqlfile, mode='r', encoding='utf-8').read()
sql = open(sqlfile, mode='r').read()
cur.execute(sql)

# Default set of relationshipships - the minimum components of a document
relationships = relationshiplist()

# Make a new document tree - this is the main part of a Word document
document = newdocument()

# This xpath location is where most interesting content lives
body = document.xpath('/w:document/w:body', namespaces=nsprefixes)[0]

# Append two headings and a paragraph
body.append(heading("DATABSSE HEALTH", 1))
body.append(heading('TABLESPACE MONITOR', 2))
allrow=cur.fetchall()
for col in(allrow):
    onerow=""
    for val in (col):
        onerow=onerow+val
        body.append(paragraph(onerow))

#body.append(paragraph('Tables are just lists of lists, like this:'))
 # Append a table
tbl_rows = [ ['A1', 'A2', 'A3']
           , ['B1', 'B2', 'B3']
           , ['C1', 'C2', 'C3']
           ]
body.append(table(tbl_rows))



body.append(pagebreak(type='page', orient='portrait'))

body.append(heading('Ideas? Questions? Want to contribute?', 2))
body.append(paragraph('Email <python.docx@librelist.com>'))

# Create our properties, contenttypes, and other support files
title    = 'Leader Oracle Document'
subject  = 'Database Health check'
creator  = 'lyf'
keywords = ['Oracle', 'health', 'phtyon']

coreprops = coreproperties(title=title, subject=subject, creator=creator,
                           keywords=keywords)
appprops = appproperties()
contenttypes = contenttypes()
websettings = websettings()
wordrelationships = wordrelationships(relationships)
# Save our document
savedocx(document, coreprops, appprops, contenttypes, websettings,
         wordrelationships, 'test4.docx')


