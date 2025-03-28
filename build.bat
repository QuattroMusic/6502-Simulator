@echo off
cls

jai build.jai - %*

if %errorlevel%==0 goto :start_tool
goto :end

:start_tool
	pushd out
	
	FOR %%f IN (*.exe) DO (
		set executable=%%f
		GOTO :cont
	)
	:cont
	if exist "%executable:~0,-4%.pdb" del /f "%executable:~0,-4%.pdb"
	start "%executable:~0,-4% - Terminal" cmd /c ""%executable%" || pause"
	
	popd

:end
	echo.
