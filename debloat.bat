@echo off
REM This batch script performs various tasks related to Windows configuration and software setup.

REM Set PowerShell execution policy to Bypass for LocalMachine
powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"

REM Download Windows 10 Debloater Script
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Sycnex/Windows10Debloater/master/Windows10Debloater.ps1' -OutFile 'C:\prep\NewWindowsScripts\debloat.ps1'"

REM Run the Debloater Script
powershell -File "C:\prep\NewWindowsScripts\debloat.ps1"

REM Run Windows Configuration Script
powershell.exe -ExecutionPolicy Bypass -File "c:\prep\NewWindowsScripts\configure.ps1"

REM Download Splashtop SOS
powershell -Command "Invoke-WebRequest -Uri 'https://download.splashtop.com/sos/SplashtopSOS.exe' -OutFile 'C:\Users\Default\Desktop\SplashtopSOS.exe'"

REM Display a message indicating success
echo Application has been placed on all users' desktops.

REM Run the Choco Installer using Python
echo Starting Chocolatey App Installer
python c:\prep\NewWindowsScripts\install_apps.py

REM Pause to keep the command prompt window open
pause
