::
:: zipme batch script for 'Oh!Crab'
::
SET LOVE_PATH=C:\LOVE
SET NSIS_PATH="C:\Program Files (x86)\NSIS\makensis.exe" 
SET ZIPEXE="C:\Program Files\WinRAR\WinRAR.exe"
SET GAMENAME=Oh!Crab
SET PACKAGE_DIR=%GAMENAME%
SET ZIPFILE=%GAMENAME%.zip
SET LOVEFILE=%GAMENAME%.love

FOR /F "tokens=1 delims=" %%A in ('git describe --dirty --tags') do SET GITDESCRIBE=%%A
FOR /F "tokens=1 delims=" %%A in ('git rev-list --count HEAD') do SET GITNUMCOMMITS=%%A

%ZIPEXE% a -y -afzip %ZIPFILE% utils sti *.ogg *.png *.lua
move %ZIPFILE% %LOVEFILE%
mkdir %PACKAGE_DIR%

timeout /T 1 > nul
copy /b %LOVE_PATH%\love.exe+%LOVEFILE% %PACKAGE_DIR%\game.exe
copy /b %LOVE_PATH%\*.dll %PACKAGE_DIR%
copy /b %LOVE_PATH%\license.txt %PACKAGE_DIR%
copy /b res\icon.ico %PACKAGE_DIR%

%ZIPEXE% a -y -afzip %GAMENAME%_%GITDESCRIBE%.zip Oh!Crab

pause