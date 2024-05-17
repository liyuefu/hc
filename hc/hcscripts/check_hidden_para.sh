#!/bin/bash
source ~/.bash_profile

sqlplus -S / as sysdba <<EOF > check_hidden_para.out
set linesize 150
set pagesize 99
set feedback off
col name for a40
col value for a20
select x.ksppinm  name, y.ksppstvl  value, y.ksppstdf  isdefault, decode(bitand(y.ksppstvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE')  ismod, decode (bitand(y.ksppstvf,2),2,'TRUE','FALSE')     isadj from sys.x\$ksppi x, sys.x\$ksppcv y where x.inst_id = userenv('Instance') and y.inst_id = userenv('Instance') and x.indx = y.indx  and  x.ksppinm in ('_optimizer_use_feedback','_use_adaptive_log_file_sync','_optim_peek_user_binds','_optimizer_extended_cursor_sharing_rel','_optimizer_extended_cursor_sharing','_optimizer_adaptive_cursor_sharing','_in_memory_undo','_memory_imm_mode_without_autosga','_b_tree_bitmap_plans','_gc_policy_time')   order by translate(x.ksppinm, ' _', ' ');

exit;
EOF

#alter system set "_optim_peek_user_binds"=false scope=spfile sid='*';
#alter system set "_optimizer_extended_cursor_sharing_rel"=none scope=spfile sid='*';
#alter system set "_optimizer_extended_cursor_sharing"=none scope=spfile sid='*';
#alter system set "_optimizer_adaptive_cursor_sharing"=false scope=spfile sid='*';
#alter system set "_in_memory_undo"=false scope=spfile sid='*';
#alter system set "_memory_imm_mode_without_autosga"=false scope=spfile sid='*';
#alter system set "_b_tree_bitmap_plans"=false scope=spfile sid='*';
#alter system set "_gc_policy_time"=0 scope=spfile sid='*';

