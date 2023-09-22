@echo off
:: Check if running with administrative privileges
>nul 2>&1 net session
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    :: Run the batch file with administrative privileges
    powershell -command Start-Process "%0" -Verb RunAs
    exit /b
)

REM Invoke PowerShell to run the script from the provided URL in a separate window
start powershell.exe -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/configure.ps1 | iex"
