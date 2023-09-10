# Load the System.Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Function to toggle UAC
# Display a dialog box to ask if the user wants to re-enable UAC
$dialogResult = [System.Windows.Forms.MessageBox]::Show("Do you want to re-enable UAC?", "UAC Re-enable", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
    Enable-UAC
    Write-Host "UAC has been re-enabled."
} else {
    Write-Host "UAC remains disabled."
}
