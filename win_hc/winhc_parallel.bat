@echo off
setlocal enabledelayedexpansion

Set BaseInfoFile=cfg\info.ini
if not exist %BaseInfoFile% (
	echo info.ini file NOT FOUND！
        pause
	goto END
)

for /F "tokens=1-5 delims=," %%a in (%BaseInfoFile%) do (
    start /b runcheck.bat %%a %%b %%c
        echo %%a %%b %%c
)

echo -------------------------------------------------
echo               check finished.
echo -------------------------------------------------
echo.&pause&goto:EOF

::--------------------------------------------------------
::-- Function do_check
::-- %%a: ip, %%b: oracle pwd, %%c: config file.
::--------------------------------------------------------
:do_check    - here starts my function identified by it's label
echo.
echo. checking %~1 begin...
set h=%time:~0,2%
set h=%h: =0%
set today=%date:~0,4%-%date:~5,2%-%date:~8,2%_%h%-%time:~3,2%-%time:~6,2%

plink -l oracle -pw %~2 %~1  mkdir -p ./scripts/old/%today%
plink -l oracle -pw %~2 %~1 mv ./scripts/healthcheck/ ./scripts/old/%today%/
plink -l oracle -pw %~2 %~1  mkdir -p ./scripts/healthcheck
pscp -pw %~2 scripts\*.tar.gz cfg\%~3 oracle@%~1:./scripts/healthcheck
plink -l oracle -pw %~2 %~1 cd ./scripts/healthcheck;tar -zxf *.tar.gz ;cp %~3 config.ini
plink -l oracle -pw %~2 %~1 cd ./scripts/healthcheck;./hc.sh;
plink -l oracle -pw %~2 %~1 cd ./scripts/healthcheck;./hcscripts/clear_oracle_lsnr_aud_log.sh
if not exist output	mkdir output
pscp -pw %~2 oracle@%~1:./scripts/healthcheck/output*.gz output
pscp -pw %~2 oracle@%~1:./scripts/healthcheck/config.ini cfg/%~3
echo. checking %~1 finished...
goto :EOF

