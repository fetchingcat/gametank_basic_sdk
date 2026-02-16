@echo off
REM make.cmd - GNU Make wrapper for GameTank BASIC SDK
REM Finds make.exe even if not on PATH (GnuWin32 default install location)

where make.exe >nul 2>nul
if not errorlevel 1 (
    make.exe %*
    goto :eof
)

set "GNUMAKE=C:\Program Files (x86)\GnuWin32\bin\make.exe"
if exist "%GNUMAKE%" (
    "%GNUMAKE%" %*
    goto :eof
)

echo ERROR: GNU Make not found.
echo Install with:  winget install GnuWin32.Make
echo Then use:      .\make compile FILE=examples/game.bas
exit /b 1
