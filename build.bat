@echo off
cls

set stall=false

jai build.jai - %*

if %errorlevel%==0 goto :start_tool
goto :end

:start_tool
	pushd out
	
	REM start RGUI.exe
	FOR %%f IN (*.exe) DO (
		  set executable=%%f
		  GOTO :cont
		)
	:cont
	if exist "%executable:~0,-4%.pdb" del /f "%executable:~0,-4%.pdb"
	if %stall% equ true start "" cmd /k "%executable%"
	if %stall% equ false start "" "%executable%"
	
	popd

:end
	echo.
