@echo off

REM Invoke PowerShell to run the script from the provided URL
powershell.exe -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/configure.ps1 | iex"

REM Run the Choco Installer using Python
echo Starting Chocolatey App Installer
C:\Python310\python.exe c:\prep\NewWindowsScripts\install_apps.py

REM Call the cleanupapps.ps1 PowerShell script
echo Cleaning up Apps

:: Define a temporary VBScript file for the pop-up message
set vbscriptFile=%temp%\popup.vbs

:: Create the VBScript content in the temporary file
(
   echo MsgBox "This window will close, and the screen will flash for a bit. Click OK to continue, and the next prompt after this window closes will be the UAC toggle."
) > "%vbscriptFile%"

:: Run the VBScript to show the pop-up message
cscript //nologo "%vbscriptFile%"

:: Delete the temporary VBScript file
del "%vbscriptFile%"

:: Run the cleanupapps.ps1 PowerShell script with Hidden WindowStyle
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "c:\prep\NewWindowsScripts\cleanupapps.ps1"

:: Continue with the rest of your script

REM Call the Toggle UAC PowerShell script
echo Toggling UAC
powershell.exe -ExecutionPolicy Bypass -File "c:\prep\NewWindowsScripts\toggle-uac.ps1"

REM Pause to keep the command prompt window open

