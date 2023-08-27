@echo off

:: Set PowerShell execution policy to Bypass for LocalMachine
powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"

curl -o debloat.ps1 https://raw.githubusercontent.com/Sycnex/Windows10Debloater/master/Windows10Debloater.ps1

:: Run the debloat.ps1 PowerShell script
powershell -File "C:\prep\NewWindowsScripts\debloat.ps1"
