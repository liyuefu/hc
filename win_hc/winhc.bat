@echo off
setlocal enabledelayedexpansion

Set BaseInfoFile=cfg\info.ini
if not exist %BaseInfoFile% (
	echo info.ini file NOT FOUND！
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
    echo "plink -l oracle -pw %%b %%a  mkdir -p ./scripts/old/%today%"
	plink -l oracle -pw %%b %%a  mkdir -p ./scripts/old/%today%


	echo -------------------------------------------------
	echo  move history tar.gz to ./scripts/old
	echo -------------------------------------------------
	plink -l oracle -pw %%b %%a mv ./scripts/healthcheck/ ./scripts/old/%today%/
	plink -l oracle -pw %%b %%a  mkdir -p ./scripts/healthcheck

	echo -------------------------------------------------
	echo                      upload scripts
	echo -------------------------------------------------
	pscp -pw %%b scripts\*.tar.gz cfg\%%c oracle@%%a:./scripts/healthcheck

	echo -------------------------------------------------
	echo                      unzip scripts
	echo -------------------------------------------------
	plink -l oracle -pw %%b %%a cd ./scripts/healthcheck;tar zxf *.tar.gz ;cp %%c config.ini

	echo -------------------------------------------------
	echo                     run scripts
	echo -------------------------------------------------
	plink -l oracle -pw %%b %%a cd ./scripts/healthcheck;./hc.sh;

	echo -------------------------------------------------
	echo                     clear lsnr log and audit log.
	echo -------------------------------------------------

	plink -l oracle -pw %%b %%a cd ./scripts/healthcheck;./hcscripts/clear_oracle_lsnr_aud_log.sh

	echo -------------------------------------------------
	echo               download to local output
	echo -------------------------------------------------
	if not exist output	mkdir output
	pscp -pw %%b oracle@%%a:./scripts/healthcheck/output*.gz output
	pscp -pw %%b oracle@%%a:./scripts/healthcheck/config.ini cfg/%%c


)
echo -------------------------------------------------
echo               check finished.
echo -------------------------------------------------
pause
