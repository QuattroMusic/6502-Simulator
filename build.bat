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
	start "%executable:~0,-4% - Terminal - %date% %time%" cmd /c ""%executable%" || pause"
	
	popd

:end
	echo.
