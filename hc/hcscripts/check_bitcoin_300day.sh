#!/bin/bash
. ~/.bash_profile
CHECK_TIME=`date +%Y%m%d_%H%M`
CHECK_FILE=bitcoin300.out


DBVER=`cat /tmp/dbver.txt`

if [ ${DBVER} == '10g' ]; then
   DBNAME=`cat /tmp/dbname.txt`
   ALERT_PATH=$ORACLE_BASE/diag/rdbms/$DBNAME/$ORACLE_SID/trace
else
   ALERT_PATH=$(sqlplus -S / as sysdba <<EOF
set heading off;
set termout off;
set echo off;
select trim(value) from v\$diag_info where name='Diag Trace';
EOF
)
fi
ALERT_FILE=${ALERT_PATH}/alert_$ORACLE_SID.log

sqlplus -S / as sysdba <<EOF > ${CHECK_FILE}
!echo '(1):select statement for check attack dba_objects view'  
COL OWNER FOR A20
COL OBJECT_NAME FOR A80
COL OBJECT_TYPE FOR A10
COL SQL_STATMENT FOR A180
SET LINE 200 PAGES 99
SELECT OWNER, '"'||OBJECT_NAME||'"' OBJECT_NAME,OBJECT_TYPE,TO_CHAR(CREATED, 'YYYY-MM-DD HH24:MI:SS') CREATED
    FROM DBA_OBJECTS
    WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';
    
!echo '(2):drop  statement for check attack dba_objects view' 
SELECT '    DROP '||OBJECT_TYPE||' "'||OWNER||'"."'||OBJECT_NAME||'";' SQL_STATMENT
    FROM DBA_OBJECTS
    WHERE OBJECT_NAME LIKE 'DBMS_CORE_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SYSTEM_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_SUPPORT_INTERNA%'
    OR OBJECT_NAME LIKE 'DBMS_STANDARD_FUN9%';

!echo '(3):select statement for check attack dba_jobs view'
COL LOG_USER FOR A20
COL WHAT FOR A120
SELECT JOB, LOG_USER, WHAT 
    FROM DBA_JOBS
    WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;
    
!echo '(4):drop job  statement for check attack dba_jobs view'
SELECT '    -- Logon with '||LOG_USER||CHR(10)||'    EXEC DBMS_JOB.BROKEN ('||JOB||', ''TRUE'')'||CHR(10)||'    EXEC DBMS_JOB.REMOVE('||JOB||')' SQL_STATMENT
  FROM DBA_JOBS
  WHERE WHAT LIKE 'DBMS_STANDARD_FUN9%' ;

!echo '(5):check 300 day delete tab$'
SELECT 'DROP PROCEDURE '||OWNER||'."'||OBJECT_NAME||'";' 
FROM DBA_OBJECTS WHERE OBJECT_NAME ='DBMS_SUPPORT_DBMONITORP' 
UNION ALL SELECT 'DROP TRIGGER '||OWNER||'."'||TRIGGER_NAME||'";' 
FROM DBA_TRIGGERS WHERE TRIGGER_NAME ='DBMS_SUPPORT_DBMONITOR';

EXIT;  
EOF

value1=`grep -i "Hi buddy, your database was hacked by SQL RUSH Team, send 5 bitcoin to address" ${ALERT_FILE}|wc -l`
value2=`grep -i "INTERNAL" ${CHECK_FILE}|wc -l`
if [ $value1 -ge 1 ]
then
   echo "YES bit attack database"
elif [ $value2 -ge 1 ]
then 
   echo "##########################################!!!!!!!!##################">>${CHECK_FILE}
   echo "!!!!!!!!!!!!!!!!YES bit attack database!!!!!!!!!!!!!!!!"
   echo "YES BITCOIN attack database!!!!!!!!!!!!!!">>${CHECK_FILE}
   echo "##########################################!!!!!!!!##################">>${CHECK_FILE}
else
   echo "---------------------------------------"
   echo "NO bit attack database"
   echo "---------------------------------------">>${CHECK_FILE}
   echo "NO bit attack database">>${CHECK_FILE}

fi
#grep -i 'Hi buddy, your database was hacked by SQL RUSH Team, send 5 bitcoin to address' ${ALERT_FILE} >> ${CHECK_FILE}

value=`grep -i "create or replace trigger DBMS_SUPPORT_DBMONITOR" $ORACLE_HOME/rdbms/admin/prvtsupp.plb|wc -l `
if [ $value -ge 1 ]
then
   echo "!!!!!!!!!!!!!!!!YES 300 day del \$tab attach database!!!!!!!!!!!!!"
   echo "##########################################!!!!!!!!##################"
   echo "##########################################!!!!!!!!##################">>${CHECK_FILE}
   echo "YES 300DAY del \$tab attach database!!!!!!!!!!!!!">>${CHECK_FILE}
   echo "change $ORACLE_HOME/rdbms/admin/prvtsupp.plb!!!!!">> ${CHECK_FILE} 
else
   echo "---------------------------------------"
   echo "NO 300 day del \$tab attach database" 
   echo "---------------------------------------">>${CHECK_FILE}
   echo "NO 300 day del \$tab attach database" >>${CHECK_FILE}
   echo "---------------------------------------">>${CHECK_FILE}

fi
