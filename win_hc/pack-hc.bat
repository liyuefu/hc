set HC_PATH=hc
set RELEASE_PATH=..\..\release
set WIN_HC_PATH=win_hc
set h=%time:~0,2%
set h=%h: =0%
set today=%date:~0,4%-%date:~5,2%-%date:~8,2%-%h%_%time:~3,2%-%time:~6,2%

cd ..\%HC_PATH%
"C:\Program Files\7-Zip\7z.exe" a -r -tzip %RELEASE_PATH%\%HC_PATH%_%today% *.*
del /Q ..\%WIN_HC_PATH%\scripts\*.*
cd ..\%WIN_HC_PATH%
plink -l oracle -pw oracle 192.168.56.7  rm -rf ./scripts/healthcheck/;mkdir -p ./scripts/healthcheck
pscp -pw oracle %RELEASE_PATH%\%HC_PATH%_%today%.zip  oracle@192.168.56.7:./scripts/healthcheck
plink -l oracle -pw oracle 192.168.56.7  cd ./scripts/healthcheck ; unzip -oqq *.zip;chmod +x *.sh;rm -f hc*.zip
plink -l oracle -pw oracle 192.168.56.7  cd ./scripts/healthcheck/;tar czf %HC_PATH%_%today%.tar.gz *
pscp -pw oracle oracle@192.168.56.7:./scripts/healthcheck/*.tar.gz  scripts
del /Q %RELEASE_PATH%\*.tar.gz
del /Q %RELEASE_PATH%\*.zip
copy scripts\*.tar.gz %RELEASE_PATH%


"C:\Program Files\7-Zip\7z.exe" a -r -tzip %RELEASE_PATH%\%WIN_HC_PATH%_%today% cfg scripts *.exe *.bat *.txt

