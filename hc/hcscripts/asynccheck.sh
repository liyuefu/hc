echo "check async..">asynccheck.out
sqlplus -s 
show parameter filesystemioa;
show parameter disk_asynch_io;

cat /proc/sys/fs/aio-max-nr >>asynccheck.out
cat /proc/sys/fs/aio-nr >>asynccheck.out
sqlplus -s 
COL NAME FORMAT A50
SELECT NAME,ASYNCH_IO FROM V$DATAFILE F,V$IOSTAT_FILE I
WHERE F.FILE#=I.FILE_NO
AND FILETYPE_NAME='Data File';
