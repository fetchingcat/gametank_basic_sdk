@echo off
REM Launch GameTank emulator with a .gtr ROM file
REM Checks GAMETANK_EMULATOR env var first, then PATH

if defined GAMETANK_EMULATOR (
    "%GAMETANK_EMULATOR%" %1
    exit /b %ERRORLEVEL%
)

where gte >nul 2>&1
if %ERRORLEVEL% equ 0 (
    gte %1
    exit /b %ERRORLEVEL%
)

where GameTankEmulator >nul 2>&1
if %ERRORLEVEL% equ 0 (
    GameTankEmulator %1
    exit /b %ERRORLEVEL%
)

echo ERROR: Emulator not found. Set GAMETANK_EMULATOR or add gte to PATH. >&2
exit /b 1
