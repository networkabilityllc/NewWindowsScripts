@echo off

:: Set PowerShell execution policy to Bypass for LocalMachine
powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"

curl -o debloat.ps1 https://raw.githubusercontent.com/Sycnex/Windows10Debloater/master/Windows10Debloater.ps1

:: Run the debloat.ps1 PowerShell script
powershell -File "C:\prep\NewWindowsScripts\wrapper.ps1"

:: Run the BoxStarter Windows Configuration
powershell.exe -ExecutionPolicy bypass -File c:\prep\NewWindowsScripts\configure.ps1

:: Run the Choco Installer 
python c:\prep\NewWindowsScripts\install_apps.py




REM Download Splashtop SOS
powershell -Command "Invoke-WebRequest -Uri 'https://download.splashtop.com/sos/SplashtopSOS.exe' -OutFile 'C:\Users\Default\Desktop\SplashtopSOS.exe'"

REM Get a list of user profiles in C:\Users
for /d %%A in (C:\Users\*) do (
    REM Copy the application to each user's desktop
    copy /Y "C:\Users\Default\Desktop\SplashtopSOS.exe" "%%A\Desktop\"
)

REM Optional: Display a message indicating success
echo Application has been placed on all users' desktops.
pause
:: Run the Choco Installer 
python c:\prep\NewWindowsScripts\install_apps.py
pause