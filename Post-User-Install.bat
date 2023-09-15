@echo off

REM Invoke PowerShell to run the script from the provided URL in a separate window
start powershell.exe -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/configure.ps1 | iex"