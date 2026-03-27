@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BIN=%SCRIPT_DIR%clay-sandbox.exe"

if not exist "%BIN%" (
    echo claw wallet sandbox is not installed. Expected binary at: %BIN%
    echo Run: %SCRIPT_DIR%install.ps1
    exit /b 1
)

if "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" start
    exit /b 0
)

if /I "%~1"=="start" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" start
    exit /b 0
)

if /I "%~1"=="restart" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" restart
    exit /b 0
)

if /I "%~1"=="stop" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" stop
    exit /b 0
)

if /I "%~1"=="is-running" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" is-running
    exit /b %ERRORLEVEL%
)

if /I "%~1"=="upgrade" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" upgrade
    exit /b %ERRORLEVEL%
)

if /I "%~1"=="uninstall" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%claw-wallet.ps1" uninstall
    exit /b %ERRORLEVEL%
)

"%BIN%" %*
