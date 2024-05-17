@echo off
setlocal enabledelayedexpansion

Set BaseInfoFile=cfg\info.ini
if not exist %BaseInfoFile% (
	echo no info.ini file！
        pause
	goto END
)
set h=%time:~0,2%
set h=%h: =0%
set today=%date:~0,4%-%date:~5,2%-%date:~8,2%_%h%-%time:~3,2%-%time:~6,2%
for /F "tokens=1-5 delims=," %%a in (%BaseInfoFile%) do (
	echo -------------------------------------------------
	echo                    start %%a healthcheck
	echo -------------------------------------------------
	echo -------------------------------------------------
	echo                      create backup directory
	echo -------------------------------------------------
    echo "plink -l oracle -pw %%b %%a  mkdir -p /home/oracle/scripts/old/%today%"
	plink -l oracle -pw %%b %%a  mkdir -p /home/oracle/scripts/old/%today%


	echo -------------------------------------------------
	echo  move old tar.gz to /home/oracle/scripts/old
	echo -------------------------------------------------
	plink -l oracle -pw %%b %%a mv /home/oracle/scripts/healthcheck/*.tar.gz /home/oracle/scripts/old/%today%/

	echo -------------------------------------------------
	echo                     run health check
	echo -------------------------------------------------
	plink -l oracle -pw %%b %%a cd /home/oracle/scripts/healthcheck;./hc.sh;

	echo -------------------------------------------------
	echo                     clear lsnr log and audit log
	echo -------------------------------------------------

	plink -l oracle -pw %%b %%a cd /home/oracle/scripts/healthcheck;./hcscripts/clear_oracle_lsnr_aud_log.sh

	echo -------------------------------------------------
	echo               download to local output
	echo -------------------------------------------------
	if not exist output	mkdir output
	pscp -pw %%b oracle@%%a:/home/oracle/scripts/healthcheck/output*.gz output
	pscp -pw %%b oracle@%%a:/home/oracle/scripts/healthcheck/config.ini cfg/%%c


)
echo -------------------------------------------------
echo               healthcheck finished.
echo -------------------------------------------------
pause
