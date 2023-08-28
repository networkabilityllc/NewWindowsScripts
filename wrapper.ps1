# Your 3rd party script code
. "c:\prep\NewWindowsScripts\debloat.ps1"

# Prompt asking if you'd like to reboot your machine
$Prompt0 = [Windows.MessageBox]::Show($Reboot, "Reboot", $Button, $Warn)
Switch ($Prompt0) {
    Yes {
        Write-Host "Unloading the HKCR drive..."
        Remove-PSDrive HKCR
        Start-Sleep 1
        Write-Host "Initiating reboot."
        Stop-Transcript
        Start-Sleep 2
        Restart-Computer
    }
    No {
        Write-Host "Unloading the HKCR drive..."
        Remove-PSDrive HKCR
        Start-Sleep 1
        Write-Host "Script has finished."
        Stop-Transcript
        Start-Sleep 2
    }
}