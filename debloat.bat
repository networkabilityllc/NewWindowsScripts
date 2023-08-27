@echo off

:: Set PowerShell execution policy to Bypass for LocalMachine
powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"

:: Run the debloat.ps1 PowerShell script
powershell -File "C:\prep\debloat.ps1"
