@echo off

REM Invoke PowerShell to run the script from the provided URL
REM powershell.exe -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/workstationprep.ps1 | iex"
powershell.exe -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/configure.ps1 | iex"

REM Run the Choco Installer using Python
echo Starting Chocolatey App Installer
C:\Python310\python.exe c:\prep\NewWindowsScripts\install_apps.py

REM Call the configure.ps1 PowerShell script
REM powershell.exe -ExecutionPolicy Bypass -File "c:\prep\NewWindowsScripts\configure.ps1"

REM Call the cleanupapps.ps1 PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "c:\prep\NewWindowsScripts\cleanupapps.ps1"

REM Download Windows 10 Debloater Script
REM powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Sycnex/Windows10Debloater/master/Windows10Debloater.ps1' -OutFile 'C:\prep\NewWindowsScripts\debloat.ps1'"

REM Run the Debloater Script
REM cd /d "C:\prep\NewWindowsScripts"
REM powershell -ExecutionPolicy Bypass -File "debloat.ps1"

REM Pause to keep the command prompt window open
pause
