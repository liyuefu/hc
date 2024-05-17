spool rmansize.out
archive log list;
colum rmansum noprint
BREAK ON rmansum
COMPUTE SUM OF "Size MB" ON rmansum
select null rmansum,ctime "Date"
   , decode(backup_type, 'L', 'Archive Log', 'D', 'Full', 'Incremental') backup_type
    , bsize "Size MB"
from (select trunc(bp.completion_time) ctime
     , backup_type
      , round(sum(bp.bytes/1024/1024),1) bsize
       from v$backup_set bs, v$backup_piece bp
       where bs.set_stamp = bp.set_stamp
       and bs.set_count  = bp.set_count
      and bp.status = 'A'
      group by trunc(bp.completion_time), backup_type)
   order by 1, 2;
spool off
exit;
