# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Enable global confirmation for Chocolatey
choco feature enable -n allowGlobalConfirmation

# Install Boxstarter using Chocolatey
choco install boxstarter --force

# Additional commands can be added here