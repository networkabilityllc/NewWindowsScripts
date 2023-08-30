REM Run the Choco Installer using Python
echo Starting Chocolatey App Installer
C:\Python310\python.exe c:\prep\NewWindowsScripts\install_apps.py

REM Call the cleanupapps.ps1 PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "c:\prep\NewWindowsScripts\configure.ps1"

REM Call the cleanupapps.ps1 PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "c:\prep\NewWindowsScripts\cleanupapps.ps1"

REM Download Windows 10 Debloater Script
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Sycnex/Windows10Debloater/master/Windows10Debloater.ps1' -OutFile 'C:\prep\NewWindowsScripts\debloat.ps1'"

REM Run the Debloater Script
cd /d "C:\prep\NewWindowsScripts"
powershell -ExecutionPolicy Bypass -File "debloat.ps1"


REM Pause to keep the command prompt window open
pause