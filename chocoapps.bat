@echo off
:: Check if running with administrative privileges
>nul 2>&1 net session
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    :: Run the batch file with administrative privileges
    powershell -command Start-Process "%0" -Verb RunAs
    exit /b
)
cd /d "C:\prep\NewWindowsScripts"
start c:\python310\python.exe install_apps.py



